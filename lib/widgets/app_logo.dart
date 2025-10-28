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
      ),
    );
  }
}

