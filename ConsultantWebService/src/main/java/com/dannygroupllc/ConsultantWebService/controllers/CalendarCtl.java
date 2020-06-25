package com.dannygroupllc.ConsultantWebService.controllers;

import com.dannygroupllc.ConsultantWebService.Utility.AuthManager;
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
import java.util.ArrayList;

@RestController
@RequestMapping("/calendar")
public class CalendarCtl {

    public CalendarService calendarService;
    public Gson gson;
    public AuthManager authManager;

    @Autowired
    public CalendarCtl(CalendarService calendarService) {
        this.calendarService = calendarService;
        this.gson = new Gson();
        authManager = new AuthManager();
    }

    @PostMapping("/create-event")
    public Response createEvent(@RequestBody Request request, HttpServletRequest httpServletRequest){

        Response response = new Response();
        System.out.println(getClass().getName()+":createEvent: request = "+request);
        Integer authRes = authManager.check(request);

        if(authRes == 200){
            Calendar calendar = calendarService.createEvent(httpServletRequest,request.getCalendar());
            response.setMsg(calendar.getMsg());
            response.setCode(calendar.getCode());
        }else {
            response.setMsg("Authentication failed!");
            response.setCode(404);
        }

        return response;

    }

    @PostMapping("/get-schedule")
    public Response getSchedule(@RequestBody Request request, HttpServletRequest httpServletRequest){

        Response response = new Response();
        System.out.println(getClass().getName()+".getSchedule: request ="+gson.toJson(request));

        Integer authRes = authManager.check(request);

        if (authRes == 200){

            Calendar calendar = calendarService.getSchedule(httpServletRequest,request.getCalendar());
            System.out.println(getClass().getName()+".getSchedule: plan list ="+gson.toJson(calendar));
            response.setMsg(calendar.getMsg());
            response.setCode(calendar.getCode());
            response.setPlanList(calendar.getPlanList());

        }else {

            response.setMsg("Authentication failed!");
            response.setCode(404);
            response.setPlanList(new ArrayList<>());

        }

        return response;

    }

}
