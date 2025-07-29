import 'package:flutter/material.dart';
import 'package:xzchat/auth/auth_service.dart';
import 'package:xzchat/widgets/xz_buttons.dart';
import 'package:xzchat/widgets/xz_textfield.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;

  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  final TextEditingController confirmPwController = TextEditingController();

  bool securePass = true;
  bool secureCoPass = true;
  String loginImageUrl = "images/message.png";

  void toggleSecurePass() {
    setState(() {
      securePass = !securePass;
      loginImageUrl = securePass ? "images/message.png" : "images/spy.png";
    });
  }

  void toggleSecureCoPass() {
    setState(() {
      secureCoPass = !secureCoPass;
      loginImageUrl = secureCoPass ? "images/message.png" : "images/spy.png";
    });
  }

  void register(BuildContext context) {
    final authService = AuthService();

    if (pwController.text == confirmPwController.text) {
      try {
        authService.signUpWithEmailPassword(
            emailController.text, pwController.text);
      } catch (e) {
        if (!context.mounted) return;
        showDialog(
            context: context,
            builder: (context) => AlertDialog(title: Text(e.toString())));
      }
    } else {
      showDialog(
          context: context,
          builder: (context) =>
              const AlertDialog(title: Text("Passwords do not match !")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              loginImageUrl,
              height: 120,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 25),
            Text(
              "Create a account",
              style: TextStyle(
                  fontSize: 25, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 25),
            XzTextfield(
              hintText: "Email",
              obscureText: false,
              controller: emailController,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: TextField(
                obscureText: securePass,
                controller: pwController,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    onPressed: toggleSecurePass,
                    icon: Icon(
                      Icons.visibility_outlined,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.tertiary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  fillColor: Theme.of(context).colorScheme.secondary,
                  filled: true,
                  hintText: "Password",
                  hintStyle:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: TextField(
                obscureText: secureCoPass,
                controller: confirmPwController,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    onPressed: toggleSecureCoPass,
                    icon: Icon(
                      Icons.visibility_outlined,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.tertiary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  fillColor: Theme.of(context).colorScheme.secondary,
                  filled: true,
                  hintText: "Confirm Password",
                  hintStyle:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 25),
            XzButtons(
              text: "Register",
              onTap: () => register(context),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account ? ",
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
                GestureDetector(
                  onTap: widget.onTap,
                  child: const Text(
                    "Login Now",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
