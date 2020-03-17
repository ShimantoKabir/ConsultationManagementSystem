package com.dannygroupllc.ConsultantWebService.pojos;

import com.braintreegateway.Customer;
import com.dannygroupllc.ConsultantWebService.models.Auth;
import com.dannygroupllc.ConsultantWebService.models.Plan;
import com.google.api.client.util.DateTime;

import java.util.List;

public class Response {

    public int code;
    public String msg;
    public String aid;
    public String paymentGatewayClientToken;
    public String clientToken;
    public String mysqlConnectionStatus;
    public String fireBaseConnectionStatus;
    public String databaseCurrentDateTime;
    public Boolean isStartTimeOverLapFound;
    public Boolean isEndTimeOverLapFound;

    public Customer customer;
    public Auth auth;
    public List<Plan> planList;
    public List<UserInfo> userInfoList;

    public Plan startTimeOverLapPlan;
    public Plan endTimeOverLapPlan;

    public Response() {}

    public Plan getStartTimeOverLapPlan() {
        return startTimeOverLapPlan;
    }

    public void setStartTimeOverLapPlan(Plan startTimeOverLapPlan) {
        this.startTimeOverLapPlan = startTimeOverLapPlan;
    }

    public Plan getEndTimeOverLapPlan() {
        return endTimeOverLapPlan;
    }

    public void setEndTimeOverLapPlan(Plan endTimeOverLapPlan) {
        this.endTimeOverLapPlan = endTimeOverLapPlan;
    }

    public Boolean getStartTimeOverLapFound() {
        return isStartTimeOverLapFound;
    }

    public void setStartTimeOverLapFound(Boolean startTimeOverLapFound) {
        isStartTimeOverLapFound = startTimeOverLapFound;
    }

    public Boolean getEndTimeOverLapFound() {
        return isEndTimeOverLapFound;
    }

    public void setEndTimeOverLapFound(Boolean endTimeOverLapFound) {
        isEndTimeOverLapFound = endTimeOverLapFound;
    }

    public String getMysqlConnectionStatus() {
        return mysqlConnectionStatus;
    }

    public void setMysqlConnectionStatus(String mysqlConnectionStatus) {
        this.mysqlConnectionStatus = mysqlConnectionStatus;
    }

    public String getFireBaseConnectionStatus() {
        return fireBaseConnectionStatus;
    }

    public void setFireBaseConnectionStatus(String fireBaseConnectionStatus) {
        this.fireBaseConnectionStatus = fireBaseConnectionStatus;
    }

    public String getDatabaseCurrentDateTime() {
        return databaseCurrentDateTime;
    }

    public void setDatabaseCurrentDateTime(String databaseCurrentDateTime) {
        this.databaseCurrentDateTime = databaseCurrentDateTime;
    }

    public List<UserInfo> getUserInfoList() {
        return userInfoList;
    }

    public void setUserInfoList(List<UserInfo> userInfoList) {
        this.userInfoList = userInfoList;
    }

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
