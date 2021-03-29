## Copyright (c) 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

# find current path if the make file is launched from a parent directory
CURRENT_PATH := $(dir $(MAKEFILE_LIST))

# import credentials
cconfig ?= $(strip $(wildcard $(abspath $(CURRENT_PATH)../../creds.env)))
ifneq ($cconfig,)
	include $(cconfig)
	export $(shell sed 's/=.*//' $(cconfig))
endif 

# import global config.
# You can change the default config with `make config="config_special.env" build`
gconfig ?= $(abspath $(CURRENT_PATH)../../global.env)
include $(gconfig)
export $(shell sed 's/=.*//' $(gconfig))

# import config.
# You can change the default config with `make cnf="config_special.env" build`
config ?= $(CURRENT_PATH)/config.env
include $(config)
export $(shell sed 's/=.*//' $(config))

# import version
VERSION_FILE := version.txt
v ?= $(CURRENT_PATH)/$(VERSION_FILE)
include $(v)
export $(shell sed 's/=.*//' $(v))

# Include the common docker makefile
include $(abspath $(CURRENT_PATH)../../makefile.common)

# Include the makefile tasks for python projects
# including install, linting, isort....
include $(abspath $(CURRENT_PATH)../../makefile.python)

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help
help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

.PHONY: run
run: ## Run container on port configured in `config.env`
	docker run -i -t --rm --env-file=./runtime.env -p=$(PORT):$(PORT) --name="$(APP_NAME)" $(APP_NAME)
