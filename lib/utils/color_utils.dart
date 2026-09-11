import 'package:flutter/material.dart';

// Converte una stringa esadecimale "AARRGGBB" o "RRGGBB" in un Color
Color parseHexColor(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6) buffer.write('FF');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}