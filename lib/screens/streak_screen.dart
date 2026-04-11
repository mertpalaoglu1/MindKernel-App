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
  int _streakDays = 0;
  String _currentQuote = "";

  // Motivasyon Sözleri Listesi
  final List<String> _quotes = [
    "Suffer the pain of discipline or suffer the pain of regret.",
    "Your future is created by what you do today, not tomorrow.",
    "Don't trade what you want most for what you want right now.",
    "Discipline equals freedom.",
    "Small disciplines repeated with consistency every day lead to great achievements over time.",
    "Control your mind or it will control you."
  ];

  @override
  void initState() {
    super.initState();
    _loadStreakData();
    _pickRandomQuote();
  }

  // Rastgele söz seçme
  void _pickRandomQuote() {
    final random = Random();
    setState(() {
      _currentQuote = _quotes[random.nextInt(_quotes.length)];
    });
  }

  // Hafızadan son sıfırlama tarihini çekip gün farkını hesaplama
  Future<void> _loadStreakData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dateString = prefs.getString('lastResetDate');

    setState(() {
      if (dateString != null) {
        _lastResetDate = DateTime.parse(dateString);
      } else {
        // Eğer uygulama ilk kez açılıyorsa bugünü başlangıç say
        _lastResetDate = DateTime.now();
        prefs.setString('lastResetDate', _lastResetDate!.toIso8601String());
      }
      
      // Geçen günü hesapla (Şu anki zaman - Son sıfırlama zamanı)
      _streakDays = DateTime.now().difference(_lastResetDate!).inDays;
    });
  }

  // Seriyi sıfırlama (Emin misin sorusuyla birlikte)
  Future<void> _resetStreak() async {
    // Onay penceresi (Yanlışlıkla sıfırlamayı önlemek için)
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
        );
      },
    );

    // Eğer evet dersen sıfırla
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setString('lastResetDate', now.toIso8601String());
      
      setState(() {
        _lastResetDate = now;
        _streakDays = 0;
      });
      _pickRandomQuote(); // Yeni başlangıç, yeni söz
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'CURRENT STREAK',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              
              // Dev Gün Sayacı
              Text(
                '$_streakDays',
                style: const TextStyle(
                  fontSize: 120,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              const Text(
                'DAYS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                ),
              ),
              const SizedBox(height: 60),

              // Sıfırlama Butonu
              OutlinedButton(
                onPressed: _resetStreak,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  side: const BorderSide(color: Colors.black, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'RESET STREAK',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const Spacer(), // Boşluğu aşağı iter
              
              // Rastgele Motivasyon Sözü
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  '"$_currentQuote"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}