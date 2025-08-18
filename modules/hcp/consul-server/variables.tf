variable "cloud_provider" {
  description = "Cloud provider for the HCP Consul cluster"
  type        = string
  default     = "aws"
}

variable "hcp_project_id" {
  description = "HCP project ID"
  type        = string
}

variable "hcp_client_id" {
  description = "HCP Client ID"
  type        = string
  sensitive   = true
}

variable "hcp_client_secret" {
  description = "HCP Client Secret"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Region for the HCP Consul cluster"
  type        = string
  default     = "us-east-1"
}

variable "cluster_id" {
  description = "HCP Consul Cluster ID"
  type        = string
}

variable "tier" {
  description = "Consul cluster tier: development or standard"
  type        = string
  default     = "development"
}

variable "size" {
  description = "Size of the HCP Consul cluster"
  type        = string
  default     = "x_small"
}
