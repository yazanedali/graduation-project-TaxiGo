var admin = require("firebase-admin");

// var serviceAccount = require("./taxigo-c21a4-firebase-adminsdk-fbsvc-501a3b16c4.json");
const serviceAccount = require("./taxigo-c21a4-firebase-adminsdk-fbsvc-501a3b16c4.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

module.exports = admin;