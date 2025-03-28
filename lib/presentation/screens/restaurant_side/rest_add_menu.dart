import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:tapeats/presentation/widgets/custom_footer_five_button_widget.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';

class AddMenuPage extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController timeToPrepareController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController ingredientsController = TextEditingController();
  final int selectedIndex; // Make this dynamic to pass the selected index

  AddMenuPage({super.key, required this.selectedIndex});

  void _openProfile() {
    // Add your logic to open the profile page
  }

  void _openSideMenu() {
    // Add your logic to open the side menu
  }

  void _saveMenu() {
    // Add your logic to save the menu item to the database
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF151611), // Dark background color to match other pages
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header Section
                HeaderWidget(
                  leftIcon: Iconsax.user,
                  onLeftButtonPressed: _openProfile, // Open profile on click
                  headingText: 'Add Menu',
                  headingIcon: Iconsax.activity, // The icon on the header
                  rightIcon: Iconsax.menu_1,
                  onRightButtonPressed:
                      _openSideMenu, // Open side menu on click
                ),
                const SizedBox(height: 20),

                // Add a new section with different background color
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1F1B), // Slightly different color
                    borderRadius: BorderRadius.circular(20), // Rounded corners
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            // Add logic to upload an image here
                          },
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: const AssetImage(
                                'assets/images/cupcake.png'), // Placeholder image
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: Text(
                          'Italian Pizza',
                          style: GoogleFonts.lato(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Text Fields for Dish Details
                      CustomTextField(
                        controller: nameController,
                        title: 'Name',
                        hintText: 'Enter dish name',
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: timeToPrepareController,
                        title: 'Time to prepare (in mins)',
                        hintText: 'Enter preparation time',
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: priceController,
                        title: 'Price',
                        hintText: 'Enter price',
                      ),
                      const SizedBox(height: 20),
                      // CustomTextField(
                      //   controller: ingredientsController,
                      //   title: 'Ingredients',
                      //   hintText: 'Enter ingredients',
                      // ),
                    ],
                  ),
                ),

                const SizedBox(height: 40), // Space before the footer

                // Centered Save Button
                Center(
                  child: ElevatedButton(
                    onPressed: _saveMenu,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: const Color(0xFFD0F0C0), // Button color
                      padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 32), // Increased padding for size
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Menu',
                      style: TextStyle(fontSize: 18), // Increased font size
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // Custom Footer Section
      bottomNavigationBar: CustomFiveFooter(
        selectedIndex: selectedIndex, // Ensure the correct index is passed
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String title;
  final String hintText;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.title,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[400], // Change to match other pages
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white), // Text color
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[600]), // Hint text color
            contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[600]!), // Border color
            ),
          ),
        ),
      ],
    );
  }
}
