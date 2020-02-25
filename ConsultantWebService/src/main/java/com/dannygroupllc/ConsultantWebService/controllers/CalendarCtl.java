package com.dannygroupllc.ConsultantWebService.controllers;

import com.dannygroupllc.ConsultantWebService.models.Calendar;
import com.dannygroupllc.ConsultantWebService.pojos.Request;
import com.dannygroupllc.ConsultantWebService.pojos.Response;
import com.dannygroupllc.ConsultantWebService.services.interfaces.CalendarService;
import com.google.gson.Gson;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import javax.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/calendar")
public class CalendarCtl {

    public CalendarService calendarService;
    public Gson gson;

    @Autowired
    public CalendarCtl(CalendarService calendarService) {
        this.calendarService = calendarService;
        this.gson = new Gson();
    }

    @PostMapping("/create-event")
    public Response createEvent(@RequestBody Request request, HttpServletRequest httpServletRequest){

        Response response = new Response();

        Calendar calendar = calendarService.createEvent(httpServletRequest,request.getCalendar());

        response.setMsg(calendar.getMsg());
        response.setCode(calendar.getCode());

        return response;

    }

}
