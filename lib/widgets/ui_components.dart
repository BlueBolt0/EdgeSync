import 'package:flutter/material.dart';

// Confidence indicator widget
class ConfidenceIndicator extends StatelessWidget {
  final double confidence;
  final bool showLabel;
  
  const ConfidenceIndicator({
    super.key,
    required this.confidence,
    this.showLabel = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final percentage = (confidence * 100).round();
    final color = _getConfidenceColor(confidence);
    
    if (!showLabel) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        '$percentage%',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.teal),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      message!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class HarmonizerButton extends StatelessWidget {
  final bool isActive;
  final bool isMinimized;
  final VoidCallback onTap;

  const HarmonizerButton({
    super.key,
    required this.isActive,
    required this.isMinimized,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.teal : Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isActive
                  ? const ImageIcon(
                      AssetImage('assets/icons/harmonizer.png'),
                      color: Colors.white,
                      size: 18,
                      key: ValueKey('active'),
                    )
                  : ImageIcon(
                      const AssetImage('assets/icons/harmonizer.png'),
                      color: Colors.white70,
                      size: 18,
                      key: const ValueKey('inactive'),
                    ),
            ),
            const SizedBox(width: 8),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isMinimized
                  ? const SizedBox.shrink()
                  : Text(
                      'Harmonizer',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white54,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacyButton extends StatelessWidget {
  final bool isActive;
  final bool isMinimized;
  final VoidCallback onTap;

  const PrivacyButton({
    super.key,
    required this.isActive,
    required this.isMinimized,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.deepPurple : Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isActive
                  ? const ImageIcon(
                      AssetImage('assets/icons/privacy.png'),
                      color: Colors.white,
                      size: 18,
                      key: ValueKey('active'),
                    )
                  : ImageIcon(
                      const AssetImage('assets/icons/privacy.png'),
                      color: Colors.white70,
                      size: 18,
                      key: const ValueKey('inactive'),
                    ),
            ),
            const SizedBox(width: 8),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isMinimized
                  ? const SizedBox.shrink()
                  : Text(
                      'Privacy',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white54,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedCountdownWidget extends StatefulWidget {
  final int countdown;

  const AnimatedCountdownWidget({
    super.key,
    required this.countdown,
  });

  @override
  State<AnimatedCountdownWidget> createState() => _AnimatedCountdownWidgetState();
}

class _AnimatedCountdownWidgetState extends State<AnimatedCountdownWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(AnimatedCountdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.countdown != oldWidget.countdown && widget.countdown > 0) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.countdown <= 0) {
      return const SizedBox.shrink();
    }

    return Center(
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.teal,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                '${widget.countdown}',
                style: const TextStyle(
                  fontSize: 72,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Custom snackbar for harmonizer actions
class HarmonizerSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    bool isSuccess = true,
    VoidCallback? action,
    String? actionLabel,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? Colors.teal : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: action != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: action,
              )
            : null,
      ),
    );
  }
}

// Gradient button for primary actions
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final List<Color> colors;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.colors = const [Colors.teal, Colors.cyan],
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: onPressed != null ? colors : [Colors.grey, Colors.grey],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
