JAVA_HOME := /Users/farzinadil/Library/Java/JavaVirtualMachines/graalvm-jdk-17.0.12/Contents/Home
ROOT      := $(shell pwd)
LOG_DIR   := /tmp/ms-logs
PID_DIR   := /tmp/ms-pids

export JAVA_HOME

.PHONY: up down status logs help

# ─── default ─────────────────────────────────────────────────────────────────

help:
	@echo "Usage:"
	@echo "  make up      Start all services (PostgreSQL + 5 Spring Boot apps)"
	@echo "  make down    Stop all services"
	@echo "  make status  Show which services are running"
	@echo "  make logs    Tail logs from all services"

# ─── up ──────────────────────────────────────────────────────────────────────

up:
	@mkdir -p $(LOG_DIR) $(PID_DIR)
	@$(MAKE) -s pg-start
	@$(MAKE) -s svc-config-server
	@$(MAKE) -s svc-discovery
	@$(MAKE) -s svc-gateway
	@$(MAKE) -s svc-student
	@$(MAKE) -s svc-school
	@echo ""
	@echo "All services are up:"
	@echo "  Config Server  →  http://localhost:8888"
	@echo "  Discovery      →  http://localhost:8761"
	@echo "  Gateway        →  http://localhost:8222"
	@echo "  Student        →  http://localhost:8090"
	@echo "  School         →  http://localhost:8070"
	@echo ""
	@echo "  API entry point: http://localhost:8222"

# ─── individual service targets ──────────────────────────────────────────────

svc-config-server:
	@echo "Starting config-server..."
	@cd $(ROOT)/config-server && \
	  ./mvnw -q spring-boot:run > $(LOG_DIR)/config-server.log 2>&1 & \
	  echo $$! > $(PID_DIR)/config-server.pid
	@$(call wait_for,config-server,Started ConfigServerApplication,8888)

svc-discovery:
	@echo "Starting discovery..."
	@cd $(ROOT)/discovery && \
	  ./mvnw -q spring-boot:run > $(LOG_DIR)/discovery.log 2>&1 & \
	  echo $$! > $(PID_DIR)/discovery.pid
	@$(call wait_for,discovery,Started DiscoveryApplication,8761)

svc-gateway:
	@echo "Starting gateway..."
	@cd $(ROOT)/gateway && \
	  ./mvnw -q spring-boot:run > $(LOG_DIR)/gateway.log 2>&1 & \
	  echo $$! > $(PID_DIR)/gateway.pid
	@$(call wait_for,gateway,Started GatewayApplication,8222)

svc-student:
	@echo "Starting student service..."
	@cd $(ROOT)/student && \
	  ./mvnw -q spring-boot:run > $(LOG_DIR)/student.log 2>&1 & \
	  echo $$! > $(PID_DIR)/student.pid
	@$(call wait_for,student,Started StudentApplication,8090)

svc-school:
	@echo "Starting school service..."
	@cd $(ROOT)/school && \
	  ./mvnw -q spring-boot:run > $(LOG_DIR)/school.log 2>&1 & \
	  echo $$! > $(PID_DIR)/school.pid
	@$(call wait_for,school,Started SchoolApplication,8070)

# ─── wait helper (polls log for "Started" or "FAILED", timeout 120s) ─────────

define wait_for
	@svc=$(1); log=$(LOG_DIR)/$(1).log; \
	for i in $$(seq 1 120); do \
	  if grep -q "$(2)" $$log 2>/dev/null; then \
	    echo "  ✓ $(1) is ready (port $(3))"; break; \
	  fi; \
	  if grep -qE "BUILD FAILURE|APPLICATION FAILED TO START" $$log 2>/dev/null; then \
	    echo "  ✗ $(1) failed to start — see $(LOG_DIR)/$(1).log"; exit 1; \
	  fi; \
	  sleep 1; \
	done
endef

# ─── down ─────────────────────────────────────────────────────────────────────

down:
	@echo "Stopping services..."
	@for svc in school student gateway discovery config-server; do \
	  pid_file=$(PID_DIR)/$$svc.pid; \
	  if [ -f $$pid_file ]; then \
	    pid=$$(cat $$pid_file); \
	    if kill -0 $$pid 2>/dev/null; then \
	      kill $$pid 2>/dev/null && echo "  stopped $$svc (PID $$pid)"; \
	    fi; \
	    rm -f $$pid_file; \
	  fi; \
	done
	@echo "Done."

# ─── status ──────────────────────────────────────────────────────────────────

status:
	@echo "Service status:"
	@$(call check_svc,config-server,8888)
	@$(call check_svc,discovery,8761)
	@$(call check_svc,gateway,8222)
	@$(call check_svc,student,8090)
	@$(call check_svc,school,8070)

define check_svc
	@pid_file=$(PID_DIR)/$(1).pid; \
	if [ -f $$pid_file ] && kill -0 $$(cat $$pid_file) 2>/dev/null; then \
	  echo "  ✓ $(1)  (port $(2), PID $$(cat $$pid_file))"; \
	else \
	  echo "  ✗ $(1)  (stopped)"; \
	fi
endef

# ─── logs ────────────────────────────────────────────────────────────────────

logs:
	@tail -f \
	  $(LOG_DIR)/config-server.log \
	  $(LOG_DIR)/discovery.log \
	  $(LOG_DIR)/gateway.log \
	  $(LOG_DIR)/student.log \
	  $(LOG_DIR)/school.log

# ─── PostgreSQL ──────────────────────────────────────────────────────────────

pg-start:
	@if pg_isready -h localhost -q 2>/dev/null; then \
	  echo "  ✓ PostgreSQL already running"; \
	else \
	  echo "Starting PostgreSQL..."; \
	  brew services start postgresql@16 > /dev/null 2>&1; \
	  for i in $$(seq 1 15); do \
	    pg_isready -h localhost -q 2>/dev/null && echo "  ✓ PostgreSQL ready" && break; \
	    sleep 1; \
	  done; \
	fi
