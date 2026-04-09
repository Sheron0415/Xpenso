import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';
import 'transaction_model.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Finance Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<TransactionModel> transactions = [];

  double totalIncome = 0;
  double totalExpense = 0;

  String selectedCurrency = 'LKR';

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    transactions = await DBHelper.instance.getTransactions();

    totalIncome = transactions
        .where((t) => t.type == 'Income')
        .fold(0, (sum, t) => sum + t.amount);

    totalExpense = transactions
        .where((t) => t.type == 'Expense')
        .fold(0, (sum, t) => sum + t.amount);

    setState(() {});
  }

  // 🔥 Currency Conversion
  double convertAmount(double amount) {
    if (selectedCurrency == 'USD') {
      return amount / 300; // approx rate
    }
    return amount;
  }

  // 🔥 Currency Format
  String formatCurrency(double amount) {
    if (selectedCurrency == 'USD') {
      return '\$${amount.toStringAsFixed(2)}';
    } else {
      return 'Rs. ${amount.toStringAsFixed(2)}';
    }
  }

  void navigateToAddTransaction() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddTransactionPage()),
    );
    fetchTransactions();
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
                  'Income: ${formatCurrency(convertAmount(totalIncome))}',
                ),
                subtitle: Text(
                  'Expense: ${formatCurrency(convertAmount(totalExpense))}',
                ),
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
                        backgroundColor: t.type == 'Income'
                            ? Colors.green
                            : Colors.red,
                        child: Text(
                          t.type == 'Income' ? '+' : '-',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(t.title),
                      subtitle: Text(
                        '${DateFormat.yMd().format(t.date)} | ${t.category}',
                      ),
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
  // ignore: library_private_types_in_public_api
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String title = '';
  String category = '';
  double amount = 0;
  String type = 'Expense';
  DateTime selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final parsedAmount = double.tryParse(_amountController.text);
      if (parsedAmount == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Enter a valid amount')));
        return;
      }
      amount = parsedAmount;

      await DBHelper.instance.insertTransaction(
        TransactionModel(
          title: title,
          category: category,
          amount: amount,
          type: type,
          date: selectedDate,
        ),
      );

      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Transaction')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  if (double.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              DropdownButtonFormField(
                initialValue: type,
                items: ['Income', 'Expense']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => type = val as String),
                decoration: InputDecoration(labelText: 'Type'),
              ),
              ListTile(
                title: Text('Date: ${DateFormat.yMd().format(selectedDate)}'),
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
              ElevatedButton(onPressed: saveTransaction, child: Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
