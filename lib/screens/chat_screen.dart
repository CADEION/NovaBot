import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
User? loggedInUser;

class ChatScreen extends StatefulWidget {
  static String id = "chat_screen";

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  String? messageText;
  final messageTextController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final currUser = await _auth.currentUser;
      if (currUser != null) {
        loggedInUser = currUser;
        print(loggedInUser!.email);
      }
    } catch (e) {
      print(e);
    }
  }

  void messageStream() async {
    await for (var snapshot in _firestore.collection("messages").snapshots()) {
      for (var message in snapshot.docs) {
        var data = message.data(); // Get the document data as a map
        print(data['text']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                //Implement logout functionality
                // _auth.signOut();
                // Navigator.pop(context);
                messageStream();
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      style: TextStyle(color: Colors.black),
                      onChanged: (value) {
                        //Do something with the user input.
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      messageTextController.clear();
                      //Implement send functionality.
                      _firestore.collection('messages').add(
                          {"text": messageText, "sender": loggedInUser!.email,"time": DateTime.now(),});
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection("messages").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.blue,
              ),
            );
          } else {
            final messages = snapshot.data!.docs;
            List<MessageBubble> messageBubbles = [];
            for (var message in messages) {
              var data = message.data()
                  as Map<String, dynamic>?; // Get the document data as a map
              var messageText = data!["text"];
              var messageSender = data["sender"];
              var messageTime = data["time"];
              final currentUser = loggedInUser!.email;
              final messageWidget = MessageBubble(
                text: messageText,
                sender: messageSender,
                time: messageTime,
                isMe: currentUser == messageSender,
              );
              messageBubbles.add(messageWidget);
              messageBubbles.sort((a , b ) => b.time!.compareTo(a.time!));
            }
            return Expanded(
              child: ListView(
                reverse: true,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: messageBubbles,
              ),
            );
          }
          // return Text("HAPPY");
        });
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({required this.text, required this.sender,required this.time, required this.isMe});

  String? sender;
  String? text;
  Timestamp? time;
  bool? isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: isMe! ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            "$sender ${time!.toDate()}",
            style: TextStyle(color: Colors.black45, fontSize: 12),
          ),
          Material(
            borderRadius: isMe!
                ?const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  )
                :const BorderRadius.only(
                    topRight: Radius.circular(25),
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
            elevation: 10,
            color: isMe! ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.all(13),
              child: Text(
                "$text",
                style: TextStyle(
                    color: isMe! ? Colors.white : Colors.lightBlue,
                    fontSize: 18),
              ),
            ),
          )
        ],
      ),
    );
  }
}
