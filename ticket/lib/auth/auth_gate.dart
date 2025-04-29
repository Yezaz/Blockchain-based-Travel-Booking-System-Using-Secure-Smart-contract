import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/passenger/LoginPage.dart';
import '../widgets/passenger/womensinterface.dart';







void main() {
  runApp(new MaterialApp(
    home: new AuthGate(),



  ));


}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
   return StreamBuilder<User?>(stream: FirebaseAuth.instance.authStateChanges(),
       builder: (context,snapshot){
if(!snapshot.hasData) {
  return BusLoginPage();

}
     return BusHomePage();
       }

    );

  }
}








