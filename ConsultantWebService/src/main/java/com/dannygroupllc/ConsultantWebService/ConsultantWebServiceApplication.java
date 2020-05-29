package com.dannygroupllc.ConsultantWebService;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class ConsultantWebServiceApplication {

	public static void main(String[] args) {
		SpringApplication.run(ConsultantWebServiceApplication.class, args);
	}

}
