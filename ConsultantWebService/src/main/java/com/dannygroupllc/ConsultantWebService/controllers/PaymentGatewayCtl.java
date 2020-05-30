package com.dannygroupllc.ConsultantWebService.controllers;

import com.dannygroupllc.ConsultantWebService.pojos.Request;
import com.dannygroupllc.ConsultantWebService.pojos.Response;
import com.dannygroupllc.ConsultantWebService.payment.PaymentGateway;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.persistence.EntityManagerFactory;

@RestController
@RequestMapping("/pg")
public class PaymentGatewayCtl {

    @Autowired
    private EntityManagerFactory entityManagerFactory;

    public PaymentGateway paymentGatewayPro = new PaymentGateway();

    @PostMapping("/get-client-token")
    public Response getClientToken(@RequestBody Request request){

        return paymentGatewayPro.getClientToken(request);

    }

    @PostMapping("/create-customer")
    public Response createCustomer(@RequestBody Request request){

        return paymentGatewayPro.createCustomer(request.getUserInfo());

    }

    @PostMapping("/checkout")
    public Response checkout(@RequestBody Request request){

        return new PaymentGateway().checkout(request,entityManagerFactory);

    }

    @PostMapping("/payout")
    public Response payout(@RequestBody Request request){

        return new PaymentGateway().payout(request,entityManagerFactory);

    }

}
