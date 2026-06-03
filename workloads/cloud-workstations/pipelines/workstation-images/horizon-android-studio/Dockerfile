# Copyright (c) 2025-2026 Accenture, All Rights Reserved.
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

#######################################################
# NoVNC Builder Container
#######################################################
FROM us-west1-docker.pkg.dev/cloud-workstations-images/predefined/base AS novnc-builder

ARG NOVNC_BRANCH=v1.5.0
ARG WEBSOCKIFY_BRANCH=v0.12.0

WORKDIR /out

RUN git clone --quiet --depth 1 --branch "${NOVNC_BRANCH}" https://github.com/novnc/noVNC.git && \
    cd noVNC/utils && \
    git clone --quiet --depth 1 --branch "${WEBSOCKIFY_BRANCH}" https://github.com/novnc/websockify.git

#######################################################
# End NoVNC Builder Container
#######################################################

# Main container
FROM us-west1-docker.pkg.dev/cloud-workstations-images/predefined/base

ARG ANDROID_STUDIO_VERSION=2025.2.3.7
ARG COMMAND_LINE_TOOLS_VERSION=11076708
ARG HORIZON_DOMAIN
ARG GOOGLE_CLOUD_PROJECT
ARG NODE_MAJOR=20

ENV ANDROID_STUDIO_VERSION="${ANDROID_STUDIO_VERSION}"
ENV GOOGLE_CLOUD_PROJECT="${GOOGLE_CLOUD_PROJECT}"

# Install Android Studio and command-line tools
RUN mkdir -p /opt/google && \
    wget "https://redirector.gvt1.com/edgedl/android/studio/ide-zips/${ANDROID_STUDIO_VERSION}/android-studio-${ANDROID_STUDIO_VERSION}-linux.tar.gz" -O android-studio.tar.gz && \
    tar -xzf android-studio.tar.gz -C /opt/google/ && \
    rm android-studio.tar.gz && \
    wget "https://dl.google.com/android/repository/commandlinetools-linux-${COMMAND_LINE_TOOLS_VERSION}_latest.zip" -O commandlinetools.zip && \
    unzip -q commandlinetools.zip -d /opt/google/ && \
    rm commandlinetools.zip && \
    # Create a folder that will house the "Default" Android packages that are
    # intended to be bundled with this workstations image. On startup we will
    # create an overlay mount at $ANDROID_HOME ($HOME/Android/Sdk) to surface
    # both the preinstalled SDKs and any SDKs that user has subsequently installed
    # on their machine.
    mkdir -p /opt/google/Android/Sdk && \
    chmod o+wr /opt/google/Android/Sdk

# Install default Android SDK packages
RUN cd /opt/google/cmdline-tools/bin && \
    yes | ./sdkmanager --sdk_root=/opt/google/Android/Sdk --install "build-tools;35.0.0" && \
    yes | ./sdkmanager --sdk_root=/opt/google/Android/Sdk --install "build-tools;35.0.0-rc1" && \
    yes | ./sdkmanager --sdk_root=/opt/google/Android/Sdk --install "emulator" && \
    yes | ./sdkmanager --sdk_root=/opt/google/Android/Sdk --install "platforms;android-34" && \
    yes | ./sdkmanager --sdk_root=/opt/google/Android/Sdk --install "platforms;android-35" && \
    yes | ./sdkmanager --sdk_root=/opt/google/Android/Sdk --install "platform-tools" && \
    yes | ./sdkmanager --sdk_root=/opt/google/Android/Sdk --install "sources;android-35" && \
    yes | ./sdkmanager --sdk_root=/opt/google/Android/Sdk --install "system-images;android-34;google_apis;x86_64" && \
    yes | ./sdkmanager --sdk_root=/opt/google/Android/Sdk --install "system-images;android-34;google_apis_playstore;x86_64" && \
    yes | ./sdkmanager --sdk_root=/opt/google/Android/Sdk --update && \
    # Grant users permissions to the sdk_root.
    chown -R 1000:users /opt/google/Android/Sdk

# Set default VM options for Android Studio
RUN echo "-Ddisable.android.first.run=true" >> /opt/google/android-studio/bin/studio64.vmoptions && \
    echo "-Ddisable.config.import=true" >> /opt/google/android-studio/bin/studio64.vmoptions && \
    echo "-Didea.trust.all.projects=true" >> /opt/google/android-studio/bin/studio64.vmoptions && \
    echo "-Duse.gemini.enterprise=true" >> /opt/google/android-studio/bin/studio64.vmoptions

# Enable Gemini in Android Studio
RUN echo "studiobot.chat.use.compose.for.ui=false" >> /opt/google/android-studio/bin/idea.properties

# Install systemd, Helm, fix Yarn GPG key, Node.js, Gemini CLI
RUN mkdir -p /etc/apt/keyrings && \
    # Fix Yarn GPG key (expired / mismatched key in base image)
    curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg -o /etc/apt/keyrings/yarn.asc && \
    # Helm
    curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | \
      gpg --dearmor > /usr/share/keyrings/helm.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" \
      > /etc/apt/sources.list.d/helm-stable-debian.list && \
    # NodeSource repo for Node.js
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | \
      gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
      > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      gnupg \
      systemd \
      python3-pip \
      python3-requests \
      python3-dotenv \
      nodejs && \
    npm install -g @google/gemini-cli && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    ln -s /dev/null /etc/systemd/system/apache2.service && \
    ln -s /dev/null /etc/systemd/system/getty@tty1.service && \
    ln -s /dev/null /etc/systemd/system/ldconfig.service && \
    /sbin/ldconfig -Xv && \
    ln -s /dev/null /etc/systemd/system/systemd-modules-load.service && \
    ln -s /dev/null /etc/systemd/system/ssh.socket && \
    ln -s /dev/null /etc/systemd/system/ssh.service && \
    echo "d /run/sshd 0755 root root" > /usr/lib/tmpfiles.d/sshd.conf && \
    echo -e "x /run/docker.socket - - - - -\nx /var/run/docker.socket - - - - -" > /usr/lib/tmpfiles.d/docker.conf

# Install GNOME, TigerVNC, and Terminal
COPY --from=novnc-builder /out/noVNC /opt/noVNC
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
      gnome-software \
      gnome-software-common \
      gnome-software-plugin-snap \
      libappstream-glib8 \
      libgd3 \
      colord \
      gnome-control-center \
      gvfs-backends \
      hplip \
      libgphoto2-6 \
      libsane1 \
      sane-utils \
      ubuntu-desktop-minimal \
      dbus-x11 \
      tigervnc-common \
      tigervnc-scraping-server \
      tigervnc-standalone-server \
      tigervnc-xorg-extension \
      python3-numpy \
      fonts-dejavu-core \
      gnome-terminal && \
    apt-get remove -y gnome-initial-setup && \
    apt-get remove -y --purge cloud-init && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    chmod -x /usr/lib/ubuntu-release-upgrader/check-new-release-gtk

# Install Google Chrome
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    dpkg -i google-chrome-stable_current_amd64.deb || apt-get update -y && apt-get install -y -f && \
    rm google-chrome-stable_current_amd64.deb && \
    # Ensure chrome will work in our headless environment without gpu support by
    # specifying environment variables and flags.
    echo "QT_X11_NO_MITSHM=1 _X11_NO_MITSHM=1 _MITSHM=0 $(tail -n -1 /opt/google/chrome/google-chrome) --disable-gpu --disable-dev-shm-usage --use-gl=swiftshader" \
      >> /opt/google/chrome/google-chrome && \
    sed -i 'N;$!P;D' /opt/google/chrome/google-chrome && \
    # Set google-chrome as the default browser.
    xdg-settings set default-web-browser google-chrome.desktop || true && \
    if [ ! -f /usr/bin/x-www-browser ]; then \
      update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/google-chrome-stable 200; \
    fi && \
    update-alternatives --set x-www-browser /usr/bin/google-chrome-stable && \
    if [ ! -f /usr/bin/gnome-www-browser ]; then \
      update-alternatives --install /usr/bin/gnome-www-browser gnome-www-browser /usr/bin/google-chrome-stable 200; \
    fi && \
    update-alternatives --set gnome-www-browser /usr/bin/google-chrome-stable && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Merge assets into the container
COPY assets/. /

# Configure deterministic GNOME Terminal defaults for VNC/noVNC rendering.
RUN mkdir -p /etc/dconf/profile /etc/dconf/db/local.d && \
    printf "user-db:user\nsystem-db:local\n" > /etc/dconf/profile/user && \
    printf "[org/gnome/terminal/legacy/profiles:]\ndefault='b1dcc9dd-5262-4d8d-a863-c897e6d979b9'\nlist=['b1dcc9dd-5262-4d8d-a863-c897e6d979b9']\n\n[org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9]\nuse-system-font=false\nfont='DejaVu Sans Mono 12'\ncell-width-scale=1.0\ncell-height-scale=1.0\n" > /etc/dconf/db/local.d/00-horizon-terminal-font

# Run VNC Server and NoVNC as services
RUN ln -s /etc/systemd/system/tigervnc.service /etc/systemd/system/multi-user.target.wants/tigervnc.service && \
    ln -s /etc/systemd/system/novnc.service /etc/systemd/system/multi-user.target.wants/novnc.service && \
    systemctl enable tigervnc && \
    systemctl enable novnc && \
    dconf update

# Automatically start Android Studio
RUN ln -s /usr/share/applications/jetbrains-studio.desktop /etc/xdg/autostart/jetbrains-studio.desktop && \
    chmod +x /google/scripts/entrypoint.sh

# Configure gemini-mcp-agent script
COPY --chmod=755 ./common-utils/gemini/gemini-mcp-agent.py /usr/local/bin/gemini-mcp-agent
RUN sed -i 's/^\(HORIZON_DOMAIN = os.environ.get("HORIZON_DOMAIN", "\)##DOMAIN##\(")\)/\1'"${HORIZON_DOMAIN}"'\2/' /usr/local/bin/gemini-mcp-agent

ENTRYPOINT ["/google/scripts/entrypoint.sh"]
