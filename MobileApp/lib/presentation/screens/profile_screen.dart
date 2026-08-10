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
        const SnackBar(content: Text('Gemini API key saved locally')),
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
            SnackBar(content: Text('Recording scan folder updated to: $result')),
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
            const SnackBar(content: Text('Profile picture updated successfully')),
          );
        }
      }
    } catch (_) {}
  }

  void _showThemeSheet(BuildContext context, PreferencesService prefs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131927),
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
                _buildRadioTile(
                  title: 'System Default',
                  icon: Icons.brightness_auto_rounded,
                  selected: prefs.themeMode == ThemeMode.system,
                  onTap: () {
                    prefs.setThemeMode(ThemeMode.system);
                    Navigator.pop(context);
                  },
                ),
                _buildRadioTile(
                  title: 'Light',
                  icon: Icons.light_mode_rounded,
                  selected: prefs.themeMode == ThemeMode.light,
                  onTap: () {
                    prefs.setThemeMode(ThemeMode.light);
                    Navigator.pop(context);
                  },
                ),
                _buildRadioTile(
                  title: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  selected: prefs.themeMode == ThemeMode.dark,
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

  Widget _buildRadioTile({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: selected ? const Color(0xFF00A896) : Colors.white70, size: 20),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00A896), size: 22)
          : null,
      onTap: onTap,
    );
  }

  void _showLanguageSheet(BuildContext context, PreferencesService prefs) {
    final languages = ['English', 'Hindi', 'Gujarati', 'Tamil', 'Telugu', 'Bengali', 'Marathi'];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131927),
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
                    'AI Language',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: languages.map((lang) {
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        leading: const Icon(Icons.language_rounded, color: Colors.white70, size: 20),
                        title: Text(lang, style: const TextStyle(color: Colors.white, fontSize: 15)),
                        trailing: prefs.aiLanguage == lang
                            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00A896), size: 22)
                            : null,
                        onTap: () {
                          prefs.setAiLanguage(lang);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final prefs = ref.watch(preferencesProvider);
    final user = auth.user;

    String getThemeLabel(ThemeMode mode) {
      switch (mode) {
        case ThemeMode.light:
          return 'Light';
        case ThemeMode.dark:
          return 'Dark';
        case ThemeMode.system:
        default:
          return 'System';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                        backgroundColor: const Color(0xFF00A896).withOpacity(0.15),
                        backgroundImage: prefs.profileImagePath.isNotEmpty && File(prefs.profileImagePath).existsSync()
                            ? FileImage(File(prefs.profileImagePath))
                            : null,
                        child: prefs.profileImagePath.isNotEmpty && File(prefs.profileImagePath).existsSync()
                            ? null
                            : Text(
                                user.userName.isNotEmpty ? user.userName[0].toUpperCase() : 'U',
                                style: const TextStyle(color: Color(0xFF00A896), fontWeight: FontWeight.bold, fontSize: 42),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF00A896),
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
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131927),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ID: ${user.employeeId}',
                    style: const TextStyle(color: Color(0xFF00A896), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 32),
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
              const SizedBox(height: 24),

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
                    const Divider(color: Colors.white10, height: 1),
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
              const SizedBox(height: 24),

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
                    const Divider(color: Colors.white10, height: 1),
                    _buildSettingsTile(
                      icon: Icons.language_outlined,
                      title: 'Language',
                      subtitle: prefs.aiLanguage,
                      onTap: () => _showLanguageSheet(context, prefs),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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
                    const Divider(color: Colors.white10, height: 1),
                    _buildSettingsTile(
                      icon: Icons.shield_outlined,
                      title: 'Privacy Policy',
                      onTap: () {},
                    ),
                    const Divider(color: Colors.white10, height: 1),
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
                    color: const Color(0xFF131927),
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
            fontSize: 12,
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
        color: const Color(0xFF131927),
        borderRadius: BorderRadius.circular(20),
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
                color: const Color(0xFF1D2435),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF00A896), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white30, fontSize: 12),
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
              color: const Color(0xFF1D2435),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF00A896), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF00A896),
            activeTrackColor: const Color(0xFF00A896).withOpacity(0.3),
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }
}
