import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../bloc/auth_bloc/auth_bloc.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Base Colors
  final Color _primaryColor = const Color(0xFFC7C8F0);
  final Color _backgroundColor = const Color(0xFFFAFAF9);
  final Color _surfaceColor = Colors.white;
  final Color _textMain = const Color(0xFF101019);

  // Calendar Variables
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // --- VARIÁVEIS DE ESTADO PARA O AI DO RESUMO DIÁRIO ---
  bool _isGeneratingDaily = false;
  String? _dailyAiQuote;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // --- FUNÇÃO MOCK (SIMULAÇÃO) PARA O AI DIÁRIO ---
  // O seu colega substituirá isto pela chamada real à API do LLM
  Future<void> _generateDailyInsight() async {
    setState(() {
      _isGeneratingDaily = true;
    });

    // Simula delay de rede (Loading)
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isGeneratingDaily = false;
      _dailyAiQuote = "Based on your mix of happiness and tiredness today, remember that rest is part of the journey. Recharge so you can shine brighter tomorrow!";
    });
  }

  // Color Map
  Color _getColorForMood(String label) {
    switch (label) {
      case 'Happy': return Colors.orangeAccent;
      case 'Sad': return Colors.lightBlueAccent;
      case 'Tired': return Colors.purpleAccent;
      case 'Anxious': return Colors.blueGrey;
      case 'Excited': return Colors.yellow;
      case 'Grateful': return Colors.pinkAccent;
      case 'Proud': return Colors.tealAccent;
      case 'Angry': return Colors.redAccent;
      default: return _primaryColor;
    }
  }

  // --- SIMPLE CIRCLE WIDGET ---
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
          fontWeight: (isSelected || isToday || hasEvents) ? FontWeight.bold : FontWeight.normal,
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
      decoration: const BoxDecoration(
        color: Colors.black87,
        shape: BoxShape.circle,
      ),
    );
  }

  // --- BOTTOM SHEET ATUALIZADO COM SECÇÃO DE AI ---
  void _showMoodDetails(BuildContext context, String label, String note, String time, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Permite que a sheet cresça com o conteúdo
      builder: (context) {
        // Variáveis locais para controlar o estado DENTRO do Bottom Sheet
        bool isGeneratingMoodAi = false;
        String? moodAiQuote;

        // StatefulBuilder permite atualizar a UI dentro do Bottom Sheet sem fechar
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            
            // Função Mock para o AI individual
            Future<void> generateMoodQuote() async {
              setSheetState(() => isGeneratingMoodAi = true);
              await Future.delayed(const Duration(seconds: 2)); // Simula LLM
              setSheetState(() {
                isGeneratingMoodAi = false;
                moodAiQuote = "Feeling $label is a valid emotion. Take a moment to breathe and acknowledge it without judgment. This is an AI generated placeholder.";
              });
            }

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pega de arrastar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Ícone Grande e Título
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(_getIconForMood(label), size: 32, color: Colors.black87),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          Text(
                            time,
                            style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Área da Descrição
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
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          note.isEmpty ? "No description provided." : note,
                          style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // --- NOVA SECÇÃO: AI MOOD INSIGHT ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      // Gradiente subtil para diferenciar a secção AI
                      gradient: LinearGradient(
                        colors: [Colors.purple.withOpacity(0.05), Colors.blue.withOpacity(0.05)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.purple.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.auto_awesome, size: 16, color: Colors.purple[300]),
                                const SizedBox(width: 8),
                                Text(
                                  "AI Insight",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple[300], letterSpacing: 1),
                                ),
                              ],
                            ),
                            // O Botão para ativar
                            if (moodAiQuote == null && !isGeneratingMoodAi)
                              InkWell(
                                onTap: generateMoodQuote,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.purple[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.purple[100]!),
                                  ),
                                  child: const Text("Generate", style: TextStyle(fontSize: 12, color: Colors.purple)),
                                ),
                              )
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Lógica: Se carregar -> Barra; Se tiver texto -> Texto; Senão -> Instrução
                        if (isGeneratingMoodAi)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.purple[50],
                              color: Colors.purple[300],
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )
                        else if (moodAiQuote != null)
                          Text(
                            moodAiQuote!,
                            style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey[800]),
                          )
                        else
                          Text(
                            "Tap generate to get an inspiring quote for this specific emotion.",
                            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            );
          }
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
          if (snapshot.hasError) return const Center(child: Text("Error loading data"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

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
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))
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
                        // Reset ao AI diário quando muda o dia
                        _dailyAiQuote = null; 
                        _isGeneratingDaily = false;
                      });
                    },
                    rowHeight: 60, 
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false, 
                      titleCentered: true,
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
                           final data = events.first.data() as Map<String, dynamic>;
                           moodColor = _getColorForMood(data['mood_label'] ?? '');
                        }
                        return _buildCalendarCell(day, moodColor, hasEvents: hasEvents);
                      },
                      selectedBuilder: (context, day, focusedDay) {
                        final key = day.toString().split(' ')[0];
                        final events = moodsByDate[key];
                        bool hasEvents = events != null && events.isNotEmpty;
                        Color moodColor = Colors.transparent;
                        if (hasEvents) {
                           final data = events.first.data() as Map<String, dynamic>;
                           moodColor = _getColorForMood(data['mood_label'] ?? '');
                        }
                        return _buildCalendarCell(day, moodColor, isSelected: true, hasEvents: hasEvents);
                      },
                      todayBuilder: (context, day, focusedDay) {
                        final key = day.toString().split(' ')[0];
                        final events = moodsByDate[key];
                        bool hasEvents = events != null && events.isNotEmpty;
                        Color moodColor = Colors.transparent;
                        if (hasEvents) {
                           final data = events.first.data() as Map<String, dynamic>;
                           moodColor = _getColorForMood(data['mood_label'] ?? '');
                        }
                        return _buildCalendarCell(day, moodColor, isToday: true, hasEvents: hasEvents);
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
                      _buildStatCard('Top Mood', 'Happy', Icons.sentiment_satisfied, Colors.green),
                      const SizedBox(width: 12),
                      _buildStatCard('Streak', '${moodsByDate.length} Days', Icons.local_fire_department, Colors.orange),
                      const SizedBox(width: 12),
                      _buildStatCard('Entries', '${docs.length} Total', Icons.history_edu, const Color(0xFF58598D)),
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
                        style: TextStyle(color: _textMain, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${moodsForSelectedDay.length} logs',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 4. Horizontal List
                if (moodsForSelectedDay.isEmpty)
                   Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text("No moods logged for this day. O _ O", style: TextStyle(color: Colors.grey[400])),
                  )
                else
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: moodsForSelectedDay.length,
                      itemBuilder: (context, index) {
                        final data = moodsForSelectedDay[index].data() as Map<String, dynamic>;
                        
                        String timeString = "--:--";
                        if (data['timestamp'] != null) {
                          DateTime date = (data['timestamp'] as Timestamp).toDate();
                          timeString = DateFormat('h:mm a').format(date);
                        }

                        String note = data['note'] ?? '';
                        String label = data['mood_label'] ?? 'Mood';

                        return _buildDailyMoodCard(
                          label,
                          timeString,
                          note, 
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 24),

                // 5. --- NOVA SECÇÃO: DAILY AI WISDOM (RESUMO DO DIA) ---
                // Só aparece se houver moods registados nesse dia
                if (moodsForSelectedDay.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _primaryColor.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(color: _primaryColor.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))
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
                             const Text(
                               "Daily Wisdom",
                               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                             ),
                           ],
                         ),
                         const SizedBox(height: 16),
                         
                         // Lógica: Se loading -> Linha; Se texto -> Mostra texto; Senão -> Botão
                         if (_isGeneratingDaily)
                           Padding(
                             padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
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
                             textAlign: TextAlign.center,
                             style: const TextStyle(
                               fontSize: 14, 
                               fontStyle: FontStyle.italic, 
                               height: 1.5,
                               color: Colors.black87
                             ),
                           )
                         else
                           ElevatedButton(
                             onPressed: _generateDailyInsight,
                             style: ElevatedButton.styleFrom(
                               backgroundColor: _textMain,
                               foregroundColor: Colors.white,
                               elevation: 0,
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
  Widget _buildCalendarCell(DateTime day, Color color, {bool isSelected = false, bool isToday = false, bool hasEvents = false}) {
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

  Widget _buildStatCard(String label, String value, IconData icon, Color iconColor) {
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
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textMain)),
            ],
          )
        ],
      ),
    );
  }

  // Card with tap gesture
  Widget _buildDailyMoodCard(String label, String time, String note) {
    Color cardColor = _getColorForMood(label).withOpacity(0.3);
    IconData icon = _getIconForMood(label);

    return GestureDetector(
      onTap: () => _showMoodDetails(context, label, note, time, _getColorForMood(label)),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: Colors.black54),
            ),
            const Spacer(),
            Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textMain)),
            Text(time, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }
}