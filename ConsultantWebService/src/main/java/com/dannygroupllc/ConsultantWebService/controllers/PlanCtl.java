package com.dannygroupllc.ConsultantWebService.controllers;

import com.dannygroupllc.ConsultantWebService.models.Plan;
import com.dannygroupllc.ConsultantWebService.pojos.Request;
import com.dannygroupllc.ConsultantWebService.pojos.Response;
import com.dannygroupllc.ConsultantWebService.services.interfaces.PlanService;
import com.google.gson.Gson;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletRequest;
import java.util.List;

@RestController
@RequestMapping("/plan")
public class PlanCtl {

    public PlanService planService;
    public Gson gson;

    @Autowired
    public PlanCtl(PlanService planService) {
        this.planService = planService;
        this.gson = new Gson();
    }

    @PostMapping("/delete")
    public Response delete(@RequestBody Request request, HttpServletRequest httpServletRequest){

        Response response = new Response();

        Plan plan = planService.delete(httpServletRequest,request.getPlan());
        response.setMsg(plan.getMsg());
        response.setCode(plan.getCode());

        return response;

    }

    @PostMapping("/change-accept-status")
    public Response changeAcceptStatus(@RequestBody Request request, HttpServletRequest httpServletRequest){

        Response response = new Response();

        Plan plan = planService.changeAcceptStatus(httpServletRequest,request.getPlan());
        response.setMsg(plan.getMsg());
        response.setCode(plan.getCode());

        return response;

    }

    @PostMapping("/save-review-and-rating")
    public Response saveReviewAndRating(@RequestBody Request request, HttpServletRequest httpServletRequest){

        Response response = new Response();

        Plan plan = planService.saveReviewAndRating(httpServletRequest,request.getPlan());
        response.setMsg(plan.getMsg());
        response.setCode(plan.getCode());

        return response;

    }

    @PostMapping("/get-all-plan-by-user")
    public Response getAllPlanByUser(@RequestBody Request request, HttpServletRequest httpServletRequest){

        Response response = new Response();

        List<Plan> planList = planService.getAllPlanByUser(httpServletRequest,request.getPlan());

        if (planList.size()>0){

            response.setMsg("Found plan list!");
            response.setCode(200);
            response.setPlanList(planList);

        }else {

            response.setMsg("No plan list found!");
            response.setCode(404);

        }

        return response;

    }


}