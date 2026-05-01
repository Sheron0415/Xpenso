import 'package:flutter/material.dart';
import 'db_helper.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  void register() async {
    final res = await DBHelper.instance.register(userCtrl.text, passCtrl.text);
    if (res != -1) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registration Success")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Username already exists")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: userCtrl, decoration: InputDecoration(labelText: "Username", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 15),
            TextField(controller: passCtrl, obscureText: true, decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(onPressed: register, style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("Register")),
            ),
          ],
        ),
      ),
    );
  }
}
