package com.dannygroupllc.ConsultantWebService.Utility;

import com.dannygroupllc.ConsultantWebService.pojos.Notification;
import com.dannygroupllc.ConsultantWebService.pojos.UserInfo;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.cloud.FirestoreClient;

public class NotificationSender {

    public static void send(Notification n){

        try {

            Firestore db = FirestoreClient.getFirestore();

            DocumentReference dr = db.collection("userInfoList").document(n.getUid());
            ApiFuture<DocumentSnapshot> future = dr.get();

            DocumentSnapshot document = future.get();
            if (document.exists()) {

                UserInfo userInfo = document.toObject(UserInfo.class);

                Notification notification = new Notification();
                notification.setFcmRegistrationToken(userInfo.getFcmRegistrationToken());
                notification.setUid(n.getUid());
                notification.setSeenStatus(0);
                notification.setTitle(n.getTitle());
                notification.setBody(n.getBody());
                notification.setStartTime(n.getStartTime());
                notification.setStartTime(n.getStartTime());

                db.collection("notificationList").add(notification);

            } else {
                System.out.println("com.dannygroupllc.ConsultantWebService.Utility.NotificationSender." +
                        "send: No userInfo found!");
            }

        }catch (Exception e){

            System.out.println("com.dannygroupllc.ConsultantWebService.Utility.NotificationSender.send : "+
                    e.getMessage());

        }

    }

}
