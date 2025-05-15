import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/data/models/user.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';
import 'package:tapeats/services/profile_image_service.dart';
import 'package:tapeats/services/user_services.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _userService = UserService.instance;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool isEditing = false;
  bool isLoading = true;
  String? error;
  UserProfile? currentUser;
  final _profileImageService = ProfileImageService();
  File? _selectedImageFile;
  bool _isImageLoading = false;
  String? _currentImageUrl;
  bool _isImageRemoved = false;
  // Text editing controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  // Gender dropdown
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  String? _selectedGender;

  final _supabase = Supabase.instance.client;

  // Date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentUser?.dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFFD0F0C0),
              onPrimary: Colors.black,
              surface: const Color(0xFF1A1A1A),
              onSurface: const Color(0xFFEEEFED),
            ),
            dialogBackgroundColor: const Color(0xFF1A1A1A),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _fetchUserData();
    _fetchProfileImage();
  }

  Future<void> _fetchProfileImage() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Try to get the image from bucket
      final imageUrl = await _profileImageService.getProfileImageUrl(userId);

      if (mounted && imageUrl != null) {
        setState(() {
          // Store the URL directly in state
          _currentImageUrl = imageUrl;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching profile image: $e');
      }
    }
  }

  Future<void> _handleProfileImageUpload() async {
    if (!isEditing) return;

    try {
      setState(() => _isImageLoading = true);

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Pick image
      final imageFile = await _profileImageService.pickImage();
      if (imageFile == null) return;

      setState(() => _selectedImageFile = imageFile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select image: $e')),
        );
      }
    } finally {
      setState(() => _isImageLoading = false);
    }
  }

  Future<void> _handleRemoveProfileImage() async {
    if (!isEditing) return;
    setState(() {
      _selectedImageFile = null;
      _isImageRemoved = true;
      _currentImageUrl = null;
    });
  }

  Future<void> _fetchUserData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final user = await _userService.getCurrentUser();
      if (user != null) {
        setState(() {
          currentUser = user;
          _updateControllers(user);
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _updateControllers(UserProfile user) {
    _nameController.text = user.username ?? '';
    _emailController.text = user.email ?? '';

    // Handle phone number (assuming full number with country code)
    if (user.phoneNumber != null && user.phoneNumber!.length > 10) {
      _numberController.text =
          user.phoneNumber!.substring(user.phoneNumber!.length - 10);
    } else {
      _numberController.text = user.phoneNumber ?? '';
    }

    _dobController.text = user.dateOfBirth != null
        ? DateFormat('dd/MM/yyyy').format(user.dateOfBirth!)
        : '';

    _selectedGender = user.gender;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _numberController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> removeTemporaryImage(String imageUrl) async {
    try {
      final storageUrl = _supabase.storage.from('users').getPublicUrl('');
      final filePath = imageUrl.replaceAll(storageUrl, '');
      await _supabase.storage.from('users').remove([filePath]);
    } catch (e) {
      if (kDebugMode) {
        print('Error removing temporary image: $e');
      }
      rethrow;
    }
  }

  Future<void> _handleSave() async {
    if (!_validateInputs()) return;

    try {
      setState(() => isLoading = true);

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Handle image first if there are changes
      if (_selectedImageFile != null) {
        // Upload new image
        await _profileImageService.uploadProfileImage(
            userId, _selectedImageFile!);
      } else if (_isImageRemoved) {
        // Remove image if flagged for removal
        await _profileImageService.removeProfileImage(userId);
      }

      // Prepare phone number with country code if needed
      String phoneNumber = _numberController.text.trim();
      phoneNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
      if (!phoneNumber.startsWith('+91')) {
        phoneNumber = '+91$phoneNumber';
      }

      // Create updated profile object with just the database fields
      var updatedProfile = UserProfile(
        userId: currentUser?.userId,
        username: _nameController.text.trim(),
        role: currentUser?.role,
        phoneNumber: phoneNumber,
        email: _emailController.text.trim(),
        dateOfBirth: _dobController.text.isNotEmpty
            ? DateFormat('dd/MM/yyyy').parse(_dobController.text)
            : null,
        gender: _selectedGender,
        createdAt: currentUser?.createdAt,
        updatedAt: DateTime.now(),
        // Don't include profileImageUrl since it's removed from the database
      );

      // Use UserService for update
      await _userService.updateUserProfile(updatedProfile);

      setState(() {
        currentUser = updatedProfile;
        isEditing = false;
        _selectedImageFile = null;
        _isImageRemoved = false;
      });

      _animationController.reverse();

      // Refresh the profile image URL after save
      await _fetchProfileImage();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

// Input validation method
  bool _validateInputs() {
    // Name validation
    if (_nameController.text.trim().isEmpty) {
      _showValidationError('Name cannot be empty');
      return false;
    }

    // Optional additional validations can be added here
    if (_selectedGender == null) {
      _showValidationError('Please select a gender');
      return false;
    }

    return true;
  }

// Helper method to show validation errors
  void _showValidationError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleCancel() {
    setState(() {
      isEditing = false;
      _selectedImageFile = null;
      _isImageRemoved = false;
      // Restore current image URL
      _fetchProfileImage();
      // Reset other fields
      if (currentUser != null) {
        _updateControllers(currentUser!);
      }
    });
    _animationController.reverse();
  }

  void _toggleEditMode() {
    setState(() {
      isEditing = !isEditing;
      if (isEditing) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _openSideMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const RoleBasedSideMenu(),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType? keyboardType,
      List<TextInputFormatter>? inputFormatters}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8E8E93),
            fontFamily: 'Helvetica Neue',
          ),
        ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                  _slideAnimation.value * MediaQuery.of(context).size.width, 0),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF3A3A3C)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  style: const TextStyle(
                    color: Color(0xFFEEEFED),
                    fontFamily: 'Helvetica Neue',
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDateField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date of Birth',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF8E8E93),
            fontFamily: 'Helvetica Neue',
          ),
        ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                  _slideAnimation.value * MediaQuery.of(context).size.width, 0),
              child: GestureDetector(
                onTap: isEditing ? () => _selectDate(context) : null,
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF3A3A3C)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            _dobController.text.isEmpty
                                ? 'Select Date'
                                : _dobController.text,
                            style: TextStyle(
                              color: _dobController.text.isEmpty
                                  ? const Color(0xFF8E8E93)
                                  : const Color(0xFFEEEFED),
                              fontFamily: 'Helvetica Neue',
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      if (isEditing)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.calendar_today,
                            color: Color(0xFFD0F0C0),
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF8E8E93),
            fontFamily: 'Helvetica Neue',
          ),
        ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                  _slideAnimation.value * MediaQuery.of(context).size.width, 0),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF3A3A3C)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedGender,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Select Gender',
                        style: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontFamily: 'Helvetica Neue',
                          fontSize: 16,
                        ),
                      ),
                    ),
                    dropdownColor: const Color(0xFF1A1A1A),
                    style: const TextStyle(
                      color: Color(0xFFEEEFED),
                      fontFamily: 'Helvetica Neue',
                      fontSize: 16,
                    ),
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFFD0F0C0),
                      ),
                    ),
                    onChanged: isEditing
                        ? (String? newValue) {
                            setState(() {
                              _selectedGender = newValue;
                            });
                          }
                        : null,
                    items: _genderOptions
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(value),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

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
              color: Color(0xFFEEEFED),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Helvetica Neue',
              fontWeight: FontWeight.w300,
              color: Color(0xFFEEEFED),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF151611),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFD0F0C0),
          ),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF151611),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                error!,
                style: const TextStyle(color: Color(0xFFEEEFED)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD0F0C0),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF151611),
      body: SafeArea(
        child: Column(
          children: [
            HeaderWidget(
              leftIcon: Iconsax.arrow_left_1,
              onLeftButtonPressed: () => Navigator.pop(context),
              headingText: 'Profile',
              headingIcon: Iconsax.user,
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        margin: const EdgeInsets.only(top: 60),
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 60),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  currentUser?.username ?? '',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontFamily: 'Helvetica Neue',
                                    color: Color(0xFFEEEFED),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _toggleEditMode,
                                  child: const Icon(
                                    Iconsax.edit,
                                    size: 18,
                                    color: Color(0xFFD0F0C0),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (!isEditing) ...[
                              _buildInfoRow('Name:', _nameController.text),
                              _buildInfoRow('Email:', _emailController.text),
                              _buildInfoRow('Number:', _numberController.text),
                              _buildInfoRow(
                                  'Date of Birth:', _dobController.text),
                              _buildInfoRow('Gender:', _selectedGender ?? ''),
                            ] else ...[
                              _buildTextField('Name', _nameController),
                              _buildTextField('Email', _emailController,
                                  keyboardType: TextInputType.emailAddress),
                              _buildTextField('Number', _numberController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ]),
                              _buildDateField(context),
                              _buildGenderDropdown(),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    height: 32,
                                    child: TextButton(
                                      onPressed: _handleCancel,
                                      style: TextButton.styleFrom(
                                        side: const BorderSide(
                                            color: Color(0xFFD0F0C0)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                        ),
                                      ),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: Color(0xFFD0F0C0),
                                          fontFamily: 'Helvetica Neue',
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 32,
                                    child: ElevatedButton(
                                      onPressed: _handleSave,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFD0F0C0),
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                        ),
                                      ),
                                      child: const Text(
                                        'Save',
                                        style: TextStyle(
                                          fontFamily: 'Helvetica Neue',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    // Profile Picture
                    Positioned(
                      top: 0,
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: isEditing ? _handleProfileImageUpload : null,
                            onLongPress:
                                isEditing ? _handleRemoveProfileImage : null,
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: const Color(0xFFD0F0C0),
                              child: ClipOval(
                                child: SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: _isImageLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                              color: Colors.white),
                                        )
                                      : _selectedImageFile != null
                                          ? Image.file(
                                              _selectedImageFile!,
                                              fit: BoxFit.cover,
                                            )
                                          : _currentImageUrl != null
                                              ? Image.network(
                                                  _currentImageUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    // Show default icon if image fails to load
                                                    return const Icon(
                                                      Icons.person,
                                                      size: 60,
                                                      color: Colors.white,
                                                    );
                                                  },
                                                  loadingBuilder: (context,
                                                      child, loadingProgress) {
                                                    if (loadingProgress == null)
                                                      return child;
                                                    return const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        color: Colors.white,
                                                      ),
                                                    );
                                                  },
                                                )
                                              : const Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: Colors.white,
                                                ),
                                ),
                              ),
                            ),
                          ),
                          if (isEditing &&
                              (_selectedImageFile != null ||
                                  _currentImageUrl != null))
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 5,
                                        )
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Iconsax.edit, size: 20),
                                      color: const Color(0xFFD0F0C0),
                                      onPressed: _handleProfileImageUpload,
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 5,
                                        )
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      color: Colors.red,
                                      onPressed: _handleRemoveProfileImage,
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
