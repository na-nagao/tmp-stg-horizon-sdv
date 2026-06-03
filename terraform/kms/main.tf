# Copyright (c) 2024-2026 Accenture, All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = local.project_id
  region  = local.region
}

# KMS Keyring - cannot be deleted, only soft-deleted for 24 hours
resource "google_kms_key_ring" "gke_secrets_keyring" {
  name     = local.keyring_name
  location = local.location
  project  = local.project_id

  lifecycle {
    # Prevent accidental destruction
    prevent_destroy = true
    # Never modify after creation
    ignore_changes = all
  }
}

# KMS Crypto Key for GKE secrets encryption
resource "google_kms_crypto_key" "gke_secrets_key" {
  name            = local.crypto_key_name
  key_ring        = google_kms_key_ring.gke_secrets_keyring.id
  rotation_period = local.rotation_period

  lifecycle {
    # Prevent accidental destruction
    prevent_destroy = true
    # Allow rotation period updates
    ignore_changes = [name, key_ring]
  }
}
