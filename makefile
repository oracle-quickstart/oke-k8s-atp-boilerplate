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
backup:
	mkdir -p k8s/build/current
	mkdir -p k8s/build/previous
	mv k8s/build/current/deployment.$(ENVIRONMENT).yaml k8s/build/previous/deployment.$(ENVIRONMENT).yaml || echo "no previous version"

IN = $(wildcard k8s-templates/*.yaml)
OUT = $(subst k8s-templates/,k8s-deploy/,$(IN))

k8s/overlays/%.yaml: k8s-templates/%.yaml
	sed 's|\\{\\{DIGEST\\}\\}|$(DIGEST)|' $< > $@

.PHONY: build
build: backup ## Build kubernetes manifests with kustomize
	kustomize build k8s/overlays/$(ENVIRONMENT) > k8s/build/current/deployment.$(ENVIRONMENT).yaml

.PHONY: deploy
deploy: backup ## Build and Deploy
	kubectl kustomize k8s/overlays/$(ENVIRONMENT) > k8s/build/current/deployment.$(ENVIRONMENT).yaml
	kubectl kustomize k8s/overlays/$(ENVIRONMENT) | kubectl apply -f -

.PHONY: undeploy
undeploy: backup ## Build and unDeploy
	kubectl kustomize k8s/overlays/$(ENVIRONMENT) > k8s/build/current/deployment.$(ENVIRONMENT).yaml
	kubectl kustomize k8s/overlays/$(ENVIRONMENT) | kubectl delete -f -

.PHONY: setup
setup: ## Setup dependencies
	./scripts/setup.sh 

.PHONY: secret
secret: ## use with NS=<namespace> :copy OCIR credentials secret from default namespace to given namespace
	kubectl get secret ocir-secret --namespace=$(NS) || kubectl get secret ocir-secret --namespace=default -o yaml | grep -v '^\s*namespace:\s' | grep -v '^\s*resourceVersion:\s' | grep -v '^\s*uid:\s' | kubectl apply --namespace=$(NS) -f -

.PHONY: buildall
buildall: ## build all images in the project
	find $(REPO_WORKSPACE)/src/ -type f -iname makefile -exec make -f {} build \;
	find $(REPO_WORKSPACE)/src/ -type f -iname makefile -exec make -f {} publish \;

.PHONY: namespace
namespace: ## create a namespace. use with NS=<namespace>
	kubectl get namespace $(NS) || kubectl create namespace $(NS)