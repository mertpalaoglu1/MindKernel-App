import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  DateTime? _lastResetDate;
  Timer? _timer;
  Duration _currentStreak = Duration.zero;
  String _currentQuote = "";

  final List<String> _quotes = [
    "Suffer the pain of discipline or suffer the pain of regret.",
    "Your future is created by what you do today, not tomorrow.",
    "Don't trade what you want most for what you want right now.",
    "Discipline equals freedom.",
  ];

  @override
  void initState() {
    super.initState();
    _loadStreakData();
    _pickRandomQuote();
    // Saniyede bir ekranı güncelleyen canlı sayaç
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lastResetDate != null) {
        setState(() {
          _currentStreak = DateTime.now().difference(_lastResetDate!);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Hafıza sızıntısını önlemek için
    super.dispose();
  }

  void _pickRandomQuote() {
    setState(() {
      _currentQuote = _quotes[Random().nextInt(_quotes.length)];
    });
  }

  Future<void> _loadStreakData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dateString = prefs.getString('lastResetDate');

    setState(() {
      if (dateString != null) {
        _lastResetDate = DateTime.parse(dateString);
      } else {
        _lastResetDate = DateTime.now();
        prefs.setString('lastResetDate', _lastResetDate!.toIso8601String());
      }
      _currentStreak = DateTime.now().difference(_lastResetDate!);
    });
  }

  Future<void> _resetStreak() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Reset Streak?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to start over? Stay strong."),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            child: const Text("Yes, Reset", style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setString('lastResetDate', now.toIso8601String());
      setState(() {
        _lastResetDate = now;
        _currentStreak = Duration.zero;
      });
      _pickRandomQuote();
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    int days = _currentStreak.inDays;
    int hours = _currentStreak.inHours % 24;
    int minutes = _currentStreak.inMinutes % 60;
    int seconds = _currentStreak.inSeconds % 60;

    // Temaya Göre Dinamik Renkler:
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDark ? Colors.white : Colors.black;
    Color boxColor = isDark ? Colors.grey[900]! : Colors.grey[100]!;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('CURRENT STREAK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 2.0, color: Colors.grey)),
              const SizedBox(height: 30),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _timeBox(days.toString().padLeft(2, '0'), 'DAYS'),
                  const Text(':', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                  _timeBox(hours.toString().padLeft(2, '0'), 'HRS'),
                  const Text(':', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                  _timeBox(minutes.toString().padLeft(2, '0'), 'MIN'),
                  const Text(':', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                  _timeBox(seconds.toString().padLeft(2, '0'), 'SEC'),
                ],
              ),
              const SizedBox(height: 60),

              OutlinedButton(
                onPressed: _resetStreak,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  side: BorderSide(color: textColor, width: 2), // Renk dinamikleşti
                ),
                child: Text('RESET STREAK', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)), // Renk dinamikleşti
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: boxColor, borderRadius: BorderRadius.circular(12)), // Renk dinamikleşti
                child: Text('"$_currentQuote"', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: textColor)), // Renk dinamikleşti
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  // Zaman kutucukları için yardımcı widget
  Widget _timeBox(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }
}