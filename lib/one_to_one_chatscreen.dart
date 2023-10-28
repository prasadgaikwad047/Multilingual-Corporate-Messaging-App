import 'package:chat_app/api/translatorapi.dart';
import 'package:chat_app/login.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:shimmer/shimmer.dart';

class Message {
  final String text;
  final String sender;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.timestamp,
    required this.sender,
  });
}

class OneToOneChatScreen extends StatefulWidget {
  final String? senderId;
  final String? receiverId;
  String? receiverName;
  OneToOneChatScreen(
      {required this.senderId,
      required this.receiverId,
      required this.receiverName});

  @override
  _OneToOneChatScreenState createState() => _OneToOneChatScreenState();
}

class _OneToOneChatScreenState extends State<OneToOneChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  CollectionReference _chatCollection =
      FirebaseFirestore.instance.collection('chats');
  Uuid _uuid = Uuid();

  Future<String> getOrCreateChatId(String? user1Id, String? user2Id) async {
    QuerySnapshot chatQuery = await _chatCollection
        .where('user1', isEqualTo: user1Id)
        .where('user2', isEqualTo: user2Id)
        .get();

    if (chatQuery.docs.isEmpty) {
      chatQuery = await _chatCollection
          .where('user1', isEqualTo: user2Id)
          .where('user2', isEqualTo: user1Id)
          .get();
    }

    if (chatQuery.docs.isEmpty) {
      String chatId = _uuid.v4();
      await _chatCollection.doc(chatId).set({
        'user1': user1Id,
        'user2': user2Id,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Create the initial messages subcollection
      CollectionReference messagesCollection =
          _chatCollection.doc(chatId).collection('messages');
      await messagesCollection.add({
        'content': 'Chat started!',
        'sender': 'system', // A special sender ID for system messages
        'timestamp': FieldValue.serverTimestamp(),
      });

      return chatId;
    } else {
      return chatQuery.docs.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    CurrentUserNotifier currentUserNotifier() =>
        Provider.of<CurrentUserNotifier>(context, listen: false);
    String oppositeUser = 'User';
    if (widget.receiverName != null) {
      oppositeUser = widget.receiverName!;
    }
    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          " Chat with ${oppositeUser}",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
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
          )
        ],
      ),
      body: FutureBuilder<String>(
        future: getOrCreateChatId(
            widget.senderId, widget.receiverId), // Replace with actual user IDs
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print("the error${snapshot.hasError}");
            return const Center(
                child: Text('Error creating or fetching chat.'));
          } else {
            String chatId = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _chatCollection
                        .doc(chatId)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        return const Center(
                            child: Text('Error fetching messages.'));
                      } else {
                        List<QueryDocumentSnapshot> messageDocs =
                            snapshot.data!.docs;
                        List<Message> messages = messageDocs.map((doc) {
                          return Message(
                            text: doc['content'],
                            timestamp: doc['timestamp'].toDate(),
                            sender: doc['sender'],
                          );
                        }).toList();

                        return ListView.builder(
                          reverse: true,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            Message message = messages[index];
                            bool isMyMessage =
                                message.sender == widget.senderId;
                            Future<String> translatedtext =
                                Translatorapi.translate(
                                    message.text,
                                    'en',
                                    // CurrentUserNotifier()
                                    // .currentUserData['langcode']
                                    currentUserNotifier().langCode);

                            return Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
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
                                        String translatedText =
                                            snapshot.data ?? '';
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              message.text,
                                              style: TextStyle(
                                                color: isMyMessage
                                                    ? Colors.white
                                                    : Colors.black87,
                                                fontSize: 16,
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
                          },
                        );
                      }
                    },
                  ),
                ),
                Divider(height: 1.0),
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
                            color: Colors.white
                                .withOpacity(0.5), // Hint text color
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(
                                    0.3)), // Border color in idle state
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
                          String chatId = await getOrCreateChatId(
                              widget.senderId, widget.receiverId);
                          _sendMessage(_messageController.text, chatId);
                        },
                        child: Icon(Icons.send),
                        backgroundColor: Color(0xFF27c1a9),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  void _sendMessage(String message, String chatId) async {
    if (message.isNotEmpty) {
      CollectionReference messagesCollection =
          _chatCollection.doc(chatId).collection('messages');
      await messagesCollection.add({
        'content': message,
        'sender': widget.senderId, // Use senderId from widget
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    }
  }
}
