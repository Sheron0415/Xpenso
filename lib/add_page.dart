import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';
import 'transaction_model.dart';

class AddPage extends StatefulWidget {
  final TransactionModel? transaction;
  final int userId;

  const AddPage({super.key, this.transaction, required this.userId});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final title = TextEditingController();
  final amount = TextEditingController();

  String type = "Expense";
  String selectedCategory = "Food & Drinks";
  DateTime date = DateTime.now();

  final List<Map<String, dynamic>> categories = [
    {"name": "Food & Drinks", "icon": Icons.restaurant_rounded},
    {"name": "Salary", "icon": Icons.payments_rounded},
    {"name": "Transport", "icon": Icons.directions_car_rounded},
    {"name": "Shopping", "icon": Icons.shopping_bag_rounded},
    {"name": "Home & Bills", "icon": Icons.home_work_rounded},
    {"name": "Entertainment", "icon": Icons.movie_rounded},
    {"name": "Health", "icon": Icons.medical_services_rounded},
    {"name": "Other", "icon": Icons.category_rounded},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      title.text = widget.transaction!.title;
      amount.text = widget.transaction!.amount.toString();
      type = widget.transaction!.type;
      date = widget.transaction!.date;
      selectedCategory = widget.transaction!.category;
    }
  }

  void save() async {
    if (title.text.isEmpty || amount.text.isEmpty) return;
    double amountVal = double.tryParse(amount.text) ?? 0;

    // Check Budget Limit
    if (type == "Expense") {
      final budgets = await DBHelper.instance.getBudgets(widget.userId);
      final budget = budgets.firstWhere((b) => b['category'] == selectedCategory, orElse: () => {});
      
      if (budget.isNotEmpty) {
        final transactions = await DBHelper.instance.getTransactions(widget.userId);
        double spent = transactions
            .where((t) => t.type == "Expense" && t.category == selectedCategory)
            .fold(0, (a, b) => a + b.amount);

        // If editing, subtract the old amount first
        if (widget.transaction != null && widget.transaction!.category == selectedCategory) {
          spent -= widget.transaction!.amount;
        }

        if (spent + amountVal > budget['limitAmount']) {
          bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: const Text("Budget Exceeded!", style: TextStyle(color: Colors.redAccent)),
              content: Text("Adding this will exceed your ${budget['category']} budget limit. Do you want to continue?"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, Save")),
              ],
            ),
          ) ?? false;
          if (!confirm) return;
        }
      }
    }

    final data = TransactionModel(
      id: widget.transaction?.id,
      title: title.text,
      category: selectedCategory,
      amount: amountVal,
      type: type,
      date: date,
    );

    if (widget.transaction == null) {
      await DBHelper.instance.insertTransaction(data, widget.userId);
    } else {
      await DBHelper.instance.updateTransaction(data);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0B0E1B) : Colors.grey[100]!;
    final Color cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.transaction == null ? "Add Transaction" : "Edit Transaction", 
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(title, "Title", Icons.edit_note_rounded),
                  const SizedBox(height: 20),
                  _buildTextField(amount, "Amount", Icons.attach_money_rounded, isNumber: true),
                  const SizedBox(height: 20),
                  const Text("Type", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(children: [_typeButton("Income", Colors.greenAccent), const SizedBox(width: 15), _typeButton("Expense", Colors.redAccent)]),
                  const SizedBox(height: 20),
                  const Text("Category", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 10),
                  _categoryDropdown(cardColor, textColor),
                  const SizedBox(height: 20),
                  _datePicker(cardColor, textColor),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _saveButton(),
          ],
        ),
      ),
    );
  }

  Widget _typeButton(String t, Color color) {
    bool isSelected = type == t;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => type = t),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : Colors.grey.withOpacity(0.2)),
          ),
          child: Center(child: Text(t, style: TextStyle(color: isSelected ? color : Colors.grey, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  Widget _categoryDropdown(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.withOpacity(0.2))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCategory, isExpanded: true, dropdownColor: cardColor,
          items: categories.map((cat) => DropdownMenuItem<String>(
            value: cat['name'],
            child: Row(children: [Icon(cat['icon'], color: const Color(0xFF6366F1)), const SizedBox(width: 15), Text(cat['name'], style: TextStyle(color: textColor))]),
          )).toList(),
          onChanged: (v) => setState(() => selectedCategory = v!),
        ),
      ),
    );
  }

  Widget _datePicker(Color cardColor, Color textColor) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2100));
        if (picked != null) setState(() => date = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.withOpacity(0.2)), color: Colors.white.withOpacity(0.02)),
        child: Row(children: [const Icon(Icons.calendar_today_rounded, color: Color(0xFF6366F1), size: 22), const SizedBox(width: 15), Text(DateFormat('MMM dd, yyyy').format(date), style: TextStyle(color: textColor, fontSize: 16)), const Spacer(), const Icon(Icons.edit_calendar_rounded, color: Colors.grey, size: 20)]),
      ),
    );
  }

  Widget _saveButton() {
    return Container(
      width: double.infinity, height: 55,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]), boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]),
      child: ElevatedButton(onPressed: save, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("SAVE TRANSACTION", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1))),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
        filled: true, fillColor: Colors.white.withOpacity(0.02),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
      ),
    );
  }
}
