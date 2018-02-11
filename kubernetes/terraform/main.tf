provider "google" {
  version = "~> 1.4.0"
  project = "${var.project_id}"
  region  = "${var.region}"
}

# create Kubernetes cluster
resource "google_container_cluster" "primary" {
  name               = "${var.cluster_name}"
  description        = "This cluster was created as part of IaC tutorial"
  zone               = "${var.zone}"
  initial_node_count = 2 # number of nodes in the cluster

  # configuration of the nodes
  node_config {
    # The set of Google API scopes
    # The following scopes are necessary to ensure the correct functioning of the cluster
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
    tags = ["iac-kubernetes"]
  }

  # configure kubectl to talk to the cluster
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.zone} --project ${var.project_id}"
  }
}

# create firewall rule to allow access to application
resource "google_compute_firewall" "nodeports" {
  name    = "node-port-range"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]
  }
  source_ranges = ["0.0.0.0/0"]
}
