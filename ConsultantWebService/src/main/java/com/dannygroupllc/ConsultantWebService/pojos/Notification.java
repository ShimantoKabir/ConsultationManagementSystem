package com.dannygroupllc.ConsultantWebService.pojos;

public class Notification {

    public String id;
    public String uid;
    public String fcmRegistrationToken;
    public String title;
    public String body;
    public Boolean isSeen;

    public Notification() {}

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
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

    public Boolean getSeen() {
        return isSeen;
    }

    public void setSeen(Boolean seen) {
        isSeen = seen;
    }
}
