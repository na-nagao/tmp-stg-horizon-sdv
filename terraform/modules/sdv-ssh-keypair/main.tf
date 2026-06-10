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

resource "tls_private_key" "this" {
  algorithm   = var.algorithm
  rsa_bits    = var.algorithm == "RSA" ? var.rsa_bits : null
  ecdsa_curve = var.algorithm == "ECDSA" ? var.ecdsa_curve : null
}

# 2) Ensure directory exists (only when writing files)
resource "null_resource" "mkdir" {
  count    = var.write_files ? 1 : 0
  triggers = { dir = var.dir }

  provisioner "local-exec" {
    command     = "mkdir -p ${var.dir}"
    interpreter = ["bash", "-c"]
  }
}

# 3) Save private key:
# If algorithm is ED25519, or RSA, use the OpenSSH attribute to get the correct key
# to avoid conversion issues.
resource "local_sensitive_file" "private_pem" {
  count      = var.write_files ? 1 : 0
  depends_on = [null_resource.mkdir]
  content = (
    contains(["ED25519", "RSA"], var.algorithm)
    ? tls_private_key.this.private_key_openssh
    : tls_private_key.this.private_key_pem
  )
  filename        = local.private_path
  file_permission = "0600"
}


# 4) Convert that private key file to OpenSSH format (-o) IN PLACE
# Force an idempotent conversion check on every run to guarantee key
# converted.
# Skip for RSA and ed25519 private keys which are already emitted
# The conversion is not suitable for ed25519 and for RSA it causes issues
# in conversion with public key creation.
resource "terraform_data" "to_openssh" {
  count      = var.write_files && var.convert_to_openssh && var.algorithm != "ED25519" && var.algorithm != "RSA" ? 1 : 0
  depends_on = [local_sensitive_file.private_pem]

  triggers_replace = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    # 1. Check if the file is already OpenSSH to prevent double-processing
    # 2. Use -p (change passphrase) to force a format rewrite (-o)
    # 3. Use -P "" to ensure it never waits on input (hang)
    # 4. Append the POSIX newline manually because ssh-keygen might strip it
    # 5. Ensure errors are caught.
    command     = <<EOT
      set -euo pipefail
      if ! grep -q "BEGIN OPENSSH PRIVATE KEY" "${local.private_path}"; then
        ssh-keygen -p -P "" -f "${local.private_path}" -N "" -o
        printf "\n" >> "${local.private_path}"
      fi
    EOT
    interpreter = ["bash", "-c"]
  }
}


# 5) Save public key (OpenSSH) to disk (0644)
resource "local_file" "public_openssh" {
  count           = var.write_files ? 1 : 0
  depends_on      = [tls_private_key.this]
  content         = tls_private_key.this.public_key_openssh
  filename        = local.public_path
  file_permission = "0644"
}
