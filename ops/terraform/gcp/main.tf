provider "google" {
  project = "my-amazon-project"
  region  = "us-central1"
}

# ==========================================
# GKE Cluster (Compute Layer)
# ==========================================
# Google Kubernetes Engine
module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = "my-amazon-project"
  name                       = "amazon-cluster"
  region                     = "us-central1"
  network                    = "default"
  subnetwork                 = "default"
  ip_range_pods              = ""
  ip_range_services          = ""
}

# ==========================================
# Cloud SQL (Database Layer)
# ==========================================
# Managed MySQL instance
resource "google_sql_database_instance" "mysql" {
  name             = "amazon-mysql"
  database_version = "MYSQL_8_0"
  region           = "us-central1"

  settings {
    tier = "db-f1-micro" # Smallest available tier
  }
}

# ==========================================
# Cloud Memorystore (Caching Layer)
# ==========================================
# Managed Redis instance for GCP
resource "google_redis_instance" "cache" {
  name           = "amazon-redis"
  memory_size_gb = 1
  region         = "us-central1"
}
