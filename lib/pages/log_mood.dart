import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Necessary for saving to DB
import '../bloc/auth_bloc/auth_bloc.dart'; // The correct path based on your image structure

class LogMoodScreen extends StatefulWidget {
  const LogMoodScreen({super.key});

  @override
  State<LogMoodScreen> createState() => _LogMoodScreenState();
}

class _LogMoodScreenState extends State<LogMoodScreen> {
  // Local state for UI
  int _selectedMoodIndex = 0; // 0:Happy, 1:Sad, 2:Tired, 3:Anxious, 4:Excited
  final TextEditingController _journalController = TextEditingController();
  bool _isSaving = false;

  // Colors extracted from your HTML (Tailwind Config)
  final Color _primaryColor = const Color(0xFFC7C8F0);

  // Data list to facilitate UI construction and Firebase submission
  final List<Map<String, dynamic>> _moods = [
    {'label': 'Happy', 'emoji': '😊', 'color': Color(0xFFFFF4E0), 'value': 5},
    {'label': 'Sad', 'emoji': '😢', 'color': Color(0xFFE0F2FF), 'value': 1},
    {'label': 'Tired', 'emoji': '😴', 'color': Color(0xFFF0E6FF), 'value': 2},
    {'label': 'Anxious', 'emoji': '😰', 'color': Color(0xFFF0F0F5), 'value': 3},
    {'label': 'Excited', 'emoji': '🤩', 'color': Color(0xFFFFFCE0), 'value': 4},
    {
      'label': 'Grateful',
      'emoji': '🥰',
      'color': Color(0xFFFFE0E0),
      'value': 6,
    },
    {'label': 'Proud', 'emoji': '😁', 'color': Color(0xFFE0FFF4), 'value': 7},
    {'label': 'Angry', 'emoji': '😡', 'color': Color(0xFFFFE0E0), 'value': 8},
  ];

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  // Logic to Save to Firebase
  Future<void> _saveMoodToFirebase() async {
    final authState = context.read<AuthBloc>().state;

    if (authState is Authenticated) {
      setState(() => _isSaving = true);

      try {
        final userId = authState.user.uid;
        final selectedMoodData = _moods[_selectedMoodIndex];

        // Creates the structure for the future Statistical Chart
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('mood_logs')
            .add({
              'mood_label': selectedMoodData['label'],
              'mood_value': selectedMoodData['value'],
              // Useful for numeric charts (1 to 5)
              'note': _journalController.text.trim(),
              'timestamp': FieldValue.serverTimestamp(),
              // Exact date for sorting in the calendar
              'date_string': DateTime.now().toIso8601String().split('T')[0],
              // "2023-10-24" for easy grouping
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mood logged successfully!')),
          );
          Navigator.pop(context); // Returns to the previous page
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving mood: $e')));
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in to save.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final surfaceColor = theme.cardColor;
    final textMain =
        theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : const Color(0xFF101019));
    final textMuted = isDark ? Colors.grey[400]! : const Color(0xFF58598D);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header (Back button and Date)
            _buildHeader(textMain, textMuted, isDark),

            // Content with Scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'How are you feeling?',
                      style: TextStyle(
                        color: textMain,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Mood Grid
                    _buildMoodGrid(surfaceColor, textMain),

                    const SizedBox(height: 30),

                    // Text Box (Journal)
                    _buildJournalInput(surfaceColor, textMain, textMuted),

                    const SizedBox(height: 100),
                    // Space so the floating button doesn't cover content
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Floating Button (Fixed Bottom in HTML)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveMoodToFirebase,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: const Color(0xFF101019),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.black)
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Save Mood',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textMain, Color textMuted, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: textMain),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          Column(
            children: [
              Text(
                // You can use the 'intl' package to format the real date here
                'TODAY',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 40), // Invisible spacer to center the text
        ],
      ),
    );
  }

  // Nova Grelha com Scroll Horizontal
  Widget _buildMoodGrid(Color surfaceColor, Color textMain) {
    // SizedBox define a altura da área de scroll.
    // 380px é suficiente para caber 2 linhas de cartões + espaços
    return SizedBox(
      height: 380,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        // Faz o scroll para a direita
        padding: const EdgeInsets.symmetric(vertical: 10),
        // Espaço em cima e em baixo para a sombra não cortar
        itemCount: _moods.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 Linhas
          mainAxisSpacing: 16, // Espaço entre colunas (horizontal)
          crossAxisSpacing: 16, // Espaço entre linhas (vertical)
          childAspectRatio:
              1.1, // Controla a "magreza" do cartão (Altura vs Largura)
        ),
        itemBuilder: (context, index) {
          return _buildMoodCard(index, surfaceColor, textMain);
        },
      ),
    );
  }

  // O Design do Cartão (Simplificado para funcionar na grelha)
  Widget _buildMoodCard(int index, Color surfaceColor, Color textMain) {
    final bool isSelected = _selectedMoodIndex == index;
    final mood = _moods[index];

    return GestureDetector(
      onTap: () => setState(() => _selectedMoodIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _primaryColor.withOpacity(0.4)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 60,
              // Ajustei o tamanho para caber bem na grelha horizontal
              width: double.infinity,
              decoration: BoxDecoration(
                color: mood['color'],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  mood['emoji'],
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const Spacer(),
            Text(
              mood['label'],
              style: TextStyle(
                color: textMain,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.black),
              )
            else
              const SizedBox(
                height: 16,
              ), // Espaço vazio para manter alinhamento
          ],
        ),
      ),
    );
  }

  // Text Input
  Widget _buildJournalInput(
    Color surfaceColor,
    Color textMain,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: _primaryColor),
              const SizedBox(width: 8),
              Text(
                'Brief Description',
                style: TextStyle(fontWeight: FontWeight.bold, color: textMain),
              ),
            ],
          ),
          const Divider(),
          TextField(
            controller: _journalController,
            maxLines: 4,
            style: TextStyle(color: textMain),
            decoration: InputDecoration(
              hintText: "I'm feeling this way because...",
              hintStyle: TextStyle(color: textMuted.withOpacity(0.5)),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}
