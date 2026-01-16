import 'package:app/pages/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile_screen.dart';
import 'log_mood.dart';
import 'insights_page.dart';
import '../widgets/custom_navigation_bar.dart';
import '../bloc/auth_bloc/auth_bloc.dart';

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
  final List<Map<String, dynamic>> _wellnessTips = [
    {
      'icon': Icons.self_improvement,
      'title': 'Practice Mindfulness',
      'tip':
          'Take 5 minutes today to focus on your breathing and be present in the moment.',
      'color': Color(0xFF9575CD),
    },
    {
      'icon': Icons.bedtime,
      'title': 'Prioritize Sleep',
      'tip':
          'Aim for 7-9 hours of quality sleep tonight. Your mind and body will thank you.',
      'color': Color(0xFF64B5F6),
    },
    {
      'icon': Icons.local_drink,
      'title': 'Stay Hydrated',
      'tip':
          'Drinking water throughout the day can improve your mood and energy levels.',
      'color': Color(0xFF81C784),
    },
    {
      'icon': Icons.directions_walk,
      'title': 'Move Your Body',
      'tip':
          'A short walk or stretch can help reduce stress and boost your mental clarity.',
      'color': Color(0xFFFFB74D),
    },
    {
      'icon': Icons.favorite,
      'title': 'Practice Gratitude',
      'tip':
          'Think of three things you\'re grateful for today. It can shift your perspective.',
      'color': Color(0xFFEF5350),
    },
  ];

  int _currentTipIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAppLockPreference();
    _loadTipIndex();
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

  Future<void> _loadTipIndex() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentTipIndex = prefs.getInt('current_tip_index') ?? 0;
      });
    }
  }

  Future<void> _saveTipIndex() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_tip_index', _currentTipIndex);
  }

  void _nextTip() {
    setState(() {
      _currentTipIndex = (_currentTipIndex + 1) % _wellnessTips.length;
    });
    _saveTipIndex();
  }

  void _previousTip() {
    setState(() {
      _currentTipIndex =
          (_currentTipIndex - 1 + _wellnessTips.length) % _wellnessTips.length;
    });
    _saveTipIndex();
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HistoryScreen()),
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
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildHomeContent(
    ThemeData theme,
    bool isDark,
    Color textColor,
    Color iconColor,
  ) {
    final authState = context.watch<AuthBloc>().state;
    String userName = 'Friend';
    if (authState is Authenticated) {
      userName = authState.user.displayName?.split(' ')[0] ?? 'Friend';
    }

    final currentTip = _wellnessTips[_currentTipIndex];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with greeting and profile
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $userName!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'How are you feeling today?',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    ).then((_) => _loadAppLockPreference());
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFB39DDB),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.cardColor,
                      child: Icon(Icons.person, color: iconColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Main mood tracking card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF4A148C), const Color(0xFF7B1FA2)]
                    : [const Color(0xFFB39DDB), const Color(0xFF9575CD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B1FA2).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Track Your Mood',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Keep track of your daily emotions and understand yourself better.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LogMoodScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF7B1FA2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Log Mood'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.spa, size: 48, color: Colors.white),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Quick actions section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildQuickActionCard(
                  theme,
                  icon: Icons.history,
                  label: 'History',
                  color: const Color(0xFF64B5F6),
                  onTap: _checkAuthAndNavigateToHistory,
                ),
                const SizedBox(width: 16),
                _buildQuickActionCard(
                  theme,
                  icon: Icons.insights,
                  label: 'Insights',
                  color: const Color(0xFF81C784),
                  onTap: () {
                    setState(() {
                      _selectedIndex = 3;
                    });
                  },
                ),
                const SizedBox(width: 16),
                _buildQuickActionCard(
                  theme,
                  icon: Icons.settings,
                  label: 'Settings',
                  color: const Color(0xFFFFB74D),
                  onTap: () {
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

          const SizedBox(height: 32),

          // Wellness tip with navigation
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  currentTip['color'].withOpacity(0.1),
                  currentTip['color'].withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: currentTip['color'].withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: currentTip['color'].withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        currentTip['icon'],
                        color: currentTip['color'],
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wellness Tip',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            currentTip['title'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  currentTip['tip'],
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: textColor.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 16),
                // Navigation controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                        _wellnessTips.length,
                        (index) => Container(
                          margin: const EdgeInsets.only(right: 6),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == _currentTipIndex
                                ? currentTip['color']
                                : (isDark
                                      ? Colors.grey[700]
                                      : Colors.grey[300]),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _previousTip,
                          icon: Icon(
                            Icons.chevron_left,
                            color: currentTip['color'],
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _nextTip,
                          icon: Icon(
                            Icons.chevron_right,
                            color: currentTip['color'],
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
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
