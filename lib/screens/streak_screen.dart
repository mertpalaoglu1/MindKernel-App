import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Titreşim için eklendi
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

// WidgetsBindingObserver arka plandan uyanmayı dinlemek için eklendi
class _StreakScreenState extends State<StreakScreen> with WidgetsBindingObserver {
  DateTime? _lastResetDate;
  Timer? _timer;
  Duration _currentStreak = Duration.zero;
  String _currentQuote = "";
  int _attemptCount = 1;

  // Başarı Kilometre Taşları (Achievements)
  final List<Map<String, dynamic>> _milestones = [
    {'days': 1, 'title': 'Seed', 'desc': 'First 24 hours conquered.'},
    {'days': 3, 'title': 'Sprout', 'desc': 'Focus starts to clear.'},
    {'days': 7, 'title': 'Disciplined', 'desc': 'One full week of control.'},
    {'days': 14, 'title': 'Warrior', 'desc': 'Breaking the physical urge.'},
    {'days': 30, 'title': 'Monk Mode', 'desc': 'Mind is being rewired.'},
    {'days': 90, 'title': 'The Reboot', 'desc': 'Kernel optimization complete.'},
  ];

  final List<String> _quotes = [
    "Suffer the pain of discipline or suffer the pain of regret.",
    "Your future is created by what you do today, not tomorrow.",
    "Don't trade what you want most for what you want right now.",
    "Discipline equals freedom.",
    "You don't need motivation, you need control.",
    "Every urge you resist makes you stronger.",
    "Short-term pleasure, long-term damage.",
    "Control your mind or it will control you.",
    "Addiction is giving up everything for one thing.",
    "Discipline is choosing what you want most over what you want now.",
    "The urge will pass. The consequences might not.",
    "Weak moments create strong regrets.",
    "You either master your habits or they master you.",
    "Comfort is the enemy of growth.",
    "You are not your urges.",
    "What you repeat, you become.",
    "Easy choices, hard life. Hard choices, easy life.",
    "One decision can change your entire trajectory.",
    "Stop escaping. Start building.",
    "Dopamine now or success later. Choose.",
    "The mind seeks comfort, the strong seek growth.",
    "Every 'just once' builds the chain.",
    "Break the loop or stay in it forever.",
    "Self-control is self-respect.",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Dinleyiciyi başlat
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
    WidgetsBinding.instance.removeObserver(this); // Dinleyiciyi kapat
    super.dispose();
  }

  // Uygulama arka plandan öne geldiğinde süreyi anında günceller
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadStreakData();
    }
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
      _attemptCount = prefs.getInt('AttemptCount') ?? 1;
      _currentStreak = DateTime.now().difference(_lastResetDate!);
    });
  }

  Future<void> _resetStreak() async {
    HapticFeedback.vibrate(); // Uyarı titreşimi
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Tema uyumlu renk
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
      HapticFeedback.heavyImpact(); // Onaylandığında güçlü titreşim
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setString('lastResetDate', now.toIso8601String());
      setState(() {
        _lastResetDate = now;
        _currentStreak = Duration.zero;
        _attemptCount++; // denemeyi arttır.
      });
      await prefs.setInt('AttemptCount', _attemptCount); // kaydet.
      _pickRandomQuote();
    }
  }

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
      child: SingleChildScrollView( // Taşmayı önlemek için SingleChildScrollView
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
                  _timeBox(days.toString().padLeft(2, '0'), 'DAYS', textColor),
                  Text(':', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: textColor)),
                  _timeBox(hours.toString().padLeft(2, '0'), 'HRS', textColor),
                  Text(':', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: textColor)),
                  _timeBox(minutes.toString().padLeft(2, '0'), 'MIN', textColor),
                  Text(':', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: textColor)),
                  _timeBox(seconds.toString().padLeft(2, '0'), 'SEC', textColor),
                ],
              ),
              const SizedBox(height: 60),

              OutlinedButton(
                onPressed: _resetStreak,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  side: BorderSide(color: textColor, width: 2), // Renk dinamikleşti
                ),
                child: Text('RESET STREAK', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)), 
              ),
              const SizedBox(height: 10),
              Text('Attempt #$_attemptCount', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 40), // Spacer yerine SizedBox kullanıldı

              // --- ACHIEVEMENTS (BAŞARILAR) BÖLÜMÜ ---
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('ACHIEVEMENTS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              const Divider(thickness: 2),
              const SizedBox(height: 10),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _milestones.length,
                itemBuilder: (context, index) {
                  var m = _milestones[index];
                  bool isUnlocked = days >= m['days']; // Gerekli gün sağlandı mı?
                  
                  return Opacity(
                    opacity: isUnlocked ? 1.0 : 0.4, // Kilitliyse soluk görünür
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isUnlocked ? textColor : Colors.transparent,
                        border: Border.all(color: textColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isUnlocked ? Icons.verified : Icons.lock_outline,
                            color: isUnlocked ? (isDark ? Colors.black : Colors.white) : textColor,
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['title'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked ? (isDark ? Colors.black : Colors.white) : textColor,
                                ),
                              ),
                              Text(
                                m['desc'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isUnlocked ? (isDark ? Colors.black54 : Colors.white70) : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            "${m['days']}d",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? (isDark ? Colors.black : Colors.white) : textColor,
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Alıntı (Quote) Bölümü
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: boxColor, borderRadius: BorderRadius.circular(12)), 
                child: Text('"$_currentQuote"', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: textColor)), 
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  // Zaman kutucukları Dark Mode için Color parametresi aldı
  Widget _timeBox(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }
}