provider "google" {
  credentials = "${file("./<service-account-cred>.json")}"
  project = "<project-id>"
  region = "us-east4-a"
}
