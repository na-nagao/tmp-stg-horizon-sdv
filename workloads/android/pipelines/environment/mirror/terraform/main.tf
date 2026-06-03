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

// Create Persistent Volume Claim
resource "kubernetes_persistent_volume_claim_v1" "sdv_mirror_pvc" {
  metadata {
    name      = var.sdv_mirror_pvc_name
    namespace = var.sdv_mirror_pvc_namespace
  }

  spec {
    access_modes = ["ReadWriteMany"]
    storage_class_name = var.sdv_mirror_storage_class_name
    resources {
      requests = {
        storage = "${var.sdv_mirror_pvc_capacity_gb}Gi"
      }
    }
  }

  timeouts {
    create = "15m"
  }
}