import 'package:chat_app/login.dart';
import 'package:chat_app/organisation_home_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:translator/translator.dart';

void main() {
  runApp(MaterialApp(
    title: 'Create Organization Example',
    home: CreateOrganizationPage(),
  ));
}

class CreateOrganizationPage extends StatefulWidget {
  @override
  _CreateOrganizationPageState createState() => _CreateOrganizationPageState();
}

class _CreateOrganizationPageState extends State<CreateOrganizationPage> {
  CurrentUserNotifier currentUserNotifier() =>
      Provider.of<CurrentUserNotifier>(context, listen: false);
  final TextEditingController _orgNameController = TextEditingController();
  final TextEditingController _orgDescriptionController =
      TextEditingController();
  final TextEditingController _orgEmailController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _createOrganization() async {
    final String orgName = _orgNameController.text;
    final String orgDescription = _orgDescriptionController.text;
    final String orgEmail = _orgEmailController.text;

    if (orgName.isNotEmpty &&
        orgDescription.isNotEmpty &&
        orgEmail.isNotEmpty) {
      DocumentReference orgDocRef =
          _firestore.collection('organisations').doc();
      await orgDocRef.set({
        'name': orgName,
        'description': orgDescription,
        'admin': currentUserNotifier()
            .currentUser, // Replace with the admin's user ID
        'org-email': orgEmail,
        'employee-list': [currentUserNotifier().currentUser],
        // Add other organization-specific data
      });
      // setting user org detail
      CollectionReference usersCollection =
          FirebaseFirestore.instance.collection('users');

      QuerySnapshot querySnapshot = await usersCollection
          .where('email', isEqualTo: currentUserNotifier().currentUser)
          .get();

      if (querySnapshot.size > 0) {
        DocumentReference userDocRef =
            usersCollection.doc(querySnapshot.docs.first.id);

        // Update the 'organisation' field in the document
        await userDocRef.update({'organisation': orgEmail});
      } else {
        print('User document not found');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Organization created successfully')),
      );

      // Clear text fields after creating organization
      _orgNameController.clear();
      _orgDescriptionController.clear();
      _orgEmailController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Please enter organization name, description, and email')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF171717),
      appBar: AppBar(
        title: const Text('Create Organization'),
        backgroundColor: Colors.transparent,
        elevation: 0, // Customize the app bar color
      ),
      body: Container(
        padding:
            const EdgeInsets.only(top: 100.0, left: 20, right: 20, bottom: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF171717), Color.fromARGB(255, 74, 73, 73)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ), // Customize the background color
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /*  TextField(
              controller: _orgNameController,
              decoration: const InputDecoration(
                labelText: 'Organization Name',
                border: OutlineInputBorder(),
              ),
            ), */
            _buildTextField('Organisation Name', CupertinoIcons.building_2_fill,
                _orgNameController),
            SizedBox(height: 10.0),
            _buildTextField('Organisation Description', CupertinoIcons.textbox,
                _orgDescriptionController),
            /* TextField(
              controller: _orgDescriptionController,
              decoration: InputDecoration(
                labelText: 'Organization Description',
                border: OutlineInputBorder(),
              ),
            ), */
            SizedBox(height: 10.0),
            _buildTextField(
                'Organisation Email', Icons.email, _orgEmailController),
            /* TextField(
              controller: _orgEmailController,
              decoration: InputDecoration(
                labelText: 'Organization Email',
                border: OutlineInputBorder(),
              ),
            ),*/
            SizedBox(height: 150.0),
            ElevatedButton(
              onPressed: () {
                _createOrganization();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MyOrganisationHomePage()),
                );
              },
              child: Text('Create Organization'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                backgroundColor: Color(0xFF27c1a9),
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildTextField(
    String label, IconData icon, TextEditingController controller) {
  return TextField(
    controller: controller,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: label,
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.5), // Hint text color
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3)), // Border color in idle state
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(
            color:
                Colors.white.withOpacity(0.9)), // Border color in focused state
      ),
      prefixIcon: Icon(icon, color: Colors.white),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    ),
  );
}
