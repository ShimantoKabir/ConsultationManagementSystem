package com.dannygroupllc.ConsultantWebService.services.implementers;

import com.dannygroupllc.ConsultantWebService.daos.interfaces.CalendarDao;
import com.dannygroupllc.ConsultantWebService.models.Calendar;
import com.dannygroupllc.ConsultantWebService.services.interfaces.CalendarService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.servlet.http.HttpServletRequest;

@Service
public class CalendarServiceImp implements CalendarService {

    public CalendarDao calendarDao;

    @Autowired
    public CalendarServiceImp(@Qualifier("calendarDaoImp") CalendarDao calendarDao) {
        this.calendarDao = calendarDao;
    }

    @Override
    @Transactional
    public Calendar createEvent(HttpServletRequest httpServletRequest, Calendar calendar) {
        return calendarDao.createEvent(httpServletRequest,calendar);
    }
}
