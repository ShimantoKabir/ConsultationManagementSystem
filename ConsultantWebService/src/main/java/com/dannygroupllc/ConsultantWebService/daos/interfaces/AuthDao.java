package com.dannygroupllc.ConsultantWebService.daos.interfaces;

import com.dannygroupllc.ConsultantWebService.models.Auth;

import javax.servlet.http.HttpServletRequest;

public interface AuthDao {

    public Auth reload(HttpServletRequest httpServletRequest, Auth auth);
    public Auth check(HttpServletRequest httpServletRequest, Auth auth);

}
