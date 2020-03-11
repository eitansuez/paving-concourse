resource "google_compute_address" "ops-manager" {
  name = "${var.environment_name}-ops-manager-ip"
}

resource "tls_private_key" "ops-manager" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "google_dns_record_set" "ops-manager" {
  name = "opsmanager.${data.google_dns_managed_zone.hosted-zone.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = var.hosted_zone

  rrdatas = [google_compute_address.ops-manager.address]
}

resource "google_compute_firewall" "ops-manager" {
  name    = "${var.environment_name}-ops-manager"
  network = google_compute_network.network.name

  direction = "INGRESS"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  target_tags = ["${var.environment_name}-ops-manager"]
}

# bucket

resource "random_integer" "bucket_suffix" {
  min = 1
  max = 100000
}

resource "google_storage_bucket" "ops-manager" {
  name          = "${var.project}-${var.environment_name}-ops-manager-${random_integer.bucket_suffix.result}"
  force_destroy = true
}

# iam

resource "google_service_account" "ops-manager" {
  account_id   = "${var.environment_name}-ops-manager"
  display_name = "${var.environment_name} Ops Manager VM Service Account"
}

resource "google_service_account_key" "ops-manager" {
  service_account_id = google_service_account.ops-manager.id
}

resource "google_project_iam_member" "iam-service-account-user" {
  project = var.project
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.ops-manager.email}"
}

resource "google_project_iam_member" "iam-service-account-token-creator" {
  project = var.project
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.ops-manager.email}"
}

resource "google_project_iam_member" "compute-instance-admin-v1" {
  project = var.project
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.ops-manager.email}"
}

resource "google_project_iam_member" "compute-network-admin" {
  project = var.project
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.ops-manager.email}"
}

resource "google_project_iam_member" "compute-storage-admin" {
  project = var.project
  role    = "roles/compute.storageAdmin"
  member  = "serviceAccount:${google_service_account.ops-manager.email}"
}

resource "google_project_iam_member" "storage-admin" {
  project = var.project
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.ops-manager.email}"
}

