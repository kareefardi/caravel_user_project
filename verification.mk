VERIFICATION_IMAGE = efabless/dv:latest

LOGS_DIR = logs
PROJECT_ROOT=$(realpath $(PWD))
CARAVEL_DIR = $(PROJECT_ROOT)/caravel
CARAVEL_CORE_DIR = $(PROJECT_ROOT)/caravel_mgmt_soc_litex
STANDALONE_DIR = $(PROJECT_ROOT)/caravel_mgmt_soc_litex/verilog/dv/tests-standalone
CARAVEL_TEST_DIR = $(PROJECT_ROOT)/caravel_mgmt_soc_litex/verilog/dv/tests-caravel

ifeq ($(wildcard $(CARAVEL_DIR)/.),)
$(error $(CARAVEL_DIR) not found)
endif

ifeq ($(wildcard $(CARAVEL_CORE_DIR)/.),)
$(error $(CARAVEL_CORE_DIR) not found)
endif

STANDALONE = $(shell cd $(STANDALONE_DIR) && find * -maxdepth 0 -type d)
CARAVEL_TEST = $(shell cd $(CARAVEL_TEST_DIR) && find * -maxdepth 0 -type d)
STANDALONE_TARGETS := $(foreach i, $(STANDALONE), standalone-$(i))
CARAVEL_TEST_TARGETS := $(foreach i, $(CARAVEL_TEST), caravel-$(i))

DOCKER_ENV =  -e CARAVEL_VERILOG_PATH=$(CARAVEL_DIR)/verilog
DOCKER_ENV += -e CORE_VERILOG_PATH=$(CARAVEL_CORE_DIR)/verilog
DOCKER_ENV += -e PDK_ROOT=$(PDK_ROOT)

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

all: $(STANDALONE_TARGETS) $(CARAVEL_TEST_TARGETS)

list: list-standalone list-caravel

list-standalone:
	# standalone $(STANDALONE_TARGETS)

list-caravel:
	# caravel $(CARAVEL_TEST_TARGETS)

logs:
	@mkdir -p logs

$(STANDALONE_TARGETS): standalone-% : % $(LOGS_DIR)
	# --------------------------------------------------------
	# target: $(STANDALONE_DIR)/$*
	# caravel: $(CARAVEL_DIR)
	# running $@
	@$(DOCKER_RUNNER_CMD) \
		bash -c "source /.bashrc && env && cd $(STANDALONE_DIR)/$* && make" 2>&1 > $(LOGS_DIR)/$@.log
	# +++++++++++++++++++++++++++++++++++++++++ done $@

$(CARAVEL_TEST_TARGETS): caravel-% : % $(LOGS_DIR)
	# --------------------------------------------------------
	# target: $(CARAVEL_TEST_DIR)/$*
	# caravel: $(CARAVEL_DIR)
	# running $@
	@$(DOCKER_RUNNER_CMD) \
		bash -c "source /.bashrc && env && cd $(CARAVEL_TEST_DIR)/$* && make" 2>&1 > $(LOGS_DIR)/$@.log
	# +++++++++++++++++++++++++++++++++++++++++ done $@
