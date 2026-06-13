import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const GoalTrackerApp());
}

class GoalTrackerApp extends StatelessWidget {
  const GoalTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Goal Tracker',
      home: const HomeDashboard(),
    );
  }
}

// --- HOME DASHBOARD SCREEN ---
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  double goalAmount = 68000.0; 
  double currentBalance = 0.0; 
  String userName = "User"; 
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    _loadSavedData(); 
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentBalance = prefs.getDouble('balance') ?? 0.0; 
      userName = prefs.getString('username') ?? "User"; 
      goalAmount = prefs.getDouble('goalAmount') ?? 68000.0; 
      
      String? savedTransactions = prefs.getString('transactions');
      if (savedTransactions != null) {
        List<dynamic> decodedList = jsonDecode(savedTransactions);
        transactions = decodedList.map((item) => {
          "icon": IconData(item["iconCode"], fontFamily: 'MaterialIcons'),
          "title": item["title"],
          "subtitle": item["subtitle"],
          "amount": item["amount"],
        }).toList();
      } else {
        transactions = [];
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('balance', currentBalance);
    
    List<Map<String, dynamic>> savableList = transactions.map((tx) => {
      "iconCode": tx["icon"].codePoint,
      "title": tx["title"],
      "subtitle": tx["subtitle"],
      "amount": tx["amount"],
    }).toList();
    
    await prefs.setString('transactions', jsonEncode(savableList));
  }

  @override
  Widget build(BuildContext context) {
    double percentageAchieved = goalAmount > 0 ? (currentBalance / goalAmount) : 0.0;
    if (percentageAchieved > 1.0) percentageAchieved = 1.0; 
    int displayPercentage = (percentageAchieved * 100).toInt();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView( 
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Bar Area with App In-UI Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // App Logo inside the UI
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.track_changes, color: Color(0xFF00E676), size: 28),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Hello, $userName!", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const Text("Your Goal Tracker", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.grey),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                        _loadSavedData(); 
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                
                // Circular Progress Indicator
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 250, height: 250,
                        child: CircularProgressIndicator(
                          value: percentageAchieved, 
                          strokeWidth: 15,
                          color: const Color(0xFF00E676),
                          backgroundColor: const Color(0xFF1E1E1E),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        children: [
                          Text("₹${goalAmount.toInt()}", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("$displayPercentage% Achieved", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                // Feed Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("Transaction & Activity Feed", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Icon(Icons.filter_alt_outlined, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Current Balance Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF333333), width: 1),
                  ),
                  child: Text(
                    "Current Balance: ₹${currentBalance.toInt()}", 
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Transactions List
                if (transactions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    alignment: Alignment.center,
                    child: Column(
                      children: const [
                        Icon(Icons.receipt_long, color: Colors.grey, size: 50),
                        SizedBox(height: 16),
                        Text(
                          "No income added yet.\nTap '+' to add your first income!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 14, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  )
                else
                  ...transactions.asMap().entries.map((entry) {
                    int index = entry.key;
                    var tx = entry.value;

                    return Dismissible(
                      key: UniqueKey(), 
                      direction: DismissDirection.endToStart, 
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        setState(() {
                          currentBalance -= tx["amount"]; 
                          transactions.removeAt(index); 
                        });
                        _saveData(); 
                      },
                      child: TransactionTile(
                        icon: tx["icon"],
                        title: tx["title"],
                        subtitle: tx["subtitle"],
                        amount: "+₹${tx["amount"].toInt()}",
                      ),
                    );
                  }),
                
                const SizedBox(height: 100), // Extra space at bottom so list isn't hidden by FAB
              ],
            ),
          ),
        ),
      ),
      
      // Floating Add Button (Bigger Size)
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: FloatingActionButton(
          onPressed: () async {
            final newIncomeData = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddIncomeScreen()),
            );

            if (newIncomeData != null) {
              setState(() {
                double addedAmount = newIncomeData['amount'];
                currentBalance += addedAmount; 
                
                transactions.insert(0, {
                  "icon": Icons.attach_money,
                  "title": newIncomeData['source'],
                  "subtitle": "Just Now",
                  "amount": addedAmount
                });
              });
              _saveData(); 
            }
          },
          backgroundColor: const Color(0xFF00E676),
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.black, size: 40),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// --- REUSABLE TRANSACTION TILE WIDGET ---
class TransactionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;

  const TransactionTile({super.key, required this.icon, required this.title, required this.subtitle, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: const Color(0xFF1E1E1E), radius: 20, child: Icon(icon, color: Colors.grey, size: 20)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          Text(amount, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --- ADD INCOME SCREEN ---
class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text("Add New Income", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 24),
              TextField(
                controller: _amountController, 
                style: const TextStyle(color: Colors.white), 
                keyboardType: TextInputType.number, 
                decoration: InputDecoration(
                  filled: true, 
                  fillColor: const Color(0xFF1E1E1E), 
                  hintText: "Amount (e.g., 2000)", 
                  hintStyle: const TextStyle(color: Colors.grey), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF333333))), 
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00E676)))
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _sourceController, 
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true, 
                  fillColor: const Color(0xFF1E1E1E), 
                  hintText: "Source (e.g., UI Project)", 
                  hintStyle: const TextStyle(color: Colors.grey), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF333333))), 
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00E676)))
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    double? parsedAmount = double.tryParse(_amountController.text);
                    String sourceText = _sourceController.text.trim();

                    if (parsedAmount == null || parsedAmount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Invalid input! Please enter a valid number for the amount."),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return; 
                    }
                    
                    if (sourceText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter the source of income."),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return; 
                    }

                    Navigator.pop(context, {'amount': parsedAmount, 'source': sourceText});
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("Save Income", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30), // PERFECT BREATHING SPACE
            ],
          ),
        ),
      ),
    );
  }
}

// --- SETTINGS SCREEN ---
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _goalController = TextEditingController(); 

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('username') ?? "User";
      _goalController.text = (prefs.getDouble('goalAmount') ?? 68000.0).toString();
    });
  }

  Future<void> _saveSettings() async {
    String newName = _nameController.text.trim();
    double? newGoal = double.tryParse(_goalController.text);

    if (newName.isEmpty || newGoal == null || newGoal <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter valid name and goal amount!"),
            backgroundColor: Colors.redAccent,
          ),
       );
       return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newName);
    await prefs.setDouble('goalAmount', newGoal);
    
    if (mounted) {
      Navigator.pop(context); 
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text("Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text("Edit Profile Name", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  hintText: "Enter your name",
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF333333))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00E676))),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Monthly Goal (₹)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _goalController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  hintText: "Enter your goal amount",
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF333333))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00E676))),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("Save Settings", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30), // PERFECT BREATHING SPACE
            ],
          ),
        ),
      ),
    );
  }
}