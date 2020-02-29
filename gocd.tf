provider "google" {
  credentials = "${file("./<service-account-cred>.json")}"
  project = "<project-id>"
  region = "us-east4-a"
}

resource "google_compute_network" "vpc_network" {
  name = "gocd-vpc-network"
}