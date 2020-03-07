package com.dannygroupllc.ConsultantWebService.controllers;

import com.dannygroupllc.ConsultantWebService.pojos.Response;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.firebase.cloud.FirestoreClient;
import com.google.firebase.database.FirebaseDatabase;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/app")
public class TestCtl {

    @GetMapping("/test")
    public Response check() {

        Response res = new Response();
        res.setCode(200);
        res.setMsg("Application testing ok.............!");

        try {

            Firestore db = FirestoreClient.getFirestore();
            ApiFuture<QuerySnapshot> query = db.collection("userInfoList").get();

            QuerySnapshot querySnapshot = query.get();
            List<QueryDocumentSnapshot> documents = querySnapshot.getDocuments();
            for (QueryDocumentSnapshot document : documents) {
                System.out.println("User: " + document.getId());
                System.out.println("DisplayName: " + document.getString("displayName"));
            }

        }catch (Exception e){

            System.out.println(e.getMessage());

        }


        return res;

    }

}
