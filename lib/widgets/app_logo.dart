import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double? width;
  
  const AppLogo({
    super.key,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final displayWidth = width ?? MediaQuery.of(context).size.width * 0.8;
    
    return Container(
      constraints: BoxConstraints(
        maxWidth: displayWidth,
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: Image.asset(
        'images/logo.png',
        fit: BoxFit.contain,
        width: displayWidth,
        errorBuilder: (context, error, stackTrace) {
          // Se a logo não carregar, mostrar ícone alternativo
          return Container(
            width: displayWidth,
            height: displayWidth * 0.5,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.favorite,
              size: displayWidth * 0.3,
              color: Colors.pink,
            ),
          );
        },
      ),
    );
  }
}

