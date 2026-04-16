import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _todos = [];
  List<bool> _todoStates = [];
  final TextEditingController _todoController = TextEditingController();

  // Eylem isimleri butonlarda kalacak
  final List<String> _habits = ['Gym', 'Meditation', 'Reading', 'Journal'];
  
  Map<String, bool> _dailyStatus = {};
  Map<String, int> _totalXP = {};
  String _lastSavedDate = "";

  @override
  void initState() {
    super.initState();
    for (var h in _habits) {
      _dailyStatus[h] = false;
      _totalXP[h] = 0;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    DateTime logicalNow = DateTime.now().subtract(const Duration(hours: 4));
    final String today = logicalNow.toIso8601String().substring(0, 10);

    setState(() {
      _todos = prefs.getStringList('todos') ?? [];
      _todoStates = (prefs.getStringList('todoStates') ?? []).map((e) => e == 'true').toList();
      _lastSavedDate = prefs.getString('lastHabitDate') ?? today;
      
      bool isNewDay = _lastSavedDate != today;

      for (var h in _habits) {
        _totalXP[h] = prefs.getInt('xp_$h') ?? 0;
        if (isNewDay) {
          _dailyStatus[h] = false;
        } else {
          _dailyStatus[h] = prefs.getBool('daily_$h') ?? false;
        }
      }

      if (isNewDay) {
        prefs.setString('lastHabitDate', today);
      }
    });
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('todos', _todos);
    await prefs.setStringList('todoStates', _todoStates.map((e) => e.toString()).toList());
  }

  Future<void> _toggleHabit(String id) async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    bool newStatus = !_dailyStatus[id]!;
    
    setState(() {
      _dailyStatus[id] = newStatus;
      if (newStatus) {
        _totalXP[id] = _totalXP[id]! + 1;
      } else {
        _totalXP[id] = _totalXP[id]! - 1;
      }
    });

    await prefs.setBool('daily_$id', newStatus);
    await prefs.setInt('xp_$id', _totalXP[id]!);
  }

  void _addTodo() {
    if (_todoController.text.isNotEmpty && _todos.length < 5) {
      setState(() {
        _todos.add(_todoController.text);
        _todoStates.add(false);
        _todoController.clear();
      });
      _saveTodos();
    }
  }

  void _deleteTodo(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _todos.removeAt(index);
      _todoStates.removeAt(index);
    });
    _saveTodos();
  }

  // XP'ye göre Unvan Belirleme
  String get _currentTitle {
    String bestHabit = _habits[0];
    int maxXP = 0;
    
    for (var h in _habits) {
      if (_totalXP[h]! > maxXP) {
        maxXP = _totalXP[h]!;
        bestHabit = h;
      }
    }
    
    if (maxXP == 0) return "The Initiate";
    
    switch (bestHabit) {
      case 'Gym': return "The Juggernaut";
      case 'Meditation': return "The Zen Master";
      case 'Reading': return "The Sage";
      case 'Journal': return "The Observer";
      default: return "The Initiate";
    }
  }

  // Kazanma Durumu (Sadece 4 alışkanlık true ise)
  bool get _isDayWon {
    return _dailyStatus.values.every((state) => state == true);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDark ? Colors.white : Colors.black;
    Color boxColor = isDark ? Colors.grey[900]! : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              HapticFeedback.heavyImpact();
              AppTheme.themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
            },
          )
        ],
      ),
      // TAŞMA HATASINI ÇÖZEN SCROLL YAPISI:
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isDayWon) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "YOU WON TODAY.",
                        style: TextStyle(color: isDark ? Colors.black : Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 3),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Now put the phone down.",
                        style: TextStyle(color: isDark ? Colors.grey[800] : Colors.grey[300], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],

              const Text('DAILY FOCUS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _todoController,
                      decoration: InputDecoration(
                        hintText: 'Add a task...',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        hintStyle: TextStyle(color: isDark ? Colors.grey : null),
                      ),
                      onSubmitted: (_) => _addTodo(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _todos.length < 5 ? _addTodo : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: textColor,
                      foregroundColor: boxColor,
                      padding: const EdgeInsets.all(15),
                    ),
                    child: const Icon(Icons.add),
                  )
                ],
              ),
              const SizedBox(height: 10),
              
              // LİSTE TAŞMASINI ÖNLEYEN YAPI:
              ListView.builder(
                shrinkWrap: true, // Listeyi içeriği kadar daralt
                physics: const NeverScrollableScrollPhysics(), // İç içe scroll çatışmasını engelle
                itemCount: _todos.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Checkbox(
                      value: _todoStates[index],
                      activeColor: textColor,
                      checkColor: boxColor,
                      onChanged: (bool? value) {
                        HapticFeedback.selectionClick();
                        setState(() { _todoStates[index] = value!; });
                        _saveTodos();
                      },
                    ),
                    title: Text(
                      _todos[index],
                      style: TextStyle(
                        decoration: _todoStates[index] ? TextDecoration.lineThrough : null,
                        color: _todoStates[index] ? Colors.grey : textColor,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => _deleteTodo(index),
                    ),
                  );
                },
              ),

              const Divider(thickness: 2),
              const SizedBox(height: 10),
              const Text('HABITS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 15),
              
              Wrap(
                spacing: 15,
                runSpacing: 15,
                children: _habits.map((String h) {
                  bool isDone = _dailyStatus[h]!;
                  int currentLevel = _totalXP[h]!;
                  
                  return InkWell(
                    onTap: () => _toggleHabit(h),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: (MediaQuery.of(context).size.width - 55) / 2,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: isDone ? textColor : boxColor,
                        border: Border.all(color: textColor, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            h, // Gym, Reading vs.
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: isDone ? boxColor : textColor,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Lv. $currentLevel",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDone ? boxColor.withOpacity(0.7) : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}