import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'db_helper.dart';
import 'transaction_model.dart';
import 'add_page.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;

  const DashboardPage({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
    required this.user,
    required this.onLogout,
  });

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
    transactions = await DBHelper.instance.getTransactions(widget.user['id']);

    income = transactions
        .where((e) => e.type == "Income")
        .fold(0, (a, b) => a + b.amount);

    expense = transactions
        .where((e) => e.type == "Expense")
        .fold(0, (a, b) => a + b.amount);

    dailyExpenses = List.filled(7, 0.0);
    dayLabels = [];
    DateTime now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      DateTime day = now.subtract(Duration(days: i));
      dayLabels.add(DateFormat('E').format(day));
      
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
        : "Rs. ${value.toStringAsFixed(0)}";
  }

  void delete(int id) async {
    await DBHelper.instance.deleteTransaction(id);
    load();
  }

  void openForm([TransactionModel? t]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPage(transaction: t, userId: widget.user['id']),
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
                    const Text("Total Balance", style: TextStyle(color: Colors.white70)),
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
    double maxVal = dailyExpenses.isEmpty ? 0 : dailyExpenses.reduce((a, b) => a > b ? a : b);

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
          Container(
            height: 350,
            padding: const EdgeInsets.all(15),
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
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox();
                              return Text(
                                value >= 1000 ? '${(value/1000).toStringAsFixed(1)}k' : value.toStringAsFixed(0),
                                style: const TextStyle(color: Colors.grey, fontSize: 10),
                              );
                            },
                          ),
                        ),
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const CircleAvatar(radius: 35, backgroundColor: Colors.purple, child: Icon(Icons.person, size: 40, color: Colors.white)),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.user['username'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Text("Premium Member", style: TextStyle(color: Colors.grey)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 30),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: widget.onLogout,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            tileColor: Theme.of(context).cardColor,
          )
        ],
      ),
    );
  }
}
