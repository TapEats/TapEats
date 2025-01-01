import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool isEditing = false;

  // Store original values
  late String _originalName;
  late String _originalEmail;
  late String _originalNumber;
  late String _originalDob;
  late String _originalGender;

  final List<String> genderOptions = ['Male', 'Female', 'Other'];

  // Text editing controllers
  final TextEditingController _nameController = TextEditingController(text: 'John Doe');
  final TextEditingController _emailController = TextEditingController(text: 'johndoe@gmail.com');
  final TextEditingController _numberController = TextEditingController(text: '0123456789');
  final TextEditingController _dobController = TextEditingController(text: '01/01/01');
  final TextEditingController _genderController = TextEditingController(text: 'Male');

  @override
  void initState() {
    super.initState();
    // Store initial values
    _storeOriginalValues();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _numberController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  void _storeOriginalValues() {
    _originalName = _nameController.text;
    _originalEmail = _emailController.text;
    _originalNumber = _numberController.text;
    _originalDob = _dobController.text;
    _originalGender = _genderController.text;
  }

  void _restoreOriginalValues() {
    _nameController.text = _originalName;
    _emailController.text = _originalEmail;
    _numberController.text = _originalNumber;
    _dobController.text = _originalDob;
    _genderController.text = _originalGender;
  }

  void _saveCurrentValues() {
    _storeOriginalValues();
  }

  void _handleEditToggle(bool isSaving) {
    setState(() {
      if (isEditing) {
        if (isSaving) {
          _saveCurrentValues();
        } else {
          _restoreOriginalValues();
        }
      }
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD0F0C0),
              surface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yy').format(picked);
      });
    }
  }

  Widget _buildTextField(
    String label, 
    TextEditingController controller, {
    bool isNumber = false,
    bool isDate = false,
    bool isGender = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Stack(
        children: [
          // Text field with floating label
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isEditing ? 1.0 : 0.0,
            child: SizedBox(
              height: 36,
              child: isGender 
              ? _buildGenderDropdown(label, controller)
              : TextFormField(
                controller: controller,
                readOnly: isDate,
                onTap: isDate ? () => _selectDate(context) : null,
                keyboardType: isNumber ? TextInputType.number : null,
                inputFormatters: isNumber ? [
                  LengthLimitingTextInputFormatter(10),
                  FilteringTextInputFormatter.digitsOnly,
                ] : null,
                style: const TextStyle(
                  color: Color(0xFFEEEFED),
                  fontFamily: 'Helvetica Neue',
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  height: 1.2,
                ),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(
                    color: Color(0xFFEEEFED),
                    fontFamily: 'Helvetica Neue',
                    fontSize: 12,
                    fontWeight: FontWeight.w100,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFF3A3A3C)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFF3A3A3C)),
                  ),
                  filled: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown(String label, TextEditingController controller) {
    return DropdownButtonFormField<String>(
      value: controller.text,
      style: const TextStyle(
        color: Color(0xFFEEEFED),
        fontFamily: 'Helvetica Neue',
        fontSize: 14,
        fontWeight: FontWeight.w300,
      ),
      dropdownColor: const Color(0xFF1A1A1A),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFFEEEFED),
          fontFamily: 'Helvetica Neue',
          fontSize: 12,
          fontWeight: FontWeight.w100,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF3A3A3C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF3A3A3C)),
        ),
        filled: false,
      ),
      items: genderOptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            controller.text = newValue;
          });
        }
      },
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
                                const Text(
                                  'John Doe',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontFamily: 'Helvetica Neue',
                                    color: Color(0xFFEEEFED),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _handleEditToggle(true),
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
                              _buildInfoRow('Gender:', _genderController.text),
                            ] else ...[
                              _buildTextField('Name', _nameController),
                              _buildTextField('Email', _emailController),
                              _buildTextField('Number', _numberController, isNumber: true),
                              _buildTextField('Date of Birth', _dobController, isDate: true),
                              _buildTextField('Gender', _genderController, isGender: true),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    height: 32,
                                    child: TextButton(
                                      onPressed: () => _handleEditToggle(false),
                                      style: TextButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFF3A3A3C)),
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
                                          color: Color(0xFF3A3A3C),
                                          fontFamily: 'Helvetica Neue',
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 32,
                                    child: ElevatedButton(
                                      onPressed: () => _handleEditToggle(true),
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
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFFD0F0C0),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/cupcake.png',
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                          ),
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
    );
  }
}