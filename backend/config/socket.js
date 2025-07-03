// config/socket.js
const { Server } = require('socket.io');
const Message = require('../models/messageModel'); // ✅ استيراد موديل الرسالة
// قد تحتاج لاستيراد موديل User أيضاً إذا كنت تريد التحقق من المستخدمين

let io; // لتخزين instance الـ Socket.IO

module.exports = {
  init: (httpServer) => {
    // تهيئة Socket.IO مع خيارات CORS
    io = new Server(httpServer, {
      cors: {
        origin: process.env.CORS_ORIGIN || '*', // السماح بكل المصادر في التطوير، وتحديدها في الإنتاج
        methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'] // ✅ تأكد أن POST مسموح به لعمليات الـ HTTP إذا كان CORS_ORIGIN ضيقاً
      }
    });

    io.on('connection', (socket) => {
      console.log('A user connected to Socket.IO. Socket ID:', socket.id);

      // ✅ منطق الانضمام إلى الغرف (rooms) بناءً على نوع المستخدم و ID
      // هذا يسمح ببث الرسائل إلى مستخدمين محددين
      socket.on('join_user', (data) => {
        const userId = data.userId; // يجب أن يكون هذا هو الـ userId الرقمي
        if (userId) {
          socket.join(`user-${userId}`);
          console.log(`Socket ${socket.id} joined user room: user-${userId}`);
        }
      });
      socket.on('join_driver', (data) => {
        const driverId = data.driverId; // يجب أن يكون هذا هو الـ driverId الرقمي
        if (driverId) {
          socket.join(`driver-${driverId}`);
          console.log(`Socket ${socket.id} joined driver room: driver-${driverId}`);
        }
      });
      socket.on('join_manager', (data) => {
        const managerId = data.managerId; // يجب أن يكون هذا هو الـ managerId الرقمي
        if (managerId) {
          socket.join(`manager-${managerId}`);
          console.log(`Socket ${socket.id} joined manager room: manager-${managerId}`);
        }
      });

      // ✅ معالجة حدث 'send_message' القادم من Flutter
socket.on('send_message', async (messageData) => {
  try {
    // حفظ الرسالة في قاعدة البيانات
    const newMessage = new Message({
      sender: messageData.sender,
      receiver: messageData.receiver,
      senderType: messageData.senderType,
      receiverType: messageData.receiverType,
      message: messageData.message || null,
      image: messageData.image || null,
      audio: messageData.audio || null,
      officeId: messageData.officeId || null,
      timestamp: messageData.timestamp || new Date(),
      read: false
    });
    await newMessage.save();

    // تحديد غرفة المستقبل فقط
    const receiverRoom = `${messageData.receiverType.toLowerCase()}-${messageData.receiver}`;

    // تجهيز البيانات للبث
    const broadcastData = {
      sender: newMessage.sender,
      receiver: newMessage.receiver,
      message: newMessage.message,
      image: newMessage.image,
      audio: newMessage.audio,
      timestamp: newMessage.timestamp.toISOString(),
      read: newMessage.read,
      _id: newMessage._id.toString()
    };

    // إرسال الرسالة فقط لغرفة المستقبل
    io.to(receiverRoom).emit('new_message', broadcastData);

    // إرسال إشعار فقط للطرف المستقبل (وليس المرسل)
    const notificationController = require('../controllers/notificationController');
    await notificationController.createNotification({
      recipient: messageData.receiver,
      recipientType: messageData.receiverType,
      title: 'رسالة جديدة',
      message: `لديك رسالة جديدة من ${messageData.senderType}`,
      type: 'system',
      data: {
        sender: messageData.sender,
        messageId: newMessage._id.toString()
      }
    });

    console.log('Message sent to', receiverRoom, 'with data:', broadcastData);

  } catch (error) {
    console.error('Error handling send_message via socket:', error);
    // socket.emit('message_error', 'Failed to send message');
  }
});

      socket.on('disconnect', () => {
        console.log('A user disconnected from Socket.IO. Socket ID:', socket.id);
      });
    });
    return io;
  },
  getIo: () => {
    if (!io) {
      throw new Error('Socket.IO not initialized!');
    }
    return io;
  },
};