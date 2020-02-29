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

data "google_client_config" "current" {}

provider "helm" {
  kubernetes {
    load_config_file = false
    host = "${google_container_cluster.ci.endpoint}"
    token = "${data.google_client_config.current.access_token}"
    client_certificate = "${base64decode(google_container_cluster.ci.master_auth.0.client_certificate)}"
    client_key = "${base64decode(google_container_cluster.ci.master_auth.0.client_key)}"
    cluster_ca_certificate = "${base64decode(google_container_cluster.ci.master_auth.0.cluster_ca_certificate)}"
  }
}

provider "kubernetes" {
  load_config_file = false
  host = "${google_container_cluster.ci.endpoint}"
  token = "${data.google_client_config.current.access_token}"
  client_certificate = "${base64decode(google_container_cluster.ci.master_auth.0.client_certificate)}"
  client_key = "${base64decode(google_container_cluster.ci.master_auth.0.client_key)}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.ci.master_auth.0.cluster_ca_certificate)}"
}

variable "helm_version" {
  default = "v3.1.1"
}

resource "kubernetes_namespace" "gocd_namespace" {
  metadata {
    name = "gocd"
  }
  depends_on = [google_container_node_pool.ci_nodes]
}

resource "helm_release" "gocd" {
  name = "gocd"
  chart = "stable/gocd"
  namespace = kubernetes_namespace.gocd_namespace.metadata.0.name
  depends_on = [kubernetes_namespace.gocd_namespace]
}