package com.dannygroupllc.ConsultantWebService.Utility;

import com.dannygroupllc.ConsultantWebService.pojos.Notification;
import com.dannygroupllc.ConsultantWebService.pojos.UserInfo;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.cloud.FirestoreClient;
import com.google.gson.Gson;

public class NotificationSender {

    public static void send(Notification n){

        try {

            Firestore db = FirestoreClient.getFirestore();

            DocumentReference dr = db.collection("userInfoList").document(n.getUid());
            ApiFuture<DocumentSnapshot> future = dr.get();

            DocumentSnapshot document = future.get();
            if (document.exists()) {

                // 1 = booking request
                // 2 = booking request cancellation
                // 3 = booking request acceptation
                // 4 = chat session reminder
                // 5 = payment reminder
                // 6 = expert send invitation to customer
                // 7 = payment received

                UserInfo userInfo = document.toObject(UserInfo.class);

                Notification notification = new Notification();
                notification.setFcmRegistrationToken(userInfo.getFcmRegistrationToken());
                notification.setUid(n.getUid());
                notification.setSeenStatus(0);
                notification.setTitle(n.getTitle());
                notification.setBody(n.getBody());
                notification.setStartTime(n.getStartTime());
                notification.setEndTime(n.getEndTime());
                notification.setType(n.getType());
                notification.setTopic(n.getTopic());
                notification.setTimeStamp(System.currentTimeMillis());

                System.out.println("Notification = "+new Gson().toJson(notification));
                db.collection("notificationList").add(notification);

            } else {
                System.out.println("com.dannygroupllc.ConsultantWebService.Utility.NotificationSender." +
                        "send: No userInfo found!");
            }

        }catch (Exception e){

            e.printStackTrace();
            System.out.println("com.dannygroupllc.ConsultantWebService.Utility.NotificationSender.send : "+
                    e.getMessage());

        }

    }

}
