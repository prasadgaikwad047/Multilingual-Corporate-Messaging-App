import 'dart:developer';

import 'package:chat_app/login_methods.dart';

import 'package:chat_app/sign_up.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_page.dart';

void main() {
  runApp(const MaterialApp(
    home: LoginPage(),
    debugShowCheckedModeBanner: false,
  ));
}

class CurrentUserNotifier extends ChangeNotifier {
  String currentpage = 'Personal';
  String _langcode = 'en';
  String? currentUser; // email of user
  dynamic currentUserData; // document data of user
  dynamic currentUserOrgData; // document data of users org
  late String currentUserDataDocId; // doc id of user
  late String currentUserOrgDataDocId; // doc id of users org
  late String currentActivegroupId;
  List<dynamic>? chatlist; // personal chatlist of user

  Future<DocumentSnapshot?> getDocumentSnapshotByEmail(String email) async {
    CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('users');
    QuerySnapshot querySnapshot =
        await usersCollection.where('email', isEqualTo: email).get();

    if (querySnapshot.docs.isNotEmpty) {
      currentUserDataDocId = querySnapshot.docs.first.id;
      currentUserData = querySnapshot.docs.first.data();
      chatlist = currentUserData['chatlist'];
      notifyListeners();
      if (currentUserData['organisation'] != "None") {
        CollectionReference orgCollection =
            FirebaseFirestore.instance.collection('organisations');
        QuerySnapshot querySnapshot2 = await orgCollection
            .where('org-email', isEqualTo: currentUserData['organisation'])
            .get();
        if (querySnapshot2.docs.isNotEmpty) {
          currentUserOrgDataDocId = querySnapshot2.docs.first.id;
          currentUserOrgData = querySnapshot2.docs.first.data();
          print(currentUserOrgData['description']);
        }
      }

      notifyListeners();
      return querySnapshot.docs.first;
    } else {
      notifyListeners();
      return null;
    }
  }

  String get langCode => _langcode;
  set langCode(String newLangCode) {
    _langcode = newLangCode;
    notifyListeners(); // Notify the listeners that the value has changed
  }

  String get currentPage => currentpage;
  set currentPage(String newcurrentPage) {
    currentpage = newcurrentPage;
    notifyListeners(); // Notify the listeners that the value has changed
  }

  void setCurrentUser(String loggedinUser) {
    currentUser = loggedinUser;
    //print("current user ${currentUser}");
    notifyListeners();
    // create a func to set currentUser to null when user logout
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  CurrentUserNotifier currentUserNotifier() =>
      Provider.of<CurrentUserNotifier>(context, listen: false);
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool isloading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isloading
          ? Center(
              child: Container(
                height: 10,
                width: 10,
                child: const CircularProgressIndicator(),
              ),
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF171717), Color.fromARGB(255, 74, 73, 73)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Login Up",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      _buildTextField(
                          "Email", Icons.email, false, _emailController),
                      const SizedBox(height: 16),
                      _buildTextField("Password", Icons.lock, _obscurePassword,
                          _passwordController),
                      const SizedBox(height: 10),
                      _buildForgotPassword(),
                      const SizedBox(height: 24),
                      _buildLoginButton(),
                      const SizedBox(height: 16),
                      _buildSignUpButton(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, IconData icon, bool obscureText,
      TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.5), // Hint text color
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
              color:
                  Colors.white.withOpacity(0.3)), // Border color in idle state
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
              color: Colors.white
                  .withOpacity(0.9)), // Border color in focused state
        ),
        prefixIcon: Icon(icon, color: Colors.white),
        suffixIcon: obscureText
            ? IconButton(
                icon: const Icon(Icons.visibility, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // TODO: Implement forgot password functionality
        },
        style: TextButton.styleFrom(foregroundColor: Colors.white),
        child: const Text("Forgot Password?"),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: () {
        //  String email = _emailController.text;
        // String password = _passwordController.text;
        if (_emailController.text.isNotEmpty &&
            _passwordController.text.isNotEmpty) {
          setState(() {
            isloading = true;
          });
          logIn(_emailController.text, _passwordController.text).then((user) {
            if (user != null) {
              log("Login Succesfull2");
              setState(() {
                isloading = false;
                currentUserNotifier().setCurrentUser(_emailController.text);
                currentUserNotifier()
                    .getDocumentSnapshotByEmail(_emailController.text);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyHomePage()),
                );
              });
            } else {
              log("Login Failed2");
            }
          });
        }
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        backgroundColor: Color(0xFF27c1a9),
        foregroundColor: Colors.black,
      ),
      child: const Text(
        "LOGIN",
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SignUpPage(),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 1.5),
      ),
      child: const Text(
        "SIGN UP",
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
//item.itemId.toString(),