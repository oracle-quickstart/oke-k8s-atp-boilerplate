# import global config.
# You can change the default config with `make config="config_special.env" build`
gconfig ?= global.env
include $(gconfig)
export $(shell sed 's/=.*//' $(gconfig))

NS?=dev
REPO_WORKSPACE?="."

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

IN = $(wildcard k8s-templates/*.yaml)
OUT = $(subst k8s-templates/,k8s-deploy/,$(IN))

k8s/overlays/%.yaml: k8s-templates/%.yaml
	sed 's|\\{\\{DIGEST\\}\\}|$(DIGEST)|' $< > $@

.PHONY: build
build: backup ## Build kubernetes manifests with kustomize
	kubectl kustomize k8s/overlays/$(ENVIRONMENT) > k8s/build/current/deployment.$(ENVIRONMENT).yaml

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

.PHONY: buildall
buildall: ## build and publish all images in the project
	@find $(REPO_WORKSPACE)/src/ -type f -iname makefile -exec make -f {} build \;
	@find $(REPO_WORKSPACE)/src/ -type f -iname makefile -exec make -f {} publish \;

.PHONY: installall
installall: ## Install all virtual environments
	@find $(REPO_WORKSPACE)/src/ -type f -iname makefile -exec make -f {} install \;

.PHONY: installall-ci
installall-ci: ## Install all virtual environments
	@find $(REPO_WORKSPACE)/src/ -type f -iname makefile -exec make -f {} install-ci \;

.PHONY: lintall
lintall:  ## Lint all python projects
	@find $(REPO_WORKSPACE)/src/ -type f -iname makefile -exec make -f {} lint \;

.PHONY: digests
digests: ## update image digests in the kustomization file
	@mv k8s/overlays/$(ENVIRONMENT)/kustomization.yaml k8s/overlays/$(ENVIRONMENT)/kustomization.yaml.bak
	@sed '/^images:/q' k8s/overlays/$(ENVIRONMENT)/kustomization.yaml.bak > k8s/overlays/$(ENVIRONMENT)/kustomization.yaml
	@find $(REPO_WORKSPACE)/src/ -type f -iname makefile -exec make -f {} digest \; | awk -F"@" '{ printf "- name: %s\n  digest: %s\n", $$1, $$2}' >> k8s/overlays/$(ENVIRONMENT)/kustomization.yaml
