import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

    void _openSideMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // Keep the background semi-transparent
        pageBuilder: (_, __, ___) => const SideMenuOverlay(),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151611),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Use the HeaderWidget with profile title and icons
              HeaderWidget(
                leftIcon: Iconsax.arrow_left_1,
                onLeftButtonPressed: () => Navigator.pop(context),
                headingText: 'Profile',
                headingIcon: Iconsax.user,
                rightIcon: Iconsax.menu_1,
                onRightButtonPressed: _openSideMenu,
              ),
              const SizedBox(height: 20),

              // Profile Picture with name and edit icon
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      margin: const EdgeInsets.only(top: 60),
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 60), // Space for the profile image overlap
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'John Doe',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontFamily: 'Helvetica Neue',
                                  color: Color(0xFFEEEFEF),
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Iconsax.edit,
                                size: 18,
                                color: Color(0xFFD0F0C0),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Profile Information
                          _buildInfoRow('Name:', 'John Doe'),
                          _buildInfoRow('Email:', 'johndoe@gmail.com'),
                          _buildInfoRow('Number:', '0123456789'),
                          _buildInfoRow('Date of Birth:', '01/01/01'),
                          _buildInfoRow('Gender:', 'Male'),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),

                  // Profile Picture
                  Positioned(
                    top: 0,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFFD0F0C0),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/cupcake.png', // Replace with your image path
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build each row of information
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Helvetica Neue',
              fontWeight: FontWeight.w400,
              color: Color(0xFFEEEFEF),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Helvetica Neue',
              fontWeight: FontWeight.w300,
              color: Color(0xFFEEEFEF), // Light color for the values
            ),
          ),
        ],
      ),
    );
  }
}
