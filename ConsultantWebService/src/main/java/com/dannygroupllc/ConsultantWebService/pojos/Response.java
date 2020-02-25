package com.dannygroupllc.ConsultantWebService.pojos;

import com.braintreegateway.Customer;
import com.dannygroupllc.ConsultantWebService.models.Auth;
import com.dannygroupllc.ConsultantWebService.models.Plan;

import java.util.List;

public class Response {

    public int code;
    public String msg;
    public String aid;
    public String paymentGatewayClientToken;
    public String clientToken;

    public Customer customer;
    public Auth auth;
    public List<Plan> planList;

    public Response() {}

    public String getClientToken() {
        return clientToken;
    }

    public void setClientToken(String clientToken) {
        this.clientToken = clientToken;
    }

    public String getAid() {
        return aid;
    }

    public void setAid(String aid) {
        this.aid = aid;
    }

    public List<Plan> getPlanList() {
        return planList;
    }

    public void setPlanList(List<Plan> planList) {
        this.planList = planList;
    }

    public Auth getAuth() {
        return auth;
    }

    public void setAuth(Auth auth) {
        this.auth = auth;
    }

    public int getCode() {
        return code;
    }

    public void setCode(int code) {
        this.code = code;
    }

    public String getMsg() {
        return msg;
    }

    public void setMsg(String msg) {
        this.msg = msg;
    }

    public String getPaymentGatewayClientToken() {
        return paymentGatewayClientToken;
    }

    public void setPaymentGatewayClientToken(String paymentGatewayClientToken) {
        this.paymentGatewayClientToken = paymentGatewayClientToken;
    }

    public Customer getCustomer() {
        return customer;
    }

    public void setCustomer(Customer customer) {
        this.customer = customer;
    }
}
