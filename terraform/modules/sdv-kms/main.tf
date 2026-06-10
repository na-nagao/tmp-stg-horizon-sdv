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

data "google_kms_key_ring" "keyring" {
  count = var.enable_kms_encryption ? 1 : 0

  name     = var.keyring_name
  location = var.location
  project  = var.project_id
}

# Reference existing KMS crypto key (managed in terraform/kms/)
# Only evaluated when KMS encryption is enabled
data "google_kms_crypto_key" "crypto_key" {
  count = var.enable_kms_encryption ? 1 : 0

  name     = var.crypto_key_name
  key_ring = data.google_kms_key_ring.keyring[0].id
}

# IAM binding is conditional - only created when KMS encryption is enabled
# When disabling encryption, GKE cluster will transition to DECRYPTED state first,
# then this IAM binding will be removed. GKE stops using the key when transitioning
# to DECRYPTED, so the timing of IAM removal is safe.
resource "google_kms_crypto_key_iam_member" "gke_key_user" {
  count = var.enable_kms_encryption ? 1 : 0

  crypto_key_id = data.google_kms_crypto_key.crypto_key[0].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${var.gke_service_account_email}"

  lifecycle {
    create_before_destroy = true
  }
}
