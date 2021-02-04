# import global config.
# You can change the default config with `make config="config_special.env" build`
gconfig ?= global.env
include $(gconfig)
export $(shell sed 's/=.*//' $(gconfig))

NS?=dev-ns

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

.PHONY: backup
backup: ## backup a current version to previous folder to keep a copy before build
	@mkdir -p k8s/build/current
	@mkdir -p k8s/build/previous
	@mv k8s/build/current/deployment.$(ENVIRONMENT).yaml k8s/build/previous/deployment.$(ENVIRONMENT).yaml || echo "no current version to backup"

.PHONY: restore
restore: ## restore a previous version to the current folder after undeploy
	@mv k8s/build/previous/deployment.$(ENVIRONMENT).yaml k8s/build/current/deployment.$(ENVIRONMENT).yaml || echo "no previous version"

.PHONY: build
build: backup ## Build, tag and push all images managed by skaffold
	skaffold build 
# kubectl kustomize k8s/overlays/$(ENVIRONMENT) > k8s/build/current/deployment.$(ENVIRONMENT).yaml

.PHONY: deploy
deploy: backup build ## Build and Deploy
	kubectl apply -f k8s/build/current/deployment.$(ENVIRONMENT).yaml

.PHONY: undeploy
undeploy: ## unDeploy the current stack
	kubectl delete -f k8s/build/current/deployment.$(ENVIRONMENT).yaml
	make restore

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
	skaffold --profile=$(ENVIRONMENT) render -l skaffold.dev/run-id= > k8s/build/current/deployment.$(ENVIRONMENT).yaml

.PHONY: check-render
check-render: ## Check if the current render matches the saved render manifests
	@skaffold --profile=$(ENVIRONMENT) render -l skaffold.dev/run-id= | diff k8s/build/current/deployment.$(ENVIRONMENT).yaml - \
	&& echo "No changes"

.PHONY: clean-jobs
clean-jobs: ## Clean completed Job. Skaffold can't update them and fails
# skaffold doesn't work well with Jobs as they are immutable
	kubectl delete job $$(kubectl get job -o=jsonpath='{.items[?(@.status.succeeded==1)].metadata.name}')

.PHONY: run
run: clean-jobs ## run the stack, rendering the manifests with skaffold and kustomize
	skaffold --profile=$(ENVIRONMENT) run --cleanup=false

.PHONY: debug
debug: clean-jobs ## run the stack in debug mode, rendering the manifests with skaffold and kustomize
	skaffold --profile=$(ENVIRONMENT) debug --port-forward --cleanup=false --auto-sync

.PHONY: dev
dev: clean-jobs ## run the stack in dev mode, rendering the manifests with skaffold and kustomize
	skaffold --profile=$(ENVIRONMENT) dev --cleanup=false --auto-sync=false --auto-build=true --force=true

.PHONY: install-all
install-all: ## Install environments for all projects
	@find ./src -type f -iname makefile -print0 | xargs -0 -n1 -I{} make -f {} install

.PHONY: lint-all
lint-all: ## Lint all python projects
	@find ./src -type f -iname makefile -print0 | xargs -0 -n1 -I{} make -f {} lint
 
