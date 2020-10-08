.PHONY: *

HELP_TAB_WIDTH = 25

.DEFAULT_GOAL := help

SHELL=/bin/bash -o pipefail

check-dependency = $(if $(shell command -v $(1)),,$(error Make sure $(1) is installed))

check-dependencies:
	@#(call check-dependency,grep)
	@#(call check-dependency,cut)

help:
	@$(foreach m,$(MAKEFILE_LIST),grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(m) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-$(HELP_TAB_WIDTH)s\033[0m %s\n", $$1, $$2}';)

version: check-dependencies ## Shows the current version of the project
	@./gradlew properties | grep 'version:' | cut -d' ' -f2

clean: check-dependencies ## Clean up and build artifacts
	@./gradlew clean	

build: check-dependencies ## Compiles the Java code
	@./gradlew build

test: build ## Run unit tests
	@./gradlew test

package: test ## Creates any package artifacts (Docker, Assembly JAR, etc..)
	@./gradlew shadowJar
	@./gradlew jibDockerBuild 

publish: package ## Publishes packages to registries (Docker only for now) 
	@./gradlew jib --image cnfldemos/cp-demo-kstreams:$(shell make version)

