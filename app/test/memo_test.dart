import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhengtu_shouzha/core/theme.dart';
import 'package:zhengtu_shouzha/features/memo/memo_export.dart';
import 'package:zhengtu_shouzha/features/memo/memo_page.dart';

void main() {
  group('memo export', () {
    test('plain text keeps the body and adds a dated footer', () {
      final created = DateTime(2026, 10, 27, 20, 30);
      final text = memoPlainText(
        text: '  第一行\n第二行\n\n',
        createdAt: created,
      );

      expect(
        text,
        '勿忘\n'
        '2026 年 10 月 27 日 · 周二\n\n'
        '第一行\n第二行\n\n'
        '—— 征途手札 · 勿忘\n',
      );
    });

    test('file names are stable and timestamped', () {
      final created = DateTime(2026, 10, 27, 20, 30, 5);
      expect(
        memoTextFileName(created),
        'zhengtu_wuwang_20261027_203005.txt',
      );
      expect(
        memoImageFileName(created),
        'zhengtu_wuwang_20261027_203005.png',
      );
    });
  });

  testWidgets('export card shows the memo and date', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light, now: DateTime(2026, 10, 27)),
        home: Scaffold(
          body: SingleChildScrollView(
            child: MemoExportCard(
              text: '把今天没说完的话，留给明天的自己。',
              createdAt: DateTime(2026, 10, 27, 20, 30),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('没说完的话'), findsOneWidget);
    expect(find.textContaining('2026 年 10 月 27 日'), findsOneWidget);
    expect(find.textContaining('征途手札'), findsWidgets);
  });
}
