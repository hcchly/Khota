import 'package:flutter_test/flutter_test.dart';
import 'package:khota_app/services/report_location_service.dart';

void main() {
  test('address shows district and street in Arabic', () {
    expect(
      GpsReportLocationProvider.formatAddress({
        'suburb': 'العليا',
        'road': 'طريق الملك فهد',
      }),
      'حي العليا، طريق الملك فهد',
    );
  });

  test('district already starting with حي is not repeated', () {
    expect(
      GpsReportLocationProvider.formatAddress({'neighbourhood': 'حي الملقا'}),
      'حي الملقا',
    );
  });

  test('only the city is known: show the city', () {
    expect(GpsReportLocationProvider.formatAddress({'city': 'الرياض'}), 'الرياض');
  });

  test('nothing known gives null', () {
    expect(GpsReportLocationProvider.formatAddress({}), isNull);
  });
}
