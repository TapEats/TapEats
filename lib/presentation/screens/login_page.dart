import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151611), // Background color #151611
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TapEats Logo (assuming it's a Text for now)
              const SizedBox(height: 100),
              const Text(
                'TapEats',
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Color(0xFFEEEFEF), // Text color #EEEFEF
                  fontSize: 42, // Font size for the logo
                  fontWeight: FontWeight.normal, // Font: Helvetica Neue Bold
                  fontFamily: 'Helvetica Neue',
                ),
              ),
              const SizedBox(height: 30),

              // Welcome Text
              const Text(
                'Hi! Welcome To TapEats',
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Color(0xFFEEEFEF), // Text color #EEEFEF
                  fontSize: 28,
                  fontWeight: FontWeight.w300, // Lighter weight
                  fontFamily: 'Helvetica Neue',
                ),
              ),
              const SizedBox(height: 20),

              // Instruction Text
              const Text(
                'Enter your phone number',
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Color(0xFFEEEFEF), // Text color #EEEFEF
                  fontSize: 16,
                  fontWeight: FontWeight.w500, // Medium weight
                  fontFamily: 'Helvetica Neue',
                ),
              ),
              const SizedBox(height: 10),

              // Country Dropdown and Phone Number Row
              Row(
                children: [
                  // Country Dropdown Button
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor:
                            const Color(0xFF222222), // Dropdown background
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      dropdownColor:
                          const Color(0xFF222222), // Dropdown list background
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFFD0F0C0),
                        size: 20, // Highlight color for dropdown icon
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'US',
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/us.png', // Path to the flag PNG
                                width: 24,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                '+1',
                                style: TextStyle(
                                  color: Color(0xFFEEEFEF),
                                  fontSize: 16,
                                  fontFamily: 'Helvetica Neue',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'IN',
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/in.png', // Path to the flag PNG
                                width: 24,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                '+91',
                                style: TextStyle(
                                  color: Color(0xFFEEEFEF),
                                  fontSize: 16,
                                  fontFamily: 'Helvetica Neue',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        // Handle dropdown change
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Phone Number Text Field with Inner Shadow
                  Expanded(
                    flex: 2,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF222222), // Background color
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Stack(
                              children: [
                                // Inner shadow effect using gradient
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.black.withOpacity(0.25),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.7],
                                    ),
                                  ),
                                ),
                                TextField(
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                      Icons.call,
                                      color: Color(
                                          0xFFD0F0C0), // Highlight color for icon
                                    ),
                                    hintText: 'Phone Number',
                                    hintStyle: const TextStyle(
                                      color: Color(
                                          0xFFEEEFEF), // Text color #EEEFEF
                                      fontFamily: 'Helvetica Neue',
                                      fontWeight: FontWeight.w200,
                                      fontSize: 16,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 18),
                                  ),
                                  style: const TextStyle(
                                    color:
                                        Color(0xFFEEEFEF), // Input text color
                                    fontFamily: 'Helvetica Neue',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(), // Push content up and button to the bottom

              // Next Button at the Bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: ElevatedButton(
                  onPressed: () {
                    // Handle login action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                        0xFFD0F0C0), // Button background color #D0F0C0
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      color: Color(
                          0xFF151611), // Button text color (contrasting background)
                      fontSize: 18,
                      fontWeight: FontWeight.normal, // Font: Helvetica Neue
                      fontFamily: 'Helvetica Neue',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
