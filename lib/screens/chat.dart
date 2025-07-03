import 'dart:convert';
import 'dart:io'; // للحفاظ على File
import 'package:flutter/foundation.dart'; // For kIsWeb and kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:taxi_app/services/drivers_api.dart'; // تأكد من المسار
import 'package:taxi_app/services/taxi_office_api.dart'; // تأكد من المسار
import 'package:taxi_app/language/localization.dart'; // تأكد من المسار
import 'package:lucide_icons/lucide_icons.dart'; // لأيقونات أفضل

// لتحويل أي ID إلى String (حتى لا يحصل خطأ String != int)
String _idToString(dynamic id) {
  if (id == null) return '';
  if (id is String) return id;
  if (id is int) return id.toString();
  return id.toString();
}

class ChatScreen extends StatefulWidget {
  final int userId;
  final String token;
  final String userType;
  final int? selectedDriverId;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.token,
    required this.userType,
    this.selectedDriverId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, dynamic>> contacts = [];
  List<Map<String, dynamic>> messages = [];
  dynamic selectedContactId;
  TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isRecording = false;
  String? _audioPath; // هذا المسار سيبقى مساراً محلياً كما كان في الكود الأصلي
  late IO.Socket socket;

  // Track the current playing audio
  String? _currentlyPlayingAudioPath;
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    // _initAudioPlayers(); // هذا كان معلقاً في الكود الأخير، لذلك أبقيه معلقاً.
    _initSocket();
    _loadContacts();

    // إذا تم تحديد سائق مسبقاً، اختره وحمل الرسائل
    if (widget.selectedDriverId != null) {
      selectedContactId = widget.selectedDriverId;
      // تأجيل تحميل الرسائل قليلاً لضمان تهيئة الواجهة
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMessages();
      });
    }
  }

  // هذا الجزء كان معلقاً في الكود الأخير، لذلك أبقيه معلقاً.
  // Future<void> _initAudioPlayers() async {
  //   await _recorder.openRecorder();
  //   await _player.openPlayer();

  //   _player.onPlayerStateChanged.listen((e) {
  //     if (mounted) {
  //       if (e != null && e.playerState == PlayerState.stopped) {
  //         setState(() {
  //           _isPlayingAudio = false;
  //           _currentlyPlayingAudioPath = null;
  //         });
  //       }
  //     }
  //   });
  // }

  void _initSocket() {
    final String socketBaseUrl =
        dotenv.env['BASE_URL'] ?? 'http://localhost:5000';

    socket = IO.io(socketBaseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {'token': widget.token}, // تمرير التوكن للمصادقة عبر WebSocket
    });

    socket.connect();

    socket.onConnect((_) {
      if (kDebugMode) print('Socket Connected!');
      if (widget.userType == 'User') {
        socket.emit('join_user', {'userId': widget.userId.toString()});
      } else if (widget.userType == 'Driver') {
        socket.emit('join_driver', {'driverId': widget.userId.toString()});
      } else if (widget.userType == 'Manager') {
        socket.emit('join_manager', {'managerId': widget.userId.toString()});
      }
    });

    socket.onConnectError(
        (err) => {if (kDebugMode) print('Socket Connect Error: $err')});
    socket.onError((err) => {if (kDebugMode) print('Socket Error: $err')});
    socket.onDisconnect((_) => {if (kDebugMode) print('Socket Disconnected!')});

    socket.on('new_message', (data) {
      if (kDebugMode) {
        print('Received new_message via socket: $data');
        print(
            'Selected Contact ID: $selectedContactId, Widget User ID: ${widget.userId}');
      }

      final String senderId = _idToString(data['sender']);
      final String receiverId = _idToString(data['receiver']);
      final String currentUserId = _idToString(widget.userId);
      final String currentSelectedContactId = _idToString(selectedContactId);

      // 1. تحقق ما إذا كانت الرسالة تخص المحادثة المفتوحة حالياً
      final bool isForCurrentConversation = (senderId ==
                  currentSelectedContactId &&
              receiverId ==
                  currentUserId) || // رسالة من جهة الاتصال الحالية إلي
          (senderId == currentUserId &&
              receiverId ==
                  currentSelectedContactId); // رسالة مني إلى جهة الاتصال الحالية

      // 2. تحقق ما إذا كانت الرسالة بالفعل موجودة محلياً (خاصة بالمرسل)
      bool isDuplicateOfLocalSend = false;
      if (messages.isNotEmpty && senderId == currentUserId) {
        // فقط إذا كان المرسل هو أنا
        final lastLocalMessage =
            messages.first; // بما أننا نضيف في index 0، آخر رسالة هي أول عنصر

        // مقارنة الرسائل بناءً على المحتوى والتاريخ (مع تسامح بسيط في الوقت)
        // هذا يمنع إضافة الرسالة التي أرسلتها للتو والتي عادت من السيرفر كـ broadcast
        try {
          final localTime =
              DateTime.parse(lastLocalMessage['timestamp'].toString());
          final remoteTime = DateTime.parse(data['timestamp'].toString());

          // تحقق من تطابق المحتوى والطرفين وتاريخ الإرسال ضمن ثانية واحدة
          if (_idToString(lastLocalMessage['sender']) == senderId &&
              _idToString(lastLocalMessage['receiver']) == receiverId &&
              lastLocalMessage['message'] == data['message'] &&
              (lastLocalMessage['image'] == data['image'] ||
                  (lastLocalMessage['image'] == null &&
                      data['image'] == null)) && // مقارنة الصور
              (lastLocalMessage['audio'] == data['audio'] ||
                  (lastLocalMessage['audio'] == null &&
                      data['audio'] == null)) && // مقارنة الصوت
              remoteTime.difference(localTime).abs().inMilliseconds < 1000) {
            // تسامح في الأوقات
            isDuplicateOfLocalSend = true;
          }
        } catch (_) {
          // في حال فشل تحليل التاريخ، قد نعتبر تطابق المحتوى كافياً
          // هذه حالة احتياطية، الأفضل دائماً الاعتماد على التاريخ أو ID فريد للرسالة
          if (_idToString(lastLocalMessage['sender']) == senderId &&
              _idToString(lastLocalMessage['receiver']) == receiverId &&
              lastLocalMessage['message'] == data['message']) {
            isDuplicateOfLocalSend = true;
          }
        }
      }

      if (mounted && isForCurrentConversation && !isDuplicateOfLocalSend) {
        if (kDebugMode)
          print(
              'Message matches current conversation and not a duplicate. Updating UI.');
        setState(() {
          messages.insert(0, {
            'sender': senderId,
            'receiver': receiverId,
            'message': data['message'],
            'image': data['image'],
            'audio': data['audio'],
            'timestamp': data['timestamp'],
            'read': data['read'],
          });
        });
      } else {
        if (kDebugMode)
          print(
              'Message not added to UI (either not for current conversation or identified as duplicate).');
      }
    });
  }

  Future<void> _loadContacts() async {
    try {
      List<Map<String, dynamic>> fetchedContacts = [];

      if (widget.userType == 'Manager') {
        final drivers =
            await TaxiOfficeApi.getOfficeDrivers(widget.userId, widget.token);
        fetchedContacts = drivers.map((driver) {
          return {
            'id': driver.driverUserId, // driverUserId هو Number
            'name': driver.fullName,
            'image': driver.profileImageUrl ?? '',
            'type': 'Driver',
            'officeId': driver.taxiOfficeId,
          };
        }).toList();
      } else if (widget.userType == 'Driver') {
        final manager = await DriversApi.getDriverManagerForDriver(
            widget.userId, widget.token);
        if (manager != null) {
          fetchedContacts = [
            {
              'id': manager
                  .id, // تصحيح: manager.id بدلاً من manager.user (تم حله في الإجابة السابقة)
              'name': manager.fullName,
              'image':
                  manager.profileImageUrl ?? 'https://example.com/default.jpg',
              'type': 'Manager',
              'officeId': manager.officeId,
            }
          ];
        }
      }
      // إذا كان userType هو 'User'، فستحتاج إلى جلب جهات الاتصال الخاصة بالمستخدمين (مديرين/سائقين) من الـ Backend

      if (mounted) {
        setState(() {
          contacts = fetchedContacts;
          if (selectedContactId == null && contacts.isNotEmpty) {
            selectedContactId = contacts.first['id'];
            _loadMessages();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load contacts: ${e.toString()}')),
        );
      }
      if (kDebugMode) {
        print('Error loading contacts: $e');
      }
    }
  }

  Future<void> _loadMessages() async {
    if (selectedContactId == null) return;
    try {
      if (kDebugMode) {
        print(
            'Loading messages for contact ID: $selectedContactId and user ID: ${widget.userId}');
      }
      final String apiBaseUrl =
          dotenv.env['BASE_URL'] ?? 'http://localhost:5000';

      final response = await http.get(
        Uri.parse(
            '$apiBaseUrl/messages?user1=${_idToString(widget.userId)}&user2=${_idToString(selectedContactId)}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            messages = data.map<Map<String, dynamic>>((msg) {
              return {
                'sender': _idToString(msg['sender']),
                'receiver': _idToString(msg['receiver']),
                'message': msg['message'],
                'image': msg['image'],
                'audio': msg['audio'],
                'timestamp': msg['timestamp'],
                'read': msg['read'],
              };
            }).toList();
          });
        } else {
          if (kDebugMode) {
            print(
                'Failed to load messages. Status: ${response.statusCode}, Body: ${response.body}');
          }
          throw Exception('Failed to load messages: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not load conversation: ${e.toString()}')),
        );
      }
      if (kDebugMode) {
        print('Error in _loadMessages: $e');
      }
    }
  }

  Future<void> _sendMessage(String message,
      {String? imagePath, String? audioPath}) async {
    if (message.isEmpty && imagePath == null && audioPath == null) return;
    if (selectedContactId == null) return;

    final contact = contacts.firstWhere(
        (c) => _idToString(c['id']) == _idToString(selectedContactId),
        orElse: () => <String, Object>{});
    if (contact.isEmpty) {
      _showErrorSnackBar(
          AppLocalizations.of(context).translate('chat_select_contact_error'));
      return;
    }

    final newMessage = {
      'sender': _idToString(widget.userId),
      'receiver': _idToString(selectedContactId),
      'senderType': widget.userType,
      'receiverType': contact['type'],
      'message': message,
      'image': imagePath,
      'audio': audioPath,
      'timestamp': DateTime.now().toIso8601String(), // استخدم وقت العميل
      'read': false,
      'officeId': contact['officeId'],
    };

    if (mounted) {
      setState(() {
        messages.insert(0, newMessage); // أضف الرسالة إلى القائمة فوراً
      });
    }

    socket.emit('send_message', newMessage); // ✅ استخدام 'send_message'

    _controller.clear();
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final date = DateTime.parse(timestamp);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      _sendMessage('', imagePath: pickedFile.path);
    }
  }

  // هذا الجزء كان معلقاً في الكود الأخير، لذلك أبقيه معلقاً.
  // Future<void> _startRecording() async {
  //   if (mounted) {
  //     setState(() {
  //       _isRecording = true;
  //     });
  //   }

  //   try {
  //     var status = await Permission.microphone.status;
  //     if (status.isDenied) {
  //       status = await Permission.microphone.request();
  //       if (status.isDenied) {
  //         if (mounted) {
  //           _showErrorSnackBar(AppLocalizations.of(context)
  //               .translate('chat_microphone_permission_denied'));
  //         }
  //         if (mounted) {
  //           setState(() {
  //             _isRecording = false;
  //           });
  //         }
  //         return;
  //       }
  //     }
  //     if (status.isPermanentlyDenied) {
  //       if (mounted) {
  //         _showErrorSnackBar(AppLocalizations.of(context)
  //             .translate('chat_microphone_permission_permanently_denied'));
  //       }
  //       openAppSettings();
  //       if (mounted) {
  //         setState(() {
  //           _isRecording = false;
  //         });
  //       }
  //       return;
  //     }

  //     _audioPath =
  //         '/storage/emulated/0/Download/audio_${DateTime.now().millisecondsSinceEpoch}.aac';

  //     await _recorder.startRecorder(toFile: _audioPath, codec: Codec.aacADTS);
  //     if (kDebugMode) {
  //       print('Recording started to: $_audioPath');
  //     }
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('Error starting recording: $e');
  //     }
  //     if (mounted) {
  //       _showErrorSnackBar(AppLocalizations.of(context)
  //           .translate('chat_failed_to_start_recording'));
  //     }
  //     if (mounted) {
  //       setState(() {
  //         _isRecording = false;
  //       });
  //     }
  //   }
  // }

  // هذا الجزء كان معلقاً في الكود الأخير، لذلك أبقيه معلقاً.
  // Future<void> _stopRecording() async {
  //   try {
  //     final path = await _recorder.stopRecorder();
  //     if (kDebugMode) {
  //       print('Recording stopped, path: $path');
  //     }
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('Error stopping recorder: $e');
  //     }
  //     if (mounted) {
  //       _showErrorSnackBar(AppLocalizations.of(context)
  //           .translate('chat_failed_to_stop_recording'));
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isRecording = false;
  //       });
  //     }
  //     if (_audioPath != null) {
  //       _sendMessage('', audioPath: _audioPath);
  //       _audioPath = null;
  //     }
  //   }
  // }

  // هذا الجزء كان معلقاً في الكود الأخير، لذلك أبقيه معلقاً.
  // Future<void> _playAudio(String path) async {
  //   if (_isPlayingAudio) {
  //     await _player.stopPlayer();
  //     if (mounted) {
  //       setState(() {
  //         _isPlayingAudio = false;
  //         _currentlyPlayingAudioPath = null;
  //       });
  //     }
  //     if (_currentlyPlayingAudioPath == path) {
  //       return;
  //     }
  //   }

  //   try {
  //     if (kDebugMode) {
  //       print('Playing audio from: $path');
  //     }
  //     await _player.startPlayer(fromURI: path);
  //     if (mounted) {
  //       setState(() {
  //         _isPlayingAudio = true;
  //         _currentlyPlayingAudioPath = path;
  //       });
  //     }
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('Error playing audio: $e');
  //     }
  //     if (mounted) {
  //       _showErrorSnackBar(AppLocalizations.of(context)
  //           .translate('chat_failed_to_play_audio'));
  //       setState(() {
  //         _isPlayingAudio = false;
  //         _currentlyPlayingAudioPath = null;
  //       });
  //     }
  //   }
  // }

  // هذا الجزء كان معلقاً في الكود الأخير، لذلك أبقيه معلقاً.
  // Future<Directory> _getTemporaryDirectory() async {
  //   return Directory('/tmp');
  // }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  @override
  void dispose() {
    socket.dispose();
    // هذه كانت معلقة في الكود السابق، ولكنها مهمة لـ FlutterSound
    // _recorder.closeRecorder();
    // _player.closePlayer();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.appBarTheme.iconTheme,
        elevation: theme.appBarTheme.elevation,
        title: Text(
          selectedContactId != null
              ? contacts.firstWhere(
                  (c) => _idToString(c['id']) == _idToString(selectedContactId),
                  orElse: () => <String, Object>{
                        'name': local.translate('chat_unknown_contact')
                      })['name']
              : local.translate('chat_app_title'),
          style: theme.appBarTheme.titleTextStyle,
        ),
        leading: isLargeScreen
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back,
                    color: theme.appBarTheme.iconTheme?.color),
                onPressed: () {
                  if (selectedContactId != null &&
                      widget.selectedDriverId == null) {
                    setState(() {
                      selectedContactId = null;
                      messages.clear();
                    });
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
      ),
      body: isLargeScreen
          ? Row(
              children: [
                _buildContactsList(theme, local),
                Expanded(
                  child: selectedContactId == null
                      ? Center(
                          child: Text(
                            local.translate('chat_select_contact_to_start'),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : _buildChatUI(theme, local),
                ),
              ],
            )
          : selectedContactId == null
              ? _buildContactsList(theme, local)
              : _buildChatUI(theme, local),
    );
  }

  Widget _buildMessageInput(ThemeData theme, AppLocalizations local) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      color: theme.colorScheme.surface, // لون خلفية حقل الإدخال
      child: Row(
        children: [
          IconButton(
            icon: Icon(LucideIcons.image, color: theme.colorScheme.primary),
            onPressed: () => _pickImage(ImageSource.gallery),
            tooltip: local.translate('chat_pick_image_gallery'),
          ),
          IconButton(
            icon: Icon(LucideIcons.camera, color: theme.colorScheme.primary),
            onPressed: () => _pickImage(ImageSource.camera),
            tooltip: local.translate('chat_pick_image_camera'),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: local.translate('chat_type_message'),
                hintStyle: theme.inputDecorationTheme.hintStyle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.send, color: theme.colorScheme.primary),
            onPressed: () => _sendMessage(_controller.text),
            tooltip: local.translate('chat_send_message'),
          ),
          // ✅ أضف زر التسجيل الصوتي إذا كانت مكتبة FlutterSoundAudioPlayers مدعومة
          // if (_recorder.isRecorderInitialized && _player.isPlayerInitialized)
          IconButton(
            icon: Icon(
                _isRecording
                    ? LucideIcons.square
                    : LucideIcons.mic, // مربع للإيقاف، ميكروفون للتسجيل
                color: _isRecording
                    ? theme.colorScheme.error
                    : theme.iconTheme.color),
            onPressed: () => {},
            tooltip: _isRecording
                ? local.translate('chat_stop_recording')
                : local.translate('chat_start_recording'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList(ThemeData theme, AppLocalizations local) {
    return Container(
      width: 280, // عرض ثابت لقائمة جهات الاتصال
      color: theme.colorScheme.background, // خلفية قائمة جهات الاتصال
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.center,
            child: Text(
              local.translate('chat_contacts_title'),
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onBackground,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                final isSelected = _idToString(contact['id']) ==
                    _idToString(selectedContactId);

                return Container(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.2)
                      : Colors.transparent, // لون التحديد
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor:
                          theme.colorScheme.surface, // خلفية افتراضية للأفاتار
                      backgroundImage: (contact['image'] != null &&
                              contact['image'].toString().isNotEmpty)
                          ? NetworkImage(contact['image'].toString())
                          : const AssetImage('assets/default_avatar.png')
                              as ImageProvider, // صورة افتراضية
                      onBackgroundImageError: (exception, stackTrace) {
                        if (kDebugMode) {
                          print(
                              'Error loading image for ${contact['name']}: $exception');
                        }
                      },
                    ),
                    title: Text(
                      contact['name'],
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                    subtitle: Text(
                      contact['type'],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          selectedContactId = contact['id'];
                          _loadMessages(); // حمل الرسائل للمحادثة الجديدة
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatUI(ThemeData theme, AppLocalizations local) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: theme.scaffoldBackgroundColor, // خلفية منطقة الدردشة
            child: ListView.builder(
              reverse: true, // الرسائل الأحدث في الأعلى
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMe = _idToString(message['sender']) ==
                    _idToString(widget.userId);

                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width *
                            0.75), // عرض أقصى لفقاعة الرسالة
                    margin:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? theme.colorScheme.primary
                              .withOpacity(0.8) // لون أساسي شفاف لرسائلي
                          : theme.cardColor, // لون الكارد لرسائل الطرف الآخر
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isMe
                            ? const Radius.circular(16)
                            : const Radius.circular(4),
                        bottomRight: isMe
                            ? const Radius.circular(4)
                            : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor
                              .withOpacity(0.1), // لون الظل من الثيم
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message['message'] != null &&
                            message['message'].toString().isNotEmpty)
                          Text(
                            message['message'],
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: isMe
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        if (message['image'] != null &&
                            message['image'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                message['image'].toString(),
                                width: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.broken_image,
                                        size: 200,
                                        color: theme.colorScheme.error),
                              ),
                            ),
                          ),
                        if (message['audio'] != null &&
                            message['audio'].toString().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? theme.colorScheme.onPrimary.withOpacity(0.2)
                                  : theme.colorScheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  // أيقونة للمسار الصوتي
                                  _currentlyPlayingAudioPath ==
                                              message['audio'] &&
                                          _isPlayingAudio
                                      ? LucideIcons.pauseCircle
                                      : LucideIcons.playCircle,
                                  color: isMe
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  local.translate(
                                      'chat_audio_message'), // "رسالة صوتية"
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isMe
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                // زر تشغيل/إيقاف الصوت
                                IconButton(
                                    icon: Icon(
                                      _currentlyPlayingAudioPath ==
                                                  message['audio'] &&
                                              _isPlayingAudio
                                          ? Icons.stop
                                          : Icons.play_arrow,
                                      color: isMe
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.primary,
                                    ),
                                    onPressed: () => {}),
                              ],
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(message['timestamp']),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isMe
                                ? theme.colorScheme.onPrimary.withOpacity(0.7)
                                : theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        _buildMessageInput(theme, local),
      ],
    );
  }
}
