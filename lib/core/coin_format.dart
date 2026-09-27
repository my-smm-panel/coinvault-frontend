/// Shared Indian-format coin formatter used across all screens.
/// Example: 12345678 -> "1,23,45,678"
String formatCoins(int n) {
  final neg = n < 0;
  final d = n.abs().toString();
  if (d.length <= 3) return (neg ? '-' : '') + d;
  final head = d.substring(0, d.length - 3);
  final buf = StringBuffer();
  for (var i = 0; i < head.length; i++) {
    final posFromEnd = head.length - i;
    buf.write(head[i]);
    if (posFromEnd > 1 && posFromEnd % 2 == 1) buf.write(',');
  }
  buf.write(',');
  buf.write(d.substring(d.length - 3));
  return (neg ? '-' : '') + buf.toString();
}
