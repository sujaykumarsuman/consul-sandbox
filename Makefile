include .env
export TF_VAR_cloud_provider
export TF_VAR_aws_region

export TF_VAR_hcp_client_id
export TF_VAR_hcp_client_secret
export TF_VAR_hcp_project_id
export TF_VAR_hcp_hvn_id
export TF_VAR_hcp_cidr_block
export TF_VAR_region

export TF_VAR_consul_ent_license

# Terraform environment targets
.PHONY: tf-init tf-plan tf-apply tf-destroy
tf-init/%:
	# Initialize Terraform
	terraform -chdir=environments/$* init -upgrade

tf-plan/%:
	# Plan Terraform changes
	terraform -chdir=environments/$* plan -out=tfplan

tf-apply/%: build-hello-server build-hello-client
	# Apply the Terraform configuration
	terraform -chdir=environments/$* apply -auto-approve

tf-destroy/%:
	# Destroy the Terraform-managed infrastructure
	terraform -chdir=environments/$* destroy -auto-approve

# build hello server: This is a simple server that responds with "Hello, World!" to any request.
.PHONY: build-hello-server
build-hello-server:
	# Ensure the output directory exists
	mkdir -p shared/bin
	# Build the hello server binary
	rm -f shared/bin/hello-server
	GOOS=linux GOARCH=amd64 go build -o shared/bin/hello-server services/hello-server/main.go

# build hello client: This is a simple client that connects to the hello server and prints the response.
.PHONY: build-hello-client
build-hello-client:
	# Ensure the output directory exists
	mkdir -p shared/bin
	# Build the hello client binary
	rm -f shared/bin/hello-client
	GOOS=linux GOARCH=amd64 go build -o shared/bin/hello-client services/hello-client/main.go

# SSH Targets
.PHONY: ssh-hcp/hello-server
	ssh-hcp/hello-server:
	ssh -o StrictHostKeyChecking=no -i environments/hcp/hello-server/client-key.pem ubuntu@$(shell terraform -chdir=environments/hcp/hello-server output -raw instance_public_ip)

.PHONY: ssh-consul-server
ssh-consul-server:
	key=$$(terraform -chdir=environments/sh/sh-dc output -raw ssh_private_key_path); \
	chmod 400 $$key; \
	ssh -o StrictHostKeyChecking=no -i $$key ubuntu@$$(terraform -chdir=environments/sh/sh-dc output -raw server_public_ip)
