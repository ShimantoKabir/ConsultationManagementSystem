const functions = require('firebase-functions');

// =====
// cmd =
// =====
// npm install -g firebase-tools
// firebase login
// firebase init functions
// firebase deploy --only functions
//

const admin = require("firebase-admin");
admin.initializeApp(functions.config().firebase);
let data;
let payload;
let tokenList = [];

exports.notificationTrigger = functions.firestore.document('notificationList/{id}')
    .onCreate((snapshot, context) => {

        data = snapshot.data();
        tokenList.push(data.fcmRegistrationToken);

        payload = {
            "notification": {
                "title": data.title,
                "body": data.body,
                "click_action": 'FLUTTER_NOTIFICATION_CLICK'
            }
        };

        return admin.messaging().sendToDevice(tokenList, payload).then((res) => {

            console.log(res);
            console.log("Notification send successfully!");

        }).catch((err) => {

            console.log(err);

        })

    });
