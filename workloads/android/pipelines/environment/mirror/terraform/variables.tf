# Copyright (c) 2026 Accenture, All Rights Reserved.
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

// from jenkins env; same as horizon-sdv cluster value
variable "sdv_mirror_project_id" {
  description = "GCP Project ID (existing) where Mirror is deployed."
  type        = string
}

// from jenkins env; same as horizon-sdv cluster value
variable "sdv_mirror_region" {
  description = "GCP region where Mirror is deployed."
  type        = string
}

// from jenkins env; new resource
variable "sdv_mirror_pvc_capacity_gb" {
  description = "Capacity (in GB) of the Mirror Filestore PVC."
  type        = number
  default     = 2048

  # Minimum 1TB (1024GB) is required
  validation {
    condition     = var.sdv_mirror_pvc_capacity_gb >= 1024
    error_message = "Minimum: 1024 GiB"
  }
  # Allow expansion of PVC but only multiples of 256GB
  validation {
    condition     = var.sdv_mirror_pvc_capacity_gb % 256 == 0
    error_message = "The capacity for Mirror Filestore share must be in multiples of 256GB to allow for proper expansion."
  }
  # Maximum allowed capacity is 100TB (102400GB)
  validation {
    condition     = var.sdv_mirror_pvc_capacity_gb <= 102400
    error_message = "Maximum capacity is 102400 GiB (100 TiB)."
  }
}

// from jenkins env; should already exist as part of argocd sync
variable "sdv_mirror_storage_class_name" {
  description = "Name of the Storage Class for Mirror Filestore."
  type        = string
  default     = "sdv-mirror-zonal-rwx"
}

// using existing namespace, same as android build pods in horizon-sdv cluster
variable "sdv_mirror_pvc_namespace" {
  description = "Namespace where the Persistent Volume Claim for Mirror Filestore is created."
  type        = string
  default     = "jenkins"
}

// new resource
variable "sdv_mirror_pvc_name" {
  description = "Name of the Persistent Volume Claim for Mirror Filestore."
  type        = string
  default     = "sdv-mirror-filestore-pvc"
}