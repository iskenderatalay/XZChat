import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:xzchat/auth/login_or_register.dart';
import 'package:xzchat/pages/users_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if(snapshot.hasData){
            return UsersPage();
          }
          else{
            return const LoginOrRegister();
          }
        },
      ),
    );
  }
}
