package com.dannygroupllc.ConsultantWebService.daos.implementers;

import com.dannygroupllc.ConsultantWebService.daos.interfaces.CalendarDao;
import com.dannygroupllc.ConsultantWebService.models.Calendar;
import com.dannygroupllc.ConsultantWebService.models.Plan;
import com.dannygroupllc.ConsultantWebService.pojos.Notification;
import com.dannygroupllc.ConsultantWebService.pojos.UserInfo;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.firebase.cloud.FirestoreClient;
import com.google.gson.Gson;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;
import javax.persistence.EntityManager;
import javax.persistence.Query;
import javax.servlet.http.HttpServletRequest;
import java.math.BigInteger;
import java.util.Date;
import java.util.List;
import java.util.UUID;

@Repository
public class CalendarDaoImp implements CalendarDao {

    public static String CLASS_NAME = "com.dannygroupllc.ConsultantWebService.daos.implementers.CalendarDao";
    public EntityManager entityManager;
    public Gson gson;
    public Firestore db;

    @Autowired
    public CalendarDaoImp(EntityManager entityManager) {
        this.entityManager = entityManager;
        gson = new Gson();
        db = FirestoreClient.getFirestore();
    }

    @Override
    public Calendar createEvent(HttpServletRequest httpServletRequest, Calendar c) {

        Calendar calendarRes = new Calendar();

        try {

            Date curDateTime = new Date();

            if (curDateTime.before(c.getPlan().getStartTime())){

                String calendarSql = "SELECT \n" +
                        "  * \n" +
                        "FROM\n" +
                        "  calendar \n" +
                        "WHERE con_uid = :conUid \n" +
                        "  AND calendar_date = :calendarDate";

                Query dateExistQuery = entityManager.createNativeQuery(calendarSql,Calendar.class);
                dateExistQuery.setParameter("conUid",c.getConUid());
                dateExistQuery.setParameter("calendarDate",c.getCalendarDate());

                List<Calendar> calendarList = dateExistQuery.getResultList();

                Integer calOid;

                if (calendarList.size() > 0){

                    calOid = calendarList.get(0).getoId();

                }else {

                    String maxOidSql = "SELECT \n" +
                            "  IFNULL(MAX(o_id), 100) + 1 AS o_id \n" +
                            "FROM\n" +
                            "   calendar";

                    BigInteger maxOid = (BigInteger) entityManager
                            .createNativeQuery(maxOidSql)
                            .getResultList()
                            .get(0);

                    calOid = maxOid.intValue();

                }

                // check is the event need to create for customer or consultant
                Plan p = c.getPlan();

                // event should be created for consultant
                if (p.getCusUid() == null){

                    // check event over lap
                    Plan planOverLapCheckingData = new Plan();
                    planOverLapCheckingData.setCalendarDate(c.getCalendarDate());
                    planOverLapCheckingData.setStartTime(p.getStartTime());
                    planOverLapCheckingData.setEndTime(p.getEndTime());
                    planOverLapCheckingData.setConUid(c.getConUid());

                    boolean isAnyOverLapFound = checkEventOverLap(planOverLapCheckingData);

                    if (isAnyOverLapFound){

                        calendarRes.setCode(404);
                        calendarRes.setMsg("Time over lapping, please change... !");

                    }else {

                        if (calendarList.size() == 0){

                            Calendar calendar = new Calendar();
                            calendar.setConUid(c.getConUid());
                            calendar.setoId(calOid);
                            calendar.setCalendarDate(c.getCalendarDate());
                            calendar.setIp(httpServletRequest.getRemoteAddr());
                            calendar.setModifiedBy(c.getConUid());
                            entityManager.persist(calendar);

                        }

                        Plan plan = new Plan();
                        plan.setCalenderOid(calOid);
                        plan.setConUid(c.getConUid());
                        plan.setEndTime(p.getEndTime());
                        plan.setIp(httpServletRequest.getRemoteAddr());
                        plan.setModifiedBy(c.getConUid());
                        plan.setStartTime(p.getStartTime());
                        plan.setTopic(p.getTopic());
                        entityManager.persist(plan);

                        calendarRes.setCode(200);
                        calendarRes.setMsg("Event created successfully!");

                    }

                    // event should be created for customer
                    // also send notification to consultant
                }else {

                    // check if this customer have an event with this consultant before
                    String havingPlanBeforeSql = "SELECT \n" +
                            "  * \n" +
                            "FROM\n" +
                            "  plan \n" +
                            "WHERE con_uid = :conUid \n" +
                            "  AND cus_uid = :cusUid ";

                    Query havingPlanBeforeQry = entityManager.createNativeQuery(havingPlanBeforeSql,Plan.class);
                    havingPlanBeforeQry.setParameter("conUid",p.getConUid());
                    havingPlanBeforeQry.setParameter("cusUid",p.getCusUid());

                    List<Plan> planList = havingPlanBeforeQry.getResultList();

                    Integer freeMinutesForNewCustomer = null;

                    if (planList.size() == 0){

                        System.out.println(CLASS_NAME+".createEvent: Free minutes available, Free minute = "+p.getFreeMinutesForNewCustomer());
                        // free second available so find free minute
                        freeMinutesForNewCustomer = p.getFreeMinutesForNewCustomer();

                    }

                    // check event over lap
                    Plan planOverLapCheckingData = new Plan();
                    planOverLapCheckingData.setCalendarDate(c.getCalendarDate());
                    planOverLapCheckingData.setStartTime(p.getStartTime());
                    planOverLapCheckingData.setEndTime(p.getEndTime());
                    planOverLapCheckingData.setConUid(c.getConUid());

                    boolean isAnyOverLapFound = checkEventOverLap(planOverLapCheckingData);

                    if (isAnyOverLapFound){

                        calendarRes.setCode(404);
                        calendarRes.setMsg("Time over lapping, please change... !");

                    }else {

                        if (calendarList.size() == 0){

                            Calendar calendar = new Calendar();
                            calendar.setConUid(c.getConUid());
                            calendar.setoId(calOid);
                            calendar.setCalendarDate(c.getCalendarDate());
                            calendar.setIp(httpServletRequest.getRemoteAddr());
                            calendar.setModifiedBy(p.getCusUid());
                            entityManager.persist(calendar);

                        }

                        Plan plan = new Plan();
                        plan.setCalenderOid(calOid);
                        plan.setConUid(c.getConUid());
                        plan.setCusUid(p.getCusUid());
                        plan.setEndTime(p.getEndTime());
                        plan.setIp(httpServletRequest.getRemoteAddr());
                        plan.setModifiedBy(p.getCusUid());
                        plan.setStartTime(p.getStartTime());
                        plan.setFreeMinutesForNewCustomer(freeMinutesForNewCustomer);
                        plan.setAcceptByCon(false);
                        plan.setHourlyRate(p.getHourlyRate());
                        plan.setTopic(p.getTopic());
                        entityManager.persist(plan);


                        DocumentReference dr = db.collection("userInfoList").document(c.getConUid());
                        ApiFuture<DocumentSnapshot> future = dr.get();

                        DocumentSnapshot document = future.get();
                        if (document.exists()) {

                            UserInfo userInfo = document.toObject(UserInfo.class);

                            Notification notification = new Notification();
                            notification.setFcmRegistrationToken(userInfo.getFcmRegistrationToken());
                            notification.setUid(c.getConUid());
                            notification.setSeen(false);
                            notification.setTitle("Booking Request");
                            notification.setBody("Topic: "+p.getTopic()+", Start Time: "+p.getStartTime().toString()
                                    + ", End Time: "+p.getEndTime());

                            db.collection("notificationList").add(notification);

                        } else {
                            System.out.println(getClass().getName()+"No userInfo found!");
                        }

                        calendarRes.setCode(200);
                        calendarRes.setMsg("Event created successfully!");

                    }

                }

            }else {

                calendarRes.setCode(404);
                calendarRes.setMsg("You can't create an event in past date time!");

            }

        }catch (Exception e){

            System.out.println("com.dannygroupllc.ConsultantWebService.daos.implementers.createEvent: "+e.getMessage());
            calendarRes.setCode(404);
            calendarRes.setMsg(e.getMessage());

        }

        return calendarRes;

    }

    private boolean checkEventOverLap(Plan p) {

        String checkOverLapSql1 = "SELECT \n" +
                "  * \n" +
                "FROM\n" +
                "  (SELECT \n" +
                "    p.start_time AS start_time,\n" +
                "    p.end_time AS end_time,\n" +
                "    :newStartTime AS new_start_time \n" +
                "  FROM\n" +
                "    calendar AS c \n" +
                "    INNER JOIN plan AS p \n" +
                "      ON p.calender_oid = c.o_id \n" +
                "      AND c.con_uid = :conUid \n" +
                "      AND c.calendar_date = :calendarDate) AS t \n" +
                "WHERE t.new_start_time BETWEEN t.start_time \n" +
                "  AND t.end_time";

        Query overLapQry1 = entityManager.createNativeQuery(checkOverLapSql1);
        overLapQry1.setParameter("conUid",p.getConUid());
        overLapQry1.setParameter("newStartTime",p.getStartTime());
        overLapQry1.setParameter("calendarDate",p.getCalendarDate());

        String checkOverLapSql2 = "SELECT \n" +
                "  * \n" +
                "FROM\n" +
                "  (SELECT \n" +
                "    p.start_time AS start_time,\n" +
                "    p.end_time AS end_time,\n" +
                "    :newEndTime AS new_start_time \n" +
                "  FROM\n" +
                "    calendar AS c \n" +
                "    INNER JOIN plan AS p \n" +
                "      ON p.calender_oid = c.o_id \n" +
                "      AND c.con_uid = :conUid \n" +
                "      AND c.calendar_date = :calendarDate) AS t \n" +
                "WHERE t.new_start_time BETWEEN t.start_time \n" +
                "  AND t.end_time ";

        Query overLapQry2 = entityManager.createNativeQuery(checkOverLapSql2);
        overLapQry2.setParameter("conUid",p.getConUid());
        overLapQry2.setParameter("newEndTime",p.getEndTime());
        overLapQry2.setParameter("calendarDate",p.getCalendarDate());

        boolean isAnyOverLapFound = false;

        if (overLapQry1.getResultList().size() >0){

            isAnyOverLapFound = true;

        }

        if (overLapQry2.getResultList().size() >0){

            isAnyOverLapFound = true;

        }

        return isAnyOverLapFound;

    }

}
