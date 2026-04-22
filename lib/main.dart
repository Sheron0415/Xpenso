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
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
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

class _DashboardPageState extends State<DashboardPage> {
  List<TransactionModel> transactions = [];

  double income = 0;
  double expense = 0;

  String currency = "LKR";
  int index = 0;

  static const double rate = 300; // 🔥 1 USD = 300 LKR

  @override
  void initState() {
    super.initState();
    load();
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

  double convert(double value) {
    if (currency == "USD") {
      return value / rate;
    }
    return value;
  }

  String format(double value) {
    if (currency == "USD") {
      return "\$${(value / rate).toStringAsFixed(2)}";
    }
    return "Rs. ${value.toStringAsFixed(2)}";
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
      appBar: AppBar(
        title: const Text("Finance Manager"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: load,
          ),

          // 🔥 Currency Switch FIXED
          DropdownButton<String>(
            value: currency,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: "LKR", child: Text("LKR")),
              DropdownMenuItem(value: "USD", child: Text("USD")),
            ],
            onChanged: (v) {
              setState(() => currency = v!);
            },
          ),

          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => openForm(),
        child: const Icon(Icons.add),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: "Stats"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: card("Income", income, Colors.green)),
            const SizedBox(width: 10),
            Expanded(child: card("Expense", expense, Colors.red)),
          ],
        ),
        card("Balance", balance, Colors.blue),

        const SizedBox(height: 10),

        ...transactions.map((t) {
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                t.type == "Income" ? Colors.green : Colors.red,
                child: Text(t.type == "Income" ? "+" : "-"),
              ),
              title: Text(t.title),
              subtitle: Text(
                  "${DateFormat.yMd().format(t.date)} | ${t.category}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(format(t.amount)),

                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => openForm(t),
                  ),

                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => delete(t.id!),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget card(String title, double value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(format(value)),
          ],
        ),
      ),
    );
  }

  // ================= STATS (FIXED + CLEAN) =================

  Widget stats() {
    double total = income + expense;
    double expensePercent = total == 0 ? 0 : expense / total;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            "Expense Breakdown",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // 🔥 PIE FIX (REAL WORKING)
          SizedBox(
            height: 180,
            width: 180,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    height: 180,
                    width: 180,
                    child: CircularProgressIndicator(
                      value: expensePercent,
                      strokeWidth: 18,
                      backgroundColor: Colors.green,
                      color: Colors.red,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    "${(expensePercent * 100).toStringAsFixed(1)}%",
                    style: const TextStyle(fontSize: 18),
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            "Monthly Chart",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              bar("Jan", 80),
              bar("Feb", 120),
              bar("Mar", 60),
              bar("Apr", 150),
              bar("May", 100),
            ],
          ),
        ],
      ),
    );
  }

  Widget bar(String label, double h) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(width: 25, height: h, color: Colors.blue),
        const SizedBox(height: 5),
        Text(label),
      ],
    );
  }

  Widget profile() {
    return const Center(child: Text("Profile"));
  }
}

// ================= ADD / EDIT =================

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

    // ignore: use_build_context_synchronously
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? "Add Transaction" : "Edit Transaction"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: title,
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: category,
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: type,
              items: const [
                DropdownMenuItem(value: "Income", child: Text("Income")),
                DropdownMenuItem(value: "Expense", child: Text("Expense")),
              ],
              onChanged: (v) => setState(() => type = v!),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Type",
              ),
            ),

            const SizedBox(height: 12),

            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.grey),
              ),
              title: Text("Date: ${date.toString().split(" ")[0]}"),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );

                if (picked != null) {
                  setState(() => date = picked);
                }
              },
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: save,
                child: const Text("SAVE"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}