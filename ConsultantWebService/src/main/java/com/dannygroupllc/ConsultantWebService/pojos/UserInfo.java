package com.dannygroupllc.ConsultantWebService.pojos;

import java.sql.Timestamp;

public class UserInfo {

    public String displayName;
    public String email;
    public String phoneNumber;
    public String photoUrl;
    public String uid;
    public Integer userType;
    public Integer hourlyRate;
    public Integer like;
    public String shortDescription;
    public String longDescription;
    public Integer freeMinutesForNewCustomer;
    public String fcmRegistrationToken;

    public String firstName;
    public String phone;
    public String customerId;

    public String lastOnlineAt;
    public Boolean isOnline;
    public Integer rating;
    public String timeZone;
    public String chattingWith;
    public String coronavirusExperience;
    public String hashTag;

    public UserInfo() {}

    public String getHashTag() {
        return hashTag;
    }

    public void setHashTag(String hashTag) {
        this.hashTag = hashTag;
    }

    public String getCoronavirusExperience() {
        return coronavirusExperience;
    }

    public void setCoronavirusExperience(String coronavirusExperience) {
        this.coronavirusExperience = coronavirusExperience;
    }

    public String getChattingWith() {
        return chattingWith;
    }

    public void setChattingWith(String chattingWith) {
        this.chattingWith = chattingWith;
    }

    public String getTimeZone() {
        return timeZone;
    }

    public void setTimeZone(String timeZone) {
        this.timeZone = timeZone;
    }

    public Integer getRating() {
        return rating;
    }

    public void setRating(Integer rating) {
        this.rating = rating;
    }

    public String getLastOnlineAt() {
        return lastOnlineAt;
    }

    public void setLastOnlineAt(String lastOnlineAt) {
        this.lastOnlineAt = lastOnlineAt;
    }

    public Boolean getOnline() {
        return isOnline;
    }

    public void setOnline(Boolean online) {
        isOnline = online;
    }

    public String getDisplayName() {
        return displayName;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public String getPhotoUrl() {
        return photoUrl;
    }

    public void setPhotoUrl(String photoUrl) {
        this.photoUrl = photoUrl;
    }

    public String getUid() {
        return uid;
    }

    public void setUid(String uid) {
        this.uid = uid;
    }

    public Integer getUserType() {
        return userType;
    }

    public void setUserType(Integer userType) {
        this.userType = userType;
    }

    public Integer getHourlyRate() {
        return hourlyRate;
    }

    public void setHourlyRate(Integer hourlyRate) {
        this.hourlyRate = hourlyRate;
    }

    public Integer getLike() {
        return like;
    }

    public void setLike(Integer like) {
        this.like = like;
    }

    public String getShortDescription() {
        return shortDescription;
    }

    public void setShortDescription(String shortDescription) {
        this.shortDescription = shortDescription;
    }

    public String getLongDescription() {
        return longDescription;
    }

    public void setLongDescription(String longDescription) {
        this.longDescription = longDescription;
    }

    public Integer getFreeMinutesForNewCustomer() {
        return freeMinutesForNewCustomer;
    }

    public void setFreeMinutesForNewCustomer(Integer freeMinutesForNewCustomer) {
        this.freeMinutesForNewCustomer = freeMinutesForNewCustomer;
    }

    public String getFcmRegistrationToken() {
        return fcmRegistrationToken;
    }

    public void setFcmRegistrationToken(String fcmRegistrationToken) {
        this.fcmRegistrationToken = fcmRegistrationToken;
    }

    public String getFirstName() {
        return firstName;
    }

    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getCustomerId() {
        return customerId;
    }

    public void setCustomerId(String customerId) {
        this.customerId = customerId;
    }
}
