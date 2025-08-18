# Consul Sandbox

This repository provisions a small Consul environment for experimentation. It uses Terraform to deploy either a self-hosted Consul datacenter on AWS or a HashiCorp Cloud Platform (HCP) Consul datacenter, and includes sample Go services that communicate through Consul.

## Repository layout

- **environments/** – Terraform configurations for each scenario. Subdirectories under `hcp/` deploy HCP Consul resources while `sh/` contains self-hosted examples.
- **modules/** – Reusable Terraform modules used by the environments.
- **services/** – Sample Go applications demonstrating service-to-service communication. `hello-server` exposes an HTTP `/hello` endpoint; `hello-client` calls it via a `/ping` endpoint.
- **shared/** – Helper scripts, compiled binaries and configuration assets used by the environments.

## Prerequisites

1. [Terraform](https://www.terraform.io/)
2. [Go](https://go.dev/)
3. AWS credentials configured for your shell
4. Values for the variables in [`.env`](.env). Populate the file with your HCP credentials and Consul Enterprise license as needed.

## Usage

### HCP Consul

1. **Initialize** the HCP environment:
   ```bash
   make tf-init/hcp/hcp-dc
   ```
2. **Plan** and **apply** the infrastructure (builds the Go services automatically):
   ```bash
   make tf-plan/hcp/hcp-dc
   make tf-apply/hcp/hcp-dc
   ```
3. **Destroy** the environment when finished:
   ```bash
   make tf-destroy/hcp/hcp-dc
   ```

### Self-hosted Consul on AWS

1. **Initialize** the self-hosted environment:
   ```bash
   make tf-init/sh/sh-dc
   ```
2. **Plan** and **apply** the infrastructure:
   ```bash
   make tf-plan/sh/sh-dc
   make tf-apply/sh/sh-dc
   ```
3. **(Optional) SSH** into the Consul server:
   ```bash
   make ssh-consul-server
   ```
4. **Destroy** the environment when finished:
   ```bash
   make tf-destroy/sh/sh-dc
   ```

To build the example applications separately:
```bash
make build-hello-server
make build-hello-client
```

## How it works

Each Terraform environment calls modules under `modules/` to provision Consul servers and clients. During `tf-apply`, the Makefile compiles the example Go binaries which can be deployed as part of the infrastructure. The scripts in `shared/scripts/` automate Consul installation and configuration on provisioned instances.

The `hello-server` listens on port `5050` and returns a greeting containing a payload ID, while the `hello-client` listens on port `8080` and proxies requests to the server. These services help verify service discovery and connectivity within the Consul sandbox.

## Cleanup

Always destroy any created infrastructure to avoid unnecessary charges:
```bash
make tf-destroy/hcp/hcp-dc
make tf-destroy/sh/sh-dc
```
