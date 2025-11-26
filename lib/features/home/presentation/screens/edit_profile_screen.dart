import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:movies_app_graduation_project/core/resources/colors.dart';
import 'package:movies_app_graduation_project/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late String _selectedAvatar;
  bool _showAvatarGrid = false;

  final List<String> _avatars = [
    'assets/images/avt_1.png',
    'assets/images/avt_2.png',
    'assets/images/avt_3.png',
    'assets/images/avt_4.png',
    'assets/images/avt_5.png',
    'assets/images/avt_6.png',
    'assets/images/avt_7.png',
    'assets/images/avt_8.png',
    'assets/images/avt_9.png',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _selectedAvatar = 'assets/images/avt_1.png';
  }

  void _initializeControllers(AuthProvider authProvider) {
    final currentUser = authProvider.currentUser;
    if (_nameController.text.isEmpty) {
      _nameController.text = currentUser?.name ?? '';
    }
    if (_phoneController.text.isEmpty) {
      _phoneController.text = currentUser?.phone ?? '';
    }
    if (_selectedAvatar == 'assets/images/avt_1.png' &&
        currentUser?.avatar != null) {
      _selectedAvatar = currentUser!.avatar;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Initialize controllers with current user data
        _initializeControllers(authProvider);

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: _buildAppBar(),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Large Avatar Display
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showAvatarGrid = !_showAvatarGrid;
                        });
                      },
                      child: _selectedAvatar.startsWith('http')
                          ? CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.transparent,
                              backgroundImage: NetworkImage(_selectedAvatar),
                            )
                          : CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.transparent,
                              backgroundImage: AssetImage(_selectedAvatar),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // User Input Fields
                  _buildStyledTextInput(
                    icon: Icons.person,
                    controller: _nameController,
                    hintText: 'Name',
                  ),
                  const SizedBox(height: 16),
                  _buildStyledTextInput(
                    icon: Icons.phone,
                    controller: _phoneController,
                    hintText: 'Phone Number',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  // Reset Password Link
                  GestureDetector(
                    onTap: () async {
                      final email = authProvider.currentUser?.email;
                      if (email == null) return;

                      final success = await authProvider.forgotPassword(email);
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Password reset email sent to $email'
                                : authProvider.errorMessage ??
                                      'Failed to send reset email',
                          ),
                          backgroundColor: success
                              ? Colors.green
                              : AppColors.error,
                        ),
                      );
                    },
                    child: Text(
                      'Reset Password',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Avatar Picker Grid (Conditional)
                  if (_showAvatarGrid) ...[
                    Text(
                      'Select Avatar',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAvatarGrid(),
                    const SizedBox(height: 24),
                  ],
                  const SizedBox(height: 32),
                  // Action Buttons
                  _buildActionButton(
                    label: 'Delete Account',
                    backgroundColor: AppColors.error,
                    textColor: Colors.white,
                    onPressed: () {
                      // Handle delete account
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    label: 'Update Data',
                    backgroundColor: AppColors.primary,
                    textColor: Colors.black,
                    isLoading: authProvider.isLoading,
                    onPressed: () async {
                      if (_nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter your name'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      final success = await authProvider.updateProfile(
                        name: _nameController.text.trim(),
                        phone: _phoneController.text.trim(),
                        avatar: _selectedAvatar,
                      );

                      if (!mounted) return;

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              authProvider.errorMessage ??
                                  'Failed to update profile',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: () {
          setState(() {
            _showAvatarGrid = !_showAvatarGrid;
          });
        },
        child: Text(
          'Pick Avatar',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildStyledTextInput({
    required IconData icon,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.grey,
          ),
          prefixIcon: Icon(icon, color: Colors.grey, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _avatars.length,
      itemBuilder: (context, index) {
        final avatar = _avatars[index];
        final isSelected = avatar == _selectedAvatar;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedAvatar = avatar;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: isSelected ? 3 : 0,
              ),
              color: isSelected
                  ? AppColors.primary.withOpacity(0.2)
                  : Colors.transparent,
            ),
            child: ClipOval(
              child: avatar.startsWith('http')
                  ? Image.network(
                      avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.person, color: Colors.grey),
                        );
                      },
                    )
                  : Image.asset(
                      avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.person, color: Colors.grey),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: backgroundColor.withOpacity(0.6),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
      ),
    );
  }
}
