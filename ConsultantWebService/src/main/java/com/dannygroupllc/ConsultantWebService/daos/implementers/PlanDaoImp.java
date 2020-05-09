package com.dannygroupllc.ConsultantWebService.daos.implementers;

import com.dannygroupllc.ConsultantWebService.Utility.NotificationSender;
import com.dannygroupllc.ConsultantWebService.daos.interfaces.PlanDao;
import com.dannygroupllc.ConsultantWebService.models.Plan;
import com.dannygroupllc.ConsultantWebService.pojos.Notification;
import com.dannygroupllc.ConsultantWebService.pojos.UserInfo;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import com.google.gson.Gson;
import org.joda.time.DateTime;
import org.joda.time.DateTimeZone;
import org.joda.time.Interval;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;
import javax.persistence.EntityManager;
import javax.persistence.Query;
import javax.servlet.http.HttpServletRequest;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.TimeZone;
import java.util.concurrent.TimeUnit;

@Repository
public class PlanDaoImp implements PlanDao {

    public EntityManager entityManager;
    public Gson gson;
    public SimpleDateFormat sdf;
    public SimpleDateFormat sdf24Hour;

    @Autowired
    public PlanDaoImp(EntityManager entityManager) {
        this.entityManager = entityManager;
        gson = new Gson();
        sdf = new SimpleDateFormat("dd-MM-yyyy hh:mm:ss a");
        sdf24Hour = new SimpleDateFormat("dd-MM-yyyy hh:mm:ss");
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

            e.printStackTrace();
            System.out.println(getClass().getName() + ".delete: " + e.getMessage());
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
                    "        DATE_ADD(CONVERT_TZ(created_date,'UTC',time_zone), INTERVAL 1 DAY),\n" +
                    "        CONVERT_TZ(NOW(),'UTC',time_zone)\n" +
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

            System.out.println(getClass().getName() + ".changeAcceptStatus " + gson.toJson(np));

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

                notification.setStartTime(sdf.format(np.getStartTime()));
                notification.setEndTime(sdf.format(np.getEndTime()));
                NotificationSender.send(notification);

            } else {

                planRes.setCode(404);
                planRes.setMsg(np.getHourDiff() + " Hour & " + np.getMinuteDiff()
                        + " minute passed away, Sorry sir/mam you can't accept the request!");

                System.out.println(getClass().getName() + ".changeAcceptStatus " + planRes.getMsg());

            }

        } catch (Exception e) {

            e.printStackTrace();
            System.out.println(getClass().getName() + ".changeAcceptStatus: " + e.getMessage());
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

            System.out.println(getClass().getName() + ".getAllPlanByUser: TimeZone = " + p.getTimeZone());

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
                        "  DATE_FORMAT(CONVERT_TZ(p.start_time,'UTC',p.time_zone),'%Y-%m-%d %T') AS f_start_time, \n" +
                        "  DATE_FORMAT(CONVERT_TZ(p.end_time,'UTC',p.time_zone),'%Y-%m-%d %T') AS f_end_time, \n" +
                        "  SUBDATE(p.start_time,INTERVAL 30 MINUTE) AS before_start_time \n" +
                        "FROM\n" +
                        "  plan AS p\n" +
                        "WHERE con_uid = :conUid AND cus_uid IS NOT NULL\n" +
                        "  AND DATE(CONVERT_TZ(end_time,'UTC',time_zone)) >= DATE(CONVERT_TZ(NOW(),'UTC',time_zone))" +
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
                        "  DATE_FORMAT(CONVERT_TZ(p.start_time,'UTC',p.time_zone),'%Y-%m-%d %T') AS f_start_time, \n" +
                        "  DATE_FORMAT(CONVERT_TZ(p.end_time,'UTC',p.time_zone),'%Y-%m-%d %T') AS f_end_time, \n" +
                        "  SUBDATE(p.start_time,INTERVAL 30 MINUTE) AS before_start_time \n" +
                        "FROM\n" +
                        "  plan AS p \n" +
                        "WHERE cus_uid = :cusUid \n" +
                        "  AND DATE(CONVERT_TZ(end_time,'UTC',time_zone)) >= DATE(CONVERT_TZ(NOW(),'UTC',time_zone))" +
                        "  AND is_accept_by_con IS TRUE";

            }

            System.out.println(getClass().getName() + ".getAllPlanByUser: SQL = " + planListSql);

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

                System.out.println(getClass().getName() + ".getAllPlanByUser stSubThirtyMin " + stSubThirtyMin);

                // if stSubThirtyMin cross
                // then only add paid plan
                if (curDateTime.after(stSubThirtyMin)) {

                    if (paymentTransId != null) {

                        planList.add(setPlan(result, paymentTransId));

                    }

                    // if not show paid unpaid all
                } else {

                    planList.add(setPlan(result, paymentTransId));

                }

            }

            System.out.println(getClass().getName() + ".getAllPlanByUser: plan List = "+planList.size());

            return planList;

        } catch (Exception e) {

            e.printStackTrace();
            System.out.println(getClass().getName() + ".getAllPlanByUser: " + e.getMessage());
            e.printStackTrace();
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
            if (p.getUserType() == 1) {

                planListSql = ""
                        + "SELECT "
                        + "  IFNULL(p.cus_rating, 0) AS rating, "
                        + "  IFNULL(p.cus_review, 'Not Given') AS review, "
                        + "  DATE_FORMAT(p.end_time, '%Y-%m-%d %T') AS f_end_time "
                        + "FROM "
                        + "  plan AS p "
                        + "WHERE cus_uid = :cusUid "
                        + "  AND are_cus_con_have_chatted IS TRUE "
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
                        + "WHERE con_uid = :conUid "
                        + "  AND are_cus_con_have_chatted IS TRUE "
                        + "  AND DATE(p.end_time) < NOW() ";

            }

            System.out.println(getClass().getName() + ".getReviewAndRating: SQL = " + planListSql);

            Query planListQry = entityManager.createNativeQuery(planListSql);

            if (p.getUserType() == 1) {
                planListQry.setParameter("cusUid", p.getCusUid());
            } else {
                planListQry.setParameter("conUid", p.getConUid());
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

            e.printStackTrace();
            System.out.println(getClass().getName() + ".getReviewAndRating: " + e.getMessage());
            return new ArrayList<>();

        }

    }

    @Override
    public Plan saveReviewAndRating(HttpServletRequest httpServletRequest, Plan plan) {

        Plan planRes = new Plan();

        System.out.println(getClass().getName()+".saveReviewAndRating plan = "+gson.toJson(plan));

        try {

            String sql;

            // customer
            if (plan.getUserType() == 1) {

                sql = "UPDATE \n" +
                        "  plan \n" +
                        "SET\n" +
                        "  con_review = :conReview,\n" +
                        "  con_rating = :conRating \n" +
                        "WHERE id = :id ";

                // consultant
            } else {

                sql = "UPDATE \n" +
                        "  plan \n" +
                        "SET\n" +
                        "  cus_review = :cusReview,\n" +
                        "  cus_rating = :cusRating \n" +
                        "WHERE id = :id ";

            }

            Query planCasQry = entityManager.createNativeQuery(sql);

            if (plan.getUserType() == 1) {

                planCasQry.setParameter("conReview", plan.getConReview());
                planCasQry.setParameter("conRating", plan.getConRating());

            } else {

                planCasQry.setParameter("cusReview", plan.getCusReview());
                planCasQry.setParameter("cusRating", plan.getCusRating());

            }

            planCasQry.setParameter("id", plan.getId());
            planCasQry.executeUpdate();


            // if customer give review and rating
            // then update expert rating in FireBase
            if (plan.getUserType() == 1) {

                updateRating(plan.getConUid(), 2);

            } else {

                updateRating(plan.getCusUid(), 1);

            }

            planRes.setCode(200);
            planRes.setMsg("Review and rating given successfully!");

        } catch (Exception e) {

            e.printStackTrace();
            System.out.println(getClass().getName() + "saveReviewAndRating: " + e.getMessage());
            planRes.setCode(404);
            planRes.setMsg(e.getMessage());

        }

        return planRes;
    }

    private void updateRating(String uid, int userType) {

        // (5 * 252 + 4 * 124 + 3 * 40 + 2 * 29 + 1 * 33) / 478 = 4.11
        String planSelectSql = (userType == 1) ? ""
                + "SELECT "
                + "	SUM(cus_rating = 5) AS five_star, "
                + "	SUM(cus_rating = 4) AS four_star , "
                + "	SUM(cus_rating = 3) AS three_star, "
                + "	SUM(cus_rating = 2) AS two_star, "
                + "	SUM(cus_rating = 1) AS one_star "
                + "FROM "
                + "	plan "
                + "WHERE cus_uid = :uid " : ""
                + "SELECT "
                + "	SUM(con_rating = 5) AS five_star, "
                + "	SUM(con_rating = 4) AS four_star , "
                + "	SUM(con_rating = 3) AS three_star, "
                + "	SUM(con_rating = 2) AS two_star, "
                + "	SUM(con_rating = 1) AS one_star "
                + "FROM "
                + "	plan "
                + "WHERE con_uid = :uid";

        Query planSelectQry = entityManager.createNativeQuery(planSelectSql);
        planSelectQry.setParameter("uid", uid);
        List<Object[]> resultList = planSelectQry.getResultList();

        Integer ttlFiveStar = ((BigDecimal) resultList.get(0)[0]).intValue();
        Integer ttlFourStar = ((BigDecimal) resultList.get(0)[1]).intValue();
        Integer ttlThreeStar = ((BigDecimal) resultList.get(0)[2]).intValue();
        Integer ttlTwoStar = ((BigDecimal) resultList.get(0)[3]).intValue();
        Integer ttlOneStar = ((BigDecimal) resultList.get(0)[4]).intValue();

        System.out.println(getClass().getName()+".updateRating: rating details => ttlFiveStar = "
                +ttlFiveStar+", ttlFourStar = "+ttlFourStar+", ttlThreeStar = "
                +ttlThreeStar+", ttlTwoStar = "+ttlTwoStar+", ttlOneStar = "
                +ttlOneStar);

        Double rating = Double.valueOf((5 * ttlFiveStar + 4 * ttlFourStar + 3 * ttlThreeStar
                + 2 * ttlTwoStar + 1 * ttlOneStar) /
                (ttlFiveStar + ttlFourStar + ttlThreeStar + ttlTwoStar + ttlOneStar));

        System.out.println(getClass().getName() + ".updateRating res = " + rating);

        FirestoreClient.getFirestore()
                .collection("userInfoList")
                .document(uid)
                .update("rating", rating);

    }

    @Override
    public Plan changeAreCusConHaveChattedStatus(HttpServletRequest httpServletRequest, Plan plan) {

        Plan planRes = new Plan();
        System.out.println(getClass().getName() + ".changeAreCusConHaveChattedStatus: plan = " + gson.toJson(plan));

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

            System.out.println(getClass().getName() + ".changeAreCusConHaveChattedStatus : changed [chat st,free min]");
            planRes.setCode(200);
            planRes.setMsg("Customer and consultant chatted status has been changed" +
                    " and free minute's also updated null");

        } catch (Exception e) {

            e.printStackTrace();
            System.out.println(getClass().getName() + ".changeAreCusConHaveChattedStatus : Exception = " + e.getMessage());
            planRes.setCode(404);
            planRes.setMsg("Exception occurred!");

        }

        return planRes;

    }

    @Override
    public Plan checkPaymentStatus(Plan p) {

        Plan planRes = new Plan();
        System.out.println(getClass().getName() + ".checkPaymentStatus: plan = " + gson.toJson(p));

        try {

            String planSelectSql = "SELECT * FROM plan WHERE payment_trans_id IS NULL AND id = :id";

            Query planSelectQry = entityManager.createNativeQuery(planSelectSql, Plan.class);
            planSelectQry.setParameter("id", p.getId());
            List<Plan> planList = planSelectQry.getResultList();

            if (planList.size() > 0) {

                planRes.setCode(404);
                planRes.setMsg("Transaction not complete yet!");
                System.out.println(getClass().getName() + ".checkPaymentStatus : [Transaction not complete yet]");

            } else {

                planRes.setCode(200);
                planRes.setMsg("Transaction successful!");
                System.out.println(getClass().getName() + ".checkPaymentStatus : [Transaction complete]");

            }

        } catch (Exception e) {

            e.printStackTrace();
            System.out.println(getClass().getName() + ".checkPaymentStatus : Exception = " + e.getMessage());
            e.printStackTrace();
            planRes.setCode(404);
            planRes.setMsg("Exception occurred!");

        }

        return planRes;

    }

    @Override
    public Plan remindToUser() {

        Plan plan = new Plan();

        try {

            String chatCancelSql = ""
                    + "SELECT "
                    + "  t.start_time, "
                    + "  t.end_time, "
                    + "  t.st, "
                    + "  t.is_free_min_available, "
                    + "  t.is_payment_complete, "
                    + "  t.cus_uid, "
                    + "  t.con_uid, "
                    + "  t.is_accept_by_con "
                    + "FROM "
                    + "(SELECT "
                    + "  CONVERT_TZ(start_time, 'UTC', time_zone) AS start_time, "
                    + "  CONVERT_TZ(end_time, 'UTC', time_zone) AS end_time, "
                    + "  DATE_SUB(start_time, INTERVAL 28 MINUTE) AS st, "
                    + "  IF(free_minutes_for_new_customer IS NULL,'no','yes') AS is_free_min_available, "
                    + "  IF(payment_trans_id IS NULL,'no','yes') AS is_payment_complete, "
                    + "  cus_uid, "
                    + "  con_uid, "
                    + "  is_accept_by_con "
                    + "FROM "
                    + "  plan) AS t "
                    + "WHERE t.is_accept_by_con IS TRUE AND t.st BETWEEN NOW() "
                    + "  AND DATE_ADD(NOW(), INTERVAL 1 MINUTE)";

            Query chatCancelQry = entityManager.createNativeQuery(chatCancelSql);
            List<Object[]> chatCancelQryList = chatCancelQry.getResultList();

            for (Object[] objects : chatCancelQryList) {

                Plan p = new Plan();
                p.setStartTime((Date) objects[0]);
                p.setEndTime((Date) objects[1]);
                String isFreeMinAvailable = (String) objects[3];
                String isPaymentComplete = (String) objects[4];
                p.setCusUid((String) objects[5]);
                p.setConUid((String) objects[6]);

                if (isFreeMinAvailable.equals("no") && isPaymentComplete.equals("no")) {

                    System.out.println(getClass().getName() + "Chat Session cancel: Plan" + gson.toJson(p));

                    Notification nForCus = new Notification();
                    nForCus.setUid(p.getCusUid());
                    nForCus.setTitle("Chat Session Canceled");
                    nForCus.setBody("You did not make payment. Chat session at "+sdf.format(p.getStartTime())+" is canceled");
                    nForCus.setStartTime(sdf.format(p.getStartTime()));
                    nForCus.setEndTime(sdf.format(p.getEndTime()));

                    NotificationSender.send(nForCus);

                    Notification nForCon = new Notification();
                    nForCon.setUid(p.getConUid());
                    nForCon.setTitle("Chat Session Canceled");
                    nForCon.setBody("Customer did not make payment. Chat session at "+sdf.format(p.getStartTime())+" is canceled");
                    nForCon.setStartTime(sdf.format(p.getStartTime()));
                    nForCon.setEndTime(sdf.format(p.getEndTime()));

                    NotificationSender.send(nForCon);

                }

            }


            String reminderSql = ""
                    + "SELECT "
                    + "	t.start_time, "
                    + "	t.end_time, "
                    + "	t.st, "
                    + "	t.is_free_min_available, "
                    + "	t.is_payment_complete, "
                    + "	t.cus_uid, "
                    + "	t.con_uid, "
                    + "	t.is_accept_by_con "
                    + "FROM "
                    + "(SELECT "
                    + "  CONVERT_TZ(start_time, 'UTC', time_zone) AS start_time, "
                    + "  CONVERT_TZ(end_time, 'UTC', time_zone) AS end_time, "
                    + "  DATE_SUB(start_time, INTERVAL 1 HOUR) AS st, "
                    + "  IF(free_minutes_for_new_customer IS NULL,'no','yes') AS is_free_min_available, "
                    + "  IF(payment_trans_id IS NULL,'no','yes') AS is_payment_complete, "
                    + "  cus_uid, "
                    + "  con_uid, "
                    + "  is_accept_by_con "
                    + "FROM "
                    + "  plan) AS t "
                    + "WHERE t.is_accept_by_con IS TRUE AND t.st BETWEEN NOW() "
                    + "  AND DATE_ADD(NOW(), INTERVAL 1 MINUTE)";

            Query reminderQry = entityManager.createNativeQuery(reminderSql);
            List<Object[]> reminderList = reminderQry.getResultList();

            for (Object[] objects : reminderList) {

                Plan p = new Plan();
                p.setStartTime((Date) objects[0]);
                p.setEndTime((Date) objects[1]);
                String isFreeMinAvailable = (String) objects[3];
                String isPaymentComplete = (String) objects[4];
                p.setCusUid((String) objects[5]);
                p.setConUid((String) objects[6]);

                System.out.println(getClass().getName() + ".remindPlanToUser: Plan" + gson.toJson(p));

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

                if (isFreeMinAvailable.equals("no") && isPaymentComplete.equals("no")) {

                    Notification nForPayment = new Notification();
                    nForPayment.setUid(p.getCusUid());
                    nForPayment.setTitle("Payment Reminder");
                    nForPayment.setBody("You didn't complete your payment for the chat session, which will start on "+sdf.format(p.getStartTime())+", Please complete your payment before 30 minute.");
                    nForPayment.setStartTime(sdf.format(p.getStartTime()));
                    nForPayment.setEndTime(sdf.format(p.getEndTime()));

                    NotificationSender.send(nForPayment);

                }

            }

            updateOnlineStatus();

            plan.setCode(200);
            plan.setMsg("Reminder triggered successfully!");

        } catch (Exception e) {
            e.printStackTrace();
            System.out.println(getClass().getName() + "remindPlanToUser: Exception = " + e.getMessage());
            plan.setCode(404);
            plan.setMsg("Reminder triggered unsuccessful!");
        }

        return plan;

    }

    private void updateOnlineStatus() {

        try{

            CollectionReference cr = FirestoreClient.getFirestore().collection("userInfoList");

            ApiFuture<QuerySnapshot> future = cr.get();
            List<QueryDocumentSnapshot> documents = future.get().getDocuments();
            for (DocumentSnapshot document : documents) {
                UserInfo ui = document.toObject(UserInfo.class);
                sdf.setTimeZone(TimeZone.getTimeZone(ui.getTimeZone()));

                Date lastOnlineAt = sdf.parse(ui.getLastOnlineAt());
                Date  curDate = sdf.parse(sdf.format(new Date()));

                System.out.println(getClass().getName()+".updateOnlineStatus: curDate = "+curDate+" lastOnlineAt = "+lastOnlineAt);

                long duration  = curDate.getTime() - lastOnlineAt.getTime();
                long diffInMinutes = TimeUnit.MILLISECONDS.toMinutes(duration);

                if(diffInMinutes > 2){
                    DocumentReference dr = cr.document(document.getId());
                    dr.update("isOnline",false);
                }

                System.out.println(getClass().getName()+".updateOnlineStatus interval = "+diffInMinutes);

            }

        }catch(Exception e){
            e.printStackTrace();
        }

    }

}

