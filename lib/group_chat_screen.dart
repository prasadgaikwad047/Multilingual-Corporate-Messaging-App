import 'package:chat_app/api/translatorapi.dart';
import 'package:chat_app/search_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uuid/uuid.dart';

import 'login.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupChatId;
  final String groupName;
  final String groupId; // Change the variable name to groupId

  const GroupChatScreen(
      {Key? key,
      required this.groupChatId,
      required this.groupName,
      required this.groupId})
      : super(key: key);

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final CollectionReference _groupChatCollection =
      FirebaseFirestore.instance.collection('groupchats');

  final Uuid _uuid = Uuid();

  // Fetch the group chat ID or create a new one if it doesn't exist
  Future<String> getOrCreateGroupChatId(String groupChatId) async {
    QuerySnapshot chatQuery = await _groupChatCollection
        .where('groupId', isEqualTo: groupChatId)
        .get();

    if (chatQuery.docs.isEmpty) {
      String groupChatId = _uuid.v4();
      await _groupChatCollection.doc(groupChatId).set({
        'groupId': groupChatId,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Create the initial messages subcollection
      CollectionReference messagesCollection =
          _groupChatCollection.doc(groupChatId).collection('messages');
      await messagesCollection.add({
        'content': 'Group chat started!',
        'sender': 'system', // A special sender ID for system messages
        'timestamp': FieldValue.serverTimestamp(),
      });

      return groupChatId;
    } else {
      return chatQuery.docs.first.id;
    }
  }

  // Send a message to the group chat
  void sendMessage(String messageContent, String groupChatId) async {
    CurrentUserNotifier currentUserNotifier() =>
        Provider.of<CurrentUserNotifier>(context, listen: false);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final messageDocRef =
          _groupChatCollection.doc(groupChatId).collection('messages').doc();

      await messageDocRef.set({
        'timestamp': FieldValue.serverTimestamp(),
        'content': messageContent,
        'sender': currentUser.email,
        'name': currentUserNotifier().currentUserData['name'],
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    CurrentUserNotifier currentUserNotifier() =>
        Provider.of<CurrentUserNotifier>(context, listen: false);
    final groupChatId = widget.groupChatId;

    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.groupName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) async {
              currentUserNotifier().langCode = result;

              print(currentUserNotifier().langCode);
              // Set the new language code
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'en',
                child: Text('English'),
              ),
              const PopupMenuItem<String>(
                value: 'fr',
                child: Text('French'),
              ),
              const PopupMenuItem<String>(
                value: 'hi',
                child: Text('Hindi'),
              ),
              const PopupMenuItem<String>(
                value: 'mr',
                child: Text('Marathi'),
              ),
              // Add more languages as needed
            ],
          ),
          IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          CustomFlutterSearchView(groupMemberAdd: true)),
                );
              },
              icon: const Icon(Icons.group_add_rounded))
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _groupChatCollection
                  .doc(widget.groupChatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error fetching messages.'));
                } else {
                  List<QueryDocumentSnapshot> messageDocs = snapshot.data!.docs;
                  List<Message> messages = messageDocs.map((doc) {
                    return Message(
                        text: doc['content'],
                        timestamp: doc['timestamp'].toDate(),
                        sender: doc['sender'],
                        name: doc['name']);
                  }).toList();

                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      Message message = messages[index];
                      bool isMyMessage = message.sender ==
                          FirebaseAuth.instance.currentUser!.email;
                      Future<String> translatedtext = Translatorapi.translate(
                          message.text,
                          'en',
                          // CurrentUserNotifier()
                          // .currentUserData['langcode']
                          currentUserNotifier().langCode);
                      return Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: Align(
                          alignment: isMyMessage
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(
                              maxWidth:
                                  225, // Adjust the maximum width as needed
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMyMessage
                                  ? Color(0xFF27c1a9)
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: FutureBuilder<String>(
                              future: translatedtext,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Shimmer.fromColors(
                                    baseColor: Colors.white,
                                    highlightColor: Colors.white,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Container(
                                          width: double.infinity,
                                          height: 20.0,
                                          color: Colors
                                              .white, // Shimmer placeholder color
                                        ),
                                        SizedBox(height: 8.0),
                                        Container(
                                          width: double.infinity,
                                          height: 20.0,
                                          color: Colors
                                              .white, // Shimmer placeholder color
                                        ),
                                        // Add more shimmer placeholders as needed
                                      ],
                                    ),
                                  ); // Or any loading indicator
                                } else if (snapshot.hasError) {
                                  return Text(
                                    'Error translating: ${snapshot.error}',
                                    style: TextStyle(
                                      color: isMyMessage
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 16,
                                    ),
                                  );
                                } else {
                                  String translatedText = snapshot.data ?? '';
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message.name,
                                        style: TextStyle(
                                          color: isMyMessage
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 4,
                                      ),
                                      Text(
                                        translatedText,
                                        style: TextStyle(
                                          color: isMyMessage
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      );

                      /*
                      return ListTile(
                        title: Text(message.sender),
                        subtitle: Text(message.text),
                        trailing: Text(
                            message.timestamp.toString()), // Customize this
                        // Customize the styling and alignment based on the sender
                        tileColor: isMyMessage
                            ? Color(0xFF27c1a9)
                            : Colors.grey.shade300,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ); */
                    },
                  );
                }
              },
            ),
          ),
          Divider(
            height: 1,
          ),
          Container(
            decoration: BoxDecoration(color: Colors.transparent),
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                  controller: _messageController,
                  style: TextStyle(
                    color: Colors.white, // Text color
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
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
                          color: Colors.white.withOpacity(
                              0.9)), // Border color in focused state
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                )),
                SizedBox(width: 16),
                FloatingActionButton(
                  onPressed: () async {
                    if (_messageController.text != null) {
                      sendMessage(_messageController.text,
                          widget.groupChatId); // Send the message
                      _messageController.clear();
                    } // Fetch or create group chat ID
                  },
                  child: Icon(Icons.send),
                  backgroundColor: Color(0xFF27c1a9),
                ),
              ],
            ),
          ),
          /*
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    // Customize text field attributes
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    String groupChatId = await getOrCreateGroupChatId(
                        widget.groupChatId); // Fetch or create group chat ID
                    sendMessage(_messageController.text,
                        widget.groupChatId); // Send the message
                    _messageController.clear();
                  },
                  icon: Icon(Icons.send),
                ),
              ],
            ),
          ), */
        ],
      ),
    );
  }
}

class Message {
  final String text;
  final String sender;
  final String name;
  final DateTime timestamp;

  Message(
      {required this.text,
      required this.timestamp,
      required this.sender,
      required this.name});
}
