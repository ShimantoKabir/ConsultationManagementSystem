package com.dannygroupllc.ConsultantWebService.services.interfaces;

import com.dannygroupllc.ConsultantWebService.models.Plan;

import javax.servlet.http.HttpServletRequest;
import java.util.List;

public interface PlanService {

    public Plan delete(HttpServletRequest httpServletRequest, Plan plan);
    public Plan changeAcceptStatus(HttpServletRequest httpServletRequest, Plan plan);
    public List<Plan> getAllPlanByUser(HttpServletRequest httpServletRequest, Plan plan);
    public Plan saveReviewAndRating(HttpServletRequest httpServletRequest, Plan plan);

}
