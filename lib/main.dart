import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'db_helper.dart';
import 'transaction_model.dart';

void main() {
  runApp(const MyApp());
}

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
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: Colors.grey[100],
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff0F172A),
        cardColor: const Color(0xff1E293B),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: DashboardPage(
        isDark: isDark,
        onToggleTheme: () {
          setState(() {
            isDark = !isDark;
          });
        },
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const DashboardPage({super.key, required this.onToggleTheme, required this.isDark});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  List<TransactionModel> transactions = [];
  List<double> dailyExpenses = List.filled(7, 0.0);
  List<String> dayLabels = [];

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

    // Calculate last 7 days expenses
    dailyExpenses = List.filled(7, 0.0);
    dayLabels = [];
    DateTime now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      DateTime day = now.subtract(Duration(days: i));
      dayLabels.add(DateFormat('E').format(day)); // Mon, Tue...
      
      double dayTotal = transactions
          .where((t) => 
              t.type == "Expense" && 
              t.date.day == day.day && 
              t.date.month == day.month && 
              t.date.year == day.year)
          .fold(0, (a, b) => a + b.amount);
      
      dailyExpenses[6 - i] = dayTotal;
    }

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Finance Manager"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: load),
          DropdownButton<String>(
            value: currency,
            dropdownColor: Theme.of(context).cardColor,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: "LKR", child: Text("LKR")),
              DropdownMenuItem(value: "USD", child: Text("USD")),
            ],
            onChanged: (v) => setState(() => currency = v!),
          ),
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        onPressed: () => openForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Stats"),
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
        Text("Recent Transactions",
            style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...transactions.map((t) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: widget.isDark ? [] : [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (t.type == "Income" ? Colors.green : Colors.red).withOpacity(0.2),
                child: Icon(
                  t.type == "Income" ? Icons.arrow_downward : Icons.arrow_upward,
                  color: t.type == "Income" ? Colors.green : Colors.red,
                ),
              ),
              title: Text(t.title,
                  style: TextStyle(
                      color: widget.isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600)),
              subtitle: Text(
                  "${DateFormat.yMd().format(t.date)} • ${t.category}",
                  style: const TextStyle(color: Colors.grey)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(format(t.amount),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: t.type == "Income" ? Colors.green : Colors.red)),
                  IconButton(
                      icon: Icon(Icons.edit, size: 20, color: widget.isDark ? Colors.white : Colors.black),
                      onPressed: () => openForm(t)),
                  IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: widget.isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(format(value),
              style: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget stats() {
    double total = income + expense;
    double percent = total == 0 ? 0 : expense / total;
    double maxVal = dailyExpenses.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text("Financial Overview",
              style: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          // Circular Ratio
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text("Expense vs Income", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 170,
                      width: 170,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: income == 0 && expense == 0 ? 1 : income,
                              color: Colors.green,
                              radius: 12,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: expense,
                              color: Colors.red,
                              radius: 12,
                              showTitle: false,
                            ),
                          ],
                          centerSpaceRadius: 60,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("${(percent * 100).toStringAsFixed(1)}%",
                            style: TextStyle(
                                color: widget.isDark ? Colors.white : Colors.black,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                        const Text("Expense", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    indicator("Income", Colors.green),
                    const SizedBox(width: 20),
                    indicator("Expense", Colors.red),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Bar Chart
          Container(
            height: 350,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Weekly Expenses", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      maxY: maxVal == 0 ? 1000 : maxVal * 1.2,
                      barGroups: List.generate(7, (i) {
                        return BarChartGroupData(x: i, barRods: [
                          BarChartRodData(
                            toY: dailyExpenses[i], 
                            color: Colors.purple, 
                            width: 16, 
                            borderRadius: BorderRadius.circular(4),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxVal == 0 ? 1000 : maxVal * 1.2,
                              color: Colors.grey.withOpacity(0.1),
                            ),
                          ),
                        ]);
                      }),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              int idx = value.toInt();
                              if (idx < 0 || idx >= dayLabels.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Text(dayLabels[idx], 
                                  style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget indicator(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget profile() {
    return Center(
        child: Text("Profile Settings",
            style: TextStyle(color: widget.isDark ? Colors.white : Colors.black)));
  }
}

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
    if (title.text.isEmpty || amount.text.isEmpty) return;

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
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.transaction == null ? "Add Transaction" : "Edit Transaction"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark ? [] : [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  _buildTextField(title, "Title", Icons.title),
                  const SizedBox(height: 15),
                  _buildTextField(category, "Category", Icons.category),
                  const SizedBox(height: 15),
                  _buildTextField(amount, "Amount", Icons.attach_money, isNumber: true),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: type,
                    dropdownColor: Theme.of(context).cardColor,
                    decoration: _inputDecoration("Type", Icons.swap_vert),
                    items: ["Income", "Expense"]
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => type = v!),
                  ),
                  const SizedBox(height: 15),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    title: Text("Date: ${DateFormat.yMd().format(date)}",
                        style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                    trailing: const Icon(Icons.calendar_today, color: Colors.purple),
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
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Save Transaction",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.purple),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
    );
  }
}
