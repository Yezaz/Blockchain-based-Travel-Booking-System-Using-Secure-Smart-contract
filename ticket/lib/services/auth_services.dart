import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../widgets/passenger/womensinterface.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.reference();

  Future<String?> womensLogin(
      Map<String, String> data, BuildContext context) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: data['email']!,
        password: data['password']!,
      );

      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        user = _auth.currentUser;

        if (user != null) {
          String userId = user.uid;
          DatabaseReference dbRef = _database.child('users').child(userId);
          DatabaseEvent event = await dbRef.once();
          var userData = event.snapshot.value;

          if (userData is Map) {
            Map<String, dynamic> userDataMap =
            Map<String, dynamic>.from(userData);

            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => BusHomePage( // Changed to PHCHomePage
                   /* name: userDataMap['full_name'],
                    email: userDataMap['email'],
                    phone: userDataMap['phone'],
                    staffId: userDataMap['staff_id'],

                    ukey: userDataMap['ukey'],*/
                  ),
                ),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Login Successful')),
              );
            }
            return null; // No error
          } else {
            return "No user data found.";
          }
        } else {
          return "User not found after reload.";
        }
      }
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Login Failed";
    } catch (e) {
      return "An error occurred. Try again.";
    }
    return "Unknown error occurred.";
  }
}