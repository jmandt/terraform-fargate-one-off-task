################################################################################
# Terraform Makefile
################################################################################

.ONESHELL:
SHELL := /bin/bash

BACKENDBUCKET=<name-of-your-terraform-remote-state-bucket>
AWS_REGION="eu-west-1"
SERVICE_NAME="my-service"

init:
	@echo "Using backend-bucket $(BACKENDBUCKET)"
	@cd terraform/rd-model && terraform init \
		-backend-config="region=$(AWS_REGION)" \
		-backend-config="bucket=$(BACKENDBUCKET)" \
		-backend-config="encrypt=true" \
        -backend-config="key=services/$(SERVICE_NAME)/$(SERVICE_NAME).tfstate"

update:
	@cd terraform/rd-model && terraform get -update=true 1>/dev/null

plan: init update
	@terraform plan \
		-input=false \
		-refresh=true \
		-module-depth=-1

plan-destroy: init update
	@terraform plan \
		-input=false \
		-refresh=true \
		-module-depth=-1 \
		-destroy

show: init
	@cdterraform show -module-depth=-1

apply: init update
	@cd terraform/rd-model && terraform apply \
	    -var environment=$(ENVIRONMENT) \
		-input=true \
		-refresh=true

destroy: init update
	@cd terraform/my-service && terraform destroy

clean:
	@rm -fR .terraform/modules

