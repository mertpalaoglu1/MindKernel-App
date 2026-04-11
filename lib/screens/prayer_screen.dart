import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  // Günlük namazlar (İngilizce terimler, minimalist dilde evrensel tutmak için)
  final Map<String, bool> _dailyPrayers = {
    'Fajr': false,
    'Dhuhr': false,
    'Asr': false,
    'Maghrib': false,
    'Isha': false,
  };

  // Kaza namazları sayaçları
  final Map<String, int> _qazaPrayers = {
    'Fajr': 0,
    'Dhuhr': 0,
    'Asr': 0,
    'Maghrib': 0,
    'Isha': 0,
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
    final String today = DateTime.now().toIso8601String().substring(0, 10); // Sadece YYYY-MM-DD
    
    setState(() {
      _lastSavedDate = prefs.getString('lastPrayerDate') ?? today;
      _totalPerfectDays = prefs.getInt('perfectPrayerDays') ?? 0;

      // Eğer gün değiştiyse günlük kutuları sıfırla, değişmediyse eski veriyi çek
      bool isNewDay = _lastSavedDate != today;

      for (var key in _dailyPrayers.keys) {
        if (isNewDay) {
          _dailyPrayers[key] = false;
        } else {
          _dailyPrayers[key] = prefs.getBool('prayer_$key') ?? false;
        }
        // Kaza verilerini çek (gün değişiminden etkilenmez)
        _qazaPrayers[key] = prefs.getInt('qaza_$key') ?? 0;
      }

      if (isNewDay) {
        prefs.setString('lastPrayerDate', today);
      }
    });
  }

  // Günlük namaz kaydetme ve "Kusursuz Gün" hesabı
  Future<void> _toggleDailyPrayer(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _dailyPrayers[key] = value;
    });
    await prefs.setBool('prayer_$key', value);

    // Eğer 5 vakit de kılındıysa total günü artır (Sadece hepsi true olduğunda 1 kez tetiklenir)
    bool allCompleted = _dailyPrayers.values.every((v) => v == true);
    bool wasCompleted = prefs.getBool('wasPerfectToday') ?? false;

    if (allCompleted && !wasCompleted) {
      setState(() {
        _totalPerfectDays++;
      });
      await prefs.setInt('perfectPrayerDays', _totalPerfectDays);
      await prefs.setBool('wasPerfectToday', true);
    } else if (!allCompleted && wasCompleted) {
      // Çentiği geri alırsa mükemmel günü düşür
      setState(() {
        _totalPerfectDays--;
      });
      await prefs.setInt('perfectPrayerDays', _totalPerfectDays);
      await prefs.setBool('wasPerfectToday', false);
    }
  }

  // Kaza artırma/azaltma
  Future<void> _updateQaza(String key, int change) async {
    final prefs = await SharedPreferences.getInstance();
    int newValue = (_qazaPrayers[key] ?? 0) + change;
    
    if (newValue < 0) return; // Kaza eksiye düşemez

    setState(() {
      _qazaPrayers[key] = newValue;
    });
    await prefs.setInt('qaza_$key', newValue);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Bilgi: Toplam Kusursuz Gün
            Center(
              child: Column(
                children: [
                  const Text(
                    'PERFECT DAYS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '$_totalPerfectDays',
                    style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Günlük Namazlar
            const Text(
              'DAILY PRAYERS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 2, color: Colors.black),
            ..._dailyPrayers.keys.map((String key) {
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.black,
                title: Text(
                  key,
                  style: TextStyle(
                    fontSize: 18,
                    decoration: _dailyPrayers[key]! ? TextDecoration.lineThrough : null,
                  ),
                ),
                value: _dailyPrayers[key],
                onChanged: (bool? value) {
                  if (value != null) _toggleDailyPrayer(key, value);
                },
              );
            }),

            const SizedBox(height: 30),

            // Kaza Takibi
            const Text(
              'QAZA (MISSED) TRACKER',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 2, color: Colors.black),
            ..._qazaPrayers.keys.map((String key) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(key, style: const TextStyle(fontSize: 16)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _updateQaza(key, -1),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${_qazaPrayers[key]}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _updateQaza(key, 1),
                        ),
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