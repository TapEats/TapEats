import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:tapeats/presentation/widgets/box_for_graph.dart';
import 'package:tapeats/presentation/widgets/custom_footer_five_button_widget.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/rectanglebox_for_graph.dart';
import 'package:tapeats/presentation/widgets/slider_button.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart'; // Import the side menu overlay

class RestaurantHomePage extends StatefulWidget {
  final int selectedIndex; // Required for footer navigation

  const RestaurantHomePage({super.key, required this.selectedIndex});

  @override
  State<RestaurantHomePage> createState() => _RestaurantHomePageState();
}

class _RestaurantHomePageState extends State<RestaurantHomePage> {
  // Function to open the profile page
  void _openProfile() {
    // Navigator.push to ProfilePage can be added here when needed.
  }

  // Function to open the side menu
  void _openSideMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // Keep the background semi-transparent
        pageBuilder: (_, __, ___) => const RoleBasedSideMenu(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151611), // Dark background color
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header Section
                HeaderWidget(
                  leftIcon: Iconsax.user,
                  onLeftButtonPressed: _openProfile, // Open profile on click
                  headingText: 'Orders',
                  headingIcon: Iconsax.activity, // The icon on the header
                  rightIcon: Iconsax.menu_1,
                  onRightButtonPressed:
                      _openSideMenu, // Open side menu on click
                ),
                const SizedBox(height: 20),

                // Heading Text 'Serve Your Signature Experience'
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Serve Your\nSignature\nExperience',
                      style: GoogleFonts.greatVibes(
                        // Use Great Vibes font
                        color:
                            const Color(0xFFD0F0C0), // Updated color for text
                        fontSize: 48, // Font size
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Row of Image Boxes (RoundedSquareImageBox and RoundedImageBox)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      RoundedImageBox(
                        imageUrl: 'assets/images/box.jpg', // Example image path
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Another Row of Image Boxes
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: RoundedSquareImageBox(
                          imageUrl:
                              'assets/images/box.jpg', // Example image path
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RoundedSquareImageBox(
                          imageUrl:
                              'assets/images/box.jpg', // Example image path
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Slider Button Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: SliderButton(
                    labelText: 'Orders',
                    subText: '2 received', // The number of orders dynamically
                    onSlideComplete: () {
                      // Handle the slide completion here (e.g., navigate to orders page)
                    }, pageId: 'restaurant_orders',
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),

            // Macaroon image at the top-right corner
            Positioned(
              top: 80,
              right: 10,
              child: Image.asset(
                'assets/images/macaroon_1.png', // Path to the macaroon image
                height: 80,
                width: 80,
              ),
            ),
          ],
        ),
      ),

      // Custom Footer Section
      bottomNavigationBar: CustomFiveFooter(
        selectedIndex:
            widget.selectedIndex, // Ensure the correct index is passed
      ),
    );
  }
}
