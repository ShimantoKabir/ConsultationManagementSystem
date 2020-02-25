package com.dannygroupllc.ConsultantWebService.processors;

import com.braintreegateway.*;
import com.dannygroupllc.ConsultantWebService.models.Auth;
import com.dannygroupllc.ConsultantWebService.pojos.Request;
import com.dannygroupllc.ConsultantWebService.pojos.Response;
import com.dannygroupllc.ConsultantWebService.pojos.UserInfo;
import org.hibernate.Session;
import org.hibernate.SessionFactory;

import javax.persistence.EntityManagerFactory;
import javax.persistence.Query;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

public class PaymentGatewayPro {

    public String CLASS_NAME = "com.dannygroupllc.ConsultantWebService.processors.PaymentGatewayPro";
    public String merchantID = "m4cf84nkgkzz9ygh";
    public String privateKey = "68405d3c7ea54135c34865ea5c0d3f4e";
    public String publicKey = "d5vm3cgzsfs6jtc8";

    public Response getClientToken(Request request) {

        Response response = new Response();

        BraintreeGateway gateway = new BraintreeGateway(Environment.SANDBOX, merchantID, publicKey, privateKey);

        ClientTokenRequest clientTokenRequest = new ClientTokenRequest().customerId(request.getCustomerId());
        String clientToken = gateway.clientToken().generate(clientTokenRequest);

        if (clientToken.length() > 0) {

            System.out.println(CLASS_NAME + ".getClientToken: clientToken = " + clientToken);
            response.setCode(200);
            response.setMsg("Token generate successfully !");
            response.setClientToken(clientToken);
            response.setPlanList(new ArrayList<>());

        } else {

            response.setCode(404);
            response.setMsg("Not token generate");

        }

        return response;

    }

    public Response createCustomer(UserInfo userInfo) {

        Response response = new Response();

        System.out.println(userInfo.getCustomerId());

        BraintreeGateway gateway = new BraintreeGateway(Environment.SANDBOX, merchantID, publicKey, privateKey);

        CustomerRequest request = new CustomerRequest()
                .firstName(userInfo.getFirstName())
                .email(userInfo.getEmail())
                .id(userInfo.getCustomerId())
                .phone(userInfo.getPhone());

        Result<Customer> result = gateway.customer().create(request);

        result.isSuccess();

        if (result.isSuccess()) {

            response.setCode(200);
            response.setMsg("User created successfully !");
            response.setCustomer(result.getTarget());

        } else {

            response.setCode(404);
            response.setMsg("User creation unsuccessful!");

        }

        return response;

    }

    public Response checkout(Request request, EntityManagerFactory entityManagerFactory) {

        System.out.println(CLASS_NAME + ".checkout = Called");

        Response response = new Response();

        BraintreeGateway gateway = new BraintreeGateway(Environment.SANDBOX, merchantID, publicKey, privateKey);
        SessionFactory sessionFactory = entityManagerFactory.unwrap(SessionFactory.class);
        Session session = null;
        org.hibernate.Transaction tx;

        try {

            session = sessionFactory.openSession();
            tx = session.beginTransaction();

            String authSql = "SELECT * FROM auth WHERE a_id = :aId AND u_id = :uId";

            Query authQuery = session.createNativeQuery(authSql, Auth.class);
            authQuery.setParameter("aId", request.getAuth().getAid());
            authQuery.setParameter("uId", request.getAuth().getuId());

            List<Auth> authList = authQuery.getResultList();

            if (authList.size() > 0) {

                System.out.println(CLASS_NAME + ".checkout: Nonce " + request.getTransaction().getNonceFromTheClient());

                TransactionRequest transactionRequest = new TransactionRequest()
                        .amount(new BigDecimal(authList.get(0).getAmount()))
                        .paymentMethodNonce(request.getTransaction().getNonceFromTheClient())
                        .options()
                        .submitForSettlement(true)
                        .done();

                Result<Transaction> result = gateway.transaction().sale(transactionRequest);

                if (result.isSuccess()) {

                    System.out.println(CLASS_NAME + "checkout: getTarget " + result.getTarget().getId());
                    Query query = session.createNativeQuery("UPDATE plan SET payment_trans_id = :txId WHERE id = :id");
                    query.setParameter("txId", result.getTarget().getId());
                    query.setParameter("id", authList.get(0).getPlanId());
                    query.executeUpdate();

                    response.setMsg("Transaction successful!");
                    response.setCode(200);

                } else {

                    response.setMsg("Transaction not successful!");
                    response.setCode(404);

                }

            } else {

                response.setMsg("Authentication failed!");
                response.setCode(200);

            }

            tx.commit();

        } catch (Exception e) {

            response.setMsg("Exception occurred !");
            response.setCode(400);

        } finally {
            if (session != null) {
                session.close();
            }
        }

        return response;

    }

}
