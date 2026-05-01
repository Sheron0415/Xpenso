import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onLogin;
  const LoginPage({super.key, required this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  void login() async {
    final res = await DBHelper.instance.login(userCtrl.text, passCtrl.text);
    if (res != null) {
      widget.onLogin(res);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Login")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.purple),
            const SizedBox(height: 20),
            const Text("Welcome Back", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(controller: userCtrl, decoration: InputDecoration(labelText: "Username", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 15),
            TextField(controller: passCtrl, obscureText: true, decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(onPressed: login, style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("Login")),
            ),
            TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())), child: const Text("Create an Account"))
          ],
        ),
      ),
    );
  }
}
