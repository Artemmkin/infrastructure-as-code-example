# Provider configuration variables
variable "project_id" {
  description = "Project ID in GCP"
}

variable "region" {
  description = "Region in which to manage GCP resources"
}

# Cluster configuration variables
variable "cluster_name" {
  description = "The name of the cluster, unique within the project and zone"
}

variable "zone" {
  description = "The zone in which nodes specified in initial_node_count should be created in"
}
