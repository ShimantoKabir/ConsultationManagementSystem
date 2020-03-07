package com.dannygroupllc.ConsultantWebService;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.stereotype.Service;

import javax.annotation.PostConstruct;
import java.io.FileInputStream;

@Service
public class FireBaseInitializer {
    @PostConstruct
    public void initialize() {
        try {
            FileInputStream fileInputStream = new FileInputStream("./FireBaseServiceAccount.json");
            FirebaseOptions options = new FirebaseOptions.Builder()
                    .setCredentials(GoogleCredentials.fromStream(fileInputStream))
                    .setDatabaseUrl("https://consultant-e6956.firebaseio.com")
                    .build();
            FirebaseApp.initializeApp(options);
            System.out.println("com.dannygroupllc.ConsultantWebService.FireBaseInitializer.initialize : Done");
        } catch (Exception e) {
            System.out.println("com.dannygroupllc.ConsultantWebService.FireBaseInitializer.initialize : " +
                    e.getMessage());
            e.printStackTrace();
        }
    }
}
