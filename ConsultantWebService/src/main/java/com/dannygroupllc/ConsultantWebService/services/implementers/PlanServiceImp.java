package com.dannygroupllc.ConsultantWebService.services.implementers;

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
    public List<Plan> getReviewAndRating(HttpServletRequest httpServletRequest, Plan plan) {
        return planDao.getReviewAndRating(httpServletRequest,plan);
    }

    @Override
    @Transactional
    public Plan saveReviewAndRating(HttpServletRequest httpServletRequest, Plan plan) {
        return planDao.saveReviewAndRating(httpServletRequest,plan);
    }

    @Override
    @Transactional
    public Plan changeAreCusConHaveChattedStatus(HttpServletRequest httpServletRequest, Plan plan) {
        return planDao.changeAreCusConHaveChattedStatus(httpServletRequest,plan);
    }

    @Override
    public Plan checkPaymentStatus(Plan plan) {
        return planDao.checkPaymentStatus(plan);
    }

    @Override
    public Plan remindToUser() {
        return planDao.remindToUser();
    }

    @Override
    public Plan updateCheckOutStatus(Plan plan) {
        return planDao.updateCheckOutStatus(plan);
    }

}
