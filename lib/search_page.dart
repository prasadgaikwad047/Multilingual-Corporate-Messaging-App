import 'package:chat_app/login.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'home_page.dart';

class Item {
  final String itemId;
  final String email;
  final String name;

  const Item({
    required this.itemId,
    required this.email,
    required this.name,
  });
}

class CustomSearchNotifier extends ChangeNotifier {
  final List<Item> items = [];
  final List<Item> queriedItems = [];

  Future<void> fetchItemsFromFirestore() async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    items.clear();

    for (QueryDocumentSnapshot<Map<String, dynamic>> doc
        in querySnapshot.docs) {
      items.add(Item(itemId: doc.id, email: doc['email'], name: doc['name']));
    }

    notifyListeners();
  }

  String? query;

  void setQuery({required String value}) {
    query = value;
    notifyListeners();
  }

  void queryData() {
    queriedItems.clear();

    for (Item item in items) {
      if (query != null) {
        if (!queriedItems.contains(item)) {
          if (item.email.toLowerCase().contains(query!.toLowerCase())) {
            queriedItems.add(item);
            notifyListeners();
          }
        }
      }
    }
  }

  void clearSearch() {
    queriedItems.clear();
    query = null;
    notifyListeners();
  }
}

Future<void> updateChatList(CollectionReference usersCollection, String email,
    CurrentUserNotifier currentUserNotifier) async {
  // this part is me adding that person in my chatlist
  DocumentSnapshot snapshot = await usersCollection
      .where('email', isEqualTo: currentUserNotifier.currentUser)
      .get()
      .then((querySnapshot) => querySnapshot.docs.first);

  if (snapshot.exists) {
    DocumentReference matchingDocumentRef = snapshot.reference;

    Map<String, dynamic> documentData = snapshot.data() as Map<String, dynamic>;
    // print(documentData['email']);
    List<dynamic> myList = documentData['chatlist'] ?? [];
    if (!myList.contains(email) && email != currentUserNotifier.currentUser) {
      myList.add(email);
      currentUserNotifier.chatlist?.add(email);

      await matchingDocumentRef.update({'chatlist': myList});
    }
  }
  DocumentSnapshot snapshot2 = await usersCollection
      .where('email', isEqualTo: email)
      .get()
      .then((querySnapshot) => querySnapshot.docs.first);
  if (snapshot2.exists) {
    DocumentReference matchingDocumentRef2 = snapshot2.reference;

    Map<String, dynamic> documentData2 =
        snapshot2.data() as Map<String, dynamic>;
    // print(documentData['email']);
    List<dynamic> myList2 = documentData2['chatlist'] ?? [];
    if (!myList2.contains(currentUserNotifier.currentUser)) {
      myList2.add(currentUserNotifier.currentUser);

      await matchingDocumentRef2.update({'chatlist': myList2});
    }
  }
}

class CustomFlutterSearchView extends StatefulWidget {
  bool groupMemberAdd;
  CustomFlutterSearchView({super.key, required this.groupMemberAdd});

  @override
  State<CustomFlutterSearchView> createState() =>
      _CustomFlutterSearchViewState();
}

class _CustomFlutterSearchViewState extends State<CustomFlutterSearchView> {
  CustomSearchNotifier customSearchNotifier({required bool renderUI}) =>
      Provider.of<CustomSearchNotifier>(context, listen: renderUI);
  CurrentUserNotifier currentUserNotifier() =>
      Provider.of<CurrentUserNotifier>(context, listen: false);
  @override
  void initState() {
    super.initState();

    customSearchNotifier(renderUI: false).fetchItemsFromFirestore();
  }

  final TextEditingController textEditingController = TextEditingController();

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isQueryNull = customSearchNotifier(renderUI: true).query == null;
    CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('users');
    List<Item> items = isQueryNull
        ? customSearchNotifier(renderUI: true).items
        : customSearchNotifier(renderUI: true).queriedItems;

    return Scaffold(
        backgroundColor: const Color(0xFF171717),
        //backgroundColor: Color.fromARGB(255, 59, 59, 59),
        appBar: AppBar(
          backgroundColor:
              Colors.transparent, // Set the background color to transparent
          elevation: 0, // Remove the shadow
          leading: IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyHomePage()),
              ); // Navigate back when the icon is pressed
            },
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white, // Set the icon color
            ),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                decoration: BoxDecoration(color: Colors.transparent),
                // padding:
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                      onChanged: (val) {
                        if (val != "") {
                          customSearchNotifier(renderUI: false)
                              .setQuery(value: val);
                          customSearchNotifier(renderUI: false).queryData();
                        } else {
                          customSearchNotifier(renderUI: false).clearSearch();
                        }
                      },
                      style: const TextStyle(
                        color: Colors.white, // Text color
                      ),
                      controller: textEditingController,
                      decoration: InputDecoration(
                        hintText: 'Search Users...',
                        hintStyle: TextStyle(
                          color:
                              Colors.white.withOpacity(0.6), // Hint text color
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                              color: Colors.white.withOpacity(
                                  0.4)), // Border color in idle state
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                              color: Colors.white.withOpacity(
                                  1)), // Border color in focused state
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      )),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (BuildContext context, int index) {
                  Item item = items[index];
                  // if (currentUserNotifier()
                  //   .currentUserOrgData['employee-list']
                  //  .contains(item)) {
                  return Padding(
                    padding:
                        const EdgeInsets.only(top: 15.0, right: 15, left: 15),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(15.0),
                        child: Container(
                          color: Color.fromARGB(255, 89, 88, 88),
                          child: ListTile(
                            /*leading: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Center(
                          child: Text(
                            item.itemId.toString(),
                            style:
                                const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),*/
                            onTap: () async {},
                            leading: const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Icon(
                                Icons.account_box,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                            subtitle: Text(
                              item.email,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white),
                            ),
                            // trailing: const Icon(Icons.chat, color: Colors.black),
                            trailing: SizedBox(
                              width: 96,
                              child: widget.groupMemberAdd == false
                                  ? Row(
                                      children: [
                                        currentUserNotifier().currentUserData[
                                                        'organisation'] !=
                                                    "None" &&
                                                currentUserNotifier()
                                                            .currentUserOrgData[
                                                        'admin'] ==
                                                    currentUserNotifier()
                                                        .currentUser
                                            ? IconButton(
                                                onPressed: () async {
                                                  DocumentReference
                                                      documentRef =
                                                      FirebaseFirestore.instance
                                                          .collection(
                                                              'organisations')
                                                          .doc(currentUserNotifier()
                                                              .currentUserOrgDataDocId);

                                                  // Update the array field
                                                  await documentRef.update({
                                                    'employee-list':
                                                        FieldValue.arrayUnion(
                                                            [item.email]),
                                                  });

                                                  // updating the org detail of new employee added to org
                                                  QuerySnapshot querySnapshot =
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection('users')
                                                          .where('email',
                                                              isEqualTo:
                                                                  item.email)
                                                          .get();

                                                  if (querySnapshot
                                                      .docs.isNotEmpty) {
                                                    DocumentReference
                                                        documentRef =
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection('users')
                                                            .doc(querySnapshot
                                                                .docs.first.id);

                                                    // Update the array field
                                                    await documentRef.update({
                                                      'organisation':
                                                          currentUserNotifier()
                                                                  .currentUserOrgData[
                                                              'org-email'],
                                                    });
                                                  }
                                                },
                                                icon: const Icon(
                                                    Icons.group_add,
                                                    color: Colors.white),
                                              )
                                            : const SizedBox(
                                                height: 5,
                                                width: 47,
                                              ),
                                        IconButton(
                                            onPressed: () async {
                                              await updateChatList(
                                                  usersCollection,
                                                  item.email,
                                                  currentUserNotifier());
                                            },
                                            icon: const Icon(Icons.chat,
                                                color: Colors.white)),
                                      ],
                                    )
                                  : IconButton(
                                      onPressed: () async {
                                        // Get a reference to the document
                                        DocumentReference docRef =
                                            FirebaseFirestore
                                                .instance
                                                .collection('groups')
                                                .doc(currentUserNotifier()
                                                    .currentActivegroupId);
                                        DocumentSnapshot documentSnapshot =
                                            await docRef.get();
                                        if (documentSnapshot.exists) {
                                          dynamic fieldValue =
                                              documentSnapshot.get('admin');
                                          //  print('Field Value: $fieldValue');
                                          if (fieldValue ==
                                              currentUserNotifier()
                                                  .currentUser) {
                                            await docRef.update({
                                              'members': FieldValue.arrayUnion(
                                                  [item.email]),
                                            });
                                            updateListFieldByEmail(
                                                item.email,
                                                currentUserNotifier()
                                                    .currentActivegroupId);
                                            //print("you are admin");
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: const Text(
                                                      'Only admins can invite')),
                                            );
                                          }
                                          // Update the list field using FieldValue.arrayUnion
                                        }
                                      },
                                      icon: Icon(
                                        Icons.group_add_outlined,
                                        color: Colors.white,
                                      )),
                            ),
                          ),
                        )),
                  );
                }
                //  },
                ),
          ],
        ));
  }
}

Future<void> updateListFieldByEmail(String email, String groupId) async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: email)
      .get();

  if (querySnapshot.docs.isNotEmpty) {
    DocumentReference documentRef = querySnapshot.docs.first.reference;

    // Update the list field with a new element
    await documentRef.update({
      'OrgGroups': FieldValue.arrayUnion([groupId]),
    });
  }
}
