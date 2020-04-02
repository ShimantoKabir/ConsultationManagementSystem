package com.dannygroupllc.ConsultantWebService.controllers;

import com.dannygroupllc.ConsultantWebService.pojos.Response;
import com.dannygroupllc.ConsultantWebService.pojos.UserInfo;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.firebase.cloud.FirestoreClient;
import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.hibernate.Transaction;
import org.hibernate.query.Query;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.persistence.EntityManagerFactory;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/app")
public class TestCtl {

    @Autowired
    private EntityManagerFactory entityManagerFactory;

    @GetMapping("/test")
    public Response check() {

        Response res = new Response();

        try {

            Firestore db = FirestoreClient.getFirestore();
            ApiFuture<QuerySnapshot> query = db.collection("userInfoList").get();

            QuerySnapshot querySnapshot = query.get();
            List<QueryDocumentSnapshot> documents = querySnapshot.getDocuments();

            List<UserInfo> userInfoList = new ArrayList<>();

            for (QueryDocumentSnapshot document : documents) {
                UserInfo userInfo = new UserInfo();
                userInfo.setUid(document.getString("uid"));
                userInfo.setDisplayName(document.getString("displayName"));
                userInfoList.add(userInfo);
            }

            SessionFactory sessionFactory = entityManagerFactory.unwrap(SessionFactory.class);
            Session session = null;
            Transaction tx;

            try {

                session = sessionFactory.openSession();
                tx = session.beginTransaction();

                String dateTimeSql = "SELECT NOW() AS currentDateTime";
                Query dateTimeQry = session.createNativeQuery(dateTimeSql);

                List<Object[]> results = dateTimeQry.getResultList();

                String currentDateTime = String.valueOf(results.get(0));

                res.setMysqlConnectionStatus("OK");
                res.setDatabaseCurrentDateTime(currentDateTime);

                String planSelectSql = ""
                        + "SELECT "
                        + "	SUM(cus_rating = 5) AS five_star, "
                        + "	SUM(cus_rating = 4) AS four_star , "
                        + "	SUM(cus_rating = 3) AS three_star, "
                        + "	SUM(cus_rating = 2) AS two_star, "
                        + "	SUM(cus_rating = 1) AS one_star "
                        + "FROM "
                        + "	plan ";

                Query planSelectQry = session.createNativeQuery(planSelectSql);
                List<Object[]> resultList = planSelectQry.getResultList();

                Integer ttlFiveStar = ((BigDecimal) resultList.get(0)[0]).intValue();
                Integer ttlFourStar = ((BigDecimal) resultList.get(0)[1]).intValue();
                Integer ttlThreeStar = ((BigDecimal) resultList.get(0)[2]).intValue();
                Integer ttlTwoStar = ((BigDecimal) resultList.get(0)[3]).intValue();
                Integer ttlOneStar = ((BigDecimal) resultList.get(0)[4]).intValue();

                Double rat = Double.valueOf((5 * ttlFiveStar + 4 * ttlFourStar + 3 * ttlThreeStar + 2 * ttlTwoStar + 1 * ttlOneStar) /
                        (ttlFiveStar + ttlFourStar + ttlThreeStar + ttlTwoStar + ttlOneStar));

                System.out.println("RES = "+rat);

                tx.commit();

            } catch (Exception e) {

                e.printStackTrace();
                res.setMysqlConnectionStatus(e.getMessage());
                System.out.println(getClass().getName() + ".check " + e.getMessage());

            } finally {
                if (session != null) {
                    session.close();
                }
            }

            res.setUserInfoList(userInfoList);
            res.setFireBaseConnectionStatus("OK");
            res.setCode(200);
            res.setMsg("Found user info list!");

        } catch (Exception e) {

            res.setUserInfoList(new ArrayList<>());
            res.setCode(200);
            res.setMsg("No user info found!");

        }


        return res;

    }

}
