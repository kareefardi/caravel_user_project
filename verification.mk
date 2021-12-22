VERIFICATION_IMAGE = verification:alpha

LOGS_DIR = logs
CARAVEL_DIR = $(realpath $(PWD)/caravel)
CARAVEL_CORE_DIR = $(realpath $(PWD)/caravel_mgmt_soc_litex)
STANDALONE_DIR = $(PWD)/caravel_mgmt_soc_litex/verilog/dv/tests-standalone
CARAVEL_TEST_DIR = $(PWD)/caravel_mgmt_soc_litex/verilog/dv/tests-caravel

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

DOCKER_RUNNER_CMD = docker run -it \
			    -v $(PWD):$(PWD) \
			    -v $(PDK_ROOT):$(PDK_ROOT) \
			    $(DOCKER_ENV) \
			    -u $(shell id -u $(USER)):$(shell id -g $(USER)) \
			    $(VERIFICATION_IMAGE) \


.PHONY: $(STANDALONE)
.PHONY: $(STANDALONE_TARGETS)
.PHONY: list-standalone
.PHONY: list-caravel
.PHONY: list

all: $(STANDALONE-TARGETS) $(CARAVEL_TEST_TARGETS)

list: list-standalone list-caravel

list-standalone:
	# standalone $(STANDALONE_TARGETS)

list-caravel:
	# caravel $(CARAVEL_TEST_TARGETS)

logs:
	@mkdir -p logs

$(STANDALONE_TARGETS): standalone-% : % $(LOGS_DIR)
	# target: $(STANDALONE_DIR)/$*
	# caravel: $(CARAVEL_DIR)
	$(DOCKER_RUNNER_CMD) \
		bash -c "source /.bashrc && env && cd $(STANDALONE_DIR)/$* && make" | tee $(LOGS_DIR)/$@.log


$(CARAVEL_TEST_TARGETS): caravel-% : % $(LOGS_DIR)
	# target: $(CARAVEL_TEST_DIR)/$*
	# caravel: $(CARAVEL_DIR)
	$(DOCKER_RUNNER_CMD) \
		bash -c "source /.bashrc && env && cd $(CARAVEL_TEST_DIR)/$* && make" | tee $(LOGS_DIR)/$@.log
