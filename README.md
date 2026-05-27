# Microservices Project -- Spring Boot + Spring Cloud

## Overview

This project is a **hands-on introduction to Microservices
Architecture** using:

-   Java 17
-   Spring Boot 3
-   Spring Cloud
-   PostgreSQL
-   OpenFeign
-   Eureka Discovery Server
-   Spring Cloud Gateway
-   Config Server
-   Maven

The goal is to help developers understand how multiple independent
services work together instead of building one large monolithic
application.

This project consists of five independent applications:

1.  Student Microservice
2.  School Microservice
3.  Discovery Server (Eureka)
4.  API Gateway
5.  Config Server

------------------------------------------------------------------------

# What is a Monolith?

Before learning microservices, it helps to understand a **monolithic
application**.

A monolith is a single application containing:

-   UI
-   business logic
-   database access
-   APIs
-   authentication
-   all features

inside one deployable unit.

Example:

``` text
One Application
├── Student Feature
├── School Feature
├── Auth
├── Billing
├── Database Access
└── REST APIs
```

### Pros

-   Easy to start
-   Simple deployment
-   Good for small projects

### Cons

As applications grow:

-   slower deployments
-   harder scaling
-   tightly coupled code
-   one failure can affect entire system
-   difficult team ownership

This motivates microservices.

------------------------------------------------------------------------

# What Are Microservices?

Microservices split an application into **smaller independent
services**.

Each service:

-   owns its own responsibility
-   can be deployed independently
-   communicates over APIs
-   may own its own database
-   scales independently

Example:

``` text
Student Service
School Service
Auth Service
Payment Service
Gateway
Discovery
```

Instead of one huge application, we have several focused services.

------------------------------------------------------------------------

# Project Architecture

High-level request flow:

``` text
Client
   |
API Gateway
   |
---------------------
|                   |
Student Service   School Service
        |
     PostgreSQL
        |
Discovery + Config
```

A client never talks directly to internal services.

Instead:

1.  Request enters API Gateway
2.  Gateway routes request
3.  Services communicate
4.  Eureka tracks services
5.  Config Server centralizes configuration

------------------------------------------------------------------------

# Project Components

------------------------------------------------------------------------

# 1. Student Microservice

Folder:

``` text
student/
```

## Purpose

Responsible for:

-   creating students
-   retrieving students
-   storing student information
-   associating students with schools

This service owns student data.

Typical fields:

-   id
-   firstName
-   lastName
-   email
-   schoolId

## Technology Used

-   Spring Boot
-   Spring Web
-   Spring Data JPA
-   PostgreSQL
-   Lombok

## Example APIs

Create Student:

``` http
POST /api/v1/students
```

Get Students:

``` http
GET /api/v1/students
```

Get Students by School:

``` http
GET /api/v1/students/school/{schoolId}
```

## Why Separate Service?

Student logic belongs only here.

Other services should not directly manipulate student database tables.

This keeps ownership clean.

------------------------------------------------------------------------

# 2. School Microservice

Folder:

``` text
school/
```

## Purpose

Responsible for:

-   creating schools
-   retrieving schools
-   storing school information

This service owns school data.

Typical fields:

-   id
-   name
-   email

## Technology Used

-   Spring Boot
-   JPA
-   PostgreSQL
-   OpenFeign

## Example APIs

Create School:

``` http
POST /api/v1/schools
```

Get Schools:

``` http
GET /api/v1/schools
```

## Important Concept

The School service needs student information.

Instead of accessing Student database directly, it makes an API call.

This is a core microservices principle.

------------------------------------------------------------------------

# OpenFeign -- Service-to-Service Communication

## What Problem Does It Solve?

Microservices often need data from other services.

Example:

School service needs:

"Show this school and its students."

Without Feign:

``` java
RestTemplate
WebClient
manual HTTP code
```

OpenFeign simplifies this.

Example:

``` java
@FeignClient(name="student-service")
```

Then:

``` java
client.findStudents()
```

Feign generates the HTTP client automatically.

## Why This Matters

Benefits:

-   cleaner code
-   declarative APIs
-   less boilerplate
-   easier maintenance

In this project:

School Service → Student Service

------------------------------------------------------------------------

# 3. Eureka Discovery Server

Folder:

``` text
discovery/
```

## What Is Service Discovery?

In microservices:

Services move.

Ports change.

Containers restart.

Hardcoding:

``` text
localhost:8090
```

becomes fragile.

We need dynamic discovery.

------------------------------------------------------------------------

## What Eureka Does

Eureka acts like a **phonebook for services**.

Services register themselves.

Example:

``` text
Student Service -> I am running at 8090
School Service -> I am running at 8070
```

Eureka stores this information.

When another service needs Student Service:

It asks Eureka.

------------------------------------------------------------------------

## Real-World Analogy

Think of Eureka like DNS or Contacts.

Instead of remembering phone numbers:

You search by name.

Same idea:

``` text
student-service
school-service
```

instead of hardcoded URLs.

------------------------------------------------------------------------

## How It Works

1.  Discovery server starts
2.  Services register
3.  Services send heartbeats
4.  Eureka removes dead instances

Benefits:

-   resilience
-   dynamic routing
-   scaling support
-   cloud readiness

------------------------------------------------------------------------

# 4. API Gateway

Folder:

``` text
gateway/
```

## What Is an API Gateway?

The Gateway is the **front door**.

Clients do not call services directly.

Instead:

``` text
Client
  |
Gateway
  |
Services
```

------------------------------------------------------------------------

## Why Use Gateway?

Without Gateway:

``` text
Client → Student
Client → School
Client → Auth
```

Client must know every address.

With Gateway:

``` text
Client → Gateway
```

Gateway handles routing.

------------------------------------------------------------------------

## Responsibilities

Gateway can:

-   route requests
-   security
-   logging
-   monitoring
-   rate limiting
-   authentication
-   traffic management

In this project:

Gateway routes:

``` text
/api/v1/students/**
/api/v1/schools/**
```

to correct services.

------------------------------------------------------------------------

## Example

Client:

``` http
GET /api/v1/students
```

Gateway:

-   receives request
-   forwards request
-   returns response

Client sees one entry point.

------------------------------------------------------------------------

# 5. Config Server

Folder:

``` text
config-server/
```

## What Problem Does It Solve?

Without Config Server:

Every service stores:

``` yaml
ports
database urls
eureka urls
credentials
```

inside local files.

Changing configuration becomes painful.

------------------------------------------------------------------------

## Config Server Idea

One central configuration location.

Services load configuration at startup.

Benefits:

-   centralized management
-   consistent configuration
-   easier environment handling
-   reduced duplication

------------------------------------------------------------------------

## Example

Instead of:

``` text
student/application.yml
school/application.yml
gateway/application.yml
```

Config Server stores shared configs.

Services import them.

------------------------------------------------------------------------

# Database Design

This project uses PostgreSQL.

Separate databases are recommended.

Example:

Student DB:

``` text
students
```

School DB:

``` text
schools
```

This reflects microservices ownership.

Services should not share database tables.

------------------------------------------------------------------------

# Startup Order

Microservices depend on each other.

Recommended order:

1.  Config Server
2.  Discovery Server
3.  Gateway
4.  Student Service
5.  School Service

This ensures:

-   configs available
-   discovery available
-   routing available
-   services register correctly

------------------------------------------------------------------------

# Why This Project Matters

This project introduces several real-world backend concepts:

-   REST APIs
-   JPA + PostgreSQL
-   service ownership
-   distributed systems
-   service discovery
-   API gateway routing
-   centralized configuration
-   inter-service communication

These are common in:

-   cloud systems
-   enterprise applications
-   fintech
-   distributed platforms
-   modern backend engineering

------------------------------------------------------------------------

# Future Improvements

Potential enhancements:

-   Docker
-   Kubernetes
-   Security/JWT
-   Kafka or RabbitMQ
-   Zipkin tracing
-   Circuit Breakers
-   CI/CD deployment
-   AWS deployment

------------------------------------------------------------------------

# Final Takeaway

This project is intentionally small.

The goal is not complexity.

The goal is to understand the building blocks of a modern distributed
backend system.

Once comfortable with these ideas, larger microservice architectures
become much easier to understand and build.
