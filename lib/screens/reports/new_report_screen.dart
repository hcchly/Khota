import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../models/report_draft.dart';
import '../../models/report_location.dart';
import '../../models/submitted_report.dart';
import '../../services/report_camera_service.dart';
import '../../services/report_location_service.dart';
import '../../services/report_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/info_card.dart';
import '../../widgets/live_camera.dart';
import '../../widgets/report_card.dart';
import '../../widgets/report_flow_header.dart';
import '../info/photo_guide_screen.dart';

/// Saves a report document. Defaults to [ReportService.submit].
typedef SubmitReport = Future<void> Function(
  String reportId,
  ReportDraft draft,
  ReportLocation location,
);

/// New report in three steps: 1) photo, 2) location, 3) review and send.
/// Pops with a [SubmittedReport] after the report has been saved.
class NewReportScreen extends StatefulWidget {
  const NewReportScreen({
    super.key,
    this.initialDraft,
    this.camera,
    this.uploadImage,
    this.locationProvider,
    this.submitReport,
  });

  final ReportDraft? initialDraft;
  final ReportCameraService? camera;
  final Future<String> Function(Uint8List)? uploadImage;

  /// GPS, manual selection and the map. Until the location task is connected,
  /// [TemporaryReportLocationProvider] is used.
  final ReportLocationProvider? locationProvider;
  final SubmitReport? submitReport;

  static const uploadTimeout = Duration(seconds: 30);
  static const saveTimeout = Duration(seconds: 15);

  @override
  State<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends State<NewReportScreen>
    with WidgetsBindingObserver {
  late final ReportCameraService _camera =
      widget.camera ?? ImagePickerReportCamera();

  /// In-app camera shown inside the frame. Not used when a camera service is
  /// injected (tests), and falls back to the system camera when unavailable.
  LiveCameraController? _live;
  late final ReportLocationProvider _locator =
      widget.locationProvider ?? const TemporaryReportLocationProvider();
  late final TextEditingController _description = TextEditingController(
    text: widget.initialDraft?.description ?? '',
  );

  int _step = 1;

  // Step 1: photo.
  Uint8List? _image;
  String? _imageUrl;
  bool _picking = false;
  String? _photoError;

  // Step 2: location.
  ReportLocation? _location;
  String? _address;
  bool _locating = false;
  String? _locationError;

  // Step 3: send.
  bool _sending = false;
  bool _failedOnce = false;
  String? _sendError;

  /// Created once per report, so a retry reuses it and never duplicates.
  String? _reportId;

  @override
  void initState() {
    super.initState();
    _image = widget.initialDraft?.imageBytes;
    _imageUrl = widget.initialDraft?.imageUrl;
    _recoverLostPhoto();
    if (widget.camera == null) {
      _live = LiveCameraController()..addListener(_onLiveChanged);
      WidgetsBinding.instance.addObserver(this);
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncCamera());
    }
  }

  @override
  void dispose() {
    if (_live != null) WidgetsBinding.instance.removeObserver(this);
    _live?.removeListener(_onLiveChanged);
    _live?.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Release the camera in the background and reopen it on return.
    // ("inactive" is ignored: it also happens while the camera permission
    // dialog is shown, and stopping then would interrupt the start.)
    if (state == AppLifecycleState.resumed) {
      _syncCamera();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _live?.stop();
    }
  }

  void _onLiveChanged() {
    if (mounted) setState(() {});
  }

  /// True when the in-app camera can be used (or is starting).
  bool get _liveUsable {
    final status = _live?.status;
    return status != null &&
        status != LiveCameraStatus.denied &&
        status != LiveCameraStatus.unavailable;
  }

  /// The camera runs only while step 1 is shown without a photo.
  void _syncCamera() {
    final live = _live;
    if (live == null || !mounted) return;
    if (_step == 1 && _image == null && !_sending) {
      live.start();
    } else {
      live.stop();
    }
  }

  Future<void> _shoot() async {
    final live = _live;
    if (live == null || !live.isReady || _picking) return;
    setState(() {
      _picking = true;
      _photoError = null;
    });
    try {
      final image = await live.takePicture();
      if (!mounted) return;
      if (image != null) {
        setState(() {
          _image = image;
          _imageUrl = null;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _photoError = 'تعذّر التقاط الصورة. حاول مرة أخرى.',
      );
    } finally {
      if (mounted) setState(() => _picking = false);
      _syncCamera();
    }
  }

  /// Retake: back to the live camera, or the system camera as a fallback.
  void _retake() {
    if (_liveUsable) {
      setState(() {
        _image = null;
        _imageUrl = null;
        _photoError = null;
      });
      _syncCamera();
    } else {
      _pickPhoto(gallery: false);
    }
  }

  // ---------------------------------------------------------------- Step 1

  Future<void> _recoverLostPhoto() async {
    try {
      final image = await _camera.recover();
      if (!mounted || image == null) return;
      setState(() {
        _image = image;
        _imageUrl = null;
      });
    } catch (_) {
      // Nothing to recover.
    }
  }

  Future<void> _pickPhoto({required bool gallery}) async {
    setState(() {
      _picking = true;
      _photoError = null;
    });
    try {
      final image = gallery
          ? await _camera.pickFromGallery()
          : await _camera.capture();
      if (!mounted) return;
      if (image != null) {
        setState(() {
          _image = image;
          _imageUrl = null; // a new photo must be uploaded again
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _photoError = gallery
            ? 'تعذّر فتح الصور. تحقّق من إذن الوصول للصور وحاول مرة أخرى.'
            : 'تعذّر فتح الكاميرا. تحقّق من إذن الكاميرا وحاول مرة أخرى.';
      });
    } finally {
      if (mounted) setState(() => _picking = false);
      _syncCamera();
    }
  }

  void _openPhotoGuide() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PhotoGuideScreen()));
  }

  // ---------------------------------------------------------------- Step 2

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      final location = await _locator.currentLocation();
      if (!mounted) return;
      if (location == null || !location.isValid) {
        setState(
          () => _locationError =
              'تعذّر تحديد موقعك تلقائياً. حدّد الموقع يدوياً على الخريطة.',
        );
        return;
      }
      setState(() {
        _location = location;
        _address = null;
      });
      final address = await _locator.addressFor(location);
      if (mounted) setState(() => _address = address);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _locationError =
            'تعذّر تحديد موقعك تلقائياً. حدّد الموقع يدوياً على الخريطة.',
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickManually() async {
    final picked = await _locator.pickManually(context, _location);
    if (!mounted) return;
    if (picked == null) {
      if (_locator is TemporaryReportLocationProvider) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تحديد الموقع يدوياً سيتوفر قريباً.')),
        );
      }
      return;
    }
    setState(() {
      _location = picked;
      _address = null;
      _locationError = null;
    });
    final address = await _locator.addressFor(picked);
    if (mounted) setState(() => _address = address);
  }

  // ---------------------------------------------------------------- Step 3

  Future<void> _submit() async {
    if (_sending) return;
    if (_image == null) {
      setState(() => _step = 1);
      return;
    }
    if (_location == null) {
      setState(() => _step = 2);
      return;
    }
    setState(() {
      _sending = true;
      _sendError = null;
    });
    final stopwatch = Stopwatch()..start();
    var stage = 'upload';
    try {
      _imageUrl ??= await (widget.uploadImage ?? StorageService().uploadImage)(
        _image!,
      ).timeout(NewReportScreen.uploadTimeout);

      stage = 'save';
      _reportId ??= ReportService.generateId();
      await (widget.submitReport ?? ReportService().submit)(
        _reportId!,
        ReportDraft(
          imageBytes: _image!,
          description: _description.text.trim(),
          imageUrl: _imageUrl,
        ),
        _location!,
      ).timeout(NewReportScreen.saveTimeout);

      stopwatch.stop();
      // NFR evidence: time from pressing Send until the report is saved.
      debugPrint(
        '[Khota perf] report $_reportId saved in '
        '${stopwatch.elapsedMilliseconds} ms',
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        SubmittedReport(
          id: _reportId!,
          location: _location!,
          address: _address,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sendError = _messageFor(error, stage);
        _failedOnce = true;
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _messageFor(Object error, String stage) {
    if (error is StateError) return error.message;
    if (error is ArgumentError) return error.message.toString();
    if (error is TimeoutException) {
      return 'استغرق الإرسال وقتاً أطول من المتوقع. تحقّق من الاتصال وحاول مرة أخرى.';
    }
    final denied =
        error is FirebaseException &&
        [
          'unauthorized',
          'unauthenticated',
          'permission-denied',
        ].contains(error.code);
    if (stage == 'upload') {
      return denied
          ? 'تعذّر رفع الصورة. تأكّد من تسجيل الدخول وحاول مرة أخرى.'
          : 'تعذّر رفع الصورة. تحقّق من الاتصال وحاول مرة أخرى.';
    }
    return denied
        ? 'تعذّر حفظ البلاغ. تأكّد من تسجيل الدخول وحاول مرة أخرى.'
        : 'تعذّر حفظ البلاغ. تحقّق من الاتصال وحاول مرة أخرى.';
  }

  // ---------------------------------------------------------------- Flow

  void _goTo(int step) {
    setState(() => _step = step);
    _syncCamera();
    if (step == 2 && _location == null && !_locating) _locate();
  }

  void _back() {
    if (_sending) return;
    if (_step > 1) {
      setState(() => _step -= 1);
      _syncCamera();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  static const _titles = ['التقاط الصورة', 'تأكيد الموقع', 'مراجعة وإرسال'];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 1 && !_sending,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: Column(
          children: [
            ReportFlowHeader(
              title: _titles[_step - 1],
              step: _step,
              onBack: _sending ? null : _back,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: switch (_step) {
                    1 => _buildPhotoStep(context),
                    2 => _buildLocationStep(context),
                    _ => _buildReviewStep(context),
                  },
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildActions(context),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final List<Widget> buttons;
    switch (_step) {
      case 1:
        buttons = _image == null && _liveUsable
            ? [
                Center(
                  child: _ShutterButton(
                    onPressed: _live!.isReady && !_picking ? _shoot : null,
                  ),
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: _picking ? null : () => _pickPhoto(gallery: true),
                  icon: const Icon(Icons.photo_library_outlined, size: 20),
                  label: const Text('اختيار من المعرض'),
                ),
              ]
            : _image == null
            ? [
                ElevatedButton.icon(
                  onPressed: _picking ? null : () => _pickPhoto(gallery: false),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('التقاط صورة'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: _outlinedStyle,
                  onPressed: _picking ? null : () => _pickPhoto(gallery: true),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('اختيار من المعرض'),
                ),
              ]
            : [
                ElevatedButton(
                  onPressed: _picking ? null : () => _goTo(2),
                  child: const Text('استخدام الصورة'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: _outlinedStyle,
                        onPressed: _picking ? null : _retake,
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: const Text('إعادة التصوير'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: _outlinedStyle,
                        onPressed: _picking
                            ? null
                            : () => _pickPhoto(gallery: true),
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 20,
                        ),
                        label: const Text('من المعرض'),
                      ),
                    ),
                  ],
                ),
              ];
      case 2:
        buttons = [
          ElevatedButton(
            onPressed: _location == null || _locating ? null : () => _goTo(3),
            child: const Text('تأكيد الموقع'),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: _locating ? null : _pickManually,
            icon: const Icon(Icons.edit_location_alt_outlined, size: 20),
            label: const Text('تحديد الموقع يدوياً'),
          ),
        ];
      default:
        buttons = [
          ElevatedButton(
            onPressed: _sending ? null : _submit,
            child: _sending
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('جارٍ إرسال البلاغ…'),
                    ],
                  )
                : Text(_failedOnce ? 'إعادة المحاولة' : 'إرسال البلاغ'),
          ),
        ];
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: buttons,
          ),
        ),
      ),
    );
  }

  static final _outlinedStyle = OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(50),
    foregroundColor: AppColors.indigo,
    side: BorderSide(color: AppColors.slate.withValues(alpha: 0.8)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );

  // ---------------------------------------------------------------- Step 1 UI

  Widget _buildPhotoStep(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _image == null
                ? _buildCameraFrame()
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: Color(0xFF0E1C2C)),
                      Image.memory(
                        _image!,
                        fit: BoxFit.contain,
                        semanticLabel: 'معاينة صورة البلاغ',
                      ),
                      PositionedDirectional(
                        top: 12,
                        start: 12,
                        child: _Pill(
                          icon: Icons.visibility_outlined,
                          label: 'معاينة الصورة',
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_picking) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(
            color: AppColors.teal,
            semanticsLabel: 'جارٍ تجهيز الصورة',
          ),
        ],
        if (_photoError != null) ...[
          const SizedBox(height: 12),
          _ErrorBox(message: _photoError!),
        ],
        const SizedBox(height: 16),
        InfoCard(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.teal,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _image == null
                      ? 'صوّر المشكلة بوضوح مع إظهار ما حولها.'
                      : 'تأكّد أن المشكلة ظاهرة كاملة والصورة غير مهزوزة.',
                  style: text.bodySmall?.copyWith(height: 1.6),
                ),
              ),
              TextButton(
                onPressed: _openPhotoGuide,
                child: const Text('دليل التصوير'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Live camera inside the frame, or the placeholder when it is not usable.
  Widget _buildCameraFrame() {
    final live = _live;
    final camera = live?.camera;
    if (live != null && live.isReady && camera != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          LiveCameraPreview(controller: camera),
          IgnorePointer(child: CustomPaint(painter: _ViewfinderPainter())),
          PositionedDirectional(
            top: 12,
            end: 12,
            child: Material(
              color: Colors.black.withValues(alpha: 0.35),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: live.flashOn ? 'إطفاء الإضاءة' : 'تشغيل الإضاءة',
                onPressed: live.toggleFlash,
                icon: Icon(
                  live.flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          PositionedDirectional(
            bottom: 14,
            start: 14,
            end: 14,
            child: Center(
              child: _Pill(
                icon: Icons.center_focus_strong_outlined,
                label: 'أظهر المشكلة كاملة مع ما حولها',
              ),
            ),
          ),
        ],
      );
    }
    return switch (live?.status) {
      LiveCameraStatus.starting || LiveCameraStatus.idle => const _Viewfinder(
        message: 'جارٍ تشغيل الكاميرا…',
        busy: true,
      ),
      LiveCameraStatus.denied => const _Viewfinder(
        message:
            'لا يوجد إذن لاستخدام الكاميرا.\nفعّله من الإعدادات، أو اختر صورة من المعرض.',
      ),
      _ => const _Viewfinder(),
    };
  }

  // ---------------------------------------------------------------- Step 2 UI

  Widget _buildLocationStep(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = AppColors.indigo.withValues(alpha: 0.65);
    final map = _locator.buildMap(context, _location) ?? const _MapPlaceholder();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 300,
            child: Stack(
              fit: StackFit.expand,
              children: [
                map,
                if (_location != null)
                  PositionedDirectional(
                    top: 12,
                    start: 12,
                    end: 12,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _AddressChip(
                        text: _address ?? 'الموقع المحدد للبلاغ',
                      ),
                    ),
                  ),
                if (_locating)
                  ColoredBox(
                    color: Colors.white.withValues(alpha: 0.6),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.teal,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'جارٍ تحديد موقعك…',
                            style: text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_locationError != null) ...[
          _ErrorBox(
            message: _locationError!,
            actionLabel: 'إعادة المحاولة',
            onAction: _locating ? null : _locate,
          ),
          const SizedBox(height: 12),
        ],
        if (_location != null)
          InfoCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'موقع البلاغ',
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _address ?? _location!.coordinatesText,
                  textDirection: _address == null
                      ? TextDirection.ltr
                      : TextDirection.rtl,
                  style: text.bodyMedium?.copyWith(color: muted),
                ),
                const SizedBox(height: 12),
                LocationAccuracyBadge(location: _location!),
              ],
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------- Step 3 UI

  Widget _buildReviewStep(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = AppColors.indigo.withValues(alpha: 0.65);
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        // Photo.
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFF0E1C2C)),
                if (_image != null)
                  Image.memory(
                    _image!,
                    fit: BoxFit.cover,
                    semanticLabel: 'صورة البلاغ',
                  ),
                PositionedDirectional(
                  bottom: 12,
                  end: 12,
                  child: _EditButton(
                    label: 'تغيير الصورة',
                    onTap: _sending ? null : () => _goTo(1),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Location.
        InfoCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconTile(icon: Icons.location_on_outlined, size: 40),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الموقع',
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _address ?? _location?.coordinatesText ?? '',
                    style: text.bodyMedium?.copyWith(color: muted),
                  ),
                  if (_location != null) ...[
                    const SizedBox(height: 8),
                    LocationAccuracyBadge(location: _location!),
                  ],
                ],
              ),
              TextButton(
                onPressed: _sending ? null : () => _goTo(2),
                child: const Text('تعديل'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Optional details.
        InfoCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'تفاصيل إضافية',
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const StatusChip(label: 'اختياري', tone: StatusTone.neutral),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _description,
                enabled: !_sending,
                minLines: 2,
                maxLines: 4,
                maxLength: ReportDraft.maxDescriptionLength,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'تفاصيل إضافية (اختياري)',
                  alignLabelWithHint: true,
                  hintText: 'مثال: بلاط مكسور يعيق مرور المشاة',
                  fillColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // What happens after sending.
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.auto_awesome_outlined,
                color: AppColors.teal,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'بعد الإرسال، يحلّل النظام الصورة تلقائياً لتحديد نوع '
                  'المشكلة ومستوى خطورتها.',
                  style: text.bodySmall?.copyWith(
                    color: AppColors.teal,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_sendError != null) ...[
          const SizedBox(height: 14),
          _ErrorBox(message: _sendError!),
        ],
      ],
    );
  }
}

// ======================================================================
// Small widgets used by the flow.
// ======================================================================

/// GPS accuracy, as recommended in the UX review: a clear label and colour,
/// and a hint when accuracy is low.
class LocationAccuracyBadge extends StatelessWidget {
  const LocationAccuracyBadge({super.key, required this.location});

  final ReportLocation location;

  static const goodMeters = 20;
  static const fairMeters = 50;

  @override
  Widget build(BuildContext context) {
    final accuracy = location.accuracyMeters;
    final (IconData icon, String label, StatusTone tone, String? hint) =
        switch (location.source) {
          ReportLocation.sourceManual => (
            Icons.touch_app_outlined,
            'تم تحديده يدوياً على الخريطة',
            StatusTone.info,
            null,
          ),
          ReportLocation.sourceGps when accuracy == null => (
            Icons.gps_fixed,
            'تم تحديده من موقعك (GPS)',
            StatusTone.success,
            null,
          ),
          ReportLocation.sourceGps when accuracy! <= goodMeters => (
            Icons.gps_fixed,
            'دقة عالية · ± ${accuracy.round()} م',
            StatusTone.success,
            null,
          ),
          ReportLocation.sourceGps when accuracy! <= fairMeters => (
            Icons.gps_not_fixed,
            'دقة متوسطة · ± ${accuracy.round()} م',
            StatusTone.progress,
            null,
          ),
          ReportLocation.sourceGps => (
            Icons.gps_off_outlined,
            'دقة منخفضة · ± ${accuracy!.round()} م',
            StatusTone.warning,
            'لموقع أدق، انتقل إلى مكان مفتوح أو حدّد الموقع يدوياً.',
          ),
          _ => (
            Icons.science_outlined,
            'موقع تجريبي مؤقت',
            StatusTone.progress,
            null,
          ),
        };
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.indigo.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Flexible(child: StatusChip(label: label, tone: tone)),
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(
            hint,
            style: text.bodySmall?.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder({
    this.message = 'وجّه الكاميرا نحو المشكلة في الرصيف',
    this.busy = false,
  });

  final String message;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF16324F), Color(0xFF0E1C2C)],
            ),
          ),
        ),
        CustomPaint(painter: _ViewfinderPainter()),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: busy
                      ? const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        )
                      : const Icon(
                          Icons.photo_camera_outlined,
                          color: Colors.white,
                          size: 36,
                        ),
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Round shutter button, like the system camera.
class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'التقاط صورة',
      excludeSemantics: true,
      child: Tooltip(
        message: 'التقاط صورة',
        child: GestureDetector(
          onTap: onPressed,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: enabled ? 1 : 0.45,
            child: Container(
              width: 76,
              height: 76,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.indigo, width: 4),
              ),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.indigo,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.photo_camera_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final corner = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const m = 22.0, l = 28.0;
    final w = size.width, h = size.height;
    for (final (Offset a, Offset b, Offset c) in [
      (const Offset(m, m + l), const Offset(m, m), const Offset(m + l, m)),
      (Offset(w - m - l, m), Offset(w - m, m), Offset(w - m, m + l)),
      (Offset(m, h - m - l), Offset(m, h - m), Offset(m + l, h - m)),
      (Offset(w - m - l, h - m), Offset(w - m, h - m), Offset(w - m, h - m - l)),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..lineTo(c.dx, c.dy),
        corner,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Shown until the map from the location task is connected.
class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _MapPainter()),
        const Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 28),
            child: Icon(
              Icons.location_on,
              size: 52,
              color: AppColors.indigo,
              semanticLabel: 'موقع البلاغ',
            ),
          ),
        ),
      ],
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE4EBE5),
    );
    final block = Paint()..color = const Color(0xFFD5E0D7);
    final road = Paint()..color = const Color(0xFFF4EFE6);
    const roadW = 22.0;
    final cols = [0.22, 0.62];
    final rows = [0.28, 0.66];
    for (final c in cols) {
      canvas.drawRect(
        Rect.fromLTWH(size.width * c, 0, roadW, size.height),
        road,
      );
    }
    for (final r in rows) {
      canvas.drawRect(
        Rect.fromLTWH(0, size.height * r, size.width, roadW),
        road,
      );
    }
    final xs = [0.0, ...cols.map((c) => size.width * c + roadW), size.width];
    final ys = [0.0, ...rows.map((r) => size.height * r + roadW), size.height];
    for (var i = 0; i < xs.length - 1; i++) {
      for (var j = 0; j < ys.length - 1; j++) {
        final right = i + 1 < xs.length - 1
            ? size.width * cols[i] - 10
            : xs[i + 1] - 10;
        final bottom = j + 1 < ys.length - 1
            ? size.height * rows[j] - 10
            : ys[j + 1] - 10;
        final rect = Rect.fromLTRB(xs[i] + 10, ys[j] + 10, right, bottom);
        if (rect.width > 0 && rect.height > 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(8)),
            block,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AddressChip extends StatelessWidget {
  const _AddressChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo.withValues(alpha: 0.10),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.place_outlined, color: AppColors.teal, size: 20),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.indigo.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.indigo.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_outlined, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.error),
              ),
            ),
            if (actionLabel != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}
