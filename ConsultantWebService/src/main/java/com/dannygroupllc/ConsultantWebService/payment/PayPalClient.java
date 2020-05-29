package com.dannygroupllc.ConsultantWebService.payment;

import com.paypal.core.PayPalEnvironment;
import com.paypal.core.PayPalHttpClient;

public class PayPalClient {

    static String clientId = "ASS1g6isVnN46cbtSg7iy0KYMV1y-n8uzPDs0qSd34j1PT5sPxKV4zzd1LZ01rFAbjQR9sCdm89s_Rpm";
    static String secret = "EAUOYGE5aoCVP-T6zy7IOooC0nw98Ggkw333k8PO4xm03MOaDvQwGnDyCvYtq5ixDvDQrQ2IVfm4Su33";

    /**
     * Setting up PayPal SDK environment with PayPal Access credentials. For demo
     * purpose, we are using SandboxEnvironment. In production this will be
     * LiveEnvironment.
     */
    private static PayPalEnvironment environment = new PayPalEnvironment.Sandbox(clientId,secret);

    /**
     * PayPal HTTP client instance with environment which has access credentials
     * context. This can be used invoke PayPal API's provided the credentials have
     * the access to do so.
     */
    static PayPalHttpClient client = new PayPalHttpClient(environment);

}
