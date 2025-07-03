// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/chat_provider.dart';


// void main() {
//   runApp(
//     ChangeNotifierProvider(
//       create: (context) => ChatProvider(),
//       child: MyApp(),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'TaxiGo Chat',
//       theme: ThemeData(
//         primarySwatch: Colors.yellow,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       home: ChatScreen(),
//     );
//   }
// }


// class ChatScreen extends StatefulWidget {
//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   TextEditingController _controller = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Chat مع AI")),
//       body: Column(
//         children: [
//           Expanded(
//             child: Consumer<ChatProvider>(
//               builder: (context, chatProvider, child) {
//                 return ListView.builder(
//                   itemCount: chatProvider.messages.length,
//                   itemBuilder: (context, index) {
//                     var message = chatProvider.messages[index];
//                     return ListTile(
//                       title: Align(
//                         alignment: message["sender"] == "AI"
//                             ? Alignment.topLeft
//                             : Alignment.topRight,
//                         child: Card(
//                           color: message["sender"] == "AI"
//                               ? Colors.blueAccent
//                               : Colors.green,
//                           child: Padding(
//                             padding: const EdgeInsets.all(10.0),
//                             child: Text(
//                               message["message"]!,
//                               style: TextStyle(color: Colors.white),
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: InputDecoration(
//                       hintText: "اكتب رسالتك...",
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.send),
//                   onPressed: () {
//                     if (_controller.text.isNotEmpty) {
//                       String userMessage = _controller.text;
//                       // إرسال رسالة المستخدم
//                       Provider.of<ChatProvider>(context, listen: false)
//                           .addMessage("User", userMessage);
//                       _controller.clear();

//                       // معالجة الرد من AI بناءً على الرسالة
//                       String aiResponse = Provider.of<ChatProvider>(context,
//                               listen: false)
//                           .generateAIResponse(userMessage);
//                       // إرسال رد AI
//                       Provider.of<ChatProvider>(context, listen: false)
//                           .addMessage("AI", aiResponse);
//                     }
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
