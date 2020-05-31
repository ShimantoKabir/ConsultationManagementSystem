package com.dannygroupllc.ConsultantWebService.daos.interfaces;

import com.dannygroupllc.ConsultantWebService.models.Calendar;
import javax.servlet.http.HttpServletRequest;

public interface CalendarDao {

    public Calendar createEvent(HttpServletRequest httpServletRequest,Calendar calendar);
    public Calendar getSchedule(HttpServletRequest httpServletRequest, Calendar calendar);

}
