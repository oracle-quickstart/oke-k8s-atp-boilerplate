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

# .PHONY: backup
# backup: ## backup a current version to previous folder to keep a copy before build
# 	@mkdir -p k8s/build/current
# 	@mkdir -p k8s/build/previous
# 	@mv k8s/build/current/deployment.$(ENVIRONMENT).yaml k8s/build/previous/deployment.$(ENVIRONMENT).yaml || echo "no current version to backup"

# .PHONY: restore
# restore: ## restore a previous version to the current folder after undeploy
# 	@mv k8s/build/previous/deployment.$(ENVIRONMENT).yaml k8s/build/current/deployment.$(ENVIRONMENT).yaml || echo "no previous version"

.PHONY: build
build: ## Build, tag and push all images managed by skaffold
	skaffold build --profile=$(ENVIRONMENT) --default-repo=$(SKAFFOLD_DEFAULT_REPO)

.PHONY: deploy
deploy: clean-all-jobs ## Build and Deploy app templates
	skaffold build --profile=$(ENVIRONMENT)  --default-repo=$(SKAFFOLD_DEFAULT_REPO) -q \
	| skaffold deploy --profile=$(ENVIRONMENT)  --default-repo=$(SKAFFOLD_DEFAULT_REPO) --build-artifacts -

.PHONY: deploy-infra
deploy-infra: clean-all-jobs ## Build and Deploy infra templates
	skaffold build --profile=$(ENVIRONMENT)-infra  --default-repo=$(SKAFFOLD_DEFAULT_REPO) -q \
	| skaffold deploy --profile=$(ENVIRONMENT)-infra  --default-repo=$(SKAFFOLD_DEFAULT_REPO) --build-artifacts -

.PHONY: undeploy
delete: ## Delete the current stack
	skaffold delete --profile=$(ENVIRONMENT) --default-repo=$(SKAFFOLD_DEFAULT_REPO)

.PHONY: setup
setup: ## Setup dependencies
	./scripts/setup.sh 

.PHONY: namespace
namespace: ## create a namespace. use with NS=<namespace>
	kubectl get namespace $(NS) || kubectl create namespace $(NS)

.PHONY: secrets
secrets: ## use with NS=<namespace> :copy secrets from default to given namespace
	kubectl get secret ocir-secret --namespace=$(NS) || kubectl get secret ocir-secret --namespace=default -o yaml | grep -v '^\s*namespace:\s' | grep -v '^\s*resourceVersion:\s' | grep -v '^\s*uid:\s' | kubectl apply --namespace=$(NS) -f -
	kubectl get secret kafka-secret --namespace=$(NS) || kubectl get secret kafka-secret --namespace=default -o yaml | grep -v '^\s*namespace:\s' | grep -v '^\s*resourceVersion:\s' | grep -v '^\s*uid:\s' | kubectl apply --namespace=$(NS) -f -

.PHONY: render
render: ## Render the manifests with skaffold and kustomize
# use the -l skaffold.dev/run-id= to keep the runId label fixed accross runs
	skaffold --profile=$(ENVIRONMENT) render  --default-repo=$(SKAFFOLD_DEFAULT_REPO) -l skaffold.dev/run-id= > k8s/build/current/deployment.$(ENVIRONMENT).yaml

.PHONY: check-render
check-render: ## Check if the current render matches the saved render manifests
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
	@[[ "$$(kubectl get job -n $(NS) -o=jsonpath='{.items[].metadata.name}')" == "" ]] \
	||	kubectl delete job $$(kubectl get job -n $(NS) -o=jsonpath='{.items[].metadata.name}') -n $(NS)

.PHONY: run
run: ## run the stack, rendering the manifests with skaffold and kustomize
	skaffold run --profile=$(ENVIRONMENT) --default-repo=$(SKAFFOLD_DEFAULT_REPO)

.PHONY: debug
debug: ## run the stack in debug mode, rendering the manifests with skaffold and kustomize
	skaffold debug --port-forward --auto-sync --default-repo=$(SKAFFOLD_DEFAULT_REPO) --cleanup=false

.PHONY: dev
dev: ## run the stack in dev mode, rendering the manifests with skaffold and kustomize
	skaffold dev --auto-sync=true --default-repo=$(SKAFFOLD_DEFAULT_REPO)

.PHONY: install-all
install-all: ## Install environments for all projects
	@find $(IMAGE_FOLDER) -type f -iname makefile -print0 | xargs -0 -n1 -I{} make -f {} install

.PHONY: lint-all
lint-all: ## Lint all python projects
	@find $(IMAGE_FOLDER) -type f -iname makefile -print0 | xargs -0 -n1 -I{} make -f {} lint

.PHONY: repo-login
repo-login: ## Login to the registry
	@docker login -u "$(DOCKER_USERNAME)" -p "$(DOCKER_PASSWORD)" $(DOCKER_REPO)
