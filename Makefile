# Usage:
#   make bootstrap GITHUB_REPO=my-org/infra-terraform
#   make plan  ENV=dev TF_STATE_BUCKET=<bucket> AWS_REGION=us-east-1
#   make apply ENV=dev TF_STATE_BUCKET=<bucket> AWS_REGION=us-east-1

ENV             ?= dev
AWS_REGION      ?= us-east-1
TF_STATE_BUCKET ?=
GITHUB_REPO     ?=

ENV_DIR := envs/$(ENV)

.PHONY: help bootstrap init plan apply destroy output fmt validate kubeconfig check-bucket

help:
	@echo "Targets: bootstrap init plan apply destroy output fmt validate kubeconfig"
	@echo "Vars:    ENV=$(ENV) AWS_REGION=$(AWS_REGION) TF_STATE_BUCKET=$(TF_STATE_BUCKET)"

# -----------------------------------------------------------------------------
# One-time account setup
# -----------------------------------------------------------------------------
bootstrap:
	@test -n "$(GITHUB_REPO)" || (echo "GITHUB_REPO is required, e.g. my-org/infra-terraform" && exit 1)
	terraform -chdir=bootstrap init
	terraform -chdir=bootstrap apply -var="aws_region=$(AWS_REGION)" -var="github_infra_repo=$(GITHUB_REPO)"

# -----------------------------------------------------------------------------
# Environments
# -----------------------------------------------------------------------------
check-bucket:
	@test -n "$(TF_STATE_BUCKET)" || (echo "TF_STATE_BUCKET is required (bootstrap output state_bucket_name)" && exit 1)

init: check-bucket
	terraform -chdir=$(ENV_DIR) init -backend-config="bucket=$(TF_STATE_BUCKET)" -backend-config="region=$(AWS_REGION)"

plan: init
	terraform -chdir=$(ENV_DIR) plan -out=plan.tfplan

apply:
	terraform -chdir=$(ENV_DIR) apply plan.tfplan

destroy: init
	terraform -chdir=$(ENV_DIR) destroy

output:
	terraform -chdir=$(ENV_DIR) output

kubeconfig:
	aws eks update-kubeconfig --region $(AWS_REGION) --name $$(terraform -chdir=$(ENV_DIR) output -raw cluster_name)

# -----------------------------------------------------------------------------
# Checks
# -----------------------------------------------------------------------------
fmt:
	terraform fmt -recursive

validate:
	@for d in bootstrap envs/dev envs/prod; do \
		echo "==> $$d"; \
		terraform -chdir=$$d init -backend=false -input=false >/dev/null && terraform -chdir=$$d validate || exit 1; \
	done
