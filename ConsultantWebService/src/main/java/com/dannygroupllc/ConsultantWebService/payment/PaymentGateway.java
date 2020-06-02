package com.dannygroupllc.ConsultantWebService.payment;

import com.braintreegateway.*;
import com.dannygroupllc.ConsultantWebService.models.Auth;
import com.dannygroupllc.ConsultantWebService.pojos.Request;
import com.dannygroupllc.ConsultantWebService.pojos.Response;
import com.dannygroupllc.ConsultantWebService.pojos.UserInfo;
import com.google.gson.Gson;
import com.paypal.payouts.*;
import org.apache.commons.lang3.RandomStringUtils;
import org.hibernate.Session;
import org.hibernate.SessionFactory;

import javax.persistence.EntityManagerFactory;
import javax.persistence.Query;
import java.io.IOException;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import com.paypal.http.HttpResponse;

public class PaymentGateway {

    public String merchantID = "m4cf84nkgkzz9ygh";
    public String privateKey = "68405d3c7ea54135c34865ea5c0d3f4e";
    public String publicKey = "d5vm3cgzsfs6jtc8";

    public Response getClientToken(Request request) {

        Response response = new Response();

        System.out.println(getClass().getName()+".getClientToken Customer Id = "+request.getCustomerId());

        BraintreeGateway gateway = new BraintreeGateway(Environment.SANDBOX, merchantID, publicKey, privateKey);

        ClientTokenRequest clientTokenRequest = new ClientTokenRequest().customerId(request.getCustomerId());
        String clientToken = gateway.clientToken().generate(clientTokenRequest);

        if (clientToken.length() > 0) {

            System.out.println(getClass().getName()+".getClientToken: clientToken = " + clientToken);
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

        System.out.println(getClass().getName()+".checkout = Called");

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

                System.out.println(getClass().getName()+".checkout: Nonce " + request.getTransaction().getNonceFromTheClient());

                TransactionRequest transactionRequest = new TransactionRequest()
                        .amount(new BigDecimal(authList.get(0).getAmount()))
                        .paymentMethodNonce(request.getTransaction().getNonceFromTheClient())
                        .options()
                        .submitForSettlement(true)
                        .done();

                Result<Transaction> result = gateway.transaction().sale(transactionRequest);

                if (result.isSuccess()) {

                    System.out.println(getClass().getName()+".checkout: getTarget " + result.getTarget().getId());
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

            e.printStackTrace();
            response.setMsg("Exception occurred !");
            response.setCode(404);

        } finally {
            if (session != null) {
                session.close();
            }
        }

        return response;

    }

    public Response payout(Request request, EntityManagerFactory entityManagerFactory) {

        System.out.println(getClass().getName()+".payout = called");
        Response response = new Response();

        SessionFactory sessionFactory = entityManagerFactory.unwrap(SessionFactory.class);
        Session session = null;
        org.hibernate.Transaction tx;

        try {

            session = sessionFactory.openSession();
            tx = session.beginTransaction();

            HttpResponse<CreatePayoutResponse> payoutResponse = createPayout(request);

            String payOutUpdateSql = ""
                    + "UPDATE "
                    + "	plan "
                    + "SET "
                    + "	pay_out_batch_id = :payOutBatchId, "
                    + "	pay_out_batch_status = :payOutBatchStatus "
                    + "WHERE "
                    + "	id = :id ";

            Query payOutUpdateQry = session.createNativeQuery(payOutUpdateSql);
            payOutUpdateQry.setParameter("id",request.getPlanId());
            payOutUpdateQry.setParameter("payOutBatchId", payoutResponse.result().batchHeader().payoutBatchId());
            payOutUpdateQry.setParameter("payOutBatchStatus", payoutResponse.result().batchHeader().batchStatus());
            payOutUpdateQry.executeUpdate();

            tx.commit();

            response.setMsg("Payout status = "+payoutResponse.result().batchHeader().batchStatus());
            response.setCode(200);

        } catch (Exception e) {

            e.printStackTrace();
            response.setMsg(e.getMessage());
            response.setCode(404);

        } finally {
            if (session != null) {
                session.close();
            }
        }

        return response;

    }

    private PayoutsPostRequest buildRequestBody(Request request) {
        List<PayoutItem> items = new ArrayList<>();

        PayoutItem payoutItem = new PayoutItem();
        payoutItem.senderItemId("sender_item_id");
        payoutItem.note("note");
        payoutItem.receiver(request.getEmail());
        payoutItem.amount(new Currency().currency("USD").value(request.getAmount()));

        items.add(payoutItem);

        CreatePayoutRequest payoutBatch = new CreatePayoutRequest()
                .senderBatchHeader(new SenderBatchHeader()
                        .senderBatchId("batch_id_" + RandomStringUtils.randomAlphanumeric(7))
                        .emailMessage("Congratulation you have received a payment.")
                        .emailSubject("Congratulation! Payment received.")
                        .note("Enjoy your payout!!")
                        .recipientType("EMAIL"))
                .items(items);

        return new PayoutsPostRequest()
                .requestBody(payoutBatch);
    }

    HttpResponse<CreatePayoutResponse> createPayout(Request request) throws IOException {

        PayoutsPostRequest payoutsPostRequest = buildRequestBody(request);

        HttpResponse<CreatePayoutResponse> response = PayPalClient.client.execute(payoutsPostRequest);
        System.out.println(getClass().getName()+".buildRequestBody: "+new Gson().toJson(response));

        return response;
    }

}
