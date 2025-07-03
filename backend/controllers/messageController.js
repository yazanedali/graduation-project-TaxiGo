// controllers/messageController.js
const Message = require('../models/messageModel');

// إرسال رسالة
exports.sendMessage = async (req, res) => {
  try {
    console.log('Request body:', req.body);
    
    // التحقق من الحقول المطلوبة
    const requiredFields = ['sender', 'receiver', 'senderType', 'receiverType'];
    for (const field of requiredFields) {
      if (!req.body[field]) {
        return res.status(400).json({ 
          error: `Missing required field: ${field}` 
        });
      }
    }

    // إنشاء رسالة جديدة
    const newMessage = new Message({
      sender: req.body.sender,
      receiver: req.body.receiver,
      senderType: req.body.senderType,
      receiverType: req.body.receiverType,
      message: req.body.message || null,
      image: req.body.image || null,
      audio: req.body.audio || null,
      officeId: req.body.officeId || null,
      timestamp: req.body.timestamp || new Date(),
      read: false
    });

    await newMessage.save();
    
    console.log('Message saved:', newMessage);
    res.status(201).json({ 
      success: true,
      message: 'Message sent successfully',
      data: newMessage 
    });
  } catch (err) {
    console.error('Error saving message:', err);
    res.status(500).json({ 
      success: false,
      error: err.message || 'Failed to send message' 
    });
  }
};

// الحصول على الرسائل لمستخدم معين
// In controllers/messageController.js
exports.getMessages = async (req, res) => {
  try {
    const { user1, user2 } = req.query;

    // --- طباعة للتحقق ---
    console.log("--- New Request to Get Messages ---");
    console.log(`Received userId: ${user1} (type: ${typeof user1})`);
    console.log(`Received otherUserId: ${user2} (type: ${typeof user2})`);

    if (!user1 || !user2) {
      return res.status(400).json({ error: "user1 و user2 مطلوبين." });
    }

    const query = {
      $or: [
        { sender: user1, receiver: user2 },
        { sender: user2, receiver: user1 }
      ]
    };

    // --- طباعة للتحقق ---
    console.log("Executing Mongoose Query:", JSON.stringify(query, null, 2));

    const messages = await Message.find(query)
      .sort({ timestamp: -1 })
      .limit(50);
    
    // --- طباعة للتحقق ---
    console.log(`Query finished. Found ${messages.length} messages.`);
    if (messages.length > 0) {
        // اطبع أول رسالة تم العثور عليها لمقارنة البيانات
        console.log("Example found message:", messages[0]);
    }
    console.log("------------------------------------");

    res.status(200).json(messages);

  } catch (err) {
    console.error('Error fetching messages:', err);
    res.status(500).json({ error: 'فشل في جلب الرسائل' });
  }
};


// تحديث حالة القراءة للرسائل
exports.markMessagesAsRead = async (req, res) => {
  try {
    const { receiver, sender } = req.body;
    
    await Message.updateMany(
      { receiver, sender, read: false },
      { 
        $set: { 
          read: true,
          readAt: new Date()
        }
      }
    );
    
    res.status(200).json({ message: 'Messages marked as read' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to mark messages as read' });
  }
};

// الحصول على عدد الرسائل غير المقروءة
exports.getUnreadCount = async (req, res) => {
  try {
    const { receiver } = req.params;
    
    const count = await Message.countDocuments({
      receiver,
      read: false
    });
    
    res.status(200).json({ unreadCount: count });
  } catch (err) {
    res.status(500).json({ error: 'Failed to get unread count' });
  }
};
