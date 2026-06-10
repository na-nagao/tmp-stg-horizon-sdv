# Copyright (c) 2024-2025 Accenture, All Rights Reserved.
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

FROM --platform=linux/amd64 python:3.9-slim-bookworm

# Add security repository and upgrade all packages to fix CVEs
RUN echo "deb http://security.debian.org/debian-security bookworm-security main" > /etc/apt/sources.list.d/security.list && \
    apt update -y && apt upgrade -y && \
    apt clean && rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip
RUN useradd -m appuser
USER appuser

WORKDIR /app

COPY --chown=appuser:appuser requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

COPY --chown=appuser:appuser configure-key.py /app/
ENTRYPOINT ["python", "/app/configure-key.py"]
