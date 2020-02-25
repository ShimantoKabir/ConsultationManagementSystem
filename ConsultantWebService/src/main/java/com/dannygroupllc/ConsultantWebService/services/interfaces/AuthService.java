package com.dannygroupllc.ConsultantWebService.services.interfaces;

import com.dannygroupllc.ConsultantWebService.models.Auth;

import javax.servlet.http.HttpServletRequest;

public interface AuthService {

    public Auth reload(HttpServletRequest httpServletRequest,Auth auth);
    public Auth check(HttpServletRequest httpServletRequest,Auth auth);

}
