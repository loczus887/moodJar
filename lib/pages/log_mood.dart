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
  final Color _surfaceColor = Colors.white;
  final Color _backgroundColor = const Color(0xFFFAFAF9);
  final Color _textMain = const Color(0xFF101019);
  final Color _textMuted = const Color(0xFF58598D);

  // Data list to facilitate UI construction and Firebase submission
  final List<Map<String, dynamic>> _moods = [
    {'label': 'Happy', 'emoji': '😊', 'color': Color(0xFFFFF4E0), 'value': 5},
    {'label': 'Sad', 'emoji': '😢', 'color': Color(0xFFE0F2FF), 'value': 1},
    {'label': 'Tired', 'emoji': '😴', 'color': Color(0xFFF0E6FF), 'value': 2},
    {'label': 'Anxious', 'emoji': '😰', 'color': Color(0xFFF0F0F5), 'value': 3},
    {'label': 'Excited', 'emoji': '🤩', 'color': Color(0xFFFFFCE0), 'value': 4},
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
          'mood_value': selectedMoodData['value'], // Useful for numeric charts (1 to 5)
          'note': _journalController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(), // Exact date for sorting in the calendar
          'date_string': DateTime.now().toIso8601String().split('T')[0], // "2023-10-24" for easy grouping
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mood logged successfully!')),
          );
          Navigator.pop(context); // Returns to the previous page
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving mood: $e')),
          );
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
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header (Back button and Date)
            _buildHeader(),
            
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
                        color: _textMain,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Mood Grid
                    _buildMoodGrid(),
                    
                    const SizedBox(height: 30),
                    
                    // Text Box (Journal)
                    _buildJournalInput(),
                    
                    const SizedBox(height: 100), // Space so the floating button doesn't cover content
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
              foregroundColor: _textMain,
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: _isSaving 
              ? const CircularProgressIndicator(color: Colors.black)
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Save Mood',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: _textMain),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.05),
            ),
          ),
          Column(
            children: [
              Text(
                // You can use the 'intl' package to format the real date here
                'TODAY', 
                style: TextStyle(
                  color: _textMuted,
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

  Widget _buildMoodGrid() {
    return Column(
      children: [
        // Row 1: Happy & Sad
        Row(
          children: [
            Expanded(child: _buildMoodCard(0)),
            const SizedBox(width: 16),
            Expanded(child: _buildMoodCard(1)),
          ],
        ),
        const SizedBox(height: 16),
        // Row 2: Tired & Anxious
        Row(
          children: [
            Expanded(child: _buildMoodCard(2)),
            const SizedBox(width: 16),
            Expanded(child: _buildMoodCard(3)),
          ],
        ),
        const SizedBox(height: 16),
        // Row 3: Excited (Full width)
        _buildWideMoodCard(4),
      ],
    );
  }

  // Square Card (Happy, Sad, etc)
  Widget _buildMoodCard(int index) {
    final bool isSelected = _selectedMoodIndex == index;
    final mood = _moods[index];

    return GestureDetector(
      onTap: () => setState(() => _selectedMoodIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? _primaryColor.withOpacity(0.4) : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: mood['color'],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                // If you have images in assets use: Image.asset('assets/${mood['label']}.png')
                child: Text(mood['emoji'], style: const TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              mood['label'],
              style: TextStyle(color: _textMain, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: _primaryColor, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 12, color: Colors.black),
              )
          ],
        ),
      ),
    );
  }

  // Wide Card (Excited)
  Widget _buildWideMoodCard(int index) {
    final bool isSelected = _selectedMoodIndex == index;
    final mood = _moods[index];

    return GestureDetector(
      onTap: () => setState(() => _selectedMoodIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.transparent,
            width: 2,
          ),
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
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: mood['color'],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(mood['emoji'], style: const TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mood['label'],
                    style: TextStyle(color: _textMain, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'High energy & motivated', // You can add subtitles to the _moods map if you want it dynamic
                    style: TextStyle(color: _textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: _primaryColor, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 14, color: Colors.black),
              ),
          ],
        ),
      ),
    );
  }

  // Text Input
  Widget _buildJournalInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
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
              Text('Brief Description', style: TextStyle(fontWeight: FontWeight.bold, color: _textMain)),
            ],
          ),
          const Divider(),
          TextField(
            controller: _journalController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "I'm feeling this way because...",
              hintStyle: TextStyle(color: _textMuted.withOpacity(0.5)),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}