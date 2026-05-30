# Spring Boot 4.0.6 + Consul Service Discovery

Short setup guide for connecting Spring Boot services to the Consul Discovery service deployed on Render.com.

## Versions

For Spring Boot `4.0.6`, use the Spring Cloud `2025.1.x` release train.

Recommended baseline:

```text
Spring Boot: 4.0.6
Java: 25
Spring Cloud: 2025.1.0
Consul starter: org.springframework.cloud:spring-cloud-starter-consul-discovery
```

## Gradle

```gradle
plugins {
    id 'java'
    id 'org.springframework.boot' version '4.0.6'
    id 'io.spring.dependency-management' version '1.1.7'
}

ext {
    set('springCloudVersion', '2025.1.0')
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(25)
    }
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.boot:spring-boot-starter-actuator'
    implementation 'org.springframework.cloud:spring-cloud-starter-consul-discovery'
    implementation 'org.springframework.cloud:spring-cloud-starter-loadbalancer'
}

dependencyManagement {
    imports {
        mavenBom "org.springframework.cloud:spring-cloud-dependencies:${springCloudVersion}"
    }
}
```

## application.yml

Use this in every Spring Boot service that should register itself in Consul.

```yaml
spring:
  application:
    name: order-service

  cloud:
    consul:
      host: ${CONSUL_HOST}
      port: ${CONSUL_PORT:443}
      scheme: ${CONSUL_SCHEME:https}
      discovery:
        enabled: true
        register: true
        service-name: ${spring.application.name}
        instance-id: ${spring.application.name}:${RENDER_INSTANCE_ID:${random.value}}
        acl-token: ${CONSUL_TOKEN}

        # For Render Web Services, register the public HTTPS address of this service.
        hostname: ${RENDER_EXTERNAL_HOSTNAME:localhost}
        port: ${SERVICE_PUBLIC_PORT:443}
        scheme: ${SERVICE_PUBLIC_SCHEME:https}
        health-check-url: ${SERVICE_PUBLIC_SCHEME:https}://${RENDER_EXTERNAL_HOSTNAME:localhost}/actuator/health
        health-check-interval: 15s

management:
  endpoints:
    web:
      exposure:
        include: health,info
  endpoint:
    health:
      probes:
        enabled: true
```

For local development against local Consul, override with:

```yaml
spring:
  cloud:
    consul:
      host: localhost
      port: 8500
      scheme: http
      discovery:
        hostname: localhost
        port: ${server.port}
        scheme: http
        health-check-url: http://localhost:${server.port}/actuator/health
```

## Render env vars for each Spring Boot service

Set these in Render for every Spring Boot service:

```text
CONSUL_HOST=<your-consul-service>.onrender.com
CONSUL_PORT=443
CONSUL_SCHEME=https
CONSUL_TOKEN=<same value as CONSUL_ACL_INITIAL_MANAGEMENT_TOKEN, or a scoped Consul ACL token>
SERVICE_PUBLIC_PORT=443
SERVICE_PUBLIC_SCHEME=https
```

Render provides these automatically:

```text
PORT
RENDER_EXTERNAL_HOSTNAME
RENDER_EXTERNAL_URL
RENDER_INSTANCE_ID
```

Your Spring Boot app must listen on Render's `PORT`:

```yaml
server:
  port: ${PORT:8080}
```

## Calling another service

Use the service name from `spring.application.name`.

Example with `RestTemplate` and Spring Cloud LoadBalancer:

```java
import org.springframework.cloud.client.loadbalancer.LoadBalanced;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

@Configuration
class HttpClientConfig {

    @Bean
    @LoadBalanced
    RestTemplate restTemplate() {
        return new RestTemplate();
    }
}
```

```java
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
class OrderClient {
    private final RestTemplate restTemplate;

    OrderClient(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    String getPaymentStatus(String orderId) {
        return restTemplate.getForObject(
            "https://payment-service/payments/" + orderId + "/status",
            String.class
        );
    }
}
```

`payment-service` is resolved through Consul. You do not hardcode the real Render URL in application code.

## Optional: Consul KV config

If you also want to load Spring configuration from Consul KV, add:

```gradle
implementation 'org.springframework.cloud:spring-cloud-starter-consul-config'
```

Then configure:

```yaml
spring:
  config:
    import: optional:consul:
  cloud:
    consul:
      config:
        acl-token: ${CONSUL_TOKEN}
```

## Notes

- `spring-cloud-starter-consul-discovery` is the required library for service registration and discovery.
- `spring-cloud-starter-loadbalancer` is needed when calling services by logical name through `RestTemplate`, `WebClient`, or Feign-style clients.
- `spring-boot-starter-actuator` gives Consul a stable `/actuator/health` endpoint for health checks.
- On Render Free, services can sleep. The first request after sleep can be slow, and Consul health may temporarily mark a service unhealthy.
- For production, create a scoped Consul ACL token instead of reusing the initial management token everywhere.

## References

- Spring Cloud Consul reference: https://docs.spring.io/spring-cloud-consul/reference/
- Spring Cloud release train compatibility: https://spring.io/projects/spring-cloud
- Render default environment variables: https://render.com/docs/environment-variables
