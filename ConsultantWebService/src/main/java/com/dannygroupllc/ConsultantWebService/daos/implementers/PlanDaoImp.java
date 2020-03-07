package com.dannygroupllc.ConsultantWebService.daos.implementers;

import com.dannygroupllc.ConsultantWebService.Utility.NotificationSender;
import com.dannygroupllc.ConsultantWebService.daos.interfaces.PlanDao;
import com.dannygroupllc.ConsultantWebService.models.Plan;
import com.dannygroupllc.ConsultantWebService.pojos.Notification;
import com.dannygroupllc.ConsultantWebService.pojos.UserInfo;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.cloud.FirestoreClient;
import com.google.gson.Gson;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import javax.persistence.EntityManager;
import javax.persistence.Query;
import javax.servlet.http.HttpServletRequest;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

@Repository
public class PlanDaoImp implements PlanDao {

    public static String PLAN_DAO_CLASS_NAME = "com.dannygroupllc.ConsultantWebService.daos.implementers.PlanDao";
    public EntityManager entityManager;
    public Gson gson;
    public Firestore db;

    @Autowired
    public PlanDaoImp(EntityManager entityManager) {
        this.entityManager = entityManager;
        gson = new Gson();
        db = FirestoreClient.getFirestore();
    }

    @Override
    public Plan delete(HttpServletRequest httpServletRequest, Plan p) {

        Plan planRes = new Plan();

        try {

            String planSelectSql = "SELECT * FROM plan WHERE id = :id";

            Query planSelectQry = entityManager.createNativeQuery(planSelectSql,Plan.class);
            planSelectQry.setParameter("id", p.getId());
            List<Plan> planList = planSelectQry.getResultList();

            if (planList.size() > 0){

                Plan plan = planList.get(0);

                Notification notification = new Notification();
                notification.setUid(plan.getCusUid());
                notification.setTitle("Booking Request Cancellation");
                notification.setBody("Topic: "+plan.getTopic()+", Start Time: "+plan.getStartTime().toString()
                        + ", End Time: "+plan.getEndTime());

                NotificationSender.send(db,notification);

            }

            String planDeleteSql = "DELETE FROM plan WHERE id = :id";

            Query planDeleteQry = entityManager.createNativeQuery(planDeleteSql);
            planDeleteQry.setParameter("id", p.getId());
            planDeleteQry.executeUpdate();

            planRes.setCode(200);
            planRes.setMsg("Event deleted successfully!");

        } catch (Exception e) {

            System.out.println(PLAN_DAO_CLASS_NAME + "getAllPlanByUser: " + e.getMessage());
            planRes.setCode(404);
            planRes.setMsg(e.getMessage());

        }

        return planRes;

    }

    @Override
    public Plan changeAcceptStatus(HttpServletRequest httpServletRequest, Plan p) {

        Plan planRes = new Plan();

        try {


            String planSelectSql = "SELECT * FROM plan WHERE id = :id";

            Query planSelectQry = entityManager.createNativeQuery(planSelectSql,Plan.class);
            planSelectQry.setParameter("id", p.getId());
            List<Plan> planList = planSelectQry.getResultList();

            if (planList.size() > 0){

                Plan plan = planList.get(0);

                Notification notification = new Notification();
                notification.setUid(plan.getCusUid());
                notification.setTitle("Booking Request Acceptation");
                notification.setBody("Topic: "+plan.getTopic()+", Start Time: "+plan.getStartTime().toString()
                        + ", End Time: "+plan.getEndTime());

                NotificationSender.send(db,notification);

            }

            String planCasSql = "UPDATE \n" +
                    "  plan \n" +
                    "SET\n" +
                    "  is_accept_by_con = b'1' \n" +
                    "WHERE id = :id ";

            Query planCasQry = entityManager.createNativeQuery(planCasSql);
            planCasQry.setParameter("id", p.getId());
            planCasQry.executeUpdate();

            planRes.setCode(200);
            planRes.setMsg("Request accepted successfully!");

        } catch (Exception e) {

            System.out.println(PLAN_DAO_CLASS_NAME + "getAllPlanByUser: " + e.getMessage());
            planRes.setCode(404);
            planRes.setMsg(e.getMessage());

        }

        return planRes;

    }

    @Override
    public List<Plan> getAllPlanByUser(HttpServletRequest httpServletRequest, Plan p) {

        try {

            String planListSql;

            if (p.getUserType() == 2) {

                planListSql = "SELECT \n" +
                        "  p.*, \n" +
                        "  DATE_FORMAT(p.start_time,'%Y-%m-%d %T') AS f_start_time, \n" +
                        "  DATE_FORMAT(p.end_time,'%Y-%m-%d %T') AS f_end_time \n" +
                        "FROM\n" +
                        "  plan AS p\n" +
                        "WHERE con_uid = :conUid AND cus_uid IS NOT NULL\n" +
                        "  AND DATE(start_time) >= CURDATE()"+
                        "  AND is_accept_by_con IS TRUE";

            } else {

                planListSql = "SELECT \n" +
                        "  p.*, \n" +
                        "  DATE_FORMAT(p.start_time,'%Y-%m-%d %T') AS f_start_time, \n" +
                        "  DATE_FORMAT(p.end_time,'%Y-%m-%d %T') AS f_end_time \n" +
                        "FROM\n" +
                        "  plan AS p \n" +
                        "WHERE cus_uid = :cusUid \n" +
                        "  AND DATE(start_time) >= CURDATE()"+
                        "  AND is_accept_by_con IS TRUE";

            }

            System.out.println(PLAN_DAO_CLASS_NAME+".getAllPlanByUser SQL = "+planListSql);

            Query planListQry = entityManager.createNativeQuery(planListSql);

            if (p.getUserType() == 2) {
                planListQry.setParameter("conUid", p.getConUid());
            } else {
                planListQry.setParameter("cusUid", p.getCusUid());
            }

            List<Object[]> results = planListQry.getResultList();
            List<Plan> planList = new ArrayList<>();

            for (Object[] result : results) {

                Boolean isAcceptByCon;
                if (result[8] == null){
                    isAcceptByCon = false;
                }else {
                    isAcceptByCon = (Boolean) result[9];
                }

                Plan np = new Plan();
                np.setId((Integer) result[0]);
                np.setCalenderOid((Integer) result[1]);
                np.setConUid((String) result[2]);
                np.setCreatedDate((Date) result[3]);
                np.setCusUid((String) result[4]);
                np.setEndTime((Date) result[5]);
                np.setFreeMinutesForNewCustomer((Integer) result[6]);
                np.setHourlyRate((Integer) result[7]);
                np.setAcceptByCon((Boolean) result[9]);
                np.setPaymentTransId((String) result[11]);
                np.setStartTime((Date) result[12]);
                np.setTopic((String) result[13]);
                np.setfStartTime((String) result[18]);
                np.setfEndTime((String) result[19]);

                planList.add(np);
            }

            return planList;

        } catch (Exception e) {

            System.out.println(PLAN_DAO_CLASS_NAME + "getAllPlanByUser: " + e.getMessage());
            return new ArrayList<>();

        }

    }

    @Override
    public Plan saveReviewAndRating(HttpServletRequest httpServletRequest, Plan plan) {

        Plan planRes = new Plan();

        try {

            String sql;

            if (plan.cusUid == null){

                sql = "UPDATE \n" +
                        "  plan \n" +
                        "SET\n" +
                        "  con_review = :conReview,\n" +
                        "  con_rating = :conRating \n" +
                        "WHERE id = :id ";

            }else {

                sql = "UPDATE \n" +
                        "  plan \n" +
                        "SET\n" +
                        "  cus_review = :cusReview,\n" +
                        "  cus_rating = :cusRating \n" +
                        "WHERE id = :id ";

            }

            Query planCasQry = entityManager.createNativeQuery(sql);

            if (plan.getCusUid() == null){

                planCasQry.setParameter("conReview", plan.getConReview());
                planCasQry.setParameter("conRating", plan.getConRating());

            }else {

                planCasQry.setParameter("cusReview", plan.getCusReview());
                planCasQry.setParameter("cusRating", plan.getCusRating());

            }

            planCasQry.setParameter("id", plan.getId());
            planCasQry.executeUpdate();

            planRes.setCode(200);
            planRes.setMsg("Review and rating given successfully!");

        } catch (Exception e) {

            System.out.println(PLAN_DAO_CLASS_NAME + "saveReviewAndRating: " + e.getMessage());
            planRes.setCode(404);
            planRes.setMsg(e.getMessage());

        }

        return planRes;
    }

}