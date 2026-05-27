# Microservices Project — Spring Boot + Spring Cloud

A hands-on microservices project built with Java 17, Spring Boot, Spring Cloud, and PostgreSQL. Five independent services communicate through an API Gateway, register with a Eureka Discovery Server, and share configuration from a central Config Server.

## Architecture

```
Client
  │
  ▼
API Gateway  :8222          ← single entry point for all requests
  │
  ├──▶ Student Service  :8090   ← manages students, owns students DB
  │
  └──▶ School Service   :8070   ← manages schools, calls Student Service
                                   via OpenFeign
Supporting services:
  Config Server   :8888    ← serves config files to all services
  Discovery       :8761    ← Eureka service registry
```

## Services

| Service | Port | Description |
|---|---|---|
| Config Server | 8888 | Centralized configuration for all services |
| Discovery (Eureka) | 8761 | Service registry and health dashboard |
| API Gateway | 8222 | Single entry point, routes to services |
| Student Service | 8090 | CRUD for students, owns `students` database |
| School Service | 8070 | CRUD for schools, fetches students via Feign |

## Prerequisites

- Java 17+
- Maven (or use the included `mvnw` wrappers)
- PostgreSQL 16
- macOS with Homebrew (for the `make` targets)

## Quick Start

### 1. One-command startup

```bash
make up
```

This will:
1. Start PostgreSQL if it isn't running
2. Start all five services in the correct order
3. Wait for each to be healthy before starting the next
4. Print the URL for every service when done

Expected output:

```
  ✓ PostgreSQL already running
Starting config-server...
  ✓ config-server is ready (port 8888)
Starting discovery...
  ✓ discovery is ready (port 8761)
Starting gateway...
  ✓ gateway is ready (port 8222)
Starting student service...
  ✓ student is ready (port 8090)
Starting school service...
  ✓ school is ready (port 8070)

All services are up:
  Config Server  →  http://localhost:8888
  Discovery      →  http://localhost:8761
  Gateway        →  http://localhost:8222
  Student        →  http://localhost:8090
  School         →  http://localhost:8070

  API entry point: http://localhost:8222
```

### 2. Stop everything

```bash
make down
```

### 3. Other commands

```bash
make status   # show which services are running and their PIDs
make logs     # tail live logs from all five services
make help     # print usage
```

Logs are written to `/tmp/ms-logs/<service>.log`.

---

## First-Time Setup

If this is a fresh clone, the PostgreSQL databases need to exist before running `make up`.

```bash
# Start PostgreSQL
brew services start postgresql@16

# Create the app user and databases
psql -h localhost -U $(whoami) -d postgres -c "CREATE USER username WITH PASSWORD 'password';"
psql -h localhost -U $(whoami) -d postgres -c "CREATE DATABASE students OWNER username;"
psql -h localhost -U $(whoami) -d postgres -c "CREATE DATABASE schools OWNER username;"
```

Database credentials are configured in the Config Server at:

```
config-server/src/main/resources/configurations/students.yml
config-server/src/main/resources/configurations/schools.yml
```

Change `username` and `password` in those files to match your PostgreSQL setup.

---

## Demo / Testing

All requests go through the **API Gateway on port 8222**. The gateway routes them to the appropriate service — you never need to call the services directly.

### Create schools

```bash
curl -s -X POST http://localhost:8222/api/v1/schools \
  -H "Content-Type: application/json" \
  -d '{"name":"MIT","email":"contact@mit.edu"}'

curl -s -X POST http://localhost:8222/api/v1/schools \
  -H "Content-Type: application/json" \
  -d '{"name":"Stanford","email":"info@stanford.edu"}'
```

### Get all schools

```bash
curl -s http://localhost:8222/api/v1/schools
```

```json
[
  {"id": 1, "name": "MIT",      "email": "contact@mit.edu"},
  {"id": 2, "name": "Stanford", "email": "info@stanford.edu"}
]
```

### Create students

```bash
# Two students at MIT (schoolId 1)
curl -s -X POST http://localhost:8222/api/v1/students \
  -H "Content-Type: application/json" \
  -d '{"firstname":"Alice","lastname":"Johnson","email":"alice@mit.edu","schoolId":1}'

curl -s -X POST http://localhost:8222/api/v1/students \
  -H "Content-Type: application/json" \
  -d '{"firstname":"Bob","lastname":"Smith","email":"bob@mit.edu","schoolId":1}'

# One student at Stanford (schoolId 2)
curl -s -X POST http://localhost:8222/api/v1/students \
  -H "Content-Type: application/json" \
  -d '{"firstname":"Carol","lastname":"Davis","email":"carol@stanford.edu","schoolId":2}'
```

### Get all students

```bash
curl -s http://localhost:8222/api/v1/students
```

```json
[
  {"id": 1, "firstname": "Alice", "lastname": "Johnson", "email": "alice@mit.edu",        "schoolId": 1},
  {"id": 2, "firstname": "Bob",   "lastname": "Smith",   "email": "bob@mit.edu",          "schoolId": 1},
  {"id": 3, "firstname": "Carol", "lastname": "Davis",   "email": "carol@stanford.edu",   "schoolId": 2}
]
```

### Get students by school

```bash
curl -s http://localhost:8222/api/v1/students/school/1   # MIT students
curl -s http://localhost:8222/api/v1/students/school/2   # Stanford students
```

### Get a school with its students (inter-service call)

This is the key demo endpoint. The School Service calls the Student Service via **OpenFeign** to assemble the response — two services collaborating behind one API call.

```bash
curl -s http://localhost:8222/api/v1/schools/with-students/1
```

```json
{
  "name": "MIT",
  "email": "contact@mit.edu",
  "students": [
    {"firstname": "Alice", "lastname": "Johnson", "email": "alice@mit.edu"},
    {"firstname": "Bob",   "lastname": "Smith",   "email": "bob@mit.edu"}
  ]
}
```

```bash
curl -s http://localhost:8222/api/v1/schools/with-students/2
```

```json
{
  "name": "Stanford",
  "email": "info@stanford.edu",
  "students": [
    {"firstname": "Carol", "lastname": "Davis", "email": "carol@stanford.edu"}
  ]
}
```

### Eureka Dashboard

Open [http://localhost:8761](http://localhost:8761) in a browser to see all registered services and their health status.

---

## API Reference

### Student Service — `/api/v1/students`

| Method | Path | Description |
|---|---|---|
| `POST` | `/api/v1/students` | Create a student |
| `GET` | `/api/v1/students` | Get all students |
| `GET` | `/api/v1/students/school/{schoolId}` | Get students by school |

**Student fields:**

```json
{
  "firstname": "string",
  "lastname":  "string",
  "email":     "string",
  "schoolId":  1
}
```

### School Service — `/api/v1/schools`

| Method | Path | Description |
|---|---|---|
| `POST` | `/api/v1/schools` | Create a school |
| `GET` | `/api/v1/schools` | Get all schools |
| `GET` | `/api/v1/schools/with-students/{schoolId}` | Get school + its students |

**School fields:**

```json
{
  "name":  "string",
  "email": "string"
}
```

---

## Project Structure

```
microservices-project/
├── Makefile                          # up / down / status / logs
├── config-server/                    # Spring Cloud Config Server (:8888)
│   └── src/main/resources/
│       ├── application.yml
│       └── configurations/           # config files served to each service
│           ├── students.yml
│           ├── schools.yml
│           ├── discovery.yml
│           └── gateway.yml
├── discovery/                        # Eureka Discovery Server (:8761)
├── gateway/                          # Spring Cloud Gateway (:8222)
├── student/                          # Student Microservice (:8090)
│   └── src/main/java/net/javaguides/student/
│       ├── Student.java              # JPA entity
│       ├── StudentRepository.java
│       ├── StudentService.java
│       └── StudentController.java
└── school/                           # School Microservice (:8070)
    └── src/main/java/net/javaguides/school/
        ├── School.java               # JPA entity
        ├── Student.java              # DTO (received from Student Service)
        ├── FullSchoolResponse.java   # DTO (school + students)
        ├── SchoolRepository.java
        ├── SchoolService.java
        ├── SchoolController.java
        └── StudentClient.java        # OpenFeign client → Student Service
```

## Technology Stack

| Technology | Role |
|---|---|
| Spring Boot 4 | Application framework |
| Spring Cloud Gateway (WebMVC) | API routing |
| Spring Cloud Netflix Eureka | Service discovery |
| Spring Cloud Config | Centralized configuration |
| Spring Cloud OpenFeign | Declarative HTTP client |
| Spring Data JPA + Hibernate | Database access |
| PostgreSQL | Relational database |
| Lombok | Boilerplate reduction |
| Maven | Build tool |
