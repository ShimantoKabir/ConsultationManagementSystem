package com.dannygroupllc.ConsultantWebService.services.implementers;

import com.dannygroupllc.ConsultantWebService.daos.interfaces.CalendarDao;
import com.dannygroupllc.ConsultantWebService.daos.interfaces.PlanDao;
import com.dannygroupllc.ConsultantWebService.models.Plan;
import com.dannygroupllc.ConsultantWebService.services.interfaces.PlanService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.servlet.http.HttpServletRequest;
import java.util.List;

@Service
public class PlanServiceImp implements PlanService {

    public PlanDao planDao;

    @Autowired
    public PlanServiceImp(@Qualifier("planDaoImp") PlanDao planDao) {
        this.planDao = planDao;
    }

    @Override
    @Transactional
    public Plan delete(HttpServletRequest httpServletRequest, Plan plan) {
        return planDao.delete(httpServletRequest,plan);
    }

    @Override
    @Transactional
    public Plan changeAcceptStatus(HttpServletRequest httpServletRequest, Plan plan) {
        return planDao.changeAcceptStatus(httpServletRequest,plan);
    }

    @Override
    public List<Plan> getAllPlanByUser(HttpServletRequest httpServletRequest, Plan plan) {
        return planDao.getAllPlanByUser(httpServletRequest,plan);
    }

    @Override
    @Transactional
    public Plan saveReviewAndRating(HttpServletRequest httpServletRequest, Plan plan) {
        return planDao.saveReviewAndRating(httpServletRequest,plan);
    }
}
