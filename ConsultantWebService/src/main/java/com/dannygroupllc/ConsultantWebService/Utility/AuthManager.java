package com.dannygroupllc.ConsultantWebService.Utility;

import com.dannygroupllc.ConsultantWebService.pojos.Request;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.cloud.FirestoreClient;

import java.util.Map;
import java.util.concurrent.ExecutionException;

public class AuthManager {

    public Integer check(Request request) {

        Firestore db = FirestoreClient.getFirestore();
        DocumentReference dr = db.collection("userInfoList").document(request.getUid());
        ApiFuture<DocumentSnapshot> future = dr.get();

        try {
            DocumentSnapshot document = future.get();
            if (document.exists()) {

                String authId = document.getData().get("authId").toString();
                System.out.println(getClass().getName()+".check: auth id = "+authId);
                if (authId.endsWith(request.getAuthId())){
                    return 200;
                }else{
                    return 404;
                }

            }else {
                return 404;
            }

        } catch (Exception e) {
            e.printStackTrace();
            return 404;
        }

    }

}
