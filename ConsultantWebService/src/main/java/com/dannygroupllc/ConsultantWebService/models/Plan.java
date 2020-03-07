package com.dannygroupllc.ConsultantWebService.models;

import org.hibernate.annotations.CreationTimestamp;

import javax.persistence.*;
import java.util.Date;

@Entity
public class Plan {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    public Integer id;
    public String topic;
    public Integer calenderOid;
    public String conUid; // if consultant uid null then the event created by customer
    public String cusUid;
    public Date startTime;
    public Date endTime;
    public Boolean isAcceptByCon; // if the event created by customer then this event need to be accept by consultant
    public String paymentTransId;
    public Integer freeMinutesForNewCustomer;
    public Integer hourlyRate;
    public String conReview;
    public String cusReview;
    public Integer conRating;
    public Integer cusRating;
    public String ip;
    public String modifiedBy;
    @CreationTimestamp
    @Temporal(TemporalType.TIMESTAMP)
    public Date createdDate;

    @Transient
    public Integer userType;

    @Transient
    public String msg;
    @Transient
    public Integer code;

    @Transient
    public Date calendarDate;

    @Transient
    public String fStartTime;
    @Transient
    public String fEndTime;


    public Integer getConRating() {
        return conRating;
    }

    public void setConRating(Integer conRating) {
        this.conRating = conRating;
    }

    public Integer getCusRating() {
        return cusRating;
    }

    public void setCusRating(Integer cusRating) {
        this.cusRating = cusRating;
    }

    public String getConReview() {
        return conReview;
    }

    public void setConReview(String conReview) {
        this.conReview = conReview;
    }

    public String getCusReview() {
        return cusReview;
    }

    public void setCusReview(String cusReview) {
        this.cusReview = cusReview;
    }

    public String getfStartTime() {
        return fStartTime;
    }

    public void setfStartTime(String fStartTime) {
        this.fStartTime = fStartTime;
    }

    public String getfEndTime() {
        return fEndTime;
    }

    public void setfEndTime(String fEndTime) {
        this.fEndTime = fEndTime;
    }

    public Integer getUserType() {
        return userType;
    }

    public void setUserType(Integer userType) {
        this.userType = userType;
    }

    public void setMsg(String msg) {
        this.msg = msg;
    }

    public void setCode(Integer code) {
        this.code = code;
    }

    public String getMsg() {
        return msg;
    }

    public Integer getCode() {
        return code;
    }

    public Plan() {}

    public Date getCalendarDate() {
        return calendarDate;
    }

    public void setCalendarDate(Date calendarDate) {
        this.calendarDate = calendarDate;
    }

    public String getTopic() {
        return topic;
    }

    public void setTopic(String topic) {
        this.topic = topic;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getCalenderOid() {
        return calenderOid;
    }

    public void setCalenderOid(Integer calenderOid) {
        this.calenderOid = calenderOid;
    }

    public String getConUid() {
        return conUid;
    }

    public void setConUid(String conUid) {
        this.conUid = conUid;
    }

    public String getCusUid() {
        return cusUid;
    }

    public void setCusUid(String cusUid) {
        this.cusUid = cusUid;
    }

    public Date getStartTime() {
        return startTime;
    }

    public void setStartTime(Date startTime) {
        this.startTime = startTime;
    }

    public Date getEndTime() {
        return endTime;
    }

    public void setEndTime(Date endTime) {
        this.endTime = endTime;
    }

    public Boolean getAcceptByCon() {
        return isAcceptByCon;
    }

    public void setAcceptByCon(Boolean acceptByCon) {
        isAcceptByCon = acceptByCon;
    }

    public String getPaymentTransId() {
        return paymentTransId;
    }

    public void setPaymentTransId(String paymentTransId) {
        this.paymentTransId = paymentTransId;
    }

    public Integer getFreeMinutesForNewCustomer() {
        return freeMinutesForNewCustomer;
    }

    public void setFreeMinutesForNewCustomer(Integer freeMinutesForNewCustomer) {
        this.freeMinutesForNewCustomer = freeMinutesForNewCustomer;
    }

    public Integer getHourlyRate() {
        return hourlyRate;
    }

    public void setHourlyRate(Integer hourlyRate) {
        this.hourlyRate = hourlyRate;
    }

    public String getIp() {
        return ip;
    }

    public void setIp(String ip) {
        this.ip = ip;
    }

    public String getModifiedBy() {
        return modifiedBy;
    }

    public void setModifiedBy(String modifiedBy) {
        this.modifiedBy = modifiedBy;
    }

    public Date getCreatedDate() {
        return createdDate;
    }

    public void setCreatedDate(Date createdDate) {
        this.createdDate = createdDate;
    }
}
