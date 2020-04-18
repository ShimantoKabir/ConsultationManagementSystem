package com.dannygroupllc.ConsultantWebService;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

import java.sql.Timestamp;

@SpringBootApplication
@EnableScheduling
public class ConsultantWebServiceApplication {

	// public static String machineIp = "3.20.119.226";
	// public static String machineIp = "192.168.43.132";
	public static void main(String[] args) {
		SpringApplication.run(ConsultantWebServiceApplication.class, args);
	}

}
