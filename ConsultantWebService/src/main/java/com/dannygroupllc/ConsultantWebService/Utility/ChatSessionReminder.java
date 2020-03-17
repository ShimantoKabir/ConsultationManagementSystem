package com.dannygroupllc.ConsultantWebService.Utility;

import com.dannygroupllc.ConsultantWebService.models.Plan;
import com.dannygroupllc.ConsultantWebService.pojos.Notification;
import com.google.gson.Gson;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import javax.persistence.EntityManager;
import javax.persistence.Query;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

@Component
public class ChatSessionReminder {

    @Autowired
    private EntityManager entityManager;

    @Scheduled(fixedRate = 5000)
    public void remind() {

        SimpleDateFormat sdf = new SimpleDateFormat("dd-MM-yyyy hh:mm:ss a");
        Gson gson = new Gson();

        try {

            String planSql = "SELECT \n" +
                    "  CONVERT_TZ(start_time, 'UTC', time_zone) AS start_time,\n" +
                    "  CONVERT_TZ(end_time, 'UTC', time_zone) AS end_time, \n" +
                    "  cus_uid, \n" +
                    "  con_uid \n" +
                    "FROM\n" +
                    "  plan \n" +
                    "WHERE start_time BETWEEN NOW() \n" +
                    "  AND DATE_ADD(NOW(), INTERVAL 5 MINUTE)";

            Query authQuery = entityManager.createNativeQuery(planSql);
            List<Object[]> resultList = authQuery.getResultList();

            for (int i = 0; i < resultList.size(); i++) {

                Plan p = new Plan();
                p.setStartTime((Date) resultList.get(i)[0]);
                p.setEndTime((Date) resultList.get(i)[1]);
                p.setCusUid((String) resultList.get(i)[2]);
                p.setConUid((String) resultList.get(i)[3]);

                System.out.println(getClass().getName()+".remind: Plan"+gson.toJson(p));

                Notification nForCus = new Notification();
                nForCus.setUid(p.getCusUid());
                nForCus.setTitle("Reminder");
                nForCus.setBody("You have a chat session which will start Time: " + sdf.format(p.getStartTime())
                        + " and end time: " + sdf.format(p.getEndTime()));
                nForCus.setStartTime(sdf.format(p.getStartTime()));
                nForCus.setEndTime(sdf.format(p.getEndTime()));

                NotificationSender.send(nForCus);

                Notification nForCon = new Notification();
                nForCon.setUid(p.getConUid());
                nForCon.setTitle("Reminder");
                nForCon.setBody("You have a chat session which will start Time: " + sdf.format(p.getStartTime())
                        + ", End Time: " + sdf.format(p.getEndTime()));
                nForCon.setStartTime(sdf.format(p.getStartTime()));
                nForCon.setEndTime(sdf.format(p.getEndTime()));

                NotificationSender.send(nForCon);

            }

            System.out.println(getClass().getName()+".remind: planList"+gson.toJson(resultList));

        }catch (Exception e){
            System.out.println(getClass().getName()+"remind: Exception = "+e.getMessage());
        }

    }

}
