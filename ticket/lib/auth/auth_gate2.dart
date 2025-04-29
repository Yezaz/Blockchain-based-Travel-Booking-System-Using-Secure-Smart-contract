/*
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';



import '../widgets/police/Login.dart';
import '../widgets/police/policeinterface.dart';






void main() {
  runApp(new MaterialApp(
    home: new AuthGatep(),



  ));


}

class AuthGatep extends StatelessWidget {
  const AuthGatep({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context,snapshot){
          if(!snapshot.hasData) {
            return policelogin();

          }
          return PoliceInterface();
        }

    );

  }
}








*/
