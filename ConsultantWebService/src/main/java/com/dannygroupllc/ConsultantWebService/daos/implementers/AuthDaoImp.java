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
import java.util.List;
import java.util.UUID;

@Repository
public class AuthDaoImp implements AuthDao {

    public EntityManager entityManager;
    public Gson gson;
    public static String CLASS_NAME = "com.dannygroupllc.ConsultantWebService.daos.implementers.AuthDao";

    @Autowired
    public AuthDaoImp(EntityManager entityManager) {
        this.entityManager = entityManager;
        gson = new Gson();
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
                        + "	auth "
                        + "SET "
                        + "	a_id =:aId, "
                        + "	ip =:ip, "
                        + "	client_token =:clientToken, "
                        + "	plan_id =:planId, "
                        + "	amount =:amount "
                        + "WHERE "
                        + "	u_id =:uId";

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

            authRes.setCode(404);
            authRes.setMsg(e.getMessage());
            System.out.println(CLASS_NAME + ".reload : " + e.getMessage());
            return authRes;

        }

        return authRes;

    }

    @Override
    public Auth check(HttpServletRequest httpServletRequest, Auth a) {

        Auth authRes = new Auth();

        try {

            Query authExistQuery = entityManager.createNativeQuery(
                    "SELECT * FROM auth WHERE u_id = :uId AND a_id = :aId",
                    Auth.class
            );
            authExistQuery.setParameter("uId", a.getuId());
            authExistQuery.setParameter("aId", a.getAid());
            List<Auth> authList = authExistQuery.getResultList();

            System.out.println(CLASS_NAME + ".check : aId = " + a.getAid());
            System.out.println(CLASS_NAME + ".check : uId = " + a.getuId());
            System.out.println(CLASS_NAME + ".check : conUid = " + a.getConUid());

            if (authList.size() > 0) {

                String planFetchingSql = "SELECT \n" +
                        "  * \n" +
                        "FROM\n" +
                        "  Plan \n" +
                        "WHERE DATE(start_time) >= CURDATE()\n" +
                        "  AND con_uid = :conUid ";

                Query planFetchingQry = entityManager.createNativeQuery(planFetchingSql, Plan.class);
                planFetchingQry.setParameter("conUid", a.getConUid());
                List<Plan> planList = planFetchingQry.getResultList();

                System.out.println("PlanListSize" + planList.size());

                authRes.setPlanList(planList);
                authRes.setAmount(authList.get(0).getAmount());
                authRes.setClientToken(authList.get(0).getClientToken());
                authRes.setAid(authList.get(0).getAid());
                authRes.setuId(authList.get(0).getuId());
                authRes.setCode(200);
                authRes.setMsg("Authentication successful ... !");

            } else {

                authRes.setCode(404);
                authRes.setMsg("Authentication not successful ... !");

            }

        } catch (Exception e) {

            authRes.setCode(404);
            authRes.setMsg(e.getMessage());

        }

        return authRes;
    }

}
