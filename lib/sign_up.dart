import 'dart:developer';

import 'package:chat_app/login.dart';
import 'package:chat_app/login_methods.dart';

import 'package:flutter/material.dart';
/*
void main() {
  runApp(const MaterialApp(
    home: LoginPage(),
    debugShowCheckedModeBanner: false,
  ));
} */

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
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
                        "Sign Up",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      _buildTextField("Name", Icons.account_circle_outlined,
                          false, _nameController),
                      const SizedBox(height: 16),
                      _buildTextField(
                          "Email", Icons.email, false, _emailController),
                      const SizedBox(height: 16),
                      _buildTextField("Password", Icons.lock, _obscurePassword,
                          _passwordController),
                      const SizedBox(height: 10),
                      _buildForgotPassword(),
                      const SizedBox(height: 24),
                      _buildSignUpButton(),
                      const SizedBox(height: 16),
                      _buildLoginButton(),
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
                color: Colors.white
                    .withOpacity(0.3)), // Border color in idle state
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
        ));
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
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
        // TODO: Implement sign-up functionality
        if (_emailController.text.isNotEmpty &&
            _passwordController.text.isNotEmpty) {
          setState(() {
            isloading = true;
          });
          createAccount(_emailController.text, _passwordController.text,
                  _nameController.text)
              .then((user) {
            if (user != null) {
              log("Sign In Succesfull2");
              setState(() {
                isloading = false;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
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
