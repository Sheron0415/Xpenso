import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';
import 'transaction_model.dart';

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

  void navigateToAddTransaction() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => AddTransactionPage()));
    fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Personal Finance Manager')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.blue.shade50,
              child: ListTile(
                title: Text('Total Income: \$${totalIncome.toStringAsFixed(2)}'),
                subtitle:
                    Text('Total Expense: \$${totalExpense.toStringAsFixed(2)}'),
                trailing: Text(
                    'Balance: \$${(totalIncome - totalExpense).toStringAsFixed(2)}'),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final t = transactions[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                          child: Text(t.type == 'Income' ? '+' : '-')),
                      title: Text(t.title),
                      subtitle: Text(
                          '${DateFormat.yMd().format(t.date)} | ${t.category}'),
                      trailing: Text('\$${t.amount.toStringAsFixed(2)}'),
                    ),
                  );
                },
              ),
            )
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

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
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
      await DBHelper.instance.insertTransaction(TransactionModel(
        title: title,
        category: category,
        amount: amount,
        type: type,
        date: selectedDate,
      ));
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    v!.isEmpty ? 'Please enter a title' : null,
                onSaved: (v) => title = v!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Category'),
                validator: (v) =>
                    v!.isEmpty ? 'Please enter a category' : null,
                onSaved: (v) => category = v!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v!.isEmpty ? 'Please enter an amount' : null,
                onSaved: (v) => amount = double.parse(v!),
              ),
              DropdownButtonFormField<String>(
                initialValue: type,
                items: ['Income', 'Expense']
                    .map((e) => DropdownMenuItem(
                        value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => type = val!),
                decoration: InputDecoration(labelText: 'Type'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                    'Date: ${DateFormat.yMd().format(selectedDate)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100));
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                  onPressed: saveTransaction, child: Text('Save'))
            ],
          ),
        ),
      ),
    );
  }
}