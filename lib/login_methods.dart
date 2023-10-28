import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<User?> createAccount(
  String email,
  String password,
  String name,
) async {
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  try {
    User? user = (await _auth.createUserWithEmailAndPassword(
            email: email, password: password))
        .user;
    if (user != null) {
      log("Account created Succesfully");
      await _firestore.collection('users').doc(_auth.currentUser?.uid).set({
        "name": name,
        "email": email,
        "status": "unavailable",
        "organisation": "None",
        "chatlist": [],
        "OrgGroups": [],
        "langcode": 'en',
      });
      return user;
    } else {
      log("Account creation failed");
      return null;
    }
  } catch (e) {
    print(e);
    return null;
  }
}

Future<User?> logIn(
  String email,
  String password,
) async {
  FirebaseAuth _auth = FirebaseAuth.instance;
  try {
    User? user = (await _auth.signInWithEmailAndPassword(
            email: email, password: password))
        .user;
    if (user != null) {
      log("Login Sucessful");
      return user;
    } else {
      log("Login Failed");
      return null;
    }
  } catch (e) {
    print(e);
    return null;
  }
}

Future logOut() async {
  FirebaseAuth _auth = FirebaseAuth.instance;
  try {
    await _auth.signOut();
  } catch (e) {
    log("error");
  }
}
