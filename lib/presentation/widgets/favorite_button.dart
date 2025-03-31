import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:tapeats/presentation/state_management/favorites_state.dart';

class FavoriteButton extends StatefulWidget {
  final int menuId;
  final Color? activeColor;
  final Color? inactiveColor;
  final double size;

  const FavoriteButton({
    super.key,
    required this.menuId,
    this.activeColor = const Color(0xFFD0F0C0),
    this.inactiveColor = const Color(0xFFEEEFEF),
    this.size = 24.0,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesState>(
      builder: (context, favoritesState, child) {
        final isFavorite = favoritesState.isFavorite(widget.menuId);
        
        // When favorited status changes, play animation
        if (isFavorite) {
          _controller.forward(from: 0.0);
        }
        
        return GestureDetector(
          onTap: () {
            favoritesState.toggleFavorite(widget.menuId);
            // Haptic feedback
            HapticFeedback.lightImpact();
          },
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Icon(
              isFavorite ? Iconsax.heart5 : Iconsax.heart,
              color: isFavorite ? widget.activeColor : widget.inactiveColor,
              size: widget.size,
            ),
          ),
        );
      },
    );
  }
}