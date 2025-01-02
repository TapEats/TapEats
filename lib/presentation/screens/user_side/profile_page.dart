import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
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

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final _userService = UserService.instance;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool isEditing = false;
  bool isLoading = true;
  String? error;
  UserProfile? currentUser;
  final _profileImageService = ProfileImageService();
  String? _profileImageUrl;
  bool _isImageLoading = false;

  // Text editing controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  
  // Gender dropdown
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  String? _selectedGender;

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
      final imageUrl = await _profileImageService.fetchCurrentProfileImageUrl();
      setState(() {
        _profileImageUrl = imageUrl;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching profile image: $e');
      }
    }
  }

  // New method to handle profile image upload
  Future<void> _handleProfileImageUpload() async {
    setState(() {
      _isImageLoading = true;
    });

    try {
      final newImageUrl = await _profileImageService.pickAndUploadProfileImage();
      if (newImageUrl != null) {
        setState(() {
          _profileImageUrl = newImageUrl;
        });
      }
    } catch (e) {
      if(mounted){ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile picture: $e')),
      );}
    } finally {
      setState(() {
        _isImageLoading = false;
      });
    }
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
      _numberController.text = user.phoneNumber!.substring(
        user.phoneNumber!.length - 10
      );
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

  Future<void> _handleSave() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Prepare phone number with country code
      String phoneNumber = _numberController.text.trim();
      
      // Ensure the phone number contains only digits
      phoneNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
      
      final updatedProfile = UserProfile(
        userId: currentUser?.userId,
        username: _nameController.text.trim(),
        role: currentUser?.role,
        phoneNumber: '+91$phoneNumber',
        email: _emailController.text.trim(),
        dateOfBirth: _dobController.text.isNotEmpty 
            ? DateFormat('dd/MM/yyyy').parse(_dobController.text)
            : null,
        gender: _selectedGender,
        createdAt: currentUser?.createdAt,
        updatedAt: DateTime.now(),
      );

      await _userService.updateUserProfile(updatedProfile);
      
      setState(() {
        currentUser = updatedProfile;
        isEditing = false;
      });

      _animationController.reverse();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handleCancel() {
    setState(() {
      isEditing = false;
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
        pageBuilder: (_, __, ___) => const SideMenuOverlay(),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {
    TextInputType? keyboardType, 
    List<TextInputFormatter>? inputFormatters
  }) {
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
              offset: Offset(_slideAnimation.value * MediaQuery.of(context).size.width, 0),
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
              offset: Offset(_slideAnimation.value * MediaQuery.of(context).size.width, 0),
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
                            _dobController.text.isEmpty ? 'Select Date' : _dobController.text,
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
              offset: Offset(_slideAnimation.value * MediaQuery.of(context).size.width, 0),
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
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
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
                              _buildInfoRow('Date of Birth:', _dobController.text),
                              _buildInfoRow('Gender:', _selectedGender ?? ''),
                            ] else ...[
                              _buildTextField('Name', _nameController),
                              _buildTextField('Email', _emailController, 
                                keyboardType: TextInputType.emailAddress
                              ),
                              _buildTextField('Number', _numberController, 
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ]
                              ),
                              _buildDateField(context),
                              _buildGenderDropdown(),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    height: 32,
                                    child: TextButton(
                                      onPressed: _handleCancel,
                                      style: TextButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFFD0F0C0)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(2),
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
                                        backgroundColor: const Color(0xFFD0F0C0),
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(2),
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
                      child: GestureDetector(
                        onTap: isEditing ? _handleProfileImageUpload : null,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: const Color(0xFFD0F0C0),
                              backgroundImage: _profileImageUrl != null 
                                ? NetworkImage(_profileImageUrl!) 
                                : null,
                              child: _isImageLoading
                                ? const CircularProgressIndicator()
                                : (_profileImageUrl == null 
                                    ? const Icon(Icons.person, size: 60) 
                                    : null),
                            ),
                            if (isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
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
                                  child: const Icon(
                                    Iconsax.edit,
                                    size: 20,
                                    color: Color(0xFFD0F0C0),
                                  ),
                                ),
                              ),
                        
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
          ],),),);
  }
}