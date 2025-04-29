import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/admin/neighborinterface.dart';



class AuthServicen {
  Future<void> neighborlogin(Map<String, String> data, BuildContext context) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: data['email']!,
        password: data['password']!,
      );

      User? user = FirebaseAuth.instance.currentUser;

        user = FirebaseAuth.instance.currentUser;
        if (user!.emailVerified) {
          DatabaseReference _database = FirebaseDatabase.instance.reference();
          String? userId = user.uid;

          /*DatabaseReference databaseReference = _database.child('homefoods').child(userId);
*/
          /*DatabaseEvent event = await databaseReference.once();*/
         /* var userData = event.snapshot.value;*/

         /* if (userData is Map) {
            Map<String, dynamic> userDataMap = Map<String, dynamic>.from(userData);

            String? name = userDataMap['name'];
            String? email = userDataMap['email'];
            String? uid = userDataMap['uid'];
            String? contact = userDataMap['contact'];
            String? city = userDataMap['city'];*/


            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Login Successfully')),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>  AdminDashboard(


/*

                  name: name,
                  email: email,
                  uid: uid,
                  contact: contact,
                  city: city,
*/




                ),
              ),
            );
          } /*else {
            showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Error"),
                  content: Text("No user data found."),
                );
              },
            );
          }
        } */
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Login Error"),
            content: Text(e.toString()),
          );
        },
      );
    }
  }

  Future<void> sendVerificationEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      print("Verification email sent to ${user.email}");
    }
  }
}
