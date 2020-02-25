package com.dannygroupllc.ConsultantWebService.services.implementers;

import com.dannygroupllc.ConsultantWebService.daos.interfaces.AuthDao;
import com.dannygroupllc.ConsultantWebService.models.Auth;
import com.dannygroupllc.ConsultantWebService.services.interfaces.AuthService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.servlet.http.HttpServletRequest;

@Service
public class AuthServiceImp implements AuthService {

    public AuthDao authDao;

    @Autowired
    public AuthServiceImp(@Qualifier("authDaoImp") AuthDao authDao) {
        this.authDao = authDao;
    }

    @Override
    @Transactional
    public Auth reload(HttpServletRequest httpServletRequest,Auth auth) {
        return authDao.reload(httpServletRequest,auth);
    }

    @Override
    public Auth check(HttpServletRequest httpServletRequest, Auth auth) {
        return authDao.check(httpServletRequest,auth);
    }
}
