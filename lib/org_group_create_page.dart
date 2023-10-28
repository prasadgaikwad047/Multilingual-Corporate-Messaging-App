import 'package:chat_app/login.dart';
import 'package:chat_app/org_group_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class GroupCreatePage extends StatefulWidget {
  @override
  _GroupCreatePageState createState() => _GroupCreatePageState();
}

class _GroupCreatePageState extends State<GroupCreatePage> {
  CurrentUserNotifier currentUserNotifier() =>
      Provider.of<CurrentUserNotifier>(context, listen: false);
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController =
      TextEditingController();
  bool _isOrganisationGroup = false;
  CollectionReference _groupChatCollection =
      FirebaseFirestore.instance.collection('groupchats');
  Uuid _uuid = Uuid();
  void _createGroup() async {
    final currentUserUid =
        context.read<CurrentUserNotifier>().currentUserDataDocId;
    final groupRef = FirebaseFirestore.instance.collection('groups');

    final newGroupDocRef = await groupRef.add({
      'groupId': '',
      'groupChatId': '',
      'name': _groupNameController.text,
      'description': _groupDescriptionController.text,
      'admin': currentUserNotifier().currentUser,
      'members': [currentUserNotifier().currentUser],
      'isOrganisationGroup': _isOrganisationGroup,
    });

    await newGroupDocRef.update({'groupId': newGroupDocRef.id});

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(currentUserUid);
    await userRef.update({
      'OrgGroups': FieldValue.arrayUnion([newGroupDocRef.id]),
    });

    // Get or create the associated group chat document ID
    String groupChatId = await getOrCreateGroupChatId(newGroupDocRef.id);

    // Update the group with the group chat document ID

    await newGroupDocRef.update({'groupChatId': groupChatId});
    print(groupChatId);

    Navigator.pop(context); // Return to the previous page
  }

// check from here
  Future<String> getOrCreateGroupChatId(String groupId) async {
    QuerySnapshot chatQuery =
        await _groupChatCollection.where('groupId', isEqualTo: groupId).get();

    if (chatQuery.docs.isEmpty) {
      String groupChatId = _uuid.v4();
      await _groupChatCollection.doc(groupChatId).set({
        'groupId': groupId,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Create the initial messages subcollection
      CollectionReference messagesCollection =
          _groupChatCollection.doc(groupChatId).collection('messages');
      await messagesCollection.add({
        'content': 'Group chat started!',
        'name': 'system',
        'sender': 'system', // A special sender ID for system messages
        'timestamp': FieldValue.serverTimestamp(),
      });

      return groupChatId;
    } else {
      return chatQuery.docs.first.id;
    }
  }
/*
  Future<String> getOrCreateGroupChatId(String groupId) async {
    // Check if the group chat already exists
    QuerySnapshot chatQuery = await FirebaseFirestore.instance
        .collection('groupschats')
        .where('groupId', isEqualTo: groupId)
        .get();

    if (chatQuery.docs.isNotEmpty) {
      return chatQuery.docs.first.id;
    } else {
      // Create the group chat document
      DocumentReference groupChatDocRef =
          FirebaseFirestore.instance.collection('groupschats').doc();
      await groupChatDocRef.set({
        'groupId': groupId,
        // Add other fields related to the group chat
      });

      return groupChatDocRef.id;
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      appBar: AppBar(
        title: Text('Create Group'),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        padding: EdgeInsets.all(20.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF171717), Color.fromARGB(255, 74, 73, 73)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /* TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),*/
            _buildTextField('Group Name', Icons.group, _groupNameController),
            SizedBox(height: 10.0),
            _buildTextField('Group Description', Icons.description,
                _groupDescriptionController),
            /* TextField(
              controller: _groupDescriptionController,
              decoration: InputDecoration(
                labelText: 'Group Description',
                border: OutlineInputBorder(),
              ),
            ),*/
            SizedBox(height: 10.0),
            Row(
              children: [
                Text(
                  'Personal Group',
                  style: TextStyle(color: Colors.white),
                ),
                Switch(
                  focusColor: Colors.white,
                  value: _isOrganisationGroup,
                  onChanged: (value) {
                    setState(() {
                      _isOrganisationGroup = value;
                    });
                  },
                ),
                Text(
                  'Organisation Group',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                _createGroup();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MyOrganisationGroupPage()),
                );
              },
              child: Text('Create Group'),
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
