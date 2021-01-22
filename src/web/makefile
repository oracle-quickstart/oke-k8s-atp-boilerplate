# find current path if the make file is launched from a parent directory
CURRENT_PATH := $(dir $(MAKEFILE_LIST))

# import credentials
cconfig ?= $(abspath $(CURRENT_PATH)../../creds.env)
include $(cconfig)
export $(shell sed 's/=.*//' $(cconfig))

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
v ?= $(CURRENT_PATH)/version
include $(v)
export $(shell sed 's/=.*//' $(v))

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

.PHONY: version
version: ## Output current version
	@echo $(MAJOR_VERSION).$(MINOR_VERSION).$(PATCH_VERSION)

# DOCKER TASKS
# Build the container
.PHONY: build
build: ## Build the container
	docker build -t $(APP_NAME) $(CURRENT_PATH)

.PHONY: build-nc
build-nc: ## Build the container without caching
	docker build --no-cache -t $(APP_NAME) $(CURRENT_PATH)

.PHONY: run
run: ## Run container on port configured in `config.env`
	docker run -i -t --rm --env-file=./config.env -p=$(PORT):$(PORT) --name="$(APP_NAME)" $(APP_NAME)

.PHONY: up
up: build run ## Run container on port configured in `config.env` (Alias to run)

.PHONY: stop
stop: ## Stop and remove a running container
	docker stop $(APP_NAME); docker rm $(APP_NAME)

.PHONY: repo-login
repo-login: ## Login to the registry
	docker login -u "$(DOCKER_USERNAME)" -p "$(DOCKER_PASSWORD)" $(DOCKER_REPO)

.PHONY: release
release: build-nc publish ## Make a release by building and publishing the `{version}` ans `latest` tagged containers to registry

# Docker publish
.PHONY: publish
publish: repo-login publish-latest publish-version ## Publish the `{version}` ans `latest` tagged containers to ECR

.PHONY: publish-latest
publish-latest: tag-latest ## Publish the `latest` taged container to ECR
	@echo 'publish latest to $(DOCKER_REPO)'
	docker push $(DOCKER_REPO)/$(APP_NAME):latest

.PHONY: publish-version
publish-version: tag-version ## Publish the `{version}` taged container to ECR
	@echo 'publish $(MAJOR_VERSION).$(MINOR_VERSION).$(PATCH_VERSION) to $(DOCKER_REPO)'
	docker push $(DOCKER_REPO)/$(APP_NAME):$(MAJOR_VERSION).$(MINOR_VERSION).$(PATCH_VERSION)

# Docker tagging
.PHONY: tag
tag: tag-latest tag-version ## Generate container tags for the `{version}` ans `latest` tags

.PHONY: tag-latest
tag-latest: ## Generate container `{version}` tag
	@echo 'create tag latest'
	docker tag $(APP_NAME) $(DOCKER_REPO)/$(APP_NAME):latest

.PHONY: tag-version
tag-version: ## Generate container `latest` tag
	@echo 'create tag $(MAJOR_VERSION).$(MINOR_VERSION).$(PATCH_VERSION)'
	docker tag $(APP_NAME) $(DOCKER_REPO)/$(APP_NAME):$(MAJOR_VERSION).$(MINOR_VERSION).$(PATCH_VERSION)


DIGEST_CMD = "docker inspect --format='{{index .RepoDigests 0}}' $(DOCKER_REPO)/$(APP_NAME):latest"

.PHONY: digest
digest: ## Output latest image digest
	$(eval DIGEST = $(shell eval $(DIGEST_CMD)))
	@echo $(DIGEST) 

.PHONY: install
install:

.PHONY: lint
lint:
