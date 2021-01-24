# Python specific makefile

.PHONY: install
install: ## Setup the virtual environment for local development
ifneq ("$(wildcard $(CURRENT_PATH)requirements.txt)","")
	virtualenv $(CURRENT_PATH).venv \
	&& source $(CURRENT_PATH).venv/bin/activate \
	&& pip3 install -r $(CURRENT_PATH)requirements.txt \
	&& pip3 install -r $(CURRENT_PATH)requirements.test.txt
endif

.PHONY: install-ci
install-ci: ## Setup the environment for CI
ifneq ("$(wildcard $(CURRENT_PATH)requirements.txt)","")
	pip3 install -r $(CURRENT_PATH)requirements.txt \
	&& pip3 install -r $(CURRENT_PATH)requirements.test.txt
endif

.PHONY: lint
lint: ## run flake8 linter and isort imports sorter test
	isort $(CURRENT_PATH)*.py --diff
	flake8 $(CURRENT_PATH)

.PHONY: isort
isort: ## run isort and fix issues
	isort $(CURRENT_PATH)*.py
