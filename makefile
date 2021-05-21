## Copyright (c) 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

# import credentials
cconfig ?= creds.env
include $(cconfig)
export $(shell sed 's/=.*//' $(cconfig))

# import global config.
# You can change the default config with `make config="config_special.env" build`
gconfig ?= global.env
include $(gconfig)
export $(shell sed 's/=.*//' $(gconfig))

NS?=dev-ns
IMAGE_FOLDER?=./images

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

.PHONY: build
build: repo-login ## Build, tag and push all app images managed by skaffold
	skaffold build --profile=$(ENVIRONMENT) --default-repo=$(SKAFFOLD_DEFAULT_REPO)

.PHONY: build-infra
build-infra: repo-login ## Build, tag and push all images from the infra managed by skaffold
	skaffold build --profile=$(ENVIRONMENT)-infra --default-repo=$(SKAFFOLD_DEFAULT_REPO)

.PHONY: deploy
deploy: repo-login clean-all-jobs ## Build and Deploy app templates
	skaffold build --profile=$(ENVIRONMENT)  --default-repo=$(SKAFFOLD_DEFAULT_REPO) -q \
	| skaffold deploy --profile=$(ENVIRONMENT)  --default-repo=$(SKAFFOLD_DEFAULT_REPO) --build-artifacts -

.PHONY: deploy-infra
deploy-infra: repo-login clean-all-jobs ## Build and Deploy infra templates
	skaffold build --profile=$(ENVIRONMENT)-infra  --default-repo=$(SKAFFOLD_DEFAULT_REPO) -q \
	| skaffold deploy --profile=$(ENVIRONMENT)-infra  --default-repo=$(SKAFFOLD_DEFAULT_REPO) --build-artifacts -

.PHONY: delete
delete: ## Delete the current stack
	skaffold delete --profile=$(ENVIRONMENT) --default-repo=$(SKAFFOLD_DEFAULT_REPO)

.PHONY: delete-infra
delete-infra: ## Delete the current stack
	skaffold delete --profile=$(ENVIRONMENT)-infra --default-repo=$(SKAFFOLD_DEFAULT_REPO)

.PHONY: setup
setup: ## Setup dependencies
	./scripts/setup.sh 

.PHONY: render
render: ## Render the manifests with skaffold and kustomize
# use the -l skaffold.dev/run-id= to keep the runId label fixed accross runs
	skaffold --profile=$(ENVIRONMENT) render  --default-repo=$(SKAFFOLD_DEFAULT_REPO) -l skaffold.dev/run-id= > k8s/build/current/deployment.$(ENVIRONMENT).yaml

.PHONY: check-render
check-render: ## Check if the current render matches the saved rendered manifests
	@skaffold --profile=$(ENVIRONMENT) render  --default-repo=$(SKAFFOLD_DEFAULT_REPO) -l skaffold.dev/run-id= | diff k8s/build/current/deployment.$(ENVIRONMENT).yaml - \
	&& echo "No changes"

.PHONY: clean-completed-jobs
clean-completed-jobs: ## Clean completed Job. Skaffold can't update them and fails
# skaffold doesn't work well with Jobs as they are immutable
	@[[ "$$(kubectl get job -o=jsonpath='{.items[?(@.status.succeeded==1)].metadata.name}')" == "" ]] \
	||	kubectl delete job $$(kubectl get job -o=jsonpath='{.items[?(@.status.succeeded==1)].metadata.name}')

.PHONY: clean-all-jobs
clean-all-jobs: ## Clean any Job. Skaffold can't update them and fails
# skaffold doesn't work well with Jobs as they are immutable
	@[[ "$$(kubectl get job -n $(NS) -o=jsonpath='{.items[*].metadata.name}')" == "" ]] \
	||	kubectl delete job $$(kubectl get job -n $(NS) -o=jsonpath='{.items[].metadata.name}') -n $(NS)

.PHONY: run
run: repo-login ## run the stack, rendering the manifests with skaffold and kustomize
	skaffold run --profile=$(ENVIRONMENT) --default-repo=$(SKAFFOLD_DEFAULT_REPO)

.PHONY: debug
debug: repo-login branch ## run the stack in debug mode, rendering the manifests with skaffold and kustomize
	skaffold debug --port-forward --auto-sync --default-repo=$(SKAFFOLD_DEFAULT_REPO) --cleanup=false

.PHONY: dev
dev: repo-login branch ## run the stack in dev mode, rendering the manifests with skaffold and kustomize
	skaffold dev --auto-sync=true --default-repo=$(SKAFFOLD_DEFAULT_REPO)

BRANCH_CMD="git branch --show-current | grep -v master | grep -v development | tr '/|\_ ' '-----' | sed 's/.*/-&/'"

.PHONY: branch
branch:
	$(eval BRANCH_NAME = $(shell eval $(BRANCH_CMD)))
	sed -i '' -e 's|nameSuffix: .*|nameSuffix: "$(BRANCH_NAME)"|g' ./k8s/overlays/branch/kustomization.yaml

.PHONY: install-all
install-all: ## Install environments for all projects
	@find $(IMAGE_FOLDER) -type f -iname makefile -print0 | xargs -0 -n1 -I{} make -f {} install

.PHONY: lint-all
lint-all: ## Lint all python projects
	@find $(IMAGE_FOLDER) -type f -iname makefile -print0 | xargs -0 -n1 -I{} make -f {} lint

.PHONY: repo-login
repo-login: ## Login to the registry
	@docker login -u "$(DOCKER_USERNAME)" -p "$(DOCKER_PASSWORD)" $(DOCKER_REPO)
