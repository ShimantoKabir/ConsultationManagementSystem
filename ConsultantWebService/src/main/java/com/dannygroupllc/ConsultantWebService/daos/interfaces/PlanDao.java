package com.dannygroupllc.ConsultantWebService.daos.interfaces;

import com.dannygroupllc.ConsultantWebService.models.Plan;

import javax.servlet.http.HttpServletRequest;
import java.util.List;

public interface PlanDao {

    public Plan delete(HttpServletRequest httpServletRequest, Plan plan);
    public Plan changeAcceptStatus(HttpServletRequest httpServletRequest, Plan plan);
    public List<Plan> getAllPlanByUser(HttpServletRequest httpServletRequest, Plan plan);
    public List<Plan> getReviewAndRating(HttpServletRequest httpServletRequest, Plan plan);
    public Plan saveReviewAndRating(HttpServletRequest httpServletRequest, Plan plan);
    public Plan changeAreCusConHaveChattedStatus(HttpServletRequest httpServletRequest, Plan plan);
    public Plan checkPaymentStatus(Plan plan);
    public Plan remindToUser();

}
