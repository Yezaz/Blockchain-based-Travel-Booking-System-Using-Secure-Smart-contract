import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/admin/Loginn.dart';
import '../widgets/admin/neighborinterface.dart';






void main() {
  runApp(new MaterialApp(
    home: new AuthGate2(),



  ));


}

class AuthGate2 extends StatelessWidget {
  const AuthGate2({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context,snapshot){
          if(!snapshot.hasData) {
            return AdminLoginPage();

          }
          return AdminDashboard();
        }

    );

  }
}








