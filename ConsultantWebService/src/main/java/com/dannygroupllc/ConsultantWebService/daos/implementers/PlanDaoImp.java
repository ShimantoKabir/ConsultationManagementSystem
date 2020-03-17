package com.dannygroupllc.ConsultantWebService.daos.implementers;

import com.dannygroupllc.ConsultantWebService.Utility.NotificationSender;
import com.dannygroupllc.ConsultantWebService.daos.interfaces.PlanDao;
import com.dannygroupllc.ConsultantWebService.models.Plan;
import com.dannygroupllc.ConsultantWebService.pojos.Notification;
import com.google.firebase.cloud.FirestoreClient;
import com.google.gson.Gson;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import javax.persistence.EntityManager;
import javax.persistence.Query;
import javax.servlet.http.HttpServletRequest;
import java.math.BigInteger;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

@Repository
public class PlanDaoImp implements PlanDao {

    public EntityManager entityManager;
    public Gson gson;
    public SimpleDateFormat sdf;

    @Autowired
    public PlanDaoImp(EntityManager entityManager) {
        this.entityManager = entityManager;
        gson = new Gson();
        sdf = new SimpleDateFormat("dd-MM-yyyy hh:mm:ss a");
    }

    @Override
    public Plan delete(HttpServletRequest httpServletRequest, Plan p) {

        Plan planRes = new Plan();

        try {

            String planSelectSql = "SELECT * FROM plan WHERE id = :id";

            Query planSelectQry = entityManager.createNativeQuery(planSelectSql, Plan.class);
            planSelectQry.setParameter("id", p.getId());
            List<Plan> planList = planSelectQry.getResultList();

            if (planList.size() > 0) {

                Plan plan = planList.get(0);

                Notification notification = new Notification();
                notification.setUid(plan.getCusUid());
                notification.setTitle("Booking Request Cancellation");
                notification.setBody("Topic: " + plan.getTopic() + ", Start Time: " + plan.getStartTime().toString()
                        + ", End Time: " + plan.getEndTime());

                NotificationSender.send(notification);

            }

            String planDeleteSql = "DELETE FROM plan WHERE id = :id";

            Query planDeleteQry = entityManager.createNativeQuery(planDeleteSql);
            planDeleteQry.setParameter("id", p.getId());
            planDeleteQry.executeUpdate();

            planRes.setCode(200);
            planRes.setMsg("Event deleted successfully!");

        } catch (Exception e) {

            System.out.println(getClass().getName()+".delete: " + e.getMessage());
            planRes.setCode(404);
            planRes.setMsg(e.getMessage());

        }

        return planRes;

    }

    @Override
    public Plan changeAcceptStatus(HttpServletRequest httpServletRequest, Plan p) {

        Plan planRes = new Plan();

        try {

            String planSelectSql = "SELECT \n" +
                    "  p.cus_uid AS cus_uid,\n" +
                    "  p.topic AS topic,\n" +
                    "  p.start_time AS start_time,\n" +
                    "  p.end_time AS end_time,\n" +
                    "  IF(p.time_diff < '00:00:00', 'y', 'n') AS is_booking_acceptance_time_passed,\n" +
                    "  HOUR(p.time_diff) AS hour_diff,\n" +
                    "  MINUTE(p.time_diff) AS minute_diff \n" +
                    "FROM\n" +
                    "  (SELECT \n" +
                    "    *,\n" +
                    "    CAST(\n" +
                    "      TIMEDIFF(\n" +
                    "        DATE_ADD(created_date, INTERVAL 1 DAY),\n" +
                    "        NOW()\n" +
                    "      ) AS CHAR\n" +
                    "    ) AS time_diff \n" +
                    "  FROM\n" +
                    "    plan \n" +
                    "  WHERE id = :id) AS p ";

            Query planSelectQry = entityManager.createNativeQuery(planSelectSql);
            planSelectQry.setParameter("id", p.getId());
            List<Object[]> results = planSelectQry.getResultList();

            Plan np = new Plan();

            if (results.size() > 0) {

                np.setCusUid((String) results.get(0)[0]);
                np.setTopic((String) results.get(0)[1]);
                np.setStartTime((Date) results.get(0)[2]);
                np.setEndTime((Date) results.get(0)[3]);
                np.setIsBookingAcceptanceTimePassed((String) results.get(0)[4]);
                np.setHourDiff(((BigInteger) results.get(0)[5]).intValue());
                np.setMinuteDiff(((BigInteger) results.get(0)[6]).intValue());

            }

            System.out.println(getClass().getName()+".changeAcceptStatus "+gson.toJson(np));

            if (np.getIsBookingAcceptanceTimePassed().equalsIgnoreCase("n")) {

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

                Notification notification = new Notification();
                notification.setUid(np.getCusUid());
                notification.setTitle("Booking Request Acceptation");
                notification.setBody("Topic: " + np.getTopic()
                        + ", Start Time: " + sdf.format(np.getStartTime())
                        + ", End Time: " + sdf.format(np.getEndTime()));

                NotificationSender.send(notification);

            }else {

                planRes.setCode(404);
                planRes.setMsg(np.getHourDiff()+" Hour & "+np.getMinuteDiff()
                        +" minute passed away, Sorry sir/mam you can't accept the request cause!");

                System.out.println(getClass().getName()+".changeAcceptStatus "+planRes.getMsg());

            }

        } catch (Exception e) {

            System.out.println(getClass().getName()+".getAllPlanByUser: " + e.getMessage());
            planRes.setCode(404);
            planRes.setMsg(e.getMessage());

        }

        return planRes;

    }

    @Override
    public List<Plan> getAllPlanByUser(HttpServletRequest httpServletRequest, Plan p) {

        try {

            Date curDateTime = new Date();

            String planListSql;
            System.out.println(getClass().getName() + ".getAllPlanByUser : TimeZone = " + p.getTimeZone());

            // plan consultant
            if (p.getUserType() == 2) {

                planListSql = "SELECT \n" +
                        "  p.id AS id, \n" +
                        "  p.calender_oid AS calender_oid, \n" +
                        "  p.con_uid AS con_uid, \n" +
                        "  p.cus_uid AS cus_uid, \n" +
                        "  p.start_time AS start_time, \n" +
                        "  p.end_time AS end_time, \n" +
                        "  p.free_minutes_for_new_customer AS free_minutes_for_new_customer, \n" +
                        "  p.hourly_rate AS hourly_rate, \n" +
                        "  p.is_accept_by_con AS is_accept_by_con, \n" +
                        "  IF(p.free_minutes_for_new_customer IS NOT NULL,'complete',p.payment_trans_id) AS payment_trans_id, \n" +
                        "  p.topic AS topic, \n" +
                        "  p.created_date AS created_date, \n" +
                        "  DATE_FORMAT(CONVERT_TZ(p.start_time,'UTC', '" + p.getTimeZone() + "'),'%Y-%m-%d %T') AS f_start_time, \n" +
                        "  DATE_FORMAT(CONVERT_TZ(p.end_time,'UTC', '" + p.getTimeZone() + "'),'%Y-%m-%d %T') AS f_end_time \n" +
                        "FROM\n" +
                        "  plan AS p\n" +
                        "WHERE con_uid = :conUid AND cus_uid IS NOT NULL\n" +
                        "  AND DATE(start_time) >= CURDATE()" +
                        "  AND is_accept_by_con IS TRUE";

                // plan for customer
            } else {

                planListSql = "SELECT \n" +
                        "  p.id AS id, \n" +
                        "  p.calender_oid AS calender_oid, \n" +
                        "  p.con_uid AS con_uid, \n" +
                        "  p.cus_uid AS cus_uid, \n" +
                        "  p.start_time AS start_time, \n" +
                        "  p.end_time AS end_time, \n" +
                        "  p.free_minutes_for_new_customer AS free_minutes_for_new_customer, \n" +
                        "  p.hourly_rate AS hourly_rate, \n" +
                        "  p.is_accept_by_con AS is_accept_by_con, \n" +
                        "  IF(p.free_minutes_for_new_customer IS NOT NULL,'complete',p.payment_trans_id) AS payment_trans_id, \n" +
                        "  p.topic AS topic, \n" +
                        "  p.created_date AS created_date, \n" +
                        "  DATE_FORMAT(CONVERT_TZ(p.start_time,'UTC', '" + p.getTimeZone() + "'),'%Y-%m-%d %T') AS f_start_time, \n" +
                        "  DATE_FORMAT(CONVERT_TZ(p.end_time,'UTC', '" + p.getTimeZone() + "'),'%Y-%m-%d %T') AS f_end_time, \n" +
                        "  SUBDATE(p.start_time,INTERVAL 30 MINUTE) AS before_start_time \n" +
                        "FROM\n" +
                        "  plan AS p \n" +
                        "WHERE cus_uid = :cusUid \n" +
                        "  AND DATE(start_time) >= CURDATE()" +
                        "  AND is_accept_by_con IS TRUE";

            }

            System.out.println(getClass().getName()+".getAllPlanByUser: SQL = " + planListSql);

            Query planListQry = entityManager.createNativeQuery(planListSql);

            if (p.getUserType() == 2) {
                planListQry.setParameter("conUid", p.getConUid());
            } else {
                planListQry.setParameter("cusUid", p.getCusUid());
            }

            List<Object[]> results = planListQry.getResultList();
            List<Plan> planList = new ArrayList<>();

            for (Object[] result : results) {

                // start time sub 30 min
                Date stSubThirtyMin = (Date) result[14];
                String paymentTransId = (String) result[9];

                // example : cur date time 7.00 | (start_date_time (7.50) - 30 min ) = 7.20
                // if current date time after start time sub 30 min

                System.out.println(getClass().getName()+".getAllPlanByUser stSubThirtyMin "+stSubThirtyMin);

                // if stSubThirtyMin cross
                // then only add paid plan
                if (curDateTime.after(stSubThirtyMin)) {

                    if (paymentTransId != null){

                        planList.add(setPlan(result,paymentTransId));

                    }

                    // if not show paid unpaid all
                }else {

                    planList.add(setPlan(result,paymentTransId));

                }


            }

            return planList;

        } catch (Exception e) {

            System.out.println(getClass().getName()+ ".getAllPlanByUser: " + e.getMessage());
            return new ArrayList<>();

        }

    }

    private Plan setPlan(Object[] result, String paymentTransId) {

        Plan np = new Plan();

        np.setId((Integer) result[0]);
        np.setCalenderOid((Integer) result[1]);
        np.setConUid((String) result[2]);
        np.setCusUid((String) result[3]);
        np.setStartTime((Date) result[4]);
        np.setEndTime((Date) result[5]);
        np.setFreeMinutesForNewCustomer((Integer) result[6]);
        np.setHourlyRate((Integer) result[7]);
        np.setAcceptByCon((Boolean) result[8]);
        np.setPaymentTransId(paymentTransId);
        np.setTopic((String) result[10]);
        np.setCreatedDate((Date) result[11]);
        np.setfStartTime((String) result[12]);
        np.setfEndTime((String) result[13]);

        return np;

    }

    @Override
    public List<Plan> getReviewAndRating(HttpServletRequest httpServletRequest, Plan p) {

        try {

            String planListSql;

            // consultant
            if (p.getUserType() == 2) {

                planListSql = ""
                        + "SELECT "
                        + "  IFNULL(p.cus_rating, 0) AS rating, "
                        + "  IFNULL(p.cus_review, 'Not Given') AS review, "
                        + "  DATE_FORMAT(p.end_time, '%Y-%m-%d %T') AS f_end_time "
                        + "FROM "
                        + "  plan AS p "
                        + "WHERE con_uid = :conUid "
                        + "  AND DATE(p.end_time) < NOW() ";

                // customer
            } else {

                planListSql = ""
                        + "SELECT "
                        + "  IFNULL(p.con_rating, 0) AS rating, "
                        + "  IFNULL(p.con_review, 'Not Given') AS review, "
                        + "  DATE_FORMAT(p.end_time, '%Y-%m-%d %T') AS f_end_time "
                        + "FROM "
                        + "  plan AS p "
                        + "WHERE cus_uid = :cusUid "
                        + "  AND DATE(p.end_time) < NOW() ";

            }

            System.out.println(getClass().getName()+".getReviewAndRating: SQL = " + planListSql);

            Query planListQry = entityManager.createNativeQuery(planListSql);

            if (p.getUserType() == 2) {
                planListQry.setParameter("conUid", p.getConUid());
            } else {
                planListQry.setParameter("cusUid", p.getCusUid());
            }

            List<Object[]> results = planListQry.getResultList();
            List<Plan> planList = new ArrayList<>();

            for (Object[] result : results) {

                Plan np = new Plan();
                np.setRating(((BigInteger) result[0]).intValue());
                np.setReview((String) result[1]);
                np.setfEndTime((String) result[2]);

                planList.add(np);
            }

            return planList;

        } catch (Exception e) {

            System.out.println(getClass().getName()+".getReviewAndRating: " + e.getMessage());
            return new ArrayList<>();

        }

    }

    @Override
    public Plan saveReviewAndRating(HttpServletRequest httpServletRequest, Plan plan) {

        Plan planRes = new Plan();

        try {

            String sql;

            if (plan.cusUid == null) {

                sql = "UPDATE \n" +
                        "  plan \n" +
                        "SET\n" +
                        "  con_review = :conReview,\n" +
                        "  con_rating = :conRating \n" +
                        "WHERE id = :id ";

            } else {

                sql = "UPDATE \n" +
                        "  plan \n" +
                        "SET\n" +
                        "  cus_review = :cusReview,\n" +
                        "  cus_rating = :cusRating \n" +
                        "WHERE id = :id ";

            }

            Query planCasQry = entityManager.createNativeQuery(sql);

            if (plan.getCusUid() == null) {

                planCasQry.setParameter("conReview", plan.getConReview());
                planCasQry.setParameter("conRating", plan.getConRating());

            } else {

                planCasQry.setParameter("cusReview", plan.getCusReview());
                planCasQry.setParameter("cusRating", plan.getCusRating());

            }

            planCasQry.setParameter("id", plan.getId());
            planCasQry.executeUpdate();


            // update rating in fireBase database
            // consultant
            if (plan.getCusUid() == null) {

                updateRating(plan.getConUid(), 2);

                // customer
            } else {

                updateRating(plan.getConUid(), 1);

            }

            planRes.setCode(200);
            planRes.setMsg("Review and rating given successfully!");

        } catch (Exception e) {

            System.out.println(getClass().getName()+"saveReviewAndRating: " + e.getMessage());
            planRes.setCode(404);
            planRes.setMsg(e.getMessage());

        }

        return planRes;
    }

    private void updateRating(String uid, int userType) {


        String planSelectSql = "SELECT * FROM plan WHERE id = :id";

        Query planSelectQry = entityManager.createNativeQuery(planSelectSql, Plan.class);
        planSelectQry.setParameter("id", uid);
        List<Plan> planList = planSelectQry.getResultList();

        int totalRating = 0;
        int gotRating = 0;


        for (int i = 0; i < planList.size(); i++) {

            // 1 = customer, 2 = consultant
            if (userType == 1 && planList.get(i).getCusRating() != null) {

                gotRating = gotRating + planList.get(i).getCusRating();

            } else {

                gotRating = gotRating + planList.get(i).getConRating();

            }

            totalRating = totalRating + 5;

        }

        totalRating = totalRating == 0 ? 1 : totalRating;

        double res = (gotRating / totalRating) * 100;

        FirestoreClient.getFirestore()
                .collection("userInfoList")
                .document(uid)
                .update("rating", res);

    }

    @Override
    public Plan changeAreCusConHaveChattedStatus(HttpServletRequest httpServletRequest, Plan plan) {

        Plan planRes = new Plan();
        System.out.println(getClass().getName()+".changeAreCusConHaveChattedStatus: plan = "+gson.toJson(plan));

        try {

            String changeCusConChatStatusSql = "UPDATE \n" +
                    "  plan \n" +
                    "SET\n" +
                    "  are_cus_con_have_chatted = TRUE\n" +
                    "WHERE id = :id";

            Query changeCusConChatStatusQry = entityManager.createNativeQuery(changeCusConChatStatusSql);
            changeCusConChatStatusQry.setParameter("id", plan.getId());
            changeCusConChatStatusQry.executeUpdate();

            String changeFreeMinutesSql = "UPDATE \n" +
                    "  plan \n" +
                    "SET \n" +
                    "  free_minutes_for_new_customer = NULL \n" +
                    "WHERE cus_uid = :cusUid \n" +
                    "   AND con_uid = :conUid \n" +
                    "   AND free_minutes_for_new_customer IS NOT NULL \n";

            Query changeFreeMinutesQry = entityManager.createNativeQuery(changeFreeMinutesSql);
            changeFreeMinutesQry.setParameter("cusUid", plan.getCusUid());
            changeFreeMinutesQry.setParameter("conUid", plan.getConUid());
            changeFreeMinutesQry.executeUpdate();

            System.out.println(getClass().getName()+".changeAreCusConHaveChattedStatus : changed [chat st,free min]");
            planRes.setCode(200);
            planRes.setMsg("Customer and consultant chatted status has been changed" +
                    " and free minute's also updated null");

        } catch (Exception e) {

            System.out.println(getClass().getName()+".changeAreCusConHaveChattedStatus : Exception = "+e.getMessage());
            planRes.setCode(404);
            planRes.setMsg("Exception occurred!");

        }

        return planRes;

    }

}
