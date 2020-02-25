package com.dannygroupllc.ConsultantWebService.controllers;

import com.dannygroupllc.ConsultantWebService.pojos.Response;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/app")
public class TestCtl {

    @GetMapping("/test")
    public Response check(){

        Response res = new Response();
        res.setCode(200);
        res.setMsg("Application testing ok !");

        return res;

    }

}
