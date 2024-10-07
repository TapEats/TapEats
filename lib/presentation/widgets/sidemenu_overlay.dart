import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class SideMenuOverlay extends StatefulWidget {
  const SideMenuOverlay({super.key});

  @override
  State<SideMenuOverlay> createState() => _SideMenuOverlayState();
}

class _SideMenuOverlayState extends State<SideMenuOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250), // Reduced duration for faster closing
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0), // Start off-screen to the left
      end: Offset.zero, // End on-screen
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward(); // Animate menu open
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeMenu() {
    _controller.reverse().then((_) => Navigator.of(context).pop());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _closeMenu, // Close menu when tapping on the background
      onHorizontalDragUpdate: (details) {
        if (details.primaryDelta != null && details.primaryDelta! < 0) {
          _closeMenu(); // Close menu when swiping to the left
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.5), // Semi-transparent background
        body: Stack(
          children: [
            GestureDetector(
              onTap: () {}, // Prevent the background tap from closing the menu when tapping inside the menu
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  width: 250,
                  height: MediaQuery.of(context).size.height,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A), // Background color of menu
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      // Image at the top
                      const CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage('assets/images/cupcake.png'), // Add your own image asset here
                      ),
                      const SizedBox(height: 20),
                      _buildMenuItem('Home', Iconsax.home),
                      _buildMenuItem('Menu', Iconsax.book_saved),
                      _buildMenuItem('Cart', Iconsax.shopping_cart),
                      _buildMenuItem('Favourites', Iconsax.heart),
                      _buildMenuItem('Status', Iconsax.timer_1),
                      _buildMenuItem('History', Iconsax.calendar),
                      _buildMenuItem('Profile', Iconsax.user),
                      _buildMenuItem('Sign out', Iconsax.logout),
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

  Widget _buildMenuItem(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontFamily: 'Helvetica Neue', // Assuming you are using this font
        ),
      ),
      onTap: () {
        // Define actions for each menu item
      },
    );
  }
}
