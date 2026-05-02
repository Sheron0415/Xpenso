import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';
import 'transaction_model.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<TransactionModel> transactions = [];

  double totalIncome = 0;
  double totalExpense = 0;

  String selectedCurrency = 'LKR';

class _MyAppState extends State<MyApp> {
  bool isDark = true;
  Map<String, dynamic>? user;
  bool isLoading = true;
  bool showSplash = true;


  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  void loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        isDark = prefs.getBool('isDark') ?? true;
        isLoading = false;
      });
    }
    
    // Show splash for 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => showSplash = false);
    });
  }

  void toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => isDark = !isDark);
    await prefs.setBool('isDark', isDark);
  }

  @override
  Widget build(BuildContext context) {
    double balance = totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: Text('Finance Manager'),
        actions: [
          DropdownButton<String>(
            value: selectedCurrency,
            dropdownColor: Colors.blue,
            icon: Icon(Icons.arrow_drop_down, color: Colors.white),
            underline: SizedBox(),
            items: ['LKR', 'USD'].map((value) {
              return DropdownMenuItem(
                value: value,
                child: Text(value, style: TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCurrency = value!;
              });
            },
          ),
        ],
      ),

      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔥 Dashboard Card
            Card(
              elevation: 5,
              child: ListTile(
                title: Text(
                    'Income: ${formatCurrency(convertAmount(totalIncome))}'),
                subtitle: Text(
                    'Expense: ${formatCurrency(convertAmount(totalExpense))}'),
                trailing: Text(
                  'Balance: ${formatCurrency(convertAmount(balance))}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            SizedBox(height: 20),

            // 🔥 Transaction List
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final t = transactions[index];

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                        t.type == 'Income' ? Colors.green : Colors.red,
                        child: Text(
                          t.type == 'Income' ? '+' : '-',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(t.title),
                      subtitle: Text(
                          '${DateFormat.yMd().format(t.date)} | ${t.category}'),
                      trailing: Text(
                        formatCurrency(convertAmount(t.amount)),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: navigateToAddTransaction,
        child: Icon(Icons.add),
      ),
    );
  }
}

// ================= ADD TRANSACTION PAGE =================

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  String title = '';
  String category = '';
  double amount = 0;
  String type = 'Expense';
  DateTime selectedDate = DateTime.now();

  void saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      await DBHelper.instance.insertTransaction(
        TransactionModel(
          title: title,
          category: category,
          amount: amount,
          type: type,
          date: selectedDate,
        ),
      );

      Navigator.pop(context);
    if (isLoading) {
      return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }

    Widget homeWidget;
    if (showSplash) {
      homeWidget = const SplashScreen(nextScreen: SizedBox());
    } else if (user == null) {
      homeWidget = LoginPage(onLogin: (u) => setState(() => user = u));
    } else {
      homeWidget = DashboardPage(
        user: user!,
        isDark: isDark,
        onToggleTheme: toggleTheme,
        onLogout: () => setState(() => user = null),
        onUserUpdate: (updatedUser) => setState(() => user = updatedUser),
      );
    }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Transaction')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Title'),
                validator: (v) => v!.isEmpty ? 'Enter title' : null,
                onSaved: (v) => title = v!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Category'),
                validator: (v) => v!.isEmpty ? 'Enter category' : null,
                onSaved: (v) => category = v!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Enter amount' : null,
                onSaved: (v) => amount = double.parse(v!),
              ),
              DropdownButtonFormField(
                initialValue: type,
                items: ['Income', 'Expense']
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ))
                    .toList(),
                onChanged: (val) => setState(() => type = val as String),
                decoration: InputDecoration(labelText: 'Type'),
              ),
              ListTile(
                title: Text(
                    'Date: ${DateFormat.yMd().format(selectedDate)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );

                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveTransaction,
                child: Text('Save'),
              ),
            ],
          ),
        ),

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[100],
        cardColor: Colors.white,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff0F172A),
        cardColor: const Color(0xff1E293B),
        useMaterial3: true,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: homeWidget,
    );
  }
}