import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/report_draft.dart';
import '../../services/report_camera_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/info_card.dart';

class ReportPhotoScreen extends StatefulWidget {
  const ReportPhotoScreen({super.key, this.initialDraft, this.camera});

  final ReportDraft? initialDraft;
  final ReportCameraService? camera;

  @override
  State<ReportPhotoScreen> createState() => _ReportPhotoScreenState();
}

class _ReportPhotoScreenState extends State<ReportPhotoScreen> {
  late final ReportCameraService _camera =
      widget.camera ?? ImagePickerReportCamera();
  late final TextEditingController _description = TextEditingController(
    text: widget.initialDraft?.description ?? '',
  );
  Uint8List? _image;
  bool _accepted = false;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _image = widget.initialDraft?.imageBytes;
    _accepted = _image != null;
    _loadImage(recover: true);
  }

  Future<void> _loadImage({bool recover = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final image = recover ? await _camera.recover() : await _camera.capture();
      if (!mounted) return;
      if (image != null) {
        setState(() {
          _image = image;
          _accepted = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر فتح الصورة أو الكاميرا. تحقّق من إذن الكاميرا وحاول مرة أخرى.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = AppColors.indigo.withValues(alpha: 0.65);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 12),
        child: GradientHeader(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppBar(
              primary: false,
              title: const Text('بلاغ جديد'),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: Colors.white,
              titleTextStyle: text.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
              children: [
                InfoCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const IconTile(
                            icon: Icons.photo_camera_outlined,
                            size: 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'صورة المشكلة',
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (_accepted)
                            const Tooltip(
                              message: 'تم اختيار الصورة',
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.teal,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ColoredBox(
                          color: AppColors.sand,
                          child: _image != null
                              ? AspectRatio(
                                  aspectRatio: 4 / 3,
                                  child: Image.memory(
                                    _image!,
                                    fit: BoxFit.contain,
                                    semanticLabel: 'معاينة صورة البلاغ',
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 40,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: AppColors.teal.withValues(
                                            alpha: 0.1,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add_a_photo_outlined,
                                          size: 36,
                                          color: AppColors.teal,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'ابدأ بصورة للمشكلة',
                                        style: text.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'ستتمكن من معاينتها قبل استخدامها',
                                        textAlign: TextAlign.center,
                                        style: text.bodySmall?.copyWith(
                                          color: muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      if (_busy) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(
                          color: AppColors.teal,
                          semanticsLabel: 'جارٍ تجهيز الصورة',
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (_image == null)
                        ElevatedButton.icon(
                          onPressed: _busy ? null : () => _loadImage(),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('التقاط صورة'),
                        )
                      else
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            foregroundColor: AppColors.indigo,
                            side: BorderSide(
                              color: AppColors.slate.withValues(alpha: 0.6),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _busy ? null : () => _loadImage(),
                          icon: const Icon(Icons.camera_alt_outlined, size: 20),
                          label: const Text('إعادة التصوير'),
                        ),
                      if (_image != null && !_accepted) ...[
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => setState(() => _accepted = true),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('استخدام الصورة'),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _error!,
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ],
                if (_accepted) ...[
                  const SizedBox(height: 20),
                  InfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'تفاصيل إضافية',
                                style: text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.sand,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'اختياري',
                                style: text.labelMedium?.copyWith(color: muted),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'هل هناك شيء آخر تود توضيحه؟',
                          style: text.bodySmall?.copyWith(color: muted),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _description,
                          enabled: !_busy,
                          minLines: 3,
                          maxLines: 5,
                          maxLength: ReportDraft.maxDescriptionLength,
                          decoration: const InputDecoration(
                            hintText: 'مثال: بلاط مكسور يعيق مرور المشاة',
                            fillColor: AppColors.warmWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).pop(
                            ReportDraft(
                              imageBytes: _image!,
                              description: _description.text.trim(),
                            ),
                          ),
                    child: const Text('حفظ الصورة والتفاصيل'),
                  ),
                ] else if (_image == null) ...[
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 20,
                        color: AppColors.teal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'لصورة واضحة، اختر إضاءة جيدة وأظهر العيب كاملًا.',
                          style: text.bodySmall?.copyWith(
                            color: muted,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
