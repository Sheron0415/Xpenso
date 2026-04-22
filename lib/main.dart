import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';
import 'transaction_model.dart';

void main() {
  runApp(const MyApp());
}

// ================= APP =================

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDark = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: DashboardPage(
        onToggleTheme: () {
          setState(() {
            isDark = !isDark;
          });
        },
      ),
    );
  }
}

// ================= DASHBOARD =================

class DashboardPage extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const DashboardPage({super.key, required this.onToggleTheme});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  List<TransactionModel> transactions = [];

  double income = 0;
  double expense = 0;

  String currency = "LKR";
  int index = 0;

  static const double rate = 300;

  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    load();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> load() async {
    transactions = await DBHelper.instance.getTransactions();

    income = transactions
        .where((e) => e.type == "Income")
        .fold(0, (a, b) => a + b.amount);

    expense = transactions
        .where((e) => e.type == "Expense")
        .fold(0, (a, b) => a + b.amount);

    setState(() {});
  }

  String format(double value) {
    return currency == "USD"
        ? "\$${(value / rate).toStringAsFixed(2)}"
        : "Rs. ${value.toStringAsFixed(2)}";
  }

  void delete(int id) async {
    await DBHelper.instance.deleteTransaction(id);
    load();
  }

  void openForm([TransactionModel? t]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPage(transaction: t),
      ),
    );
    load();
  }

  @override
  Widget build(BuildContext context) {
    double balance = income - expense;

    return Scaffold(
      backgroundColor: const Color(0xff0F172A),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Finance Manager"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: load),

          DropdownButton<String>(
            value: currency,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: "LKR", child: Text("LKR")),
              DropdownMenuItem(value: "USD", child: Text("USD")),
            ],
            onChanged: (v) => setState(() => currency = v!),
          ),

          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        onPressed: () => openForm(),
        child: const Icon(Icons.add),
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xff0F172A),
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: load,
        child: index == 0
            ? home(balance)
            : index == 1
            ? stats()
            : profile(),
      ),
    );
  }

  // ================= HOME =================

  Widget home(double balance) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            return Transform.scale(
              scale: controller.value,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.blue],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Balance",
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 10),
                    Text(format(balance),
                        style: const TextStyle(
                            fontSize: 26,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(child: modernCard("Income", income, Colors.green)),
            const SizedBox(width: 10),
            Expanded(child: modernCard("Expense", expense, Colors.red)),
          ],
        ),

        const SizedBox(height: 20),

        const Text("Recent Transactions",
            style: TextStyle(color: Colors.white, fontSize: 18)),

        const SizedBox(height: 10),

        ...transactions.map((t) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xff1E293B),
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                t.type == "Income" ? Colors.green : Colors.red,
                child: Icon(
                  t.type == "Income"
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                ),
              ),
              title:
              Text(t.title, style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                  "${DateFormat.yMd().format(t.date)} • ${t.category}",
                  style: const TextStyle(color: Colors.white54)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(format(t.amount),
                      style: TextStyle(
                          color: t.type == "Income"
                              ? Colors.green
                              : Colors.red)),
                  IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => openForm(t)),
                  IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => delete(t.id!)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget modernCard(String title, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color)),
          const SizedBox(height: 8),
          Text(format(value),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ================= STATS =================

  Widget stats() {
    double total = income + expense;
    double percent = total == 0 ? 0 : expense / total;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Expense Ratio",
              style: TextStyle(color: Colors.white, fontSize: 20)),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            width: 180,
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 20,
              backgroundColor: Colors.green,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 10),
          Text("${(percent * 100).toStringAsFixed(1)}%",
              style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget profile() {
    return const Center(
        child: Text("Profile", style: TextStyle(color: Colors.white)));
  }
}

// ================= ADD PAGE =================

class AddPage extends StatefulWidget {
  final TransactionModel? transaction;

  const AddPage({super.key, this.transaction});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final title = TextEditingController();
  final category = TextEditingController();
  final amount = TextEditingController();

  String type = "Expense";
  DateTime date = DateTime.now();

  @override
  void initState() {
    super.initState();

    if (widget.transaction != null) {
      title.text = widget.transaction!.title;
      category.text = widget.transaction!.category;
      amount.text = widget.transaction!.amount.toString();
      type = widget.transaction!.type;
      date = widget.transaction!.date;
    }
  }

  void save() async {
    final data = TransactionModel(
      id: widget.transaction?.id,
      title: title.text,
      category: category.text,
      amount: double.tryParse(amount.text) ?? 0,
      type: type,
      date: date,
    );

    if (widget.transaction == null) {
      await DBHelper.instance.insertTransaction(data);
    } else {
      await DBHelper.instance.updateTransaction(data);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Transaction")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: category, decoration: const InputDecoration(labelText: "Category")),
            TextField(controller: amount, keyboardType: TextInputType.number),

            DropdownButtonFormField(
              value: type,
              items: const [
                DropdownMenuItem(value: "Income", child: Text("Income")),
                DropdownMenuItem(value: "Expense", child: Text("Expense")),
              ],
              onChanged: (v) => setState(() => type = v!),
            ),

            ListTile(
              title: Text(DateFormat.yMd().format(date)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => date = picked);
              },
            ),

            ElevatedButton(onPressed: save, child: const Text("Save")),
          ],
        ),
      ),
    );
  }
}