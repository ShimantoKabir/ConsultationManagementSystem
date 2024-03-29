package com.dannygroupllc.ConsultantWebService.daos.implementers;

import com.dannygroupllc.ConsultantWebService.daos.interfaces.AuthDao;
import com.dannygroupllc.ConsultantWebService.models.Auth;
import com.dannygroupllc.ConsultantWebService.models.Plan;
import com.google.gson.Gson;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import javax.persistence.EntityManager;
import javax.persistence.Query;
import javax.servlet.http.HttpServletRequest;
import java.math.BigInteger;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Repository
public class AuthDaoImp implements AuthDao {

    public EntityManager entityManager;
    public Gson gson;
    public SimpleDateFormat sdf;

    @Autowired
    public AuthDaoImp(EntityManager entityManager) {
        this.entityManager = entityManager;
        gson = new Gson();
        sdf = new SimpleDateFormat("dd-MM-yyyy hh:mm:ss a");
    }

    @Override
    public Auth reload(HttpServletRequest httpServletRequest, Auth a) {

        Auth authRes = new Auth();

        try {

            Query authExistQuery = entityManager.createNativeQuery("SELECT * FROM auth WHERE u_id = :uId", Auth.class);
            authExistQuery.setParameter("uId", a.getuId());
            List<Auth> authList = authExistQuery.getResultList();

            // if auth already exist then update the auth id
            if (authList.size() > 0) {

                String sql = ""
                        + "UPDATE "
                        + " auth "
                        + "SET "
                        + " a_id =:aId, "
                        + " ip =:ip, "
                        + " client_token =:clientToken, "
                        + " plan_id =:planId, "
                        + " amount =:amount "
                        + "WHERE "
                        + " u_id =:uId";

                Query authUpdateQuery = entityManager.createNativeQuery(sql);

                String aid = UUID.randomUUID().toString();

                authUpdateQuery.setParameter("aId", aid);
                authUpdateQuery.setParameter("ip", httpServletRequest.getRemoteAddr());
                authUpdateQuery.setParameter("uId", a.getuId());
                authUpdateQuery.setParameter("clientToken", a.getClientToken());
                authUpdateQuery.setParameter("planId", a.getPlanId());
                authUpdateQuery.setParameter("amount", a.getAmount());
                authUpdateQuery.executeUpdate();

                authRes.setAid(aid);
                authRes.setCode(200);
                authRes.setMsg("Update auth id, auth reload successful!");

                // else insert a new row
            } else {

                String aid = UUID.randomUUID().toString();
                Auth auth = new Auth();
                auth.setuId(a.getuId());
                auth.setAid(aid);
                auth.setClientToken(a.getClientToken());
                auth.setPlanId(a.getPlanId());
                auth.setAmount(a.getAmount());
                auth.setIp(httpServletRequest.getRemoteAddr());
                auth.setModifiedBy(auth.getuId());
                entityManager.persist(auth);

                authRes.setCode(200);
                authRes.setMsg("Set up new auth id, auth reload successful!");
                authRes.setAid(aid);

            }

        } catch (Exception e) {

            e.printStackTrace();
            authRes.setCode(404);
            authRes.setMsg(e.getMessage());
            System.out.println(getClass().getName() + ".reload : " + e.getMessage());
            return authRes;

        }

        return authRes;

    }

    @Override
    public Auth check(HttpServletRequest httpServletRequest, Auth a) {

        Auth authRes = new Auth();

        try {

            System.out.println(getClass().getName() + ".check : conUid = " + a.getConUid());
            System.out.println(getClass().getName() + ".check : timeZone = " + a.getTimeZone());

            // common sense
            // ============
            // 1. no customer can't create a plan in future date
            // 2. start time will never less then plan created date
            // 3. if chat session has been passed then we don't have to worry about weather it accept by expert's
            // or not

            // logic
            // =====
            // 1. don't fetch passed date plan
            // 2. don't fetch those plan which don't accept by expert's and 24 hour's left after created

            String planFetchingSql = "SELECT \n" +
                    "  p.id AS id,\n" +
                    "  p.topic AS topic,\n" +
                    "  DATE_FORMAT(CONVERT_TZ(start_time,'UTC',time_zone),'%Y-%m-%d %T') AS f_start_time,\n" +
                    "  DATE_FORMAT(CONVERT_TZ(end_time,'UTC',time_zone),'%Y-%m-%d %T') AS f_end_time,\n" +
                    "  p.is_accept_by_con AS is_accept_by_con,\n" +
                    "  p.payment_trans_id AS payment_trans_id,\n" +
                    "  p.free_minutes_for_new_customer AS free_minutes_for_new_customer,\n" +
                    "  p.cus_uid AS cus_uid,\n" +
                    "  p.con_uid AS con_uid,\n" +
                    "  IF(\n" +
                    "    p.time_diff < '00:00:00',\n" +
                    "    'y',\n" +
                    "    'n'\n" +
                    "  ) AS is_booking_acceptance_time_passed,\n" +
                    "  HOUR(p.time_diff) AS hour_diff,\n" +
                    "  MINUTE(p.time_diff) AS minute_diff, \n" +
                    "  DATE_FORMAT(DATE_SUB(CONVERT_TZ(start_time,'UTC',time_zone),INTERVAL 5 MINUTE),'%Y-%m-%d %T') AS before_padding, \n" +
                    "  DATE_FORMAT(DATE_ADD(CONVERT_TZ(end_time,'UTC',time_zone),INTERVAL 5 MINUTE),'%Y-%m-%d %T') AS after_padding \n" +
                    "FROM\n" +
                    "  (SELECT \n" +
                    "    *,\n" +
                    "    CAST(TIMEDIFF(\n" +
                    "      DATE_ADD(CONVERT_TZ(created_date,'UTC',time_zone), INTERVAL 1 DAY),\n" +
                    "      CONVERT_TZ(NOW(),'UTC',time_zone)\n" +
                    "    ) AS CHAR) AS time_diff \n" +
                    "  FROM\n" +
                    "    plan \n" +
                    "  WHERE CONVERT_TZ(start_time,'UTC',time_zone) >= CONVERT_TZ(NOW(),'UTC',time_zone) \n" +
                    "    AND con_uid = :conUid) AS p ";

            Query planFetchingQry = entityManager.createNativeQuery(planFetchingSql);
            planFetchingQry.setParameter("conUid", a.getConUid());
            List<Object[]> results = planFetchingQry.getResultList();

            List<Plan> rPlanList = new ArrayList<>();

            for (Object[] result : results) {

                Plan np = new Plan();
                Plan bp = new Plan();
                Plan ap = new Plan();
                String isBookingAcceptanceTimePassed = (String) result[9];

                if (isBookingAcceptanceTimePassed.equalsIgnoreCase("n")){

                    bp.setId(0);
                    bp.setTopic("--");
                    bp.setfStartTime((String) result[12]);
                    bp.setfEndTime((String) result[2]);
                    rPlanList.add(bp);

                    np.setId((Integer) result[0]);
                    np.setTopic((String) result[1]);
                    np.setfStartTime((String) result[2]);
                    np.setfEndTime((String) result[3]);
                    np.setAcceptByCon((Boolean) result[4]);
                    np.setPaymentTransId((String) result[5]);
                    np.setFreeMinutesForNewCustomer((Integer) result[6]);
                    np.setCusUid((String) result[7]);
                    np.setConUid((String) result[8]);
                    np.setHourDiff(((BigInteger) result[10]).intValue());
                    np.setMinuteDiff(((BigInteger) result[11]).intValue());
                    rPlanList.add(np);

                    ap.setId(0);
                    ap.setTopic("--");
                    ap.setfStartTime((String) result[3]);
                    ap.setfEndTime((String) result[13]);
                    rPlanList.add(ap);

                }

            }

            System.out.println(getClass().getName() + ".check PlanListSize = " + rPlanList.size());

            authRes.setPlanList(rPlanList);
            authRes.setCode(200);
            authRes.setMsg("Schedule found!");

        } catch (Exception e) {

            e.printStackTrace();
            authRes.setCode(404);
            authRes.setMsg(e.getMessage());
            System.out.println(getClass().getName()+".check Exception "+e.getMessage());

        }

        return authRes;

    }

}
