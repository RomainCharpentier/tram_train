import 'package:flutter/material.dart';

/// Widget pour afficher le logo Train'Qil
class LogoWidget extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? textColor;

  const LogoWidget({
    super.key,
    this.size = 100.0,
    this.showText = true,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo avec l'image icon.png
        ClipOval(
          child: Image.asset(
            'assets/icon.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
            errorBuilder: (context, error, stackTrace) {
              // Fallback si l'image n'est pas trouvée
              return Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4A90E2), Color(0xFF2E5BBA)],
                  ),
                ),
                child: const Icon(
                  Icons.train,
                  color: Colors.white,
                  size: 40,
                ),
              );
            },
          ),
        ),

        if (showText) ...[
          const SizedBox(height: 8),
          Text(
            'Train\'Qil',
            style: TextStyle(
              fontSize: size * 0.18,
              fontWeight: FontWeight.bold,
              color: textColor ?? const Color(0xFF1E3A8A),
            ),
          ),
          Text(
            'Tranquille & Ponctuel',
            style: TextStyle(
              fontSize: size * 0.1,
              color: textColor ?? const Color(0xFF4A90E2),
            ),
          ),
        ],
      ],
    );
  }
}
