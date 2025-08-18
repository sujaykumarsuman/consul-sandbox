terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = ">= 0.108.0"
    }
  }
}

resource "hcp_hvn" "main" {
  cloud_provider = var.cloud_provider
  project_id     = var.hcp_project_id
  hvn_id         = "hvn-${var.cluster_id}"
  region         = var.region
}

resource "hcp_consul_cluster" "main" {
  depends_on      = [hcp_hvn.main]
  project_id      = var.hcp_project_id
  cluster_id      = var.cluster_id
  hvn_id          = hcp_hvn.main.hvn_id
  tier            = var.tier
  size            = var.size
  public_endpoint = true
}

resource "hcp_consul_cluster_root_token" "admin" {
  cluster_id = hcp_consul_cluster.main.cluster_id
  project_id = var.hcp_project_id
}
