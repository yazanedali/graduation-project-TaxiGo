const Client = require('../models/client');

exports.getAllClients = async (req, res) => {
  try {
    const allClients = await Client.find({})
      .populate({
        path: 'user',
        select: 'fullName userId email phone'
      })
      .select('user tripsnumber profileImageUrl totalSpending isAvailable')
      .lean();
    res.status(200).json(allClients);
  } catch (error) {
    console.error("Error fetching all clients:", error);
    res.status(500).json({ message: "حدث خطأ أثناء جلب جميع العملاء", error: error.message });
  }
};

exports.getClientById = async (req, res) => {
  try {
    const clientId = req.params.id;

    const client = await Client.findOne({ clientUserId: clientId })
      .populate({
        path: 'user',
        select: 'fullName userId email phone profilePhoto'
      })
      .select('user tripsnumber profileImageUrl totalSpending isActive')
      .lean();

    if (!client) {
      return res.status(404).json({ message: "لم يتم العثور على العميل" });
    }
    const response = {
      ...client,
      user: {
        ...client.user,
        profilePhoto: client.user.profilePhoto
          ? `${req.protocol}://${req.get('host')}/uploads/${client.user.profilePhoto}`
          : null
      }
    };

    res.status(200).json(response);
  } catch (error) {
    console.error("Error fetching client by ID:", error);
    res.status(500).json({ 
      message: "حدث خطأ أثناء جلب بيانات العميل",
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

exports.updateAvailability = async (req, res) => {
  try {
    const { id } = req.params;
    const { isAvailable } = req.body;

    const updatedClient = await Client.findOneAndUpdate(
      { clientUserId: id },
      { isAvailable },
      { new: true }
    );

    if (!updatedClient) {
      return res.status(404).json({ message: 'Client not found' });
    }
    res.status(200).json(updatedClient);
  } catch (error) {
    console.error("Error updating client status:", error);
    res.status(500).json({ message: error.message });
  }
};

exports.uploadClientImage = async (req, res) => {
  try {
    const { id } = req.params;

    console.log('تم استلام طلب رفع صورة العميل:', id);
    console.log('req.file: ', req.file);

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'لم يتم اختيار أي صورة للرفع'
      });
    }

    const client = await Client.findOne({ clientUserId: id });

    if (!client) {
      return res.status(404).json({
        success: false,
        message: 'العميل غير موجود'
      });
    }

    // حذف الصورة القديمة من Cloudinary إذا موجودة
    if (client.profileImageUrl) {
      const publicId = client.profileImageUrl
        .split('/')
        .pop()
        .split('.')[0];

      await cloudinary.uploader.destroy(`Taxi-Go/clients/${publicId}`);
    }

    // تحديث رابط الصورة الجديدة
    client.profileImageUrl = req.file.path;
    await client.save();

    res.status(200).json({
      success: true,
      message: 'تم تحديث صورة العميل بنجاح',
      imageUrl: req.file.path,
      client: {
        id: client._id,
        image: client.profileImageUrl
      }
    });

  } catch (error) {
    console.error('حدث خطأ أثناء تحديث صورة العميل:', error);
    res.status(500).json({
      success: false,
      message: 'فشل تحديث صورة العميل',
      error: error.message
    });
  }
};

exports.editClientProfile = async (req, res) => {
  try {
    const clientUserId = req.params.id;
    const { fullName, email, phone } = req.body;
    console.log('تم استلام طلب تحديث بروفايل العميل:', clientUserId);

    // نعدل بيانات اليوزر المرتبط بالعميل
    const client = await Client.findOne({ clientUserId }).populate('user');

    if (!client) {
      return res.status(404).json({ message: 'العميل غير موجود' });
    }

    // نحدث بيانات المستخدم نفسه
    if (fullName) client.user.fullName = fullName;
    if (email) client.user.email = email;
    if (phone) client.user.phone = phone;

    await client.user.save();

    res.status(200).json({ message: 'تم تحديث بيانات البروفايل بنجاح', user: client.user });
  } catch (error) {
    console.error("خطأ أثناء تحديث بيانات البروفايل:", error);
    res.status(500).json({ message: 'فشل تحديث بيانات البروفايل', error: error.message });
  }
};


  