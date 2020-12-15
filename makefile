# import global config.
# You can change the default config with `make config="config_special.env" build`
gconfig ?= global.env
include $(gconfig)
export $(shell sed 's/=.*//' $(gconfig))

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
	rm -rf k8s/build/previous
	mv k8s/build/current k8s/build/previous
	mkdir -p k8s/build/current

IN = $(wildcard k8s-templates/*.yaml)
OUT = $(subst k8s-templates/,k8s-deploy/,$(IN))

k8s/overlays/%.yaml: k8s-templates/%.yaml
	sed 's|\\{\\{DIGEST\\}\\}|$(DIGEST)|' $< > $@

.PHONY: build
build: backup ## Build kubernetes manifests with kustomize
	kustomize build k8s/overlays/$(ENVIRONMENT) > k8s/build/current/deployment.$(ENVIRONMENT).yaml

.PHONY: deploy
deploy: backup ## Build and Deploy
	kustomize build k8s/overlays/$(ENVIRONMENT) > k8s/build/current/deployment.$(ENVIRONMENT).yaml
	kustomize build k8s/overlays/$(ENVIRONMENT) | kubectl apply -f -

.PHONY: setup
setup: ## Setup dependencies
	./scripts/setup.sh 
