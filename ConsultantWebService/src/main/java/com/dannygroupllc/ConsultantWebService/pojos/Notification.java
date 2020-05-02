package com.dannygroupllc.ConsultantWebService.pojos;

public class Notification {

    public String uid;
    public String fcmRegistrationToken;
    public String title;
    public String body;
    public Integer seenStatus;
    public String startTime;
    public String endTime;
    public Long timeStamp;

    public Notification() {}

    public Long getTimeStamp() {
        return timeStamp;
    }

    public void setTimeStamp(Long timeStamp) {
        this.timeStamp = timeStamp;
    }

    public String getStartTime() {
        return startTime;
    }

    public void setStartTime(String startTime) {
        this.startTime = startTime;
    }

    public String getEndTime() {
        return endTime;
    }

    public void setEndTime(String endTime) {
        this.endTime = endTime;
    }

    public String getUid() {
        return uid;
    }

    public void setUid(String uid) {
        this.uid = uid;
    }

    public String getFcmRegistrationToken() {
        return fcmRegistrationToken;
    }

    public void setFcmRegistrationToken(String fcmRegistrationToken) {
        this.fcmRegistrationToken = fcmRegistrationToken;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getBody() {
        return body;
    }

    public void setBody(String body) {
        this.body = body;
    }

    public Integer getSeenStatus() {
        return seenStatus;
    }

    public void setSeenStatus(Integer seenStatus) {
        this.seenStatus = seenStatus;
    }
}
