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

data "google_project" "project" {}

resource "google_dns_managed_zone" "sdv-cloud-dns-zone" {
  name          = var.zone_name
  dns_name      = var.dns_name
  force_destroy = true

  # DNSSEC: set state to "off" explicitly when disabled so the zone is updated (omitting
  # the block would leave DNSSEC enabled). Key specs and non_existence only when state is on.
  dnssec_config {
    state         = var.dnssec_enabled ? "on" : "off"
    non_existence = var.dnssec_enabled ? "nsec3" : null

    dynamic "default_key_specs" {
      for_each = var.dnssec_enabled ? [{ algorithm = "rsasha256", key_length = 2048, key_type = "keySigning" }, { algorithm = "rsasha256", key_length = 1024, key_type = "zoneSigning" }] : []
      content {
        algorithm  = default_key_specs.value.algorithm
        key_length = default_key_specs.value.key_length
        key_type   = default_key_specs.value.key_type
      }
    }
  }
}

# Create Google certificate manager certificate CNAME records required for DNS Authz
resource "google_dns_record_set" "sdv_auth_cname" {
  count        = length(var.dns_auth_records)
  project      = data.google_project.project.project_id
  managed_zone = google_dns_managed_zone.sdv-cloud-dns-zone.name

  name = var.dns_auth_records[count.index].name
  type = var.dns_auth_records[count.index].type
  ttl  = 300

  rrdatas = [
    var.dns_auth_records[count.index].data
  ]

  depends_on = [
    google_dns_managed_zone.sdv-cloud-dns-zone
  ]
}
