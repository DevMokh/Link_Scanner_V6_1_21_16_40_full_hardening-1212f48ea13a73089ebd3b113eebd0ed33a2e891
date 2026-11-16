import '../core/models.dart';

/// إحصاءات التقرير المجمّع. الحالات متنافية حتى لا يُحسب الفحص الجزئي
/// كفحص مكتمل، ولا يُحسب فشل التحليل كفحص جزئي.
class BatchReportSummary {
  const BatchReportSummary({
    required this.recognized,
    required this.completed,
    required this.partial,
    required this.unscanned,
    required this.invalidInput,
    required this.analysisFailed,
  });

  /// Number of URL-like inputs recognized by the batch parser.
  final int recognized;

  /// Fully completed local analyses (partial results are counted separately).
  final int completed;

  /// Analyses that returned a score but were marked partial.
  final int partial;

  /// Inputs that did not receive a usable score (invalid or analysis failure).
  final int unscanned;

  /// Inputs rejected by URL validation before scoring.
  final int invalidInput;

  /// Inputs for which analysis failed unexpectedly.
  final int analysisFailed;

  factory BatchReportSummary.fromResults(Iterable<ScanResult> results) {
    var recognized = 0;
    var completed = 0;
    var partial = 0;
    var invalidInput = 0;
    var analysisFailed = 0;

    for (final result in results) {
      recognized++;
      switch (result.state) {
        case ScanState.completed:
          if (result.partial) {
            partial++;
          } else {
            completed++;
          }
          break;
        case ScanState.invalidInput:
          invalidInput++;
          break;
        case ScanState.failed:
          analysisFailed++;
          break;
      }
    }

    return BatchReportSummary(
      recognized: recognized,
      completed: completed,
      partial: partial,
      unscanned: invalidInput + analysisFailed,
      invalidInput: invalidInput,
      analysisFailed: analysisFailed,
    );
  }
}

/// عنوان واضح للدرجة المنخفضة في التقرير المجمّع:
/// الدرجة الأقل من 20 قد تحتوي على إشارة ضعيفة، فلا نصفها بأنها بلا مؤشرات.
class BatchReportLabels {
  BatchReportLabels._();

  static String headline(ScanResult result) {
    if (!result.hasScore) return result.headline;

    final score = result.effectiveScore;
    if (score > 0 && score < kBandMedium) return 'مؤشرات محدودة';

    if (score == 0 &&
        result.findings.any((finding) => finding.severity != Severity.good)) {
      return 'ملاحظات معلوماتية فقط';
    }

    return result.headline;
  }
}
