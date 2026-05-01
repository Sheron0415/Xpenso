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
      await DBHelper.instance.insertTransaction(data, widget.userId);
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
