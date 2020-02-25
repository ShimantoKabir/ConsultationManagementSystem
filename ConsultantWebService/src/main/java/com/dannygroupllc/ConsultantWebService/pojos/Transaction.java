package com.dannygroupllc.ConsultantWebService.pojos;

import java.math.BigDecimal;

public class Transaction {

    public String nonceFromTheClient;
    public BigDecimal amount;
    public Integer planId;

    public Transaction() {}

    public Integer getPlanId() {
        return planId;
    }

    public void setPlanId(Integer planId) {
        this.planId = planId;
    }

    public Transaction(String nonceFromTheClient, BigDecimal amount) {
        this.nonceFromTheClient = nonceFromTheClient;
        this.amount = amount;
    }

    public String getNonceFromTheClient() {
        return nonceFromTheClient;
    }

    public void setNonceFromTheClient(String nonceFromTheClient) {
        this.nonceFromTheClient = nonceFromTheClient;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }


}
