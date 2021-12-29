VERIFICATION_IMAGE = efabless/dv:latest

LOGS_DIR = logs
PROJECT_ROOT=$(realpath $(PWD))
CARAVEL_ROOT = $(PROJECT_ROOT)/caravel
CARAVEL_PICO_ROOT=$(PROJECT_ROOT)/caravel_pico
PICO_STANDALONE_DIR = $(CARAVEL_PICO_ROOT)/verilog/dv/standalone
PICO_CARAVEL_TEST_DIR = $(CARAVEL_PICO_ROOT)/verilog/dv/caravel

THREADS ?= 1
SIM ?= RTL

ifeq ($(wildcard $(CARAVEL_ROOT)/.),)
$(error $(CARAVEL_ROOT) not found)
endif

ifeq ($(wildcard $(CARAVEL_PICO_ROOT)/.),)
$(error $(CARAVEL_PICO_ROOT) not found)
endif

STANDALONE = $(shell cd $(PICO_STANDALONE_DIR) && find * -maxdepth 0 -type d)
CARAVEL_TEST = $(shell cd $(PICO_CARAVEL_TEST_DIR) && find * -maxdepth 0 -type d)
STANDALONE_TARGETS := $(foreach i, $(STANDALONE), standalone-$(i))
CARAVEL_TEST_TARGETS := $(foreach i, $(CARAVEL_TEST), caravel-$(i))

DOCKER_ENV =  -e CARAVEL_PICO_ROOT=$(CARAVEL_PICO_ROOT)
DOCKER_ENV += -e CARAVEL_ROOT=$(CARAVEL_ROOT)
DOCKER_ENV += -e PDK_ROOT=$(PDK_ROOT)
DOCKER_ENV += -e GCC_PREFIX=riscv32-unknown-linux-gnu

check_defined = \
		    $(strip $(foreach 1,$1, \
		            $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
		      $(if $(value $1),, \
		            $(error Undefined $1$(if $2, ($2))))

$(call check_defined, PDK_ROOT, Please define missing variables)

DOCKER_RUNNER_CMD = docker run -t \
			    -v $(PROJECT_ROOT):$(PROJECT_ROOT) \
			    -v $(PDK_ROOT):$(PDK_ROOT) \
			    $(DOCKER_ENV) \
			    -u $(shell id -u $(USER)):$(shell id -g $(USER)) \
			    $(VERIFICATION_IMAGE) \


.PHONY: $(CARAVEL_TEST_TARGETS)
.PHONY: $(CARAVEL_TEST)
.PHONY: $(STANDALONE_TARGETS)
.PHONY: $(STANDALONE)
.PHONY: $(STANDALONE_TARGETS)
.PHONY: list-standalone
.PHONY: list-caravel
.PHONY: list


caravel-all : $(CARAVEL_TEST_TARGETS)

all: $(STANDALONE_TARGETS) caravel-all

list: list-standalone list-caravel

list-standalone:
	# standalone $(STANDALONE_TARGETS)

list-caravel:
	# caravel $(CARAVEL_TEST_TARGETS)

logs:
	@mkdir -p logs

$(STANDALONE_TARGETS): standalone-% : % $(LOGS_DIR)
	@echo "Time: $$(date) --------------------------------------------------------"
	# target: $(PICO_STANDALONE_DIR)/$*
	# caravel: $(CARAVEL_ROOT)
	# running $@
	@$(DOCKER_RUNNER_CMD) \
		bash -c "source /.bashrc && env && cd $(PICO_STANDALONE_DIR)/$* && make $(SIM) -j$(THREADS)" 2>&1 > $(LOGS_DIR)/$@.log
	@echo "Time: $$(date) +++++++++++++++++++++++++++++++++++++++++ done $@"

$(CARAVEL_TEST_TARGETS): caravel-% : % $(LOGS_DIR)
	@echo "Time: $$(date) --------------------------------------------------------"
	# target: $(PICO_CARAVEL_TEST_DIR)/$*
	# caravel: $(CARAVEL_ROOT)
	# running $@
	@$(DOCKER_RUNNER_CMD) \
		bash -c "source /.bashrc && env && cd $(PICO_CARAVEL_TEST_DIR)/$* && make $(SIM) -j$(THREADS)" 2>&1 > $(LOGS_DIR)/$@.log
	@echo "Time: $$(date) +++++++++++++++++++++++++++++++++++++++++ done $@"
