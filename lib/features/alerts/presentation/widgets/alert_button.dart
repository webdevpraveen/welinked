import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/core/constants/alert_constants.dart';
import 'package:welinked/features/alerts/presentation/providers/alert_providers.dart';

class AlertButton extends ConsumerStatefulWidget {
  final AlertType type;
  final VoidCallback onTap;

  const AlertButton({
    super.key,
    required this.type,
    required this.onTap,
  });

  @override
  ConsumerState<AlertButton> createState() => _AlertButtonState();
}

class _AlertButtonState extends ConsumerState<AlertButton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cooldownMap = ref.watch(alertCooldownProvider);
    final isCoolingDown = ref.read(alertCooldownProvider.notifier).isCoolingDown(widget.type);
    
    // Calculate remaining seconds if in cooldown
    int remainingSeconds = 0;
    if (isCoolingDown && cooldownMap[widget.type] != null) {
      remainingSeconds = cooldownMap[widget.type]!.difference(DateTime.now()).inSeconds + 1;
    }

    return GestureDetector(
      onTapDown: isCoolingDown ? null : (_) {
        _animController.forward();
        HapticFeedback.mediumImpact();
      },
      onTapUp: isCoolingDown ? null : (_) {
        _animController.reverse();
        widget.onTap();
      },
      onTapCancel: isCoolingDown ? null : () => _animController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isCoolingDown ? theme.cardColor : widget.type.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isCoolingDown
                ? []
                : [
                    BoxShadow(
                      color: widget.type.color.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.type.icon,
                size: 44,
                color: isCoolingDown 
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                    : widget.type.textColor,
              ),
              const SizedBox(height: 12),
              Text(
                widget.type.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isCoolingDown 
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                      : widget.type.textColor,
                  letterSpacing: 1.0,
                ),
              ),
              if (isCoolingDown) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Cooldown: ${remainingSeconds}s',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
