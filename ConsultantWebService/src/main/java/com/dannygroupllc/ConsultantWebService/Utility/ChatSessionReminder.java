package com.dannygroupllc.ConsultantWebService.Utility;

import com.dannygroupllc.ConsultantWebService.daos.interfaces.PlanDao;
import com.google.gson.Gson;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.net.URI;

@EnableAsync
@Component
public class ChatSessionReminder {

    @Async
    @Scheduled(fixedRate = 300000)
    public void remind() {

        try {

            Gson gson = new Gson();
            RestTemplate restTemplate = new RestTemplate();

            HttpHeaders headers = new HttpHeaders();
            headers.set("Content-Type", "application/json");

            HttpEntity requestEntity = new HttpEntity<>(null, headers);

            final String baseUrl = "http://localhost:8080/plan/remind-to-user";
            URI uri = new URI(baseUrl);
            ResponseEntity<String> result = restTemplate.exchange(uri, HttpMethod.GET, requestEntity, String.class);

            System.out.println(getClass().getName()+".remind: "+result.getBody());

        }catch (Exception e){
            e.printStackTrace();
            System.out.println(getClass().getName()+".remind: "+e.getLocalizedMessage());
        }

    }

}
