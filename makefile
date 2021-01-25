# import global config.
# You can change the default config with `make config="config_special.env" build`
gconfig ?= global.env
include $(gconfig)
export $(shell sed 's/=.*//' $(gconfig))

NS?=dev

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

.PHONY: build-all
build-all: ## build all images in the project
# the find -exec pattern does not return exit codes, so use xargs this way
	@find ./src -type f -iname makefile -print0 | xargs -0 -n1 -I{} make -f {} build

.PHONY: publish-all
publish-all: ## publish all images in the project
	@find ./src -type f -iname makefile -print0 | xargs -0 -n1 -I{} make -f {} publish

.PHONY: release-all
release-all: ## release all images in the project
	@find ./src -type f -iname makefile -print0 | xargs -0 -n1 -I{} make -f {} release

.PHONY: install-all
install-all: ## Install environments for all projects
	@find ./src -type f -iname makefile -print0 | xargs -0 -n1 -I{} make -f {} install

.PHONY: lint-all
lint-all: ## Lint all python projects
	@find ./src -type f -iname makefile -print0 | xargs -0 -n1 -I{} make -f {} lint
 
.PHONY: set-digests
set-digests: ## set image digests in the kustomization file
	@mv k8s/overlays/$(ENVIRONMENT)/kustomization.yaml k8s/overlays/$(ENVIRONMENT)/kustomization.yaml.bak
	@sed '/^images:/q' k8s/overlays/$(ENVIRONMENT)/kustomization.yaml.bak > k8s/overlays/$(ENVIRONMENT)/kustomization.yaml
	@find ./src -type f -iname makefile -print0 | xargs -0 -n1 -I{} make -f {} digest | awk -F"@" '{ printf "- name: %s\n  digest: %s\n", $$1, $$2}' >> k8s/overlays/$(ENVIRONMENT)/kustomization.yaml
	@rm k8s/overlays/$(ENVIRONMENT)/kustomization.yaml.bak

.PHONY: check-digests
check-digests: ## check that image digests in the kustomization file match latest digests
	@cp k8s/overlays/$(ENVIRONMENT)/kustomization.yaml k8s/overlays/$(ENVIRONMENT)/kustomization.yaml.bak
	@sed '/^images:/q' k8s/overlays/$(ENVIRONMENT)/kustomization.yaml.bak > k8s/overlays/$(ENVIRONMENT)/check.yaml
	@find ./src -type f -iname makefile -print0 | xargs -0 -n1 -I{} make -f {} digest | awk -F"@" '{ printf "- name: %s\n  digest: %s\n", $$1, $$2}' >> k8s/overlays/$(ENVIRONMENT)/check.yaml
	@diff k8s/overlays/$(ENVIRONMENT)/kustomization.yaml k8s/overlays/$(ENVIRONMENT)/check.yaml
	@rm k8s/overlays/$(ENVIRONMENT)/check.yaml

.PHONY: set-versions
set-versions: ## set image versions in the kustomization file
	@mv k8s/overlays/$(ENVIRONMENT)/kustomization.yaml k8s/overlays/$(ENVIRONMENT)/kustomization.yaml.bak
	@sed '/^images:/q' k8s/overlays/$(ENVIRONMENT)/kustomization.yaml.bak > k8s/overlays/$(ENVIRONMENT)/kustomization.yaml
	@find ./src -type f -iname makefile -print0 | xargs -0 -n1 -I{} make -f {} image-version | awk -F":" '{ printf "- name: %s\n  newTag: %s\n", $$1, $$2}' >> k8s/overlays/$(ENVIRONMENT)/kustomization.yaml

.PHONY: check-versions
check-versions: ## check that image digests in the kustomization file match latest digests
	@cp k8s/overlays/$(ENVIRONMENT)/kustomization.yaml k8s/overlays/$(ENVIRONMENT)/kustomization.yaml.bak
	@sed '/^images:/q' k8s/overlays/$(ENVIRONMENT)/kustomization.yaml.bak > k8s/overlays/$(ENVIRONMENT)/check.yaml
	@find ./src -type f -iname makefile -print0 | xargs -0 -n1 -I{} make -f {} image-version | awk -F":" '{ printf "- name: %s\n  newTag: %s\n", $$1, $$2}' >> k8s/overlays/$(ENVIRONMENT)/check.yaml
	@diff k8s/overlays/$(ENVIRONMENT)/kustomization.yaml k8s/overlays/$(ENVIRONMENT)/check.yaml
	@rm k8s/overlays/$(ENVIRONMENT)/check.yaml
