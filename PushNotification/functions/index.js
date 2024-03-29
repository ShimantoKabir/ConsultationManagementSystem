const functions = require('firebase-functions');

// install nodejs version 8.15.0
// =====
// cmd =
// =====
// npm install -g firebase-tools
// firebase login
// firebase init functions
// -------- Choose [Use an existing projects]
// firebase deploy --only functions

const admin = require("firebase-admin");
admin.initializeApp(functions.config().firebase);
let data;
let payload;

exports.notificationTrigger = functions.firestore.document('notificationList/{id}')
    .onCreate((snapshot, context) => {

        data = snapshot.data();
        console.log("fcmRegistrationToken = "+data.fcmRegistrationToken);

        payload = {
            "notification": {
                "title": data.title,
                "body": data.body,
                "click_action": 'FLUTTER_NOTIFICATION_CLICK'
            },
            "data": {
                "docId": context.params.id
            }
        };

        return admin.messaging().sendToDevice(data.fcmRegistrationToken, payload).then((res) => {

            console.log(res);
            console.log("Notification send successfully!");

        }).catch((err) => {

            console.log(err);

        })

    });
