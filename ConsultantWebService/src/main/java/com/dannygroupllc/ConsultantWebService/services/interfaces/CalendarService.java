package com.dannygroupllc.ConsultantWebService.services.interfaces;

import com.dannygroupllc.ConsultantWebService.models.Calendar;

import javax.servlet.http.HttpServletRequest;

public interface CalendarService {

    public Calendar createEvent(HttpServletRequest httpServletRequest,Calendar calendar);

}
