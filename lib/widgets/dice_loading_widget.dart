import 'package:flutter/material.dart';

class DiceLoadingWidget extends StatelessWidget {
  final String? message;
  final double size;
  final Color? backgroundColor;
  final bool showMessage;

  const DiceLoadingWidget({
    super.key,
    this.message,
    this.size = 80.0,
    this.backgroundColor,
    this.showMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.transparent,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dice rolling GIF
            Image.asset(
              'assets/dice-roll-dice.gif',
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
            
            if (showMessage && message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Fullscreen loading overlay
class DiceLoadingOverlay extends StatelessWidget {
  final String? message;
  final bool isVisible;

  const DiceLoadingOverlay({
    super.key,
    this.message,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: DiceLoadingWidget(
          message: message,
          size: 100.0,
        ),
      ),
    );
  }
}

// Small inline dice loader
class DiceLoadingSmall extends StatelessWidget {
  final double size;

  const DiceLoadingSmall({
    super.key,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/dice-roll-dice.gif',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

// Loading dialog with dice animation
class DiceLoadingDialog extends StatelessWidget {
  final String? message;

  const DiceLoadingDialog({
    super.key,
    this.message,
  });

  static void show(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DiceLoadingDialog(message: message),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: DiceLoadingWidget(
          message: message ?? 'Loading...',
          size: 80.0,
          showMessage: true,
        ),
      ),
    );
  }
}
