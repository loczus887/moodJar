import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import '../bloc/auth_bloc/auth_bloc.dart';
import '../bloc/theme_cubit/theme_cubit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _dailyReminder = true;
  bool _appLock = false;
  bool _isExporting = false;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyReminder = prefs.getBool('daily_reminder') ?? true;
      _appLock = prefs.getBool('app_lock_enabled') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _toggleAppLock(bool value) async {
    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await auth.isDeviceSupported();

    if (!canAuthenticate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Biometric authentication not available on this device.',
            ),
          ),
        );
      }
      return;
    }

    if (mounted) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(value ? 'Enable App Lock' : 'Disable App Lock'),
            content: Text(
              value
                  ? 'Are you sure you want to enable App Lock? You will need to authenticate to open the app.'
                  : 'Are you sure you want to disable App Lock?',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text('Confirm'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        try {
          final bool didAuthenticate = await auth.authenticate(
            localizedReason: 'Please authenticate to change App Lock settings',
            options: const AuthenticationOptions(biometricOnly: false),
          );

          if (didAuthenticate) {
            setState(() {
              _appLock = value;
            });
            _saveSetting('app_lock_enabled', value);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Authentication failed: $e')),
            );
          }
        }
      }
    }
  }

  Future<void> _exportData(String userId) async {
    setState(() {
      _isExporting = true;
    });

    try {
      // 1. Fetch data from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('mood_logs')
          .orderBy('timestamp', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No data to export.')));
        }
        setState(() {
          _isExporting = false;
        });
        return;
      }

      // 2. Convert to CSV format
      List<List<dynamic>> rows = [];
      // Header row
      rows.add([
        "Date",
        "Time",
        "Mood Label",
        "Mood Value",
        "Note",
        "Timestamp (ISO)",
      ]);

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        final date = timestamp?.toDate() ?? DateTime.now();

        rows.add([
          data['date_string'] ?? '',
          "${date.hour}:${date.minute.toString().padLeft(2, '0')}",
          data['mood_label'] ?? '',
          data['mood_value'] ?? '',
          data['note'] ?? '',
          date.toIso8601String(),
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);

      // 3. Save to temporary file
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/mood_jar_export.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      // 4. Share the file
      if (mounted) {
        await Share.shareXFiles([
          XFile(path),
        ], text: 'Here is my Mood Jar data export.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
        final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Updated: October 2023',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildPolicySection(
                        '1. Introduction',
                        'Welcome to Mood Jar. We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you as to how we look after your personal data when you visit our application and tell you about your privacy rights and how the law protects you.',
                        textColor,
                      ),
                      _buildPolicySection(
                        '2. Data We Collect',
                        'We may collect, use, store and transfer different kinds of personal data about you which we have grouped together follows:\n\n• Identity Data: includes first name, last name, username or similar identifier.\n• Contact Data: includes email address.\n• Usage Data: includes information about how you use our app, such as mood logs, notes, and timestamps.',
                        textColor,
                      ),
                      _buildPolicySection(
                        '3. How We Use Your Data',
                        'We will only use your personal data when the law allows us to. Most commonly, we will use your personal data in the following circumstances:\n\n• To provide the mood tracking service.\n• To generate AI-powered insights (processed securely).\n• To manage your account and authentication.',
                        textColor,
                      ),
                      _buildPolicySection(
                        '4. Data Security',
                        'We have put in place appropriate security measures to prevent your personal data from being accidentally lost, used or accessed in an unauthorized way, altered or disclosed. In addition, we limit access to your personal data to those employees, agents, contractors and other third parties who have a business need to know.',
                        textColor,
                      ),
                      _buildPolicySection(
                        '5. Your Legal Rights',
                        'Under certain circumstances, you have rights under data protection laws in relation to your personal data, including the right to request access, correction, erasure, restriction, transfer, to object to processing, to portability of data and (where the lawful ground of processing is consent) to withdraw consent.',
                        textColor,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPolicySection(String title, String content, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: textColor.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userEmail = 'Guest';
    String userId = '';

    if (authState is Authenticated) {
      userEmail = authState.user.email ?? 'Anonymous';
      userId = authState.user.uid;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : const Color(0xFF2D2D2D));
    final iconColor =
        theme.iconTheme.color ??
        (isDark ? Colors.white : const Color(0xFF2D2D2D));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings', style: theme.appBarTheme.titleTextStyle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/avatar.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 40,
                                  color: iconColor,
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB39DDB),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.cardColor,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jamie Doe',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pro Member',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSection(context, 'APPEARANCE', [
                _buildAppearanceToggle(context),
              ]),
              const SizedBox(height: 24),
              _buildSection(context, 'NOTIFICATIONS', [
                _buildNotificationItem(
                  context,
                  icon: Icons.notifications,
                  iconColor: const Color(0xFFB39DDB),
                  title: 'Daily Reminder',
                  trailing: _buildSwitch(context, _dailyReminder, (val) {
                    setState(() {
                      _dailyReminder = val;
                    });
                    _saveSetting('daily_reminder', val);
                  }),
                ),
                const SizedBox(height: 12),
                _buildNotificationItem(
                  context,
                  icon: Icons.access_time,
                  iconColor: const Color(0xFF64B5F6),
                  title: 'Time',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '08:00 PM',
                      style: TextStyle(fontSize: 14, color: textColor),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSection(context, 'SECURITY & DATA', [
                _buildSecurityItem(
                  context,
                  icon: Icons.lock,
                  iconColor: const Color(0xFF81C784),
                  title: 'App Lock',
                  trailing: _buildSwitch(context, _appLock, (val) {
                    _toggleAppLock(val);
                  }),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    if (userId.isNotEmpty && !_isExporting) {
                      _exportData(userId);
                    }
                  },
                  child: _buildSecurityItem(
                    context,
                    icon: Icons.cloud_upload,
                    iconColor: const Color(0xFFFFB74D),
                    title: 'Export My Data',
                    trailing: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.chevron_right,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showPrivacyPolicy(context),
                  child: _buildSecurityItem(
                    context,
                    icon: Icons.shield,
                    iconColor: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                    title: 'Privacy Policy',
                    trailing: Icon(
                      Icons.chevron_right,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () {
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Log Out',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'MoodJar v2.4.0 (Build 392)',
                style: TextStyle(
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildAppearanceToggle(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return Row(
          children: [
            _buildAppearanceButton(
              context,
              Icons.wb_sunny,
              'Light',
              themeMode == ThemeMode.light,
              () => context.read<ThemeCubit>().updateTheme(ThemeMode.light),
            ),
            const SizedBox(width: 8),
            _buildAppearanceButton(
              context,
              Icons.nightlight_round,
              'Dark',
              themeMode == ThemeMode.dark,
              () => context.read<ThemeCubit>().updateTheme(ThemeMode.dark),
            ),
            const SizedBox(width: 8),
            _buildAppearanceButton(
              context,
              Icons.brightness_auto,
              'Auto',
              themeMode == ThemeMode.system,
              () => context.read<ThemeCubit>().updateTheme(ThemeMode.system),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppearanceButton(
    BuildContext context,
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
    final unselectedColor = isDark ? Colors.grey[600] : Colors.grey[400];
    final selectedBg = isDark ? Colors.grey[800] : Colors.grey[100];

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? selectedColor : unselectedColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? selectedColor : unselectedColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget trailing,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : const Color(0xFF2D2D2D));

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing,
      ],
    );
  }

  Widget _buildSecurityItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget trailing,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : const Color(0xFF2D2D2D));

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing,
      ],
    );
  }

  Widget _buildSwitch(
    BuildContext context,
    bool value,
    Function(bool) onChanged,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 30,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value
              ? const Color(0xFFB39DDB)
              : (isDark ? const Color(0xFF383838) : Colors.grey[300]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isDark && !value ? const Color(0xFFB0B0B0) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
