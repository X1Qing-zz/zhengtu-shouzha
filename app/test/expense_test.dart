import 'package:flutter_test/flutter_test.dart';
import 'package:zhengtu_shouzha/data/models.dart';

void main() {
  final at = DateTime(2026, 10, 20, 9, 30);

  group('ledger entry type', () {
    test('legacy rows default to expense', () {
      final entry = Expense.fromMap({
        'id': 1,
        'amount': 12.5,
        'category': '餐饮',
        'note': '',
        'spent_at': at.toIso8601String(),
        'created_at': at.toIso8601String(),
      });

      expect(entry.isIncome, isFalse);
      expect(entry.signedAmount, -12.5);
      expect(entry.meta.name, '餐饮');
    });

    test('income persists and resolves an income category', () {
      final entry = Expense(
        amount: 6500,
        category: '工资',
        note: '实习工资',
        spentAt: at,
        createdAt: at,
        isIncome: true,
      );

      final map = entry.toMap();
      expect(map['is_income'], 1);

      final restored = Expense.fromMap(map);
      expect(restored.isIncome, isTrue);
      expect(restored.signedAmount, 6500);
      expect(restored.meta.name, '工资');
      expect(restored.meta.icon, isNotNull);
    });

    test('income and expense category lists stay separate', () {
      expect(categoriesFor(income: false).any((c) => c.name == '餐饮'), isTrue);
      expect(categoriesFor(income: true).any((c) => c.name == '工资'), isTrue);
      expect(categoriesFor(income: true).any((c) => c.name == '餐饮'), isFalse);
    });
  });
}
