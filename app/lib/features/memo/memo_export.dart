import '../../core/date_utils.dart';

/// Plain-text representation used by the TXT export.
///
/// The memo itself is intentionally memory-only; this is the only place where
/// its contents become a file.
String memoPlainText({required String text, required DateTime createdAt}) {
  final body = text.trim();
  return '勿忘\n'
      '${fullDateLabel(createdAt)}\n\n'
      '$body\n\n'
      '—— 征途手札 · 勿忘\n';
}

String memoTextFileName(DateTime createdAt) =>
    'zhengtu_wuwang_${fileDateStamp(createdAt)}.txt';

String memoImageFileName(DateTime createdAt) =>
    'zhengtu_wuwang_${fileDateStamp(createdAt)}.png';
