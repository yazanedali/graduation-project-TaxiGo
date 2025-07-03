const express = require("express");
const TelegramBot = require("node-telegram-bot-api");
const axios = require("axios");
const cors = require("cors");

const app = express();
app.use(express.json());
app.use(cors());

// بيانات تيليجرام
const TELEGRAM_BOT_TOKEN = "7608922442:AAHaWNXgfJFxgPBi2VJgdWekfznFIQ-4ZOQ";
const TELEGRAM_CHANNEL_ID = "-1002436928564";
const bot = new TelegramBot(TELEGRAM_BOT_TOKEN, { polling: true });

// مصفوفة لحفظ بيانات الطرق في الذاكرة
let roadStatuses = [];

// استقبال رسائل تيليجرام وتحديث حالة الطرق
bot.on("message", async (msg) => {
  try {
    if (msg.chat.id.toString() === TELEGRAM_CHANNEL_ID) {
      const text = msg.text.split(":"); // مثال: "شارع القدس: مغلق"
      if (text.length === 2) {
        const roadName = text[0].trim();
        const status = text[1].trim();

        // تحديث أو إضافة حالة الطريق
        const index = roadStatuses.findIndex((road) => road.roadName === roadName);
        if (index !== -1) {
          roadStatuses[index].status = status;
          roadStatuses[index].updatedAt = new Date();
        } else {
          roadStatuses.push({ roadName, status, updatedAt: new Date() });
        }

        console.log(`تم تحديث حالة الطريق: ${roadName} -> ${status}`);
      }
    }
  } catch (error) {
    console.error("❌ خطأ في تحديث حالة الطرق:", error);
  }
});

// API لاسترجاع بيانات الطرق
app.get("/roads", (req, res) => {
  res.json(roadStatuses);
});

// API لحساب المسار متجنبًا الطرق المغلقة
app.post("/calculate-route", async (req, res) => {
  try {
    const { start, destination } = req.body;
    const closedRoads = roadStatuses.filter((road) => road.status !== "Open");
    const avoidRoads = closedRoads.map((road) => road.roadName);

    const response = await axios.get("https://maps.googleapis.com/maps/api/directions/json", {
      params: {
        origin: start,
        destination,
        key: "YOUR_GOOGLE_MAPS_API_KEY", // ضع مفتاح Google API هنا
        avoid: avoidRoads.join("|"),
      },
    });

    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: "❌ فشل في حساب المسار" });
  }
});

// تشغيل السيرفر على المنفذ 3000
app.listen(3000, () => console.log("🚀 السيرفر يعمل على المنفذ 3000 بدون MongoDB!"));
