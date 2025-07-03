// import 'package:flutter/material.dart';
// import 'package:taxi_app/language/localization.dart';
// import 'package:taxi_app/models/message.dart';
// import 'package:taxi_app/services/chat_api.dart';

// class ChatScreen extends StatefulWidget {
//   final int receiverId;
//   final String receiverName;
//   final String token;

//   const ChatScreen({
//     Key? key,
//     required this.receiverId,
//     required this.receiverName,
//     required this.token,
//   }) : super(key: key);

//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   List<Message> messages = [];
//   bool isLoading = true;
//   String? errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     _loadMessages();
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadMessages() async {
//     try {
//       final messagesList = await ChatApi.getMessages(widget.receiverId, widget.token);
//       setState(() {
//         messages = messagesList;
//         isLoading = false;
//         errorMessage = null;
//       });
//       _scrollToBottom();
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//         errorMessage = e.toString();
//       });
//     }
//   }

//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }

//   Future<void> _sendMessage() async {
//     if (_messageController.text.trim().isEmpty) return;

//     final message = _messageController.text.trim();
//     _messageController.clear();

//     try {
//       final newMessage = await ChatApi.sendMessage(
//         widget.receiverId,
//         message,
//         widget.token,
//       );
//       setState(() {
//         messages.add(newMessage);
//       });
//       _scrollToBottom();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('فشل في إرسال الرسالة: ${e.toString()}')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final local = AppLocalizations.of(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.receiverName),
//         backgroundColor: theme.colorScheme.primary,
//       ),
//       body: Column(
//         children: [
//           if (errorMessage != null)
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Text(
//                 errorMessage!,
//                 style: const TextStyle(color: Colors.red),
//               ),
//             ),
//           Expanded(
//             child: isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : messages.isEmpty
//                     ? Center(
//                         child: Text(local.translate('no_messages')),
//                       )
//                     : ListView.builder(
//                         controller: _scrollController,
//                         padding: const EdgeInsets.all(8.0),
//                         itemCount: messages.length,
//                         itemBuilder: (context, index) {
//                           final message = messages[index];
//                           final isMe = message.senderId == widget.receiverId;

//                           return Align(
//                             alignment:
//                                 isMe ? Alignment.centerRight : Alignment.centerLeft,
//                             child: Container(
//                               margin: const EdgeInsets.symmetric(
//                                 vertical: 4.0,
//                                 horizontal: 8.0,
//                               ),
//                               padding: const EdgeInsets.all(12.0),
//                               decoration: BoxDecoration(
//                                 color: isMe
//                                     ? theme.colorScheme.primary
//                                     : theme.colorScheme.secondary,
//                                 borderRadius: BorderRadius.circular(12.0),
//                               ),
//                               child: Text(
//                                 message.content,
//                                 style: TextStyle(
//                                   color: isMe ? Colors.white : Colors.black,
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//           ),
//           Container(
//             padding: const EdgeInsets.all(8.0),
//             decoration: BoxDecoration(
//               color: theme.scaffoldBackgroundColor,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.grey.withOpacity(0.2),
//                   spreadRadius: 1,
//                   blurRadius: 3,
//                   offset: const Offset(0, -1),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: InputDecoration(
//                       hintText: local.translate('type_message'),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(24.0),
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 16.0,
//                         vertical: 8.0,
//                       ),
//                     ),
//                     maxLines: null,
//                     textInputAction: TextInputAction.send,
//                     onSubmitted: (_) => _sendMessage(),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send),
//                   onPressed: _sendMessage,
//                   color: theme.colorScheme.primary,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// } 