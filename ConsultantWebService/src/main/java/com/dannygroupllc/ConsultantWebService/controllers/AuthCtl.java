package com.dannygroupllc.ConsultantWebService.controllers;

import com.dannygroupllc.ConsultantWebService.models.Auth;
import com.dannygroupllc.ConsultantWebService.pojos.Request;
import com.dannygroupllc.ConsultantWebService.pojos.Response;
import com.dannygroupllc.ConsultantWebService.services.interfaces.AuthService;
import com.google.gson.Gson;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import javax.servlet.http.HttpServletRequest;
import java.util.ArrayList;

@RestController
@RequestMapping("/auth")
public class AuthCtl {

    public AuthService authService;
    public Gson gson;

    @Autowired
    public AuthCtl(AuthService authService) {
        this.authService = authService;
        this.gson = new Gson();
    }

    @PostMapping("/reload")
    public Response reload(@RequestBody Request request, HttpServletRequest httpServletRequest){

        Response response = new Response();


        System.out.println("Hello world");
        Auth auth = authService.reload(httpServletRequest,request.getAuth());
        response.setMsg(auth.getMsg());
        response.setCode(auth.getCode());
        response.setAid(auth.getAid());
        response.setPlanList(new ArrayList<>());

        return response;

    }

    @PostMapping("/check")
    public Response check(@RequestBody Request request, HttpServletRequest httpServletRequest){

        Response response = new Response();

        Auth auth = authService.check(httpServletRequest,request.getAuth());
        response.setMsg(auth.getMsg());
        response.setCode(auth.getCode());
        response.setPlanList(auth.getPlanList());
        response.setAuth(auth);

        return response;

    }

}
