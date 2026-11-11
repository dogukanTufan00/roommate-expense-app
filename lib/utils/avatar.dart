import 'package:flutter/material.dart';

// Warm pastel colors for member avatars.
const List<Color> _avatarColors = [
  Color(0xFFF4A261),
  Color(0xFF81B29A),
  Color(0xFFE07A5F),
  Color(0xFF8E7DBE),
  Color(0xFFF2CC8F),
  Color(0xFF6D9DC5),
];

// The same person always gets the same color on every screen,
// because the color depends only on their user id.
Color avatarColor(int userId) {
  return _avatarColors[userId % _avatarColors.length];
}

// The letters shown inside an avatar: the first letter of the first two words.
// For example "Ayşe Kaya" gives "AK", and an empty name gives "?".
String initials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final letters = words.take(2).map((w) => w.substring(0, 1).toUpperCase()).join();
  return letters.isEmpty ? '?' : letters;
}
