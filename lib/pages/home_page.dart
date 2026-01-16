import 'dart:convert';
import 'package:app/pages/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile_screen.dart';
import 'log_mood.dart';
import 'insights_page.dart';
import '../widgets/custom_navigation_bar.dart';
import '../bloc/auth_bloc/auth_bloc.dart';
import '../widgets/home_page/home_header.dart';
import '../widgets/home_page/mood_tracking_card.dart';
import '../widgets/home_page/quick_actions_section.dart';
import '../widgets/home_page/wellness_tips_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final LocalAuthentication auth = LocalAuthentication();

  // App Lock
  DateTime? _lastAuthTime;
  static const Duration _authValidityDuration = Duration(minutes: 2);
  bool _isAuthenticating = false;
  bool _isAppLockEnabled = false;

  // Wellness tips collection
  List<Map<String, dynamic>> _wellnessTips = [];
  int _currentTipIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAppLockPreference();
    _loadTips();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
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

  Future<void> _loadTips() async {
    try {
      final String response = await rootBundle.loadString('assets/tips.json');
      final List<dynamic> data = json.decode(response);

      setState(() {
        _wellnessTips = data.map((item) {
          return {
            'tip': item['tip'],
            'category': item['category'],
            'icon': _getIconForCategory(item['category']),
            'color': _getColorForCategory(item['category']),
          };
        }).toList();
      });

      _loadTipIndex();
    } catch (e) {
      debugPrint('Error loading tips: $e');
      // Fallback tips if JSON fails
      setState(() {
        _wellnessTips = [
          {
            'icon': Icons.self_improvement,
            'category': 'Mindfulness',
            'tip': 'Take 5 minutes today to focus on your breathing.',
            'color': const Color(0xFF9575CD),
          },
        ];
      });
    }
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Relaxation':
        return Icons.spa;
      case 'Health':
        return Icons.local_drink;
      case 'Activity':
        return Icons.directions_walk;
      case 'Mindfulness':
        return Icons.self_improvement;
      case 'Physical':
        return Icons.accessibility_new;
      case 'Joy':
        return Icons.music_note;
      case 'Productivity':
        return Icons.check_circle_outline;
      case 'Social':
        return Icons.people;
      case 'Digital Detox':
        return Icons.phonelink_off;
      case 'Self-Love':
        return Icons.favorite;
      default:
        return Icons.lightbulb_outline;
    }
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'Relaxation':
        return const Color(0xFF9575CD);
      case 'Health':
        return const Color(0xFF64B5F6);
      case 'Activity':
        return const Color(0xFFFFB74D);
      case 'Mindfulness':
        return const Color(0xFF81C784);
      case 'Physical':
        return const Color(0xFF4DB6AC);
      case 'Joy':
        return const Color(0xFFF06292);
      case 'Productivity':
        return const Color(0xFF7986CB);
      case 'Social':
        return const Color(0xFFFF8A65);
      case 'Digital Detox':
        return const Color(0xFFA1887F);
      case 'Self-Love':
        return const Color(0xFFE57373);
      default:
        return const Color(0xFFBA68C8);
    }
  }

  Future<void> _loadTipIndex() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      int savedIndex = prefs.getInt('current_tip_index') ?? 0;
      if (savedIndex >= _wellnessTips.length) savedIndex = 0;

      setState(() {
        _currentTipIndex = savedIndex;
      });

      // Jump to the saved page after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentTipIndex);
        }
      });
    }
  }

  Future<void> _saveTipIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_tip_index', index);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAppLockPreference();

      // Re-authenticate when returning to history screen
      if (_selectedIndex == 1 && _isAppLockEnabled) {
        _checkAuthAndNavigateToHistory();
      }
    }
  }

  Future<bool> _authenticate() async {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication not available.'),
            ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Authentication error: $e')));
      }
      return false;
    }
  }

  Future<void> _checkAuthAndNavigateToHistory() async {
    final isAuthenticated = await _authenticate();

    if (isAuthenticated) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) =>
                const HistoryScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed.'),
            backgroundColor: Colors.red,
          ),
        );
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
      ).then((_) => _loadAppLockPreference());
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
      _checkAuthAndNavigateToHistory();
      return;
    }
    if (index == 3) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) =>
              const InsightsPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHeader(
                onProfileTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  ).then((_) => _loadAppLockPreference());
                },
              ),
              const SizedBox(height: 32),
              const MoodTrackingCard(),
              const SizedBox(height: 32),
              QuickActionsSection(
                onHistoryTap: _checkAuthAndNavigateToHistory,
                onInsightsTap: () {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) =>
                          const InsightsPage(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
                onSettingsTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  ).then((_) => _loadAppLockPreference());
                },
              ),
              const SizedBox(height: 32),
              WellnessTipsSection(
                wellnessTips: _wellnessTips,
                currentTipIndex: _currentTipIndex,
                pageController: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentTipIndex = index;
                  });
                  _saveTipIndex(index);
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
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
