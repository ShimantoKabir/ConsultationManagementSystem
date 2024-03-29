package com.dannygroupllc.ConsultantWebService.daos.implementers;

import com.dannygroupllc.ConsultantWebService.Utility.NotificationSender;
import com.dannygroupllc.ConsultantWebService.daos.interfaces.CalendarDao;
import com.dannygroupllc.ConsultantWebService.models.Calendar;
import com.dannygroupllc.ConsultantWebService.models.Plan;
import com.dannygroupllc.ConsultantWebService.pojos.Notification;
import com.dannygroupllc.ConsultantWebService.pojos.Response;
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
import java.util.GregorianCalendar;
import java.util.List;

@Repository
public class CalendarDaoImp implements CalendarDao {

    public EntityManager entityManager;
    public Gson gson;
    public SimpleDateFormat sdf;
    public GregorianCalendar gc;

    @Autowired
    public CalendarDaoImp(EntityManager entityManager) {
        this.entityManager = entityManager;
        gson = new Gson();
        sdf = new SimpleDateFormat("dd-MM-yyyy hh:mm:ss a");
        gc = new GregorianCalendar();
    }

    @Override
    public Calendar createEvent(HttpServletRequest httpServletRequest, Calendar c) {

        Calendar calendarRes = new Calendar();

        try {

            Date curDateTime = sdf.parse(c.getCurrentDateTime());
            Date startDateTime = sdf.parse(c.getPlan().getfStartTime());
            System.out.println(getClass().getName()+".createEvent cur date time = "+curDateTime);

            // if current date time before plan start time
            if (curDateTime.before(startDateTime)) {

                String calendarSql = "SELECT \n" +
                        "  * \n" +
                        "FROM\n" +
                        "  calendar \n" +
                        "WHERE con_uid = :conUid \n" +
                        "  AND calendar_date = :calendarDate";

                Query dateExistQuery = entityManager.createNativeQuery(calendarSql, Calendar.class);
                dateExistQuery.setParameter("conUid", c.getConUid());
                dateExistQuery.setParameter("calendarDate", c.getCalendarDate());

                List<Calendar> calendarList = dateExistQuery.getResultList();

                Integer calOid;

                if (calendarList.size() > 0) {

                    calOid = calendarList.get(0).getoId();

                } else {

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

                System.out.println(getClass().getName()+".createEvent: is chat duration ok ="
                        +p.getChatDurationOk()+", chat duration limit ="
                        +p.getChatDurationMinLimit());

                // consultant creating his plan
                if (p.getCusUid() == null) {

                    if (calendarList.size() == 0) {

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
                    plan.setTimeZone(p.getTimeZone());
                    plan.setCreatedDate(p.getCreatedDate());
                    entityManager.persist(plan);

                    calendarRes.setCode(200);
                    calendarRes.setMsg("Event created successfully!");

                    // customer creating his plan
                    // also send notification to consultant
                } else {

                    // COMMENT OUT BEFORE APP GOES LIVE
                    // curDateTime = DateUtils.addHours(curDateTime,1);

                    if (curDateTime.before(startDateTime)) {

                        if(p.getChatDurationOk()){

                            // check if this customer have an plan with this consultant before
                            String havingPlanBeforeSql = "SELECT \n" +
                                    "   id \n" +
                                    "FROM\n" +
                                    "  plan \n" +
                                    "WHERE con_uid = :conUid \n" +
                                    "  AND cus_uid = :cusUid \n"+
                                    "  AND are_cus_con_have_chatted IS TRUE";

                            Query havingPlanBeforeQry = entityManager.createNativeQuery(havingPlanBeforeSql);
                            havingPlanBeforeQry.setParameter("conUid", p.getConUid());
                            havingPlanBeforeQry.setParameter("cusUid", p.getCusUid());
                            List<Object[]> results = havingPlanBeforeQry.getResultList();

                            System.out.println(getClass().getName()+".createEvent free min res: "+results.size());
                            Integer freeMinutesForNewCustomer = (results.size() >= 1) ? null : p.getFreeMinutesForNewCustomer();

                            // check event over lap
                            Plan planOverLapCheckingData = new Plan();
                            planOverLapCheckingData.setStartTime(p.getStartTime());
                            planOverLapCheckingData.setEndTime(p.getEndTime());
                            planOverLapCheckingData.setConUid(c.getConUid());
                            planOverLapCheckingData.setCusUid(p.getCusUid());

                            Response cusOverLapRes = checkCusPlanOverLap(planOverLapCheckingData);

                            System.out.println(getClass().getName() + ".createEvent cusOverLapRes "
                                    + gson.toJson(cusOverLapRes));

                            if (cusOverLapRes.getCode() == 404) {

                                calendarRes.setCode(404);

                                String msg = "Warning!";
                                Plan sop = cusOverLapRes.getStartTimeOverLapPlan();
                                Plan eop = cusOverLapRes.getEndTimeOverLapPlan();
                                String sopMsg = "";
                                String eopMsg = "";

                                if (sop != null){

                                    sopMsg = " Your start time ["+sdf.format(planOverLapCheckingData.getStartTime())+
                                            "] is conflicting with another schedule with another customer on ["+
                                            sdf.format(sop.getStartTime())+" to "+sdf.format(sop.getEndTime())+"].";

                                }

                                if (eop != null){

                                    eopMsg = " Your end time ["+sdf.format(planOverLapCheckingData.getEndTime())+
                                            "] is conflicting with another schedule with another customer on ["+
                                            sdf.format(eop.getStartTime())+" to "+sdf.format(eop.getEndTime())+"].";

                                }

                                calendarRes.setMsg(msg+" "+sopMsg+" "+eopMsg);

                            }else {

                                if (calendarList.size() == 0) {

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
                                plan.setAreCusConHaveChatted(false);
                                plan.setTimeZone(p.getTimeZone());
                                plan.setCreatedDate(p.getCreatedDate());
                                entityManager.persist(plan);

                                Notification notification = new Notification();
                                notification.setUid(c.getConUid());
                                notification.setTitle("Booking Request");
                                notification.setBody("Topic " + p.getTopic()+", start time "+
                                        p.getfStartTime()+", end time "+
                                        p.getfEndTime());
                                notification.setStartTime(p.getfStartTime());
                                notification.setEndTime(p.getfEndTime());
                                notification.setTopic(p.getTopic());
                                notification.setType(1);
                                NotificationSender.send(notification);

                                calendarRes.setCode(200);
                                calendarRes.setMsg("Event created successfully!");

                            }

                        }else {

                            calendarRes.setCode(404);
                            calendarRes.setMsg("Chat duration should be at least "+p.getChatDurationMinLimit()+" minutes!");

                        }

                    }else {


                        calendarRes.setCode(404);
                        calendarRes.setMsg("You can create an event after "+sdf.format(curDateTime));


                    }

                }

            } else {

                calendarRes.setCode(404);
                calendarRes.setMsg("You can't create an event on past time!");

            }

        } catch (Exception e) {

            e.printStackTrace();
            System.out.println(getClass().getName() + ".createEvent: Exception " + e.getMessage());
            calendarRes.setCode(404);
            calendarRes.setMsg(e.getMessage());

        }

        return calendarRes;

    }

    private List<Plan> getAllowedPlan(int type,Date dateTime,String conUid) {

        String startAllowedSql = "SELECT \n" +
                "  * \n" +
                "FROM\n" +
                "  plan \n" +
                "WHERE con_uid = :conUid \n" +
                "  AND start_time < :startTime \n" +
                "  AND start_time >= CURDATE() \n" +
                "ORDER BY start_time \n" +
                "LIMIT 1 ";

        String endAllowedSql = "SELECT \n" +
                "  * \n" +
                "FROM\n" +
                "  plan \n" +
                "WHERE con_uid = :conUid \n" +
                "  AND end_time > :endTime \n" +
                "  AND end_time >= CURDATE() \n" +
                "ORDER BY end_time \n" +
                "LIMIT 1 ";

        Query qry;

        if (type == -1){

            qry = entityManager.createNativeQuery(startAllowedSql,Plan.class);
            qry.setParameter("conUid",conUid);
            qry.setParameter("startTime",dateTime);

        }else {

            qry = entityManager.createNativeQuery(endAllowedSql,Plan.class);
            qry.setParameter("conUid",conUid);
            qry.setParameter("endTime",dateTime);

        }

        return qry.getResultList();

    }

    private Response checkCusPlanOverLap(Plan p) {

        Response res = new Response();
        res.setCode(200);

        Plan planStartOverLap = new Plan();
        Plan planEndOverLap = new Plan();

        String checkStartOverLapSq = "SELECT \n" +
                "  * \n" +
                "FROM\n" +
                "  (SELECT \n" +
                "    id AS id,\n" +
                "    topic AS topic,\n" +
                "    SUBTIME(start_time, '00:05:00') AS allowed_start_time,\n" +
                "    ADDTIME(end_time, '00:05:00') AS allowed_end_time,\n" +
                "    start_time AS st,\n" +
                "    end_time AS et, \n" +
                "    :newStartTime AS new_start_time \n" +
                "  FROM\n" +
                "    plan \n" +
                "  WHERE cus_uid = :cusUid \n" +
                "    AND con_uid != :conUid \n" +
                "    AND start_time >= CURDATE()) AS p \n" +
                "WHERE p.new_start_time BETWEEN p.st \n" +
                "  AND p.et";

        Query startOverLapQry = entityManager.createNativeQuery(checkStartOverLapSq);
        startOverLapQry.setParameter("cusUid", p.getCusUid());
        startOverLapQry.setParameter("conUid", p.getConUid());
        startOverLapQry.setParameter("newStartTime", p.getStartTime());
        List<Object[]> startOverLapPlanList = startOverLapQry.getResultList();

        getStartOverLapRes(res, planStartOverLap, startOverLapPlanList);

        String checkEndOverLapSql = "SELECT \n" +
                "  * \n" +
                "FROM\n" +
                "  (SELECT \n" +
                "    id AS id,\n" +
                "    topic AS topic,\n" +
                "    SUBTIME(start_time, '00:05:00') AS allowed_start_time,\n" +
                "    ADDTIME(end_time, '00:05:00') AS allowed_end_time,\n" +
                "    start_time AS st,\n" +
                "    end_time AS et,\n" +
                "    :newEndTime AS new_end_time \n" +
                "  FROM\n" +
                "    plan \n" +
                "  WHERE cus_uid = :cusUid \n" +
                "    AND con_uid != :conUid \n" +
                "    AND start_time >= CURDATE()) AS p \n" +
                "WHERE p.new_end_time BETWEEN p.st \n" +
                "  AND p.et";

        Query endOverLapQry = entityManager.createNativeQuery(checkEndOverLapSql);
        endOverLapQry.setParameter("cusUid", p.getCusUid());
        endOverLapQry.setParameter("conUid", p.getConUid());
        endOverLapQry.setParameter("newEndTime", p.getEndTime());
        List<Object[]> endOverLapPlanList = endOverLapQry.getResultList();

        getEndOverLapRes(res, planEndOverLap, endOverLapPlanList);

        return res;

    }

    private Response checkConPlanOverLap(Plan p) {

        Response res = new Response();
        res.setCode(200);

        Plan planStartOverLap = new Plan();
        Plan planEndOverLap = new Plan();

        String checkStartOverLapSq = "SELECT \n" +
                "  * \n" +
                "FROM\n" +
                "  (SELECT \n" +
                "    id AS id,\n" +
                "    topic AS topic,\n" +
                "    SUBTIME(start_time, '00:05:00') AS start_time,\n" +
                "    ADDTIME(end_time, '00:05:00') AS end_time,\n" +
                "    SUBTIME(start_time, '00:04:00') AS st,\n" +
                "    ADDTIME(end_time, '00:04:00') AS et,\n" +
                "    :newStartTime AS new_start_time\n" +
                "  FROM\n" +
                "    plan \n" +
                "  WHERE con_uid = :conUid \n" +
                "    AND start_time >= CURDATE()) AS p \n" +
                "WHERE p.new_start_time BETWEEN p.st \n" +
                "  AND p.et";

        Query startOverLapQry = entityManager.createNativeQuery(checkStartOverLapSq);
        startOverLapQry.setParameter("conUid", p.getConUid());
        startOverLapQry.setParameter("newStartTime", p.getStartTime());
        List<Object[]> startOverLapPlanList = startOverLapQry.getResultList();

        getStartOverLapRes(res, planStartOverLap, startOverLapPlanList);

        String checkEndOverLapSql = "SELECT \n" +
                "  * \n" +
                "FROM\n" +
                "  (SELECT \n" +
                "    id AS id,\n" +
                "    topic AS topic,\n" +
                "    SUBTIME(start_time, '00:05:00') AS start_time,\n" +
                "    ADDTIME(end_time, '00:05:00') AS end_time,\n" +
                "    SUBTIME(start_time, '00:04:00') AS st,\n" +
                "    ADDTIME(end_time, '00:04:00') AS et,\n" +
                "    :newEndTime AS new_end_time\n" +
                "  FROM\n" +
                "    plan \n" +
                "  WHERE con_uid = :conUid \n" +
                "    AND start_time >= CURDATE()) AS p \n" +
                "WHERE p.new_end_time BETWEEN p.st \n" +
                "  AND p.et";

        Query endOverLapQry = entityManager.createNativeQuery(checkEndOverLapSql);
        endOverLapQry.setParameter("conUid", p.getConUid());
        endOverLapQry.setParameter("newEndTime", p.getEndTime());
        List<Object[]> endOverLapPlanList = endOverLapQry.getResultList();

        getEndOverLapRes(res, planEndOverLap, endOverLapPlanList);

        return res;

    }

    private void getEndOverLapRes(Response res, Plan planEndOverLap, List<Object[]> endOverLapPlanList) {
        if (endOverLapPlanList.size() > 0) {

            planEndOverLap.setId((Integer) endOverLapPlanList.get(0)[0]);
            planEndOverLap.setTopic((String) endOverLapPlanList.get(0)[1]);
            planEndOverLap.setAllowedStartTime((Date) endOverLapPlanList.get(0)[2]);
            planEndOverLap.setAllowedEndTime((Date) endOverLapPlanList.get(0)[3]);
            planEndOverLap.setStartTime((Date) endOverLapPlanList.get(0)[4]);
            planEndOverLap.setEndTime((Date) endOverLapPlanList.get(0)[5]);
            res.setEndTimeOverLapPlan(planEndOverLap);
            res.setCode(404);

        }
    }

    private void getStartOverLapRes(Response res, Plan planStartOverLap, List<Object[]> startOverLapPlanList) {
        if (startOverLapPlanList.size() > 0) {

            planStartOverLap.setId((Integer) startOverLapPlanList.get(0)[0]);
            planStartOverLap.setTopic((String) startOverLapPlanList.get(0)[1]);
            planStartOverLap.setAllowedStartTime((Date) startOverLapPlanList.get(0)[2]);
            planStartOverLap.setAllowedEndTime((Date) startOverLapPlanList.get(0)[3]);
            planStartOverLap.setStartTime((Date) startOverLapPlanList.get(0)[4]);
            planStartOverLap.setEndTime((Date) startOverLapPlanList.get(0)[5]);
            res.setStartTimeOverLapPlan(planStartOverLap);
            res.setCode(404);

        }
    }

    @Override
    public Calendar getSchedule(HttpServletRequest httpServletRequest, Calendar c) {

        Calendar res = new Calendar();

        try {

            System.out.println(getClass().getName() + ".getSchedule : conUid = " + c.getConUid());

            String planFetchingSql = ""
                    + "SELECT "
                    + "  p.id AS id, "
                    + "  p.topic AS topic, "
                    + "  DATE_FORMAT(CONVERT_TZ(start_time,'UTC',time_zone),'%Y-%m-%d %T') AS f_start_time, "
                    + "  DATE_FORMAT(CONVERT_TZ(end_time,'UTC',time_zone),'%Y-%m-%d %T') AS f_end_time, "
                    + "  p.is_accept_by_con AS is_accept_by_con, "
                    + "  p.check_out_id AS check_out_id, "
                    + "  p.free_minutes_for_new_customer AS free_minutes_for_new_customer, "
                    + "  p.cus_uid AS cus_uid, "
                    + "  p.con_uid AS con_uid, "
                    + "  IF( "
                    + "    p.time_diff_with_created_date < '00:00:00', "
                    + "    'y', "
                    + "    'n' "
                    + "  ) AS is_booking_acceptance_time_passed, "
                    + "  IF(HOUR(p.time_diff_with_start_time)> 24,HOUR(p.time_diff_with_created_date),HOUR(p.time_diff_with_start_time)) AS hour_diff, "
                    + "  IF(HOUR(p.time_diff_with_start_time)> 24,MINUTE(p.time_diff_with_created_date),MINUTE(p.time_diff_with_start_time)) AS minute_diff, "
                    + "  DATE_FORMAT(DATE_SUB(CONVERT_TZ(start_time,'UTC',time_zone),INTERVAL 5 MINUTE),'%Y-%m-%d %T') AS before_padding, "
                    + "  DATE_FORMAT(DATE_ADD(CONVERT_TZ(end_time,'UTC',time_zone),INTERVAL 5 MINUTE),'%Y-%m-%d %T') AS after_padding "
                    + "FROM "
                    + "  (SELECT "
                    + "    *, "
                    + "    CAST(TIMEDIFF( "
                    + "      DATE_ADD(CONVERT_TZ(created_date,'UTC',time_zone), INTERVAL 1 DAY), "
                    + "      CONVERT_TZ(NOW(),'UTC',time_zone) "
                    + "    ) AS CHAR) AS time_diff_with_created_date, "
                    + "    CAST(TIMEDIFF( "
                    + "      CONVERT_TZ(start_time,'UTC',time_zone), "
                    + "      CONVERT_TZ(NOW(),'UTC',time_zone) "
                    + "    ) AS CHAR) AS time_diff_with_start_time "
                    + "  FROM "
                    + "    plan "
                    + "  WHERE CONVERT_TZ(start_time,'UTC',time_zone) >= CONVERT_TZ(NOW(),'UTC',time_zone) "
                    + "    AND con_uid = :conUid) AS p "
                    + "  ORDER BY p.start_time";

            Query planFetchingQry = entityManager.createNativeQuery(planFetchingSql);
            planFetchingQry.setParameter("conUid", c.getConUid());
            List<Object[]> results = planFetchingQry.getResultList();

            List<Plan> rPlanList = new ArrayList<>();

            for (Object[] result : results) {

                Plan np = new Plan();
                Plan bp = new Plan();
                Plan ap = new Plan();
                String isBookingAcceptanceTimePassed = (String) result[9];

                // 7 = cus uid
                String uid = result[7] == null ? (String) result[8] : (String) result[7];
                System.out.println(getClass().getName()+":getSchedule: uid = "+uid);

                if (isBookingAcceptanceTimePassed.equalsIgnoreCase("n")){

                    bp.setId(0);
                    bp.setTopic("--");
                    bp.setfStartTime((String) result[12]);
                    bp.setfEndTime((String) result[2]);
                    bp.setUid(uid);
                    rPlanList.add(bp);

                    np.setId((Integer) result[0]);
                    np.setTopic((String) result[1]);
                    np.setfStartTime((String) result[2]);
                    np.setfEndTime((String) result[3]);
                    np.setAcceptByCon((Boolean) result[4]);
                    np.setCheckOutId((String) result[5]);
                    np.setFreeMinutesForNewCustomer((Integer) result[6]);
                    np.setCusUid((String) result[7]);
                    np.setConUid((String) result[8]);
                    np.setUid(uid);
                    np.setHourDiff(((BigInteger) result[10]).intValue());
                    np.setMinuteDiff(((BigInteger) result[11]).intValue());
                    rPlanList.add(np);

                    ap.setId(0);
                    ap.setTopic("--");
                    ap.setfStartTime((String) result[3]);
                    ap.setfEndTime((String) result[13]);
                    ap.setUid(uid);
                    rPlanList.add(ap);

                }

            }

            System.out.println(getClass().getName() + ".check plan list size = " + rPlanList.size());

            if (rPlanList.size() > 0){

                res.setPlanList(rPlanList);
                res.setCode(200);
                res.setMsg("Schedule found!");

            }else {

                res.setPlanList(rPlanList);
                res.setCode(404);
                res.setMsg("No schedule found!");

            }

        } catch (Exception e) {

            e.printStackTrace();
            res.setCode(404);
            res.setMsg(e.getMessage());
            System.out.println(getClass().getName()+".getSchedule: exception "+e.getMessage());

        }

        return res;

    }

}
