import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:tapeats/presentation/screens/user_side/notification_page.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';
import 'package:tapeats/services/notification_service.dart';

class SettingsAdminPage extends StatefulWidget {
  const SettingsAdminPage({super.key});

  @override
  State<SettingsAdminPage> createState() => _SettingsAdminPageState();
}

class _SettingsAdminPageState extends State<SettingsAdminPage> {
  // Settings state
  bool _logUserActivities = true;
  bool _enablePushNotifications = true;
  bool _maintenanceMode = false;
  
  void _openSideMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const RoleBasedSideMenu(),
      ),
    );
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF151611),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            children: [
              // Header
              HeaderWidget(
                leftIcon: Iconsax.notification,
                onLeftButtonPressed: _navigateToNotifications,
                headingText: "Admin Settings",
                rightIcon: Iconsax.menu_1,
                onRightButtonPressed: _openSideMenu,
                notificationCount: notificationService.unreadCount,
              ),
              
              // Settings content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // App Settings Card
                    Card(
                      color: const Color(0xFF1A1A1A),
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'App Settings',
                              style: TextStyle(
                                color: Color(0xFFD0F0C0),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            _buildSettingToggle(
                              'Log User Activities',
                              'Track important user actions',
                              _logUserActivities,
                              (value) {
                                setState(() {
                                  _logUserActivities = value;
                                });
                              },
                            ),
                            
                            _buildSettingToggle(
                              'Enable Push Notifications',
                              'For order updates and alerts',
                              _enablePushNotifications,
                              (value) {
                                setState(() {
                                  _enablePushNotifications = value;
                                });
                              },
                            ),
                            
                            _buildSettingToggle(
                              'Maintenance Mode',
                              'Temporarily disable customer access',
                              _maintenanceMode,
                              (value) {
                                setState(() {
                                  _maintenanceMode = value;
                                });
                                // Show alert about maintenance mode
                                if (value) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Maintenance mode will disable customer-facing features'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Account Management Card
                    Card(
                      color: const Color(0xFF1A1A1A),
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Account Settings',
                              style: TextStyle(
                                color: Color(0xFFD0F0C0),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            _buildActionButton(
                              'Add Administrator',
                              Iconsax.user_add,
                              _showAddAdminDialog,
                            ),
                            
                            _buildActionButton(
                              'Change Password',
                              Iconsax.lock,
                              () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Password change feature coming soon'),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              },
                            ),
                            
                            _buildActionButton(
                              'Session Management',
                              Iconsax.mobile,
                              () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Session management feature coming soon'),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Danger Zone Card
                    Card(
                      color: Colors.red.withAlpha(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Danger Zone',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            _buildActionButton(
                              'Reset Database (Development Only)',
                              Iconsax.trash,
                              _showResetConfirmation,
                              textColor: Colors.red,
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
        ),
      ),
    );
  }
  
  Widget _buildSettingToggle(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFEEEFEF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFEEEFEF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFD0F0C0),
            activeTrackColor: const Color(0xFF151611),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(
    String title, 
    IconData icon, 
    VoidCallback onPressed, 
    {Color textColor = const Color(0xFFEEEFEF)}
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          icon: Icon(icon, color: textColor),
          label: Text(
            title,
            style: TextStyle(color: textColor),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.centerLeft,
            backgroundColor: const Color(0xFF151611),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
  
  void _showAddAdminDialog() {
    final emailController = TextEditingController();
    String selectedRole = 'super_admin';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text(
          'Add Administrator',
          style: TextStyle(
            color: Color(0xFFEEEFEF),
            fontFamily: 'Helvetica Neue',
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Email Address:',
                  style: TextStyle(
                    color: Color(0xFFEEEFEF),
                    fontFamily: 'Helvetica Neue',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  style: const TextStyle(
                    color: Color(0xFFEEEFEF),
                    fontFamily: 'Helvetica Neue',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter email address',
                    hintStyle: TextStyle(
                      color: const Color(0xFFEEEFEF).withAlpha(120),
                      fontFamily: 'Helvetica Neue',
                    ),
                    filled: true,
                    fillColor: const Color(0xFF151611),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Admin Type:',
                  style: TextStyle(
                    color: Color(0xFFEEEFEF),
                    fontFamily: 'Helvetica Neue',
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF151611),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: selectedRole,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF222222),
                    underline: const SizedBox(),
                    style: const TextStyle(
                      color: Color(0xFFEEEFEF),
                      fontFamily: 'Helvetica Neue',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'super_admin',
                        child: Text('Super Admin (Full Access)'),
                      ),
                      DropdownMenuItem(
                        value: 'developer_admin',
                        child: Text('Developer Admin (Technical Access)'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'Helvetica Neue',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // In a real app, you would add the admin user here
              if (emailController.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Admin invitation sent to ${emailController.text}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text(
              'Add Admin',
              style: TextStyle(
                color: Color(0xFFD0F0C0),
                fontFamily: 'Helvetica Neue',
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text(
          'WARNING: Reset Database',
          style: TextStyle(
            color: Colors.red,
            fontFamily: 'Helvetica Neue',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'This will reset your database to default state. All user data, restaurants, and orders will be permanently deleted. This action cannot be undone!',
          style: TextStyle(
            color: Color(0xFFEEEFEF),
            fontFamily: 'Helvetica Neue',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFFD0F0C0),
                fontFamily: 'Helvetica Neue',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Show confirmation message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Database reset feature disabled in production'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withAlpha(50),
            ),
            child: const Text(
              'Reset Database',
              style: TextStyle(
                color: Colors.red,
                fontFamily: 'Helvetica Neue',
              ),
            ),
          ),
        ],
      ),
    );
  }
}