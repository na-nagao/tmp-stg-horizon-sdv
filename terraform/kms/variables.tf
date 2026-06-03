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

# Variables use the same naming convention as the main infrastructure
# This allows sharing the same terraform.tfvars file via -var-file

variable "sdv_gcp_project_id" {
  description = "GCP Project ID (required)"
  type        = string
}

variable "sdv_gcp_region" {
  description = "GCP region (used for provider and KMS location)"
  type        = string
  default     = "us-central1"
}

# Below values are hardcoded to match the main infrastructure expectations
# These should not be changed unless you also update terraform/modules/sdv-kms/

locals {
  project_id      = var.sdv_gcp_project_id
  region          = var.sdv_gcp_region
  location        = var.sdv_gcp_region # KMS location matches region
  keyring_name    = "gke-secrets-keyring"
  crypto_key_name = "gke-secrets-key"
  rotation_period = "7776000s" # 90 days
}
