import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc/auth_bloc.dart';
import '../widgets/mood_line_chart.dart';
import 'package:intl/intl.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
    final backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF3F5F9);
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey;

    final authState = context.read<AuthBloc>().state;
    final String userId = (authState is Authenticated)
        ? authState.user.uid
        : '';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                DateFormat('EEEE, MMM d').format(DateTime.now()),
                style: TextStyle(
                  color: subTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                "Weekly Overview👋",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(height: 350, child: MoodBarChart(userId: userId)),
            ],
          ),
        ),
      ),
    );
  }
}
