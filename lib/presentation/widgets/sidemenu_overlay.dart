import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/screens/user_side/favourite_page.dart';
import 'package:tapeats/presentation/screens/user_side/order_history_page.dart';
import 'package:tapeats/presentation/state_management/navbar_state.dart';
import 'package:tapeats/services/profile_image_service.dart';
import 'package:provider/provider.dart';
import 'package:tapeats/presentation/screens/user_side/home_page.dart';
import 'package:tapeats/presentation/screens/user_side/menu_page.dart';
import 'package:tapeats/presentation/screens/user_side/profile_page.dart';

class SideMenuOverlay extends StatefulWidget {
  const SideMenuOverlay({super.key});

  @override
  State<SideMenuOverlay> createState() => _SideMenuOverlayState();
}

class _SideMenuOverlayState extends State<SideMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  String? _profileImageUrl;
  final _supabase = Supabase.instance.client;
  final _profileImageService = ProfileImageService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final imageUrl = await _profileImageService.getProfileImageUrl(userId);
        if (mounted) {
          setState(() {
            _profileImageUrl = imageUrl;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in _loadProfileImage: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeMenu() {
    _controller.reverse().then((_) => Navigator.of(context).pop());
  }

  Future<void> _handleSignOut() async {
    try {
      // First close the menu with animation
      await _controller.reverse();
      if (!mounted) return;
      
      // Remove the overlay
      Navigator.of(context).pop();
      
      // Then sign out
      await _supabase.auth.signOut();
      if (!mounted) return;

      // Navigate to login using named route and clear stack
      await Navigator.of(context).pushNamedAndRemoveUntil(
        '/auth/login',
        (route) => false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error signing out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToPage(Widget page) async {
    if (page is OrderHistoryPage) {
      // For OrderHistoryPage, wait for animation to complete before navigation
      await _controller.reverse();
      if (!mounted) return;
      
      // Remove the overlay
      Navigator.of(context).pop();
      
      // Add a small delay to ensure overlay is completely gone
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;

      // Navigate to history page
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const OrderHistoryPage(),
        ),
      );
    } else {
      // Wait for animation
      await _controller.reverse();
      if (!mounted) return;
      
      // Remove the overlay
      Navigator.of(context).pop();
      
      // If we're currently in OrderHistoryPage or other pushed routes, pop them
      while (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Get the NavbarState and update the index
      final navbarState = Provider.of<NavbarState>(context, listen: false);
      
      if (page is HomePage) {
        navbarState.updateIndex(0);
      } else if (page is MenuPage) {
        navbarState.updateIndex(1);
      } else if (page is FavouritesPage) {
        navbarState.updateIndex(2);
      } else if (page is ProfilePage) {
        navbarState.updateIndex(3);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _closeMenu,
      onHorizontalDragUpdate: (details) {
        if (details.primaryDelta != null && details.primaryDelta! < 0) {
          _closeMenu();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black.withAlpha(128),
        body: Stack(
          children: [
            GestureDetector(
              onTap: () {},
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  width: 250,
                  height: MediaQuery.of(context).size.height,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : const AssetImage('assets/images/cupcake.png') as ImageProvider,
                      ),
                      const SizedBox(height: 20),
                      _buildMenuItem(
                        'Home',
                        Iconsax.home,
                        onTap: () => _navigateToPage(const HomePage()),
                      ),
                      _buildMenuItem(
                        'Menu',
                        Iconsax.book_saved,
                        onTap: () => _navigateToPage(const MenuPage()),
                      ),
                      _buildMenuItem(
                        'Favourites',
                        Iconsax.heart,
                        onTap: () => _navigateToPage(const FavouritesPage()),
                      ),
                      _buildMenuItem(
                        'History',
                        Iconsax.calendar,
                        onTap: () => _navigateToPage(const OrderHistoryPage()),
                      ),
                      _buildMenuItem(
                        'Profile',
                        Iconsax.user,
                        onTap: () => _navigateToPage(const ProfilePage()),
                      ),
                      _buildMenuItem(
                        'Sign out',
                        Iconsax.logout,
                        onTap: _handleSignOut,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontFamily: 'Helvetica Neue',
        ),
      ),
      onTap: onTap,
    );
  }
}