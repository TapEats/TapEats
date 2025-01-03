import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tapeats/presentation/screens/user_side/order_history_page.dart';

class SideMenuOverlay extends StatefulWidget {
  const SideMenuOverlay({super.key});

  @override
  State<SideMenuOverlay> createState() => _SideMenuOverlayState();
}

class _SideMenuOverlayState extends State<SideMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

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
                      const CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            AssetImage('assets/images/cupcake.png'),
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
          fontFamily: 'Helvetica Neue',
        ),
      ),
      onTap: () {
        if (title == 'History') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OrderHistoryPage(
                cartItems: {}, // Pass cartItems if needed
                totalItems: 0, // Pass the total item count
              ),
            ),
          );
        } else {
          // Handle other menu item taps if needed
        }
      },
    );
  }
}
