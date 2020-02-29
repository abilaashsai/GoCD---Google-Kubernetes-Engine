provider "google" {
  credentials = "${file("./<service-account-cred>.json")}"
  project = "<project-id>"
  region = "us-east4-a"
}

resource "google_compute_network" "vpc_network" {
  name = "gocd-vpc-network"
}

resource "google_container_cluster" "ci" {
  name = "gocd-cluster"
  network = google_compute_network.vpc_network.name
  location = "us-east4-a"
  initial_node_count = 1
  remove_default_node_pool = true
  depends_on = [
    "google_compute_network.vpc_network"]
}

resource "google_container_node_pool" "ci_nodes" {
  name = "gocd-node-pool"
  location = "us-east4-a"
  cluster = google_container_cluster.ci.name

  node_config {
    machine_type = "n1-standard-2"
  }

  autoscaling {
    min_node_count = 3
    max_node_count = 5
  }
  depends_on = [
    "google_container_cluster.ci"]
}