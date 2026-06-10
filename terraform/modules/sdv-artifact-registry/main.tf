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

resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.location
  repository_id = var.repository_id
  format        = "DOCKER"
  description   = "Docker repository for Horizon SDV Dev"

  # Note: Artifact Registry doesn't support force_destroy parameter
  # To destroy a repository with images, you must either:
  # 1. Delete all images first: gcloud artifacts docker images delete <IMAGE> --delete-tags
  # 2. Delete the entire repository via gcloud: gcloud artifacts repositories delete <REPO> --location=<LOC> --quiet
  # 3. Use lifecycle prevent_destroy = false (already set below) to allow Terraform destroy

  lifecycle {
    prevent_destroy = false # Allow Terraform to destroy this repository
  }
}

resource "google_project_iam_member" "artifact_registry_writer" {
  for_each = toset(var.members)

  project = data.google_project.project.project_id
  role    = "roles/artifactregistry.writer"
  member  = each.value
}

resource "google_project_iam_member" "artifact_registry_reader" {
  for_each = toset(var.reader_members)

  project = data.google_project.project.project_id
  role    = "roles/artifactregistry.reader"
  member  = each.value
}
