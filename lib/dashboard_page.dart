import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'db_helper.dart';
import 'transaction_model.dart';
import 'add_page.dart';
import 'pdf_service.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;
  final Function(Map<String, dynamic>) onUserUpdate;

  const DashboardPage({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
    required this.user,
    required this.onLogout,
    required this.onUserUpdate,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<TransactionModel> transactions = [];
  List<TransactionModel> filteredTransactions = [];
  List<double> dailyExpenses = List.filled(7, 0.0);
  List<String> dayLabels = [];
  List<Map<String, dynamic>> budgets = [];

  double income = 0, expense = 0, lastMonthExpense = 0;
  String currency = "LKR", searchQuery = "";
  int index = 0;
  DateTime selectedMonth = DateTime.now();

  static const double rate = 300;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    transactions = await DBHelper.instance.getTransactions(widget.user['id']);
    budgets = await DBHelper.instance.getBudgets(widget.user['id']);
    _filterByMonth();

    DateTime firstDayLastMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    DateTime firstDayThisMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);

    lastMonthExpense = transactions
        .where((t) => t.type == "Expense" && t.date.isAfter(firstDayLastMonth.subtract(const Duration(seconds: 1))) && t.date.isBefore(firstDayThisMonth))
        .fold(0, (a, b) => a + b.amount);

    dailyExpenses = List.filled(7, 0.0);
    dayLabels = [];
    DateTime now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      DateTime day = now.subtract(Duration(days: i));
      dayLabels.add(DateFormat('E').format(day));
      double dayTotal = transactions
          .where((t) => t.type == "Expense" && t.date.day == day.day && t.date.month == day.month && t.date.year == day.year)
          .fold(0, (a, b) => a + b.amount);
      dailyExpenses[6 - i] = dayTotal;
    }
    if (mounted) setState(() {});
  }

  void _filterByMonth() {
    filteredTransactions = transactions.where((t) => t.date.month == selectedMonth.month && t.date.year == selectedMonth.year).toList();
    income = filteredTransactions.where((e) => e.type == "Income").fold(0, (a, b) => a + b.amount);
    expense = filteredTransactions.where((e) => e.type == "Expense").fold(0, (a, b) => a + b.amount);
    _filterTransactions();
  }

  void _filterTransactions() {
    setState(() {
      filteredTransactions = transactions
          .where((t) => (t.date.month == selectedMonth.month && t.date.year == selectedMonth.year) &&
              (t.title.toLowerCase().contains(searchQuery.toLowerCase()) || t.category.toLowerCase().contains(searchQuery.toLowerCase())))
          .toList();
    });
  }

  String format(double value) => currency == "USD" ? "\$${(value / rate).toStringAsFixed(2)}" : "LKR ${NumberFormat('#,###.00').format(value)}";

  void delete(int id) async {
    await DBHelper.instance.deleteTransaction(id);
    load();
  }

  void openForm([TransactionModel? t]) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AddPage(transaction: t, userId: widget.user['id'])));
    load();
  }

  void showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: widget.user['username']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text("Edit Username", style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87)),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "New Name"), style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () async {
            if (nameCtrl.text.isNotEmpty) {
              await DBHelper.instance.updateUsername(widget.user['id'], nameCtrl.text);
              final updatedUser = await DBHelper.instance.getUserById(widget.user['id']);
              if (updatedUser != null && mounted) {
                widget.onUserUpdate(updatedUser);
              }
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name Updated!")));
            }
          }, child: const Text("Update")),
        ],
      ),
    );
  }

  void showChangePasswordDialog() {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text("Change Password", style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87)),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: "New Password"),
          style: TextStyle(color: widget.isDark ? Colors.white : Colors.black),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (passCtrl.text.isNotEmpty) {
                await DBHelper.instance.updatePassword(widget.user['id'], passCtrl.text);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password Updated Successfully")));
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void showSetBudgetDialog() {
    final amountCtrl = TextEditingController();
    String category = "Food & Drinks";
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Text("Set Monthly Budget", style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: category, isExpanded: true, dropdownColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
                items: ["Food & Drinks", "Salary", "Transport", "Shopping", "Home & Bills", "Entertainment", "Health", "Other"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87)))).toList(),
                onChanged: (v) => setDialogState(() => category = v!),
              ),
              const SizedBox(height: 10),
              TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Limit Amount"), style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (amountCtrl.text.isNotEmpty) {
                  await DBHelper.instance.setBudget(widget.user['id'], category, double.parse(amountCtrl.text));
                  if (!mounted) return;
                  Navigator.pop(context);
                  load();
                }
              },
              child: const Text("Set"),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    category = category.toLowerCase();
    if (category.contains('food')) return Icons.restaurant_rounded;
    if (category.contains('salary')) return Icons.payments_rounded;
    if (category.contains('transport')) return Icons.directions_car_rounded;
    if (category.contains('home')) return Icons.home_work_rounded;
    if (category.contains('shopping')) return Icons.shopping_bag_rounded;
    if (category.contains('entertainment')) return Icons.movie_rounded;
    if (category.contains('health')) return Icons.medical_services_rounded;
    return Icons.category_rounded;
  }

  Color _getCategoryColor(String category) {
    category = category.toLowerCase();
    if (category.contains('food')) return Colors.orangeAccent;
    if (category.contains('salary')) return Colors.greenAccent;
    if (category.contains('transport')) return Colors.blueAccent;
    if (category.contains('home')) return Colors.purpleAccent;
    if (category.contains('shopping')) return Colors.pinkAccent;
    if (category.contains('entertainment')) return Colors.redAccent;
    return Colors.tealAccent;
  }

  @override
  Widget build(BuildContext context) {
    double balance = income - expense;
    Color bgColor = widget.isDark ? const Color(0xFF0B0E1B) : Colors.grey[100]!;
    Color textColor = widget.isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, toolbarHeight: 80,
        title: Text("Xpenso", style: TextStyle(color: textColor, fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        actions: [
          DropdownButton<String>(
            value: currency, dropdownColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white, underline: const SizedBox(),
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            items: const [DropdownMenuItem(value: "LKR", child: Text("LKR")), DropdownMenuItem(value: "USD", child: Text("USD"))],
            onChanged: (v) => setState(() => currency = v!),
          ),
          IconButton(icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode, color: textColor), onPressed: widget.onToggleTheme),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6366F1), shape: const CircleBorder(),
        onPressed: () => openForm(), child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: widget.isDark ? const Color(0xFF151929) : Colors.white, shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(height: 60, child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _bottomNavItem(Icons.home_filled, "Dashboard", 0), _bottomNavItem(Icons.list_alt_rounded, "History", 10),
          const SizedBox(width: 40), _bottomNavItem(Icons.pie_chart_outline_rounded, "Budget", 1), _bottomNavItem(Icons.person_outline_rounded, "Profile", 2),
        ])),
      ),
      body: _getBody(balance),
    );
  }

  Widget _getBody(double balance) {
    switch (index) {
      case 0: return home(balance);
      case 10: return transactionsPage();
      case 1: return stats();
      case 2: return profile();
      default: return home(balance);
    }
  }

  Widget _bottomNavItem(IconData icon, String label, int i) {
    bool isSelected = index == i;
    return GestureDetector(onTap: () => setState(() => index = i), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: isSelected ? const Color(0xFF6366F1) : Colors.grey, size: 26),
      const SizedBox(height: 4), Text(label, style: TextStyle(color: isSelected ? const Color(0xFF6366F1) : Colors.grey, fontSize: 10)),
    ]));
  }

  Widget home(double balance) {
    Color textColor = widget.isDark ? Colors.white : Colors.black87;
    String formattedBalance = format(balance);
    String mainPart = formattedBalance.split('.')[0], decimalPart = formattedBalance.contains('.') ? formattedBalance.split('.')[1] : "00";

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Hello, ${widget.user['username']} 👋", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor), overflow: TextOverflow.ellipsis),
              const Text("Welcome back", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () async {
              final DateTime? picked = await showDatePicker(context: context, initialDate: selectedMonth, firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (picked != null) { setState(() => selectedMonth = picked); _filterByMonth(); }
            },
            icon: const Icon(Icons.calendar_month_rounded, size: 16), 
            label: Text(DateFormat('MMM yyyy').format(selectedMonth), style: const TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          )
        ]),
        const SizedBox(height: 25),
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Stack(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Text("Total Balance", style: TextStyle(color: Colors.white70, fontSize: 16)), const SizedBox(width: 8), const Icon(Icons.visibility_outlined, color: Colors.white70, size: 18), const Spacer(), const Icon(Icons.more_vert, color: Colors.white)]),
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text(mainPart, style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                Text(".$decimalPart", style: const TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 20),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 14), SizedBox(width: 4), Text("12.5%", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)), Text(" from last month", style: TextStyle(color: Colors.white70, fontSize: 11))])),
            ]),
            Positioned(right: -5, bottom: 5, child: Opacity(opacity: 0.9, child: Icon(Icons.account_balance_wallet_rounded, size: 90, color: Colors.white.withValues(alpha: 0.2)))),
          ]),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: miniStatCard("Income", income, Colors.greenAccent, Icons.arrow_circle_down_rounded)), const SizedBox(width: 15),
          Expanded(child: miniStatCard("Expense", expense, Colors.redAccent, Icons.arrow_circle_up_rounded)),
        ]),
        const SizedBox(height: 25),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("Recent Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          TextButton(onPressed: () => setState(() => index = 10), child: const Text("See All", style: TextStyle(color: Color(0xFF6366F1)))),
        ]),
        ...filteredTransactions.take(5).map((t) => transactionItem(t)),
        const SizedBox(height: 100),
      ]),
    );
  }

  Widget miniStatCard(String title, double amount, Color color, IconData icon) {
    Color cardColor = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    return Container(
      padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: widget.isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: color, size: 24), const SizedBox(width: 8), Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14))]),
        const SizedBox(height: 12),
        Text(format(amount), style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        SizedBox(height: 40, child: LineChart(LineChartData(gridData: const FlGridData(show: false), titlesData: const FlTitlesData(show: false), borderData: FlBorderData(show: false), lineBarsData: [LineChartBarData(spots: const [FlSpot(0, 1), FlSpot(1, 1.5), FlSpot(2, 1.2), FlSpot(3, 2.3), FlSpot(4, 1.8), FlSpot(5, 2.1)], isCurved: true, color: color, barWidth: 2, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.1)))]))),
      ]),
    );
  }

  Widget transactionsPage() {
    Color textColor = widget.isDark ? Colors.white : Colors.black87;
    return RefreshIndicator(
      onRefresh: load,
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(20), child: Row(children: [
          Expanded(child: TextField(onChanged: (v) { searchQuery = v; _filterTransactions(); }, style: TextStyle(color: textColor), decoration: InputDecoration(hintText: "Search transactions...", prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1)), filled: true, fillColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)))),
          const SizedBox(width: 10), IconButton(onPressed: () => PdfService.generateReport(filteredTransactions, widget.user['username']), icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 30)),
        ])),
        Expanded(
          child: ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
            Text("Results for ${DateFormat('MMMM yyyy').format(selectedMonth)}", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (filteredTransactions.isEmpty) const Center(child: Padding(padding: EdgeInsets.only(top: 50.0), child: Text("No transactions found", style: TextStyle(color: Colors.grey))))
            else ...filteredTransactions.map((t) => transactionItem(t)),
            const SizedBox(height: 100),
          ]),
        ),
      ]),
    );
  }

  Widget transactionItem(TransactionModel t) {
    bool isIncome = t.type == "Income";
    Color iconColor = isIncome ? Colors.greenAccent : Colors.orangeAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: widget.isDark ? const Color(0xFF151929) : Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: widget.isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(_getCategoryIcon(t.category), color: iconColor, size: 24)),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t.title, style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white : Colors.black87, fontSize: 15)), const SizedBox(height: 4), Text("${DateFormat('MMM dd').format(t.date)} • ${t.category}", style: const TextStyle(color: Colors.grey, fontSize: 12))])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text("${isIncome ? '+' : '-'} ${format(t.amount)}", style: TextStyle(color: isIncome ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15)),
          Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.edit_note_rounded, size: 20, color: Colors.grey), onPressed: () => openForm(t)), IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent), onPressed: () => delete(t.id!))])
        ]),
      ]),
    );
  }

  Widget stats() {
    Map<String, double> catSpent = {};
    for (var t in filteredTransactions.where((t) => t.type == "Expense")) { catSpent[t.category] = (catSpent[t.category] ?? 0) + t.amount; }
    double currentMonthExpense = filteredTransactions.where((t) => t.type == "Expense").fold(0, (a, b) => a + b.amount);
    double diff = currentMonthExpense - lastMonthExpense;
    double diffP = lastMonthExpense == 0 ? 0 : (diff / lastMonthExpense) * 100;
    Color cardColor = widget.isDark ? const Color(0xFF1E293B) : Colors.white, textColor = widget.isDark ? Colors.white : Colors.black87;

    return RefreshIndicator(
      onRefresh: load,
      child: SingleChildScrollView(padding: const EdgeInsets.all(20), physics: const AlwaysScrollableScrollPhysics(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Budget Overview", style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)), ElevatedButton.icon(onPressed: showSetBudgetDialog, icon: const Icon(Icons.add_task_rounded, size: 18), label: const Text("Set Budget"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white))]),
        const SizedBox(height: 15),
        Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)), child: Row(children: [Icon(diff >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: diff >= 0 ? Colors.redAccent : Colors.greenAccent), const SizedBox(width: 10), Text("${diffP.abs().toStringAsFixed(1)}% ${diff >= 0 ? 'more' : 'less'} than last month", style: TextStyle(color: textColor, fontWeight: FontWeight.w500))])),
        const SizedBox(height: 25),
        if (catSpent.isNotEmpty) ...[
          Text("Spending by Category", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 15),
          Container(height: 200, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)), child: PieChart(PieChartData(sections: catSpent.entries.map((e) => PieChartSectionData(value: e.value, color: _getCategoryColor(e.key), title: "${expense == 0 ? 0 : (e.value/expense*100).toStringAsFixed(0)}%", radius: 50, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))).toList(), centerSpaceRadius: 40))),
          const SizedBox(height: 25),
        ],
        if (budgets.isNotEmpty) ...[
          Text("Active Budgets", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 15),
          ...budgets.map((b) {
            double spent = filteredTransactions.where((t) => t.type == "Expense" && t.category == b['category']).fold(0, (a, b) => a + b.amount);
            double p = b['limitAmount'] == 0 ? 0 : spent / b['limitAmount'];
            return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15)), child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(b['category'], style: TextStyle(color: textColor, fontWeight: FontWeight.bold)), Row(children: [Text("${format(spent)} / ${format(b['limitAmount'])}", style: const TextStyle(color: Colors.grey, fontSize: 11)), IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), onPressed: () async { await DBHelper.instance.deleteBudget(b['id']); load(); })])]),
              LinearProgressIndicator(value: p > 1 ? 1 : p, color: p > 0.8 ? Colors.redAccent : Colors.greenAccent, backgroundColor: Colors.grey.withValues(alpha: 0.1), minHeight: 8, borderRadius: BorderRadius.circular(10)),
            ]));
          }),
        ],
        const SizedBox(height: 25),
        Container(
          height: 300, padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: widget.isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Weekly Expenses", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            Expanded(child: BarChart(BarChartData(
              maxY: dailyExpenses.reduce((a, b) => a > b ? a : b) == 0 ? 1000 : dailyExpenses.reduce((a, b) => a > b ? a : b) * 1.2,
              barGroups: List.generate(7, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: dailyExpenses[i], color: const Color(0xFF6366F1), width: 15, borderRadius: BorderRadius.circular(4))])),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45, getTitlesWidget: (v, m) => Text(v >= 1000 ? '${(v/1000).toInt()}k' : v.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10)))),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => v.toInt() >= 0 && v.toInt() < dayLabels.length ? Text(dayLabels[v.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)) : const SizedBox())),
                topTitles: const AxisTitles(), rightTitles: const AxisTitles(),
              ),
              gridData: const FlGridData(show: false), borderData: FlBorderData(show: false),
            ))),
          ]),
        ),
        const SizedBox(height: 100),
      ])),
    );
  }

  Widget profile() {
    Color cardColor = widget.isDark ? const Color(0xFF1E293B) : Colors.white, textColor = widget.isDark ? Colors.white : Colors.black87;
    return RefreshIndicator(
      onRefresh: load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          Container(padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(25), boxShadow: widget.isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]), child: Row(children: [
            const CircleAvatar(radius: 40, backgroundColor: Color(0xFF6366F1), child: Icon(Icons.person, size: 50, color: Colors.white)), const SizedBox(width: 20),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.user['username'], style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)), const Text("Premium Member", style: TextStyle(color: Colors.grey))])
          ])),
          const SizedBox(height: 20),
          ListTile(onTap: showEditProfileDialog, leading: const Icon(Icons.edit_rounded, color: Colors.orangeAccent), title: Text("Edit Username", style: TextStyle(color: textColor)), tileColor: cardColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: 12),
          ListTile(onTap: showChangePasswordDialog, leading: const Icon(Icons.security, color: Colors.blueAccent), title: Text("Security (Change Password)", style: TextStyle(color: textColor)), tileColor: cardColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: 12),
          ListTile(onTap: widget.onLogout, leading: const Icon(Icons.logout, color: Colors.redAccent), title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)), tileColor: cardColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        ])),
      ),
    );
  }
}
