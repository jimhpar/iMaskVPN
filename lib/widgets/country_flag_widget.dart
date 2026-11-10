import 'package:flutter/material.dart';

class CountryFlagWidget extends StatelessWidget {
  final String countryCode;
  final String fallbackEmoji;
  final double width;
  final double height;

  const CountryFlagWidget({
    super.key,
    required this.countryCode,
    this.fallbackEmoji = '🌐',
    this.width = 28,
    this.height = 19,
  });

  @override
  Widget build(BuildContext context) {
    final code = countryCode.toLowerCase().trim();
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.asset(
          'assets/flags/$code.png',
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Text(
              fallbackEmoji,
              style: TextStyle(fontSize: height * 0.8),
            ),
          ),
        ),
      ),
    );
  }
}

