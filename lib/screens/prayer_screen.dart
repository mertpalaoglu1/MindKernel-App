import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  // Türkçeleri eklendi
  final Map<String, bool> _dailyPrayers = {
    'Fajr (Sabah)': false,
    'Dhuhr (Öğle)': false,
    'Asr (İkindi)': false,
    'Maghrib (Akşam)': false,
    'Isha (Yatsı)': false,
  };

  final Map<String, int> _qazaPrayers = {
    'Fajr (Sabah)': 0,
    'Dhuhr (Öğle)': 0,
    'Asr (İkindi)': 0,
    'Maghrib (Akşam)': 0,
    'Isha (Yatsı)': 0,
  };

  int _totalPerfectDays = 0;
  String _lastSavedDate = "";

  @override
  void initState() {
    super.initState();
    _loadPrayerData();
  }

  Future<void> _loadPrayerData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // TRICK: Günü sabah 4'te bitirir. Gece 2'de yatsı kılarsan dünün yatsısı sayılır.
    DateTime logicalNow = DateTime.now().subtract(const Duration(hours: 4));
    final String today = logicalNow.toIso8601String().substring(0, 10);
    
    setState(() {
      _lastSavedDate = prefs.getString('lastPrayerDate') ?? today;
      _totalPerfectDays = prefs.getInt('perfectPrayerDays') ?? 0;

      bool isNewDay = _lastSavedDate != today;

      for (var key in _dailyPrayers.keys) {
        if (isNewDay) {
          _dailyPrayers[key] = false;
        } else {
          _dailyPrayers[key] = prefs.getBool('prayer_$key') ?? false;
        }
        _qazaPrayers[key] = prefs.getInt('qaza_$key') ?? 0;
      }

      if (isNewDay) {
        prefs.setString('lastPrayerDate', today);
        prefs.setBool('wasPerfectToday', false);
      }
    });
  }

  Future<void> _toggleDailyPrayer(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyPrayers[key] = value;
    });
    await prefs.setBool('prayer_$key', value);

    bool allCompleted = _dailyPrayers.values.every((v) => v == true);
    bool wasCompleted = prefs.getBool('wasPerfectToday') ?? false;

    if (allCompleted && !wasCompleted) {
      setState(() => _totalPerfectDays++);
      await prefs.setInt('perfectPrayerDays', _totalPerfectDays);
      await prefs.setBool('wasPerfectToday', true);
    } else if (!allCompleted && wasCompleted) {
      setState(() => _totalPerfectDays--);
      await prefs.setInt('perfectPrayerDays', _totalPerfectDays);
      await prefs.setBool('wasPerfectToday', false);
    }
  }

  Future<void> _updateQaza(String key, int change) async {
    final prefs = await SharedPreferences.getInstance();
    int newValue = (_qazaPrayers[key] ?? 0) + change;
    if (newValue < 0) return;

    setState(() {
      _qazaPrayers[key] = newValue;
    });
    await prefs.setInt('qaza_$key', newValue);
  }
  
  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color iconColor = isDark ? Colors.white : Colors.black;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Camii Logosu ve Hadis
            Icon(Icons.mosque, size: 48, color: iconColor),
            const SizedBox(height: 10),
            const Text(
              '"Allah ibadetin az da olsa devamlı olanını sever."',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),

            Column(
              children: [
                const Text('PERFECT DAYS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 2.0, color: Colors.grey)),
                Text('$_totalPerfectDays', style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),

            const Align(alignment: Alignment.centerLeft, child: Text('DAILY PRAYERS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const Divider(thickness: 2, color: Colors.black),
            ..._dailyPrayers.keys.map((String key) {
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.black,
                title: Text(key, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, decoration: _dailyPrayers[key]! ? TextDecoration.lineThrough : null)),
                value: _dailyPrayers[key],
                onChanged: (bool? value) {
                  if (value != null) _toggleDailyPrayer(key, value);
                },
              );
            }),

            const SizedBox(height: 30),
            const Align(alignment: Alignment.centerLeft, child: Text('QAZA (MISSED)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const Divider(thickness: 2, color: Colors.black),
            ..._qazaPrayers.keys.map((String key) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _updateQaza(key, -1)),
                        SizedBox(width: 30, child: Text('${_qazaPrayers[key]}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _updateQaza(key, 1)),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}