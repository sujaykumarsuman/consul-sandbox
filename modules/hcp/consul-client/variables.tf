variable "aws_region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "t3.medium"
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

variable "hcp_project_id" {
  description = "HCP project ID"
  type        = string
}

variable "hcp_hvn_id" {
  description = "HCP HVN ID"
  type        = string
  default     = "hvn"
}

variable "hcp_cidr_block" {
  description = "CIDR block for the HCP HVN"
  type        = string
}

variable "consul_ent_license" {
  description = "Consul Enterprise license file content"
  type        = string
  sensitive   = true
}

variable "payload_binary" {
  description = "payload binary name (e.g. hello-server or hello-client)"
  type        = string
  default     = "hello-server"  # Default to hello-server binary
}

variable "payload_id" {
  description = "ID for the payload instance running the Consul client"
  type        = string
  default = "hello_server_01"
}

variable "payload_port" {
  description = "Port for the service payload (e.g. hello-server or hello-client)"
  type        = number
  default     = 0  # 0 means 'not set'
}

variable "datacenter" {
  description = "Datacenter name for the Consul client"
  type        = string
  default     = "hcp-dc"
}
