import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../bloc/auth_bloc/auth_bloc.dart';
import '../data/models/gemini_models.dart';
import '../data/repositories/gemini_repository.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Base Colors
  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  Color get _primaryColor => const Color(0xFFC7C8F0);

  Color get _backgroundColor =>
      _isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAF9);

  Color get _surfaceColor =>
      _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

  Color get _textMain => _isDarkMode ? Colors.white : const Color(0xFF101019);

  Color get _textSecondary =>
      _isDarkMode ? Colors.grey[400]! : Colors.grey[500]!;

  // Calendar Variables
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // AI Daily Summary State
  bool _isGeneratingDaily = false;
  String? _dailyAiQuote;
  final GeminiRepository _geminiRepository = GeminiRepository();
  bool _isApiAvailable = false;

  // Cache for mood quotes
  Map<String, String> _moodQuotesCache = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _checkApiAvailability();
    _loadMoodQuotesCache();
  }

  Future<void> _checkApiAvailability() async {
    final isHealthy = await _geminiRepository.checkHealth();
    if (mounted) {
      setState(() {
        _isApiAvailable = isHealthy;
      });
    }
  }

  Future<void> _loadMoodQuotesCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheString = prefs.getString('mood_quotes_cache');
    if (cacheString != null) {
      setState(() {
        _moodQuotesCache = Map<String, String>.from(jsonDecode(cacheString));
      });
    }
  }

  Future<void> _saveMoodQuotesCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mood_quotes_cache', jsonEncode(_moodQuotesCache));
  }

  // Daily AI Insight Generation
  Future<void> _generateDailyInsight(
    List<QueryDocumentSnapshot> dailyMoods,
    String userId,
  ) async {
    setState(() {
      _isGeneratingDaily = true;
      _dailyAiQuote = null;
    });

    // Double check health just in case connection dropped
    final isHealthy = await _geminiRepository.checkHealth();
    if (!isHealthy) {
      if (mounted) {
        setState(() {
          _isGeneratingDaily = false;
          _dailyAiQuote =
              "AI Service is currently unavailable. Please try again later.";
          _isApiAvailable = false; // Update state to hide UI next time
        });
      }
      return;
    }

    // Prepare data for API
    List<DiaryEntry> diaries = dailyMoods.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return DiaryEntry(
        id: doc.id,
        content: "Mood: ${data['mood_label']}. Note: ${data['note'] ?? ''}",
        date: data['date_string'] ?? DateTime.now().toIso8601String(),
      );
    }).toList();

    // Fetch existing memories
    List<MemoryEntry> currentMemories = [];
    try {
      final memoriesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('memories')
          .get();

      currentMemories = memoriesSnapshot.docs.map((doc) {
        return MemoryEntry(
          id: doc.id,
          content: doc['content'] as String? ?? '',
          score: doc['score'] as int?, // Fetch score
        );
      }).toList();
    } catch (e) {
      debugPrint("Error fetching memories: $e");
    }

    // Only update memories if the selected day is TODAY
    bool isToday = isSameDay(_selectedDay, DateTime.now());

    // Call API
    final response = await _geminiRepository.analyze(
      diaries: diaries,
      memories: currentMemories,
      options: AnalysisOptions(
        dailyText: true,
        moodSentences: true, // Generate mood sentences as well
        memories: isToday, // Only generate/update memories if it's today
      ),
    );

    if (mounted) {
      setState(() {
        _isGeneratingDaily = false;
        if (response.success) {
          if (response.data?.dailyText != null) {
            _dailyAiQuote = response.data!.dailyText;
          }

          // Cache mood sentences
          if (response.data?.moodSentences != null) {
            _moodQuotesCache.addAll(response.data!.moodSentences!);
            _saveMoodQuotesCache();
          }

          // Store memories if returned and it is today
          if (isToday && response.data?.finalMemories != null) {
            _storeMemories(userId, response.data!.finalMemories!);
          }
        } else {
          _dailyAiQuote =
              "Could not generate insight. ${response.error?.message ?? ''}";
        }
      });
    }
  }

  Future<void> _storeMemories(String userId, List<MemoryEntry> memories) async {
    final batch = FirebaseFirestore.instance.batch();
    final memoriesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('memories');

    for (var memory in memories) {
      DocumentReference docRef;
      if (memory.id.isNotEmpty) {
        docRef = memoriesRef.doc(memory.id);
      } else {
        docRef = memoriesRef.doc(); // Generate new ID
      }

      final data = {
        'content': memory.content,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (memory.score != null) {
        data['score'] = memory.score!;
      }

      batch.set(docRef, data);
    }

    await batch.commit();
  }

  // Color Map
  Color _getColorForMood(String label) {
    switch (label) {
      case 'Happy':
        return Colors.orangeAccent;
      case 'Sad':
        return Colors.lightBlueAccent;
      case 'Tired':
        return Colors.purpleAccent;
      case 'Anxious':
        return Colors.blueGrey;
      case 'Excited':
        return Colors.yellow;
      case 'Grateful':
        return Colors.pinkAccent;
      case 'Proud':
        return Colors.tealAccent;
      case 'Angry':
        return Colors.redAccent;
      default:
        return _primaryColor;
    }
  }

  // Simple Circle Widget
  Widget _buildSimpleMoodCircle({
    required String text,
    required Color color,
    bool isSelected = false,
    bool isToday = false,
    bool hasEvents = false,
  }) {
    Color bgColor = Colors.transparent;

    if (hasEvents) {
      bgColor = color.withOpacity(0.4);
    } else if (isSelected || isToday) {
      bgColor = _primaryColor.withOpacity(0.3);
    }

    BoxBorder? border;
    if (isSelected) {
      border = Border.all(color: _textMain, width: 1);
    } else if (isToday) {
      border = Border.all(color: _primaryColor, width: 2);
    }

    return Container(
      margin: const EdgeInsets.all(2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: border,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: _textMain,
          fontWeight: (isSelected || isToday || hasEvents)
              ? FontWeight.bold
              : FontWeight.normal,
          fontSize: 16,
        ),
      ),
    );
  }

  // Black Marker Dot
  Widget _buildMarker() {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.white70 : Colors.black87,
        shape: BoxShape.circle,
      ),
    );
  }

  // Bottom Sheet with AI Section
  void _showMoodDetails(
    BuildContext context,
    String label,
    String note,
    String time,
    Color color,
    String docId, // Added docId to identify specific entry
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allows the sheet to grow with content
      builder: (context) {
        // Local variables to control state INSIDE the Bottom Sheet
        bool isGeneratingMoodAi = false;
        String? moodAiQuote = _moodQuotesCache[docId]; // Check cache first

        // StatefulBuilder allows updating UI inside Bottom Sheet without closing
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            // Function for individual AI
            Future<void> generateMoodQuote() async {
              setSheetState(() => isGeneratingMoodAi = true);

              // Check health
              final isHealthy = await _geminiRepository.checkHealth();
              if (!isHealthy) {
                setSheetState(() {
                  isGeneratingMoodAi = false;
                  moodAiQuote = "AI Service unavailable.";
                });
                // Also update parent state to reflect unavailability
                if (mounted) {
                  setState(() {
                    _isApiAvailable = false;
                  });
                }
                return;
              }

              // Prepare single entry
              final entry = DiaryEntry(
                id: docId,
                content: "Mood: $label. Note: $note",
                date: DateTime.now()
                    .toIso8601String(), // Date doesn't matter much for single insight
              );

              // Call API
              final response = await _geminiRepository.analyze(
                diaries: [entry],
                options: const AnalysisOptions(
                  dailyText: false,
                  moodSentences: true, // We want specific mood insight
                  memories: false,
                ),
              );

              setSheetState(() {
                isGeneratingMoodAi = false;
                if (response.success && response.data?.moodSentences != null) {
                  // The API returns a map keyed by ID
                  final quote = response.data!.moodSentences![docId];
                  if (quote != null) {
                    moodAiQuote = quote;
                    // Update cache
                    _moodQuotesCache[docId] = quote;
                    _saveMoodQuotesCache();
                  } else {
                    moodAiQuote = "No specific insight generated.";
                  }
                } else {
                  moodAiQuote =
                      "Error: ${response.error?.message ?? 'Unknown'}";
                }
              });
            }

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Large Icon and Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _getIconForMood(label),
                          size: 32,
                          color: _textMain,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _textMain,
                            ),
                          ),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 14,
                              color: _textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Description Area
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Description",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _textSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          note.isEmpty ? "No description provided." : note,
                          style: TextStyle(
                            fontSize: 16,
                            color: _textMain,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // AI Mood Insight Block
                  if (_isApiAvailable || moodAiQuote != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        // Subtle gradient to differentiate AI section
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.withOpacity(0.05),
                            Colors.blue.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 16,
                                    color: Colors.purple[300],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "AI Insight",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple[300],
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              // The Button to activate
                              if (moodAiQuote == null && !isGeneratingMoodAi)
                                InkWell(
                                  onTap: generateMoodQuote,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isDarkMode
                                          ? Colors.purple.withOpacity(0.2)
                                          : Colors.purple[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.purple[100]!,
                                      ),
                                    ),
                                    child: const Text(
                                      "Generate",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.purple,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Logic: If loading -> Bar; If text -> Text; Else -> Instruction
                          if (isGeneratingMoodAi)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: LinearProgressIndicator(
                                backgroundColor: _isDarkMode
                                    ? Colors.purple.withOpacity(0.2)
                                    : Colors.purple[50],
                                color: Colors.purple[300],
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          else if (moodAiQuote != null)
                            Text(
                              moodAiQuote!,
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: _isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[800],
                              ),
                            )
                          else
                            Text(
                              "Tap generate to get an inspiring quote for this specific emotion.",
                              style: TextStyle(
                                fontSize: 14,
                                color: _isDarkMode
                                    ? Colors.grey[500]
                                    : Colors.grey[400],
                              ),
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _getIconForMood(String label) {
    if (label == 'Happy') return Icons.sentiment_satisfied;
    if (label == 'Sad') return Icons.sentiment_dissatisfied;
    if (label == 'Angry') return Icons.warning;
    if (label == 'Excited') return Icons.star;
    if (label == 'Tired') return Icons.nightlight_round;
    if (label == 'Anxious') return Icons.help_outline;
    if (label == 'Grateful') return Icons.favorite;
    if (label == 'Proud') return Icons.workspace_premium;
    return Icons.sentiment_neutral;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    if (authState is! Authenticated) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    final userId = authState.user.uid;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'History',
          style: TextStyle(color: _textMain, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: _textMain),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('mood_logs')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text("Error loading data"));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          Map<String, List<QueryDocumentSnapshot>> moodsByDate = {};
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final dateKey = data['date_string'] ?? '';
            if (dateKey.isNotEmpty) {
              if (moodsByDate[dateKey] == null) moodsByDate[dateKey] = [];
              moodsByDate[dateKey]!.add(doc);
            }
          }

          final selectedDateKey = _selectedDay.toString().split(' ')[0];
          final moodsForSelectedDay = moodsByDate[selectedDateKey] ?? [];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Calendar
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                        // Reset daily AI when day changes
                        _dailyAiQuote = null;
                        _isGeneratingDaily = false;
                      });
                    },
                    rowHeight: 60,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: TextStyle(color: _textMain),
                      weekendTextStyle: TextStyle(color: _textMain),
                      outsideTextStyle: TextStyle(color: _textSecondary),
                    ),
                    eventLoader: (day) {
                      final key = day.toString().split(' ')[0];
                      return moodsByDate[key] ?? [];
                    },
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        final key = day.toString().split(' ')[0];
                        final events = moodsByDate[key];
                        bool hasEvents = events != null && events.isNotEmpty;
                        Color moodColor = Colors.transparent;
                        if (hasEvents) {
                          final data =
                              events.first.data() as Map<String, dynamic>;
                          moodColor = _getColorForMood(
                            data['mood_label'] ?? '',
                          );
                        }
                        return _buildCalendarCell(
                          day,
                          moodColor,
                          hasEvents: hasEvents,
                        );
                      },
                      selectedBuilder: (context, day, focusedDay) {
                        final key = day.toString().split(' ')[0];
                        final events = moodsByDate[key];
                        bool hasEvents = events != null && events.isNotEmpty;
                        Color moodColor = Colors.transparent;
                        if (hasEvents) {
                          final data =
                              events.first.data() as Map<String, dynamic>;
                          moodColor = _getColorForMood(
                            data['mood_label'] ?? '',
                          );
                        }
                        return _buildCalendarCell(
                          day,
                          moodColor,
                          isSelected: true,
                          hasEvents: hasEvents,
                        );
                      },
                      todayBuilder: (context, day, focusedDay) {
                        final key = day.toString().split(' ')[0];
                        final events = moodsByDate[key];
                        bool hasEvents = events != null && events.isNotEmpty;
                        Color moodColor = Colors.transparent;
                        if (hasEvents) {
                          final data =
                              events.first.data() as Map<String, dynamic>;
                          moodColor = _getColorForMood(
                            data['mood_label'] ?? '',
                          );
                        }
                        return _buildCalendarCell(
                          day,
                          moodColor,
                          isToday: true,
                          hasEvents: hasEvents,
                        );
                      },
                      markerBuilder: (context, day, events) => const SizedBox(),
                    ),
                  ),
                ),

                // 2. Stats
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildStatCard(
                        'Top Mood',
                        'Happy',
                        Icons.sentiment_satisfied,
                        Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'Streak',
                        '${moodsByDate.length} Days',
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'Entries',
                        '${docs.length} Total',
                        Icons.history_edu,
                        const Color(0xFF58598D),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Header List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Moods on ${DateFormat('MMM d').format(_selectedDay!)}',
                        style: TextStyle(
                          color: _textMain,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${moodsForSelectedDay.length} logs',
                        style: TextStyle(color: _textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 4. Horizontal List
                if (moodsForSelectedDay.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "No moods logged for this day. O _ O",
                      style: TextStyle(color: _textSecondary),
                    ),
                  )
                else
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: moodsForSelectedDay.length,
                      itemBuilder: (context, index) {
                        final doc = moodsForSelectedDay[index];
                        final data = doc.data() as Map<String, dynamic>;

                        String timeString = "--:--";
                        if (data['timestamp'] != null) {
                          DateTime date = (data['timestamp'] as Timestamp)
                              .toDate();
                          timeString = DateFormat('h:mm a').format(date);
                        }

                        String note = data['note'] ?? '';
                        String label = data['mood_label'] ?? 'Mood';

                        return _buildDailyMoodCard(
                          label,
                          timeString,
                          note,
                          doc.id,
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 24),

                // 5. Daily AI Wisdom (Daily Summary)
                // Only appears if there are moods logged for this day AND API is available
                if (moodsForSelectedDay.isNotEmpty && _isApiAvailable)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _surfaceColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _primaryColor.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, color: _primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              "Daily Wisdom",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _textMain,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Logic: If loading -> Line; If text -> Show text; Else -> Button
                        if (_isGeneratingDaily)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 10,
                            ),
                            child: LinearProgressIndicator(
                              color: _primaryColor,
                              backgroundColor: _primaryColor.withOpacity(0.2),
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )
                        else if (_dailyAiQuote != null)
                          Text(
                            _dailyAiQuote!,
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                              color: _textMain,
                            ),
                          )
                        else
                          ElevatedButton(
                            onPressed: () => _generateDailyInsight(
                              moodsForSelectedDay,
                              userId,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _textMain,
                              foregroundColor: _isDarkMode
                                  ? Colors.black
                                  : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text("Get Daily Insight"),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper to build calendar cell column
  Widget _buildCalendarCell(
    DateTime day,
    Color color, {
    bool isSelected = false,
    bool isToday = false,
    bool hasEvents = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: _buildSimpleMoodCircle(
            text: '${day.day}',
            color: color,
            isSelected: isSelected,
            isToday: isToday,
            hasEvents: hasEvents,
          ),
        ),
        if (hasEvents) ...[
          _buildMarker(),
          const SizedBox(height: 4),
        ] else
          const SizedBox(height: 9),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _textMain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card with tap gesture
  Widget _buildDailyMoodCard(
    String label,
    String time,
    String note,
    String docId,
  ) {
    Color cardColor = _getColorForMood(label).withOpacity(0.3);
    IconData icon = _getIconForMood(label);

    return GestureDetector(
      onTap: () => _showMoodDetails(
        context,
        label,
        note,
        time,
        _getColorForMood(label),
        docId,
      ),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: _isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textMain,
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
