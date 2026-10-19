String groupThousands(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// ¥1,280 / ¥1,280.50 — drops trailing .00 for a cleaner ledger.
String money(num value, {bool symbol = true, bool compactCents = true}) {
  final negative = value < 0;
  final abs = value.abs();
  final fixed = abs.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = groupThousands(parts[0]);
  final cents = parts[1];
  final showCents = !(compactCents && cents == '00');
  final body = showCents ? '$whole.$cents' : whole;
  return '${negative ? '-' : ''}${symbol ? '¥' : ''}$body';
}

String moneyPlain(num value) => money(value, symbol: false);

String compactMoney(num value) {
  if (value.abs() >= 10000) {
    return '¥${(value / 10000).toStringAsFixed(1)}w';
  }
  return money(value);
}

String amountInput(num value) {
  final fixed = value.toStringAsFixed(2);
  return fixed.endsWith('.00') ? fixed.substring(0, fixed.length - 3) : fixed;
}
