# 🚖 TaxiGo – Smart Taxi Booking & Management System

**TaxiGo** is a smart, real-time, role-based platform for managing and booking taxi rides across Palestine 🇵🇸.  
It’s designed to serve multiple roles: **Users (Passengers)**, **Drivers**, **Managers**, and **Admins** — each with their own dashboard and permissions.  
Built using modern technologies to ensure performance, security, and scalability across both mobile and web platforms.

---

## 🚀 Features

- 📍 Real-time location tracking using **OpenStreetMap**
- 📅 Scheduled & instant ride booking
- 🤖 Telegram Bot integration for booking trips
- 📡 Live trip tracking with push notifications (via **Firebase**)
- 👮 Emergency buttons (Police 🚔, Fire 🚒, Ambulance 🚑)
- 🌐 Multilingual UI (Arabic 🇸🇦 & English 🇬🇧)
- 🌙 Dark / Light theme support
- 🧠 AI-powered road condition analysis using **Gemini AI**
- 🔐 Role-based access control (User / Driver / Manager / Admin)
- 💬 Real-time chat between drivers and managers (via WebSocket)
- 🧾 Admin dashboard for managing trips, users, drivers, and offices
- 🧮 Automatic driver rating based on trip behavior
- 📸 Secure media storage with **Cloudinary**
- 💳 (Coming Soon) In-App Payments using **Stripe**
- 📞 (Coming Soon) Voice calls, image sharing, and group chats

---

## 🛠️ Tech Stack

| Layer            | Technology                                      |
|------------------|--------------------------------------------------|
| Frontend         | Flutter (Mobile & Web)                          |
| Backend          | Node.js (Express.js)                            |
| Database         | MongoDB (Main) & Firebase (Real-time features)  |
| Deployment       | Render                                          |
| Map Services     | OpenRouteService & OpenStreetMap                |
| Media Storage    | Cloudinary                                      |
| Notifications    | Firebase Cloud Messaging (FCM)                  |
| AI Integration   | Gemini AI (via Telegram road data)              |

---

## 📸 Screenshots

> (You can upload screenshots here using `![screenshot](link)` once pushed)

---

## 🧠 How It Works

```bash
# 1. Clone the project
git clone https://github.com/YOUR_USERNAME/taxigo.git

# 2. Install dependencies (frontend & backend)
cd taxigo
flutter pub get
npm install

# 3. Run Backend
cd backend
npm start

# 4. Run Flutter App
flutter run -d chrome # or use mobile emulator
