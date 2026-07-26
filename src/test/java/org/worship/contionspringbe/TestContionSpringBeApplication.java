package org.worship.contionspringbe;

import org.springframework.boot.SpringApplication;

public class TestContionSpringBeApplication {

	public static void main(String[] args) {
		SpringApplication.from(ContionSpringBeApplication::main).with(TestcontainersConfiguration.class).run(args);
	}

}
