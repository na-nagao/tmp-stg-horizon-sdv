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

locals {
  deleted_mirror_pvc_output = "[DELETED MIRROR PVC] ${var.sdv_mirror_pvc_name}"
}

output "mirror_pvc_name" {
  description = "Name of the created Persistent Volume Claim for Mirror"
  value       = try(kubernetes_persistent_volume_claim_v1.sdv_mirror_pvc.metadata[0].name, local.deleted_mirror_pvc_output)
}

output "mirror_pvc_size" {
  description = "Size of the created Persistent Volume Claim for Mirror"
  value       = try(kubernetes_persistent_volume_claim_v1.sdv_mirror_pvc.spec[0].resources[0].requests.storage, local.deleted_mirror_pvc_output)
}

output "mirror_pvc_storage_class" {
  description = "Storage Class of the created Persistent Volume Claim for Mirror"
  value       = try(kubernetes_persistent_volume_claim_v1.sdv_mirror_pvc.spec[0].storage_class_name, local.deleted_mirror_pvc_output)
}
