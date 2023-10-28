import 'package:chat_app/home_page.dart';
import 'package:chat_app/login.dart';
import 'package:chat_app/org_group_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'one_to_one_chatscreen.dart';
import 'search_page.dart';

class MyOrganisationHomePage extends StatefulWidget {
  const MyOrganisationHomePage({super.key});

  @override
  State<MyOrganisationHomePage> createState() => _MyOrganisationHomePageState();
}

class _MyOrganisationHomePageState extends State<MyOrganisationHomePage> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _dataStream;
  @override
  void initState() {
    super.initState();
    // Replace 'your_collection_name' with the actual name of your collection in Firestore
    _dataStream = FirebaseFirestore.instance.collection('users').snapshots();
  }

  CurrentUserNotifier currentUserNotifier() =>
      Provider.of<CurrentUserNotifier>(context, listen: false);

  @override
  Widget build(BuildContext context) {
    //final currentUserNotifier = Provider.of<CurrentUserNotifier>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      body: Stack(children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 70, left: 5, right: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      onPressed: () {
                        currentUserNotifier().currentPage = 'Personal';
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyHomePage(),
                          ),
                        );
                        //Navigator.pop(context);
                      },
                      icon: const Icon(
                        CupertinoIcons.home,
                        color: Colors.white,
                      )),
                  Text(
                    currentUserNotifier().currentpage,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CustomFlutterSearchView(
                                    groupMemberAdd: false,
                                  )),
                        );
                      },
                      icon: const Icon(
                        Icons.search,
                        color: Colors.white,
                      )),
                ],
              ),
            ),
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 10),
                children: [
                  TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Messages",
                        style: TextStyle(color: Colors.grey, fontSize: 26),
                      )),
                  const SizedBox(
                    width: 35,
                  ),
                  TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Online",
                        style: TextStyle(color: Colors.grey, fontSize: 26),
                      )),
                  const SizedBox(
                    width: 35,
                  ),
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const MyOrganisationGroupPage()),
                        );
                      },
                      child: const Text(
                        "Group",
                        style: TextStyle(color: Colors.grey, fontSize: 26),
                      )),
                  const SizedBox(
                    width: 35,
                  ),
                  TextButton(
                      onPressed: () {},
                      child: const Text(
                        "More",
                        style: TextStyle(color: Colors.grey, fontSize: 26),
                      )),
                ],
              ),
            )
          ],
        ),
        Positioned(
            top: 190,
            left: 0,
            right: 0,
            child: Container(
              height: 220,
              padding: const EdgeInsets.only(top: 5, left: 25, right: 25),
              decoration: const BoxDecoration(
                  color: Color(0xFF27c1a9),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40))),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "favourite contacts",
                        style: TextStyle(color: Colors.white),
                      ),
                      IconButton(
                          onPressed: () {
                            setState(() {});
                          },
                          icon: const Icon(
                            Icons.more_horiz,
                            color: Colors.white,
                          )),
                    ],
                  ),
                  SizedBox(
                      height: 90,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [
                          BuildContactAvatar(
                            name: "Alla",
                            filename: 'profileimg1.jpg',
                          ),
                          BuildContactAvatar(
                            name: "July",
                            filename: 'profileimg2.jpg',
                          ),
                          BuildContactAvatar(
                            name: "Mikle",
                            filename: 'profileimg3.jpg',
                          ),
                          BuildContactAvatar(
                            name: "Jack",
                            filename: 'profileimg4.jpg',
                          ),
                          BuildContactAvatar(
                            name: "August",
                            filename: 'profileimg5.jpg',
                          ),
                          BuildContactAvatar(
                            name: "Alice",
                            filename: 'profileimg6.jpg',
                          ),
                          BuildContactAvatar(
                            name: "Merry",
                            filename: 'profileimg7.jpg',
                          ),
                          BuildContactAvatar(
                            name: "Chris",
                            filename: 'profileimg8.jpg',
                          )
                        ],
                      ))
                ],
              ),
            )),
        Positioned(
            top: 360,
            right: 0,
            left: 0,
            bottom: 0,
            child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFFFFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _dataStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final documents = snapshot.data!.docs;
                      final currentUserNotifier = context.watch<
                          CurrentUserNotifier>(); // getting reference of the currentUserNotifier
                      final employeeList = currentUserNotifier
                          .currentUserOrgData['employee-list'];
                      // Get the chatlist of currentUser from provider which is constantly updated when new user added from searchpage
                      return ListView.builder(
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          final data = documents[index].data();
                          //here from _datastream or users collection, every users email is checked, if its present in chatlist of currentUser or not
                          if (employeeList!.contains(data['email'])) {
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OneToOneChatScreen(
                                      senderId: currentUserNotifier.currentUser,
                                      receiverId: data['email'],
                                      receiverName: data['name'],
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(left: 25),
                                child: buildChatsList(
                                  data['name'],
                                  data['email'],
                                  'profileimg7.jpg',
                                ),
                              ),
                            );
                          } else {
                            return const SizedBox(height: 0, width: 0);
                          }
                        },
                      );
                    } else if (snapshot.hasError) {
                      return const Center(
                        child: Text('Error loading data'),
                      );
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  },
                )))
      ]),
    );
  }

  Column buildChatsList(String name, String message, String filename) {
    return Column(
      children: [
        Row(
          // add to this row or wrap this row for more elments in chatlist column ,, see video
          children: [
            UserAvatar(filename: filename),
            const SizedBox(
              width: 15,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  message,
                  style: const TextStyle(color: Colors.black),
                )
              ],
            )
          ],
        ),
        const Divider(
          indent: 70,
        ),
      ],
    );
  }
}

class BuildContactAvatar extends StatelessWidget {
  final String filename;
  final String name;
  const BuildContactAvatar(
      {super.key, required this.filename, required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          UserAvatar(
            filename: filename,
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          )
        ],
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String filename;
  const UserAvatar({
    super.key,
    required this.filename,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 32,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 29,
        backgroundImage: Image.asset('assets/images/$filename').image,
      ),
    );
  }
}
