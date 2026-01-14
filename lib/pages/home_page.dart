import 'package:app/pages/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_screen.dart';
import 'log_mood.dart';
import 'history_page.dart';
import 'insights_page.dart';
import '../widgets/custom_navigation_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final LocalAuthentication auth = LocalAuthentication();
  
  // App Lock Variables
  DateTime? _lastAuthTime;
  static const Duration _authValidityDuration = Duration(minutes: 2);
  bool _isAuthenticating = false;
  bool _isAppLockEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAppLockPreference();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadAppLockPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isAppLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground
      // Reload preference in case it changed in settings
      _loadAppLockPreference();
      
      // If we are currently on the history screen (index 1), re-verify if needed
      if (_selectedIndex == 1 && _isAppLockEnabled) {
        _checkAuthAndNavigateToHistory();
      }
    } else if (state == AppLifecycleState.paused) {
      // App went to background
      // No specific action needed, but _lastAuthTime remains set
    }
  }

  Future<bool> _authenticate() async {
    // If App Lock is disabled, bypass authentication
    if (!_isAppLockEnabled) return true;

    if (_isAuthenticating) return false;
    
    // Check if previous authentication is still valid
    if (_lastAuthTime != null) {
      final difference = DateTime.now().difference(_lastAuthTime!);
      if (difference < _authValidityDuration) {
        return true;
      }
    }

    try {
      _isAuthenticating = true;
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        // If auth not available, we might want to allow access or block it.
        // For security, usually block, but for dev/testing maybe allow.
        // Let's assume we allow if no hardware support, or show error.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric authentication not available.')),
          );
        }
        _isAuthenticating = false;
        return false; 
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access history',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      _isAuthenticating = false;

      if (didAuthenticate) {
        _lastAuthTime = DateTime.now();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _isAuthenticating = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication error: $e')),
        );
      }
      return false;
    }
  }

  Future<void> _checkAuthAndNavigateToHistory() async {
    // If we are already on the history tab (e.g. app resumed), we might need to lock it
    // But since this function is called on tap, let's handle the tap logic.
    
    final isAuthenticated = await _authenticate();
    
    if (isAuthenticated) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HistoryScreen()),
        ).then((_) {
           // When coming back from HistoryScreen, we don't necessarily need to reset auth immediately
           // The timer will handle it.
        });
      }
    } else {
      if (mounted) {
        // Show failure screen or snackbar and go back/stay home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed.'),
            backgroundColor: Colors.red,
          ),
        );
        // Ensure we are not on the history tab visually if we were trying to switch tabs
        if (_selectedIndex == 1) {
           setState(() {
             _selectedIndex = 0;
           });
        }
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      ).then((_) => _loadAppLockPreference()); // Reload pref when coming back from profile
      return;
    }
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LogMoodScreen()),
      );
      return;
    }
    if (index == 1) {
      // Intercept History tap for Authentication
      _checkAuthAndNavigateToHistory();
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _testFingerprint() async {
    // Kept for manual testing if needed, but logic is now in _authenticate
    await _authenticate();
  }

  Widget _buildHomeContent(
    ThemeData theme,
    bool isDark,
    Color textColor,
    Color iconColor,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mood Jar',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.person, color: iconColor),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  ).then((_) => _loadAppLockPreference());
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(Icons.spa, size: 80, color: iconColor),
                ),
                const SizedBox(height: 32),
                Text(
                  'Welcome to Mood Jar!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Start tracking your moods',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LogMoodScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D2D2D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.3),
                    ),
                    child: const Text(
                      'Add a mood',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _testFingerprint,
                  child: Column(
                    children: [
                      Icon(
                        Icons.fingerprint,
                        size: 40,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Test fingerprint security',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        theme.textTheme.titleLarge?.color ??
        (isDark ? Colors.white : const Color(0xFF2D2D2D));
    final iconColor =
        theme.iconTheme.color ??
        (isDark ? Colors.white : const Color(0xFF2D2D2D));

    Widget bodyContent;
    switch (_selectedIndex) {
      case 0:
        bodyContent = _buildHomeContent(theme, isDark, textColor, iconColor);
        break;
      case 1:
        // This case might not be reached often if we push HistoryScreen, 
        // but if we use bottom nav to switch tabs, we keep it consistent.
        // However, since we push a new route for History, this might be unused 
        // or used as a placeholder.
        bodyContent = const SizedBox();
        break;
      case 3:
        bodyContent = const InsightsPage();
        break;
      default:
        bodyContent = _buildHomeContent(theme, isDark, textColor, iconColor);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(child: bodyContent),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LogMoodScreen()),
            );
          },
          backgroundColor: const Color(0xFFB39DDB),
          elevation: 8,
          child: const Icon(Icons.add, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
