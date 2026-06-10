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
# 
# Description
# Configuration file containing variables for the "sdv-gke-apps" module.

variable "sub_environments" {
  type        = list(string)
  description = "List of sub-environments to be deployed."
}

variable "sub_env_branches" {
  description = "Map of sub-environment name to Git branch for ArgoCD sync"
  type        = map(string)
  default     = {}
}

variable "git_auth_method" {
  description = "Authentication method for Argo CD: 'app' or 'pat'."
  type        = string
}

variable "es_namespace" {
  description = "Namespace for External Secrets"
  type        = string
  default     = "external-secrets"
}

variable "es_chart_version" {
  description = "Chart version for External Secrets"
  type        = string
  default     = "0.10.4"
}

variable "argocd_namespace" {
  description = "Namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Chart version for Argo CD"
  type        = string
  default     = "9.1.4"
}

variable "gcp_project_id" {
  description = "The GCP Project ID."
  type        = string
}

variable "gcp_cloud_region" {
  description = "The GCP cluster region"
  type        = string
}

variable "sdv_cluster_name" {
  description = "Name of the GKE Cluster"
  type        = string
}

variable "argocd_application_name" {
  description = "Name of the Argo CD Application"
  type        = string
  default     = "horizon-sdv"
}

variable "git_repo_url" {
  description = "The URL of the git repository."
  type        = string
}

variable "git_repo_branch" {
  description = "The target branch for Argo CD."
  type        = string
}

variable "git_repo_owner" {
  description = "Git repository owner (user or organization name)"
  type        = string
}

variable "git_repo_name" {
  description = "Git repository name"
  type        = string
}

variable "domain_name" {
  description = "The base domain name."
  type        = string
}

variable "subdomain_name" {
  description = "The subdomain for the environment"
  type        = string
}

variable "gcp_cloud_zone" {
  description = "The GCP zone"
  type        = string
}

variable "gcp_backend_bucket" {
  description = "The name of the GCS backend bucket."
  type        = string
}

variable "gcp_registry_id" {
  description = "The ID of the Artifact Registry repository (e.g., 'horizon-sdv')."
  type        = string
}

variable "images" {
  description = "A map of images to deploy. The key is the image name and the value is an object containing its build directory and version."
  type = map(object({
    directory = string
    version   = string
  }))
}
variable "enable_network_policies" {
  description = "Enable network policies for all workloads. When disabled, all network policies will be removed. Default is enabled."
  type        = bool
  default     = true
}
