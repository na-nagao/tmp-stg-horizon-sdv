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

output "map_id" {
  value = google_certificate_manager_certificate_map.horizon_sdv_map.id
}

# Flatten the DNS records so the DNS module can easily consume them
output "dns_auth_records" {
  value = flatten([
    for k, v in google_certificate_manager_dns_authorization.instance : {
      name = v.dns_resource_record[0].name
      type = v.dns_resource_record[0].type
      data = v.dns_resource_record[0].data
    }
  ])
}
