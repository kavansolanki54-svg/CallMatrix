import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/auth_provider.dart';
import '../../core/storage/preferences_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _apiKeyController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadCustomApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomApiKey() async {
    final key = await _storage.read(key: 'gemini_api_key');
    if (key != null && key.isNotEmpty) {
      _apiKeyController.text = key;
    }
  }

  Future<void> _saveCustomApiKey(String val) async {
    await _storage.write(key: 'gemini_api_key', value: val.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI API key saved locally'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickCustomFolder(PreferencesService service) async {
    try {
      String? result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        await service.setCustomRecordingPath(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recording scan folder updated to: $result'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _pickProfileImage(PreferencesService service) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        await service.setProfileImagePath(path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {}
  }

  void _showThemeSheet(BuildContext context, PreferencesService prefs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1D2939),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Text(
                    'Choose Theme',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.brightness_auto_rounded, color: Colors.white70),
                  title: const Text('System Default', style: TextStyle(color: Colors.white)),
                  trailing: prefs.themeMode == ThemeMode.system
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0070F3))
                      : null,
                  onTap: () {
                    prefs.setThemeMode(ThemeMode.system);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.light_mode_rounded, color: Colors.white70),
                  title: const Text('Light Mode', style: TextStyle(color: Colors.white)),
                  trailing: prefs.themeMode == ThemeMode.light
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0070F3))
                      : null,
                  onTap: () {
                    prefs.setThemeMode(ThemeMode.light);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode_rounded, color: Colors.white70),
                  title: const Text('Dark Mode', style: TextStyle(color: Colors.white)),
                  trailing: prefs.themeMode == ThemeMode.dark
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0070F3))
                      : null,
                  onTap: () {
                    prefs.setThemeMode(ThemeMode.dark);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguageSheet(BuildContext context, PreferencesService prefs) {
    final languages = ['English', 'Spanish', 'French', 'Hindi', 'German'];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1D2939),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Text(
                    'Choose Language',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...languages.map((lang) => ListTile(
                      leading: const Icon(Icons.language_rounded, color: Colors.white70),
                      title: Text(lang, style: const TextStyle(color: Colors.white)),
                      trailing: prefs.aiLanguage == lang
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0070F3))
                          : null,
                      onTap: () {
                        prefs.setAiLanguage(lang);
                        Navigator.pop(context);
                      },
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCustomApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D2939),
          title: const Text('Custom AI API Key', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your personal AI API key. This will be encrypted and saved locally on your device.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _apiKeyController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'API Key',
                  labelStyle: TextStyle(color: Colors.blueGrey.shade400),
                  filled: true,
                  fillColor: const Color(0xFF0C111D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF334155).withOpacity(0.3)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                _saveCustomApiKey(_apiKeyController.text);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0070F3)),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final prefs = ref.watch(preferencesProvider);

    String getThemeLabel(ThemeMode mode) {
      switch (mode) {
        case ThemeMode.light:
          return 'Light';
        case ThemeMode.dark:
          return 'Dark';
        case ThemeMode.system:
          return 'System Default';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0C111D),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0C111D),
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Identity Section
              if (user != null) ...[
                GestureDetector(
                  onTap: () => _pickProfileImage(ref.read(preferencesProvider)),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: const Color(0xFF0070F3).withOpacity(0.15),
                        backgroundImage: prefs.profileImagePath.isNotEmpty && File(prefs.profileImagePath).existsSync()
                            ? FileImage(File(prefs.profileImagePath))
                            : null,
                        child: prefs.profileImagePath.isNotEmpty && File(prefs.profileImagePath).existsSync()
                            ? null
                            : Text(
                                user.userName.isNotEmpty ? user.userName[0].toUpperCase() : 'U',
                                style: const TextStyle(color: Color(0xFF38bdf8), fontWeight: FontWeight.bold, fontSize: 42),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0070F3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.userName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  user.email,
                  style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D2939),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155).withOpacity(0.3)),
                  ),
                  child: Text(
                    'ID: ${user.employeeId}',
                    style: const TextStyle(color: Color(0xFF38bdf8), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // APPEARANCE
              _buildSectionHeader('Appearance'),
              const SizedBox(height: 8),
              _buildCardContainer(
                child: _buildSettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Theme',
                  subtitle: getThemeLabel(prefs.themeMode),
                  onTap: () => _showThemeSheet(context, prefs),
                ),
              ),
              const SizedBox(height: 20),

              // CALL SETTINGS
              _buildSectionHeader('Call Settings'),
              const SizedBox(height: 8),
              _buildCardContainer(
                child: Column(
                  children: [
                    _buildSwitchTile(
                      icon: Icons.mic_none_outlined,
                      title: 'Automatic Recording',
                      value: prefs.autoRecord,
                      onChanged: (val) => prefs.setAutoRecord(val),
                    ),
                    Divider(color: const Color(0xFF334155).withOpacity(0.2), height: 1),
                    _buildSettingsTile(
                      icon: Icons.folder_open_outlined,
                      title: 'Recording Storage Location',
                      subtitle: prefs.customRecordingPath.isNotEmpty
                          ? prefs.customRecordingPath
                          : '/storage/emulated/0/Recordings/Call',
                      onTap: () => _pickCustomFolder(prefs),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // AI SETTINGS
              _buildSectionHeader('AI Settings'),
              const SizedBox(height: 8),
              _buildCardContainer(
                child: Column(
                  children: [
                    _buildSwitchTile(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Enable AI Summary',
                      value: prefs.aiEnabled,
                      onChanged: (val) => prefs.setAiEnabled(val),
                    ),
                    Divider(color: const Color(0xFF334155).withOpacity(0.2), height: 1),
                    _buildSettingsTile(
                      icon: Icons.language_outlined,
                      title: 'Language',
                      subtitle: prefs.aiLanguage,
                      onTap: () => _showLanguageSheet(context, prefs),
                    ),
                    Divider(color: const Color(0xFF334155).withOpacity(0.2), height: 1),
                    _buildSettingsTile(
                      icon: Icons.vpn_key_outlined,
                      title: 'Personal AI API Key',
                      subtitle: _apiKeyController.text.isNotEmpty ? '••••••••••••••••' : 'Not set (uses server)',
                      onTap: _showCustomApiKeyDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ABOUT
              _buildSectionHeader('About'),
              const SizedBox(height: 8),
              _buildCardContainer(
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: 'Version',
                      subtitle: '1.0.0',
                      onTap: () {},
                      showArrow: false,
                    ),
                    Divider(color: const Color(0xFF334155).withOpacity(0.2), height: 1),
                    _buildSettingsTile(
                      icon: Icons.shield_outlined,
                      title: 'Privacy Policy',
                      onTap: () {},
                    ),
                    Divider(color: const Color(0xFF334155).withOpacity(0.2), height: 1),
                    _buildSettingsTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // LOGOUT BUTTON
              InkWell(
                onTap: widget.onLogout,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D2939),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1D2939),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155).withOpacity(0.3)),
      ),
      child: child,
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0C111D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF0070F3), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (showArrow)
              const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0C111D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF0070F3), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF0070F3),
            activeTrackColor: const Color(0xFF0070F3).withOpacity(0.3),
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }
}
