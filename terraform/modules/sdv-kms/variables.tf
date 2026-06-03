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

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "location" {
  description = "GCP location for KMS resources"
  type        = string
}

variable "keyring_name" {
  description = "Name of the KMS keyring"
  type        = string
  default     = "gke-secrets-keyring"
}

variable "crypto_key_name" {
  description = "Name of the KMS crypto key"
  type        = string
  default     = "gke-secrets-key"
}

variable "rotation_period" {
  description = "Key rotation period in seconds"
  type        = string
  default     = "7776000s"
}

variable "gke_service_account_email" {
  description = "GKE service account email for IAM binding"
  type        = string
}

variable "enable_kms_encryption" {
  description = "Enable KMS encryption for GKE secrets. When false, KMS resources remain but GKE doesn't use them and IAM binding is removed."
  type        = bool
  default     = true
}

