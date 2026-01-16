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

          // Wellness tip with swipeable cards
          if (_wellnessTips.isNotEmpty)
            Container(
              height: 240,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _wellnessTips[_currentTipIndex]['color'].withOpacity(
                        0.15,
                      ),
                      _wellnessTips[_currentTipIndex]['color'].withOpacity(
                        0.05,
                      ),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _wellnessTips[_currentTipIndex]['color'].withOpacity(
                      0.3,
                    ),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _wellnessTips[_currentTipIndex]['color']
                          .withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _wellnessTips.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentTipIndex = index;
                          });
                          _saveTipIndex(index);
                        },
                        itemBuilder: (context, index) {
                          final tip = _wellnessTips[index];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: tip['color'].withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        tip['icon'],
                                        color: tip['color'],
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Wellness Tip',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          Text(
                                            tip['category'],
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
                                Expanded(
                                  child: Text(
                                    tip['tip'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                      color: textColor.withOpacity(0.85),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // Static Page Indicator
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20, top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _wellnessTips.length,
                          (dotIndex) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: dotIndex == _currentTipIndex ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: dotIndex == _currentTipIndex
                                  ? _wellnessTips[_currentTipIndex]['color']
                                  : _wellnessTips[_currentTipIndex]['color']
                                        .withOpacity(0.2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
