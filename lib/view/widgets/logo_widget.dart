import 'package:flutter/material.dart';
import 'package:train_qil/view/theme/theme_x.dart';

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
        ClipOval(
          child: Image.asset(
            'assets/icon.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.theme.gradientStart,
                      context.theme.gradientEnd,
                    ],
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
              color: textColor ?? Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            'Tranquille & Ponctuel',
            style: TextStyle(
              fontSize: size * 0.1,
              color: textColor ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}
