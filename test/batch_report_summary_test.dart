import 'package:flutter_test/flutter_test.dart';

import 'package:cobra_shield/core/models.dart';
import 'package:cobra_shield/services/batch_report_summary.dart';

void main() {
  ScanResult completed({int score = 0, bool partial = false, List<Finding> findings = const <Finding>[]}) =>
      ScanResult(
        kind: ScanKind.url,
        score: score,
        findings: findings,
        partial: partial,
      );

  test('summary counts are disjoint: completed, partial, invalid, failed', () {
    final results = <ScanResult>[
      completed(score: 5),
      completed(score: 15, partial: true),
      ScanResult.invalid(
        kind: ScanKind.url,
        issueCode: 'invalid_port',
        detail: 'invalid port',
        title: 'https://example.invalid:99999/',
      ),
      ScanResult.failed(
        kind: ScanKind.url,
        detail: 'unexpected error',
        title: 'https://example.invalid/',
      ),
    ];

    final summary = BatchReportSummary.fromResults(results);
    expect(summary.recognized, 4);
    expect(summary.completed, 1);
    expect(summary.partial, 1);
    expect(summary.unscanned, 2);
    expect(summary.invalidInput, 1);
    expect(summary.analysisFailed, 1);
  });

  test('low non-zero scores are not described as no indicators', () {
    final result = completed(
      score: 15,
      findings: const <Finding>[
        Finding(
          code: 'nested_url',
          severity: Severity.warn,
          title: 'رابط داخل رابط',
          detail: 'عنوان آخر مضمن',
          points: 15,
        ),
      ],
    );
    expect(BatchReportLabels.headline(result), 'مؤشرات محدودة');
  });

  test('zero-score informational findings are labeled as informational', () {
    final result = completed(
      findings: const <Finding>[
        Finding(
          code: 'reserved_test_domain',
          severity: Severity.info,
          title: 'نطاق اختباري',
          detail: 'نطاق محجوز',
        ),
      ],
    );
    expect(BatchReportLabels.headline(result), 'ملاحظات معلوماتية فقط');
  });

  test('zero-score result without findings keeps the neutral headline', () {
    expect(BatchReportLabels.headline(completed()), 'لا مؤشرات واضحة');
  });
}
