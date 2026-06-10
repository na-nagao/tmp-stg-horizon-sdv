# Horizon SDV Release Notes

## Horizon SDV - Release 3.1.0 (2026-03-16)

### Summary

Horizon SDV 3.1.0 is the minor release which extends platform capabilities with support for Sub-environments and additional MCP server configuration for Android Studio and Android Studio for Platforms IDEs. Horizon 3.1.0 also delivers several critical bug fixes including security fixes for network configurations and vulnerabilities in application containers.

Rel.3.1.0 defines rules for Partner Contributions Repository and recommended directory structure for third party modules provided from external Horizon Partners which are documented in **contributing.md** file located in the **/doc** directory of Horizon SDV repository.

Horizon SDV 3.1.0 package offers fully verified and documented upgrade patch (from Rel.3.0.0 to Rel.3.1.0). (see details in /docs/guides/upgrade_guide_3_0_0_to_3_1_0.md)

***
### New Features

<table>
<tr>
  <th>ID</th>
  <th>Feature</th>
  <th>Description</th>
</tr>
<tr>
  <td valign="top">TAA-1057</td>
  <td valign="top">Support for Sub-Environments in Horizon SDV platform</td>
  <td valign="top">Horizon SDV 3.1.0 introduces <strong>sub-environments</strong>: multiple isolated copies of the platform that run on the <strong>same GKE cluster</strong> as the main environment. Each sub-environment has its own namespaces (prefixed by sub-environment name, e.g. <code>sub-jenkins</code>, <code>sub-keycloak</code>), its own Argo CD instance, its own sub-domain (e.g. <code>sub.<SUB_DOMAIN>.<HORIZON_DOMAIN></code>), and its own GCP Certificate Manager certificate, Secret Manager secrets, and Workload Identity service accounts. Sub-environments are defined entirely in <code>terraform.tfvars</code> via the <code>sdv_sub_env_configs</code> variable; no code changes are required to add or remove them. Typical use cases include giving teams isolated instances without extra clusters, testing platform changes on a branch before merge, and running a stable environment alongside a short-lived experimental one.<br><br><strong>Changes</strong><br><br><ul><li><strong>Terraform:</strong> New variable <code>sdv_sub_env_configs</code> in <code>terraform/env/terraform.tfvars</code> (optional; defaults to empty map). Each key is the sub-environment name; each value supplies required Keycloak passwords and optional <code>branch</code> and <code>manual_secrets</code>.</li><li><strong>Certificate Manager:</strong> DNS Authorization and certificate resources converted to <code>for_each</code> to support one certificate per sub-environment. Upgrade from 3.0.0 uses <code>moved {}</code> blocks and a name-preserving conditional to avoid destroying and recreating existing GCP resources.</li><li><strong>Argo CD:</strong> Argo CD-related Kubernetes resources managed by Terraform converted to <code>for_each</code>. One Argo CD instance per sub-environment (e.g. <code>helm_release.argocd_subenvs["sub"]</code> in <code>sub-argocd</code> namespace). Upgrade from 3.0.0 uses <code>moved {}</code> blocks to migrate state without destroying live resources.</li><li><strong>GCP:</strong> Per sub-environment: Workload Identity service accounts (e.g. <code>gke-<SUB_ENV_NAME>-<app>-sa</code>), Secret Manager secrets (prefixed <code><SUB_ENV_NAME>-</code>), Certificate Manager certificate and DNS authorization for <code><SUB_ENV_NAME>.<SUB_DOMAIN>.<HORIZON_DOMAIN></code>, and Cloud DNS CNAME for certificate verification.</li><li><strong>GitOps:</strong> Helm values <code>namespacePrefix</code>, <code>isSubEnvironment</code>, and <code>environmentName</code> drive namespace and resource naming. Cluster-scoped components (External Secrets Operator, Node Exporter, Kubescape Operator, Gerrit Operator) are gated with <code>isSubEnvironment</code> and remain single-instance; sub-environments use namespace-scoped resources and the shared operators.</li><li><strong>Documentation:</strong> [Sub-Environment Deployment Guide](guides/sub_environments/sub_environment_deployment_guide.md) (configuration, deploy, access, destroy) and [Sub-Environment Developer Guide](guides/sub_environments/sub_environment_developer_guide.md) (architecture, adding apps, naming). Deployment guide referenced from main [Deployment Guide](deployment_guide.md).</li></ul><br><br><strong>Action Required</strong><br><br><ul><li><strong>None for existing 3.0.0 users who do not use sub-environments.</strong> Upgrade path is described in [Upgrade Guide: 3.0.0 to 3.1.0](guides/upgrade_guide_3_0_0_to_3_1_0.md); follow post-upgrade steps (e.g. delete/recreate affected resources, sync with prune) as documented.</li><li><strong>To use sub-environments:</strong> Add <code>sdv_sub_env_configs</code> to <code>terraform/env/terraform.tfvars</code> with at least <code>keycloak_admin_password</code> and <code>keycloak_horizon_admin_password</code> per sub-environment. Sub-environment names must be lowercase alphanumeric with hyphens, 1-4 characters. See [Sub-Environment Deployment Guide – Configuring Sub-Environments](guides/sub_environments/sub_environment_deployment_guide.md#configuring-sub-environments).</li></ul></td>
</tr>
</table>

***

### Improved Features

<table>
<tr>
  <th>ID</th>
  <th>Feature</th>
  <th>Description</th>
</tr>
<tr>
  <td valign="top">TAA-1328</td>
  <td valign="top">MCP server configuration caching by Android Studio and ASfP IDE</td>
  <td valign="top">This improvement provides the MCP configuration caching by Android Studio and ASfP IDE that makes MCP requests by Gemini Code Assist use expired tokens.<br><br><strong>MCP configuration caching in Android Studio and ASfP</strong><br><br>The Android Studio and Android Studio for Platform IDEs cache the MCP configuration (<code>mcp.json</code>) for their current session.<br><br><ul><li>This means, if we store auth tokens in <code>mcp.json</code> and later update them, the IDE will still use the old tokens from its cache.</li><li>To fix this, a standard workaround has been implemented in <code>gemini-mcp-agent</code> using the <code>--mcp-client-bridge</code> mode where each MCP server configured in <code>mcp.json</code> spawns its own MCP-client bridge.</li><li>It transparently forwards requests from the IDE to the MCP server (and vice-versa), injecting a fresh authentication token each time from <code>.gemini/settings.json</code>. This ensures seamless access without needing to restart your IDE.</li><li>Note that, structure of <code>mcp.json</code> is now slightly different from <code>settings.json</code> as <code>mcp.json</code> now configures servers in a pseduo-stdio mode using <code>command</code>, <code>args</code> and <code>env</code> blocks instead of standard <code>httpUrl</code> block so that the client-bridge can proxy requests with latest token injection.</li></ul><br><br><strong>Key Changes</strong><br><br><strong><code>gemini-mcp-setup.py</code></strong><br><br><ul><li>Renamed <code>gemini-mcp-setup.py</code> to <code>gemini-mcp-agent.py</code> to reflect its upgraded feature set.</li><li><code>gemini-mcp-agent</code> now provides an internal-use command option <code>--mcp-client-bridge</code> for IDEs like Android Studio (and ASfP) that cache configurations</li><li>where each MCP server configured in <code>mcp.json</code> spawns its own MCP-client bridge.</li><li>The bridge uses <code>stdio</code> to communicate with the IDE, injects updated tokens from <code>.gemini/settings.json</code>, and forwards <code>JSON-RPC</code> requests to the MCP server over HTTPS (and vice-versa).</li><li>This solves the MCP config caching issue in such IDEs, ensuring seamless access without needing to restart your IDE.</li><li>Updated <code>mcp_setup.md</code> guide for new features and improved clarity</li></ul><br><br><strong>Cloud-WS images (all 3):</strong><br><br><ul><li>added <code>GOOGLE_CLOUD_PROJECT</code> as dockerfile ARG and set as container ENV</li><li>passing value for <code>GOOGLE_CLOUD_PROJECT</code> from Jenkins env var <code>CLOUD_PROJECT</code></li><li>Updated descriptions in jenkinsfile for all 3 cloud-ws groovy files</li><li>Yarn GPG key fix that caused build failure</li><li>simplified and optimized image layers</li></ul><br><br><strong>More</strong> <strong>on</strong> <code>gemini-mcp-agent</code> <strong>changes</strong><br><br><ul><li>new func <code>discover_android_studio_mcp_file_path</code> to find mcp.json if platform is Android Studio or ASFP and set the constant <code>ANDROID_STUDIO_MCP_FILE_PATH</code></li><li>agent updates the <code>mcp.json</code> only when <code>ANDROID_STUDIO_MCP_FILE_PATH</code> holds a non-None value.</li><li>added <code>update_android_studio_mcp_file</code> which has slightly diff logic to <code>update_gemini_cli_settings_file</code> as mcp.json structure is diff from settings.json as <code>mcp.json</code> now defines MCP servers with <code>command</code> as this agent script with args <code>--mcp-client-bridge</code> and <code>--mcp-server</code> name. This option combo calls the new <code>run_mcp_client_bridge</code> function.</li><li>added new <code>run_mcp_client_bridge</code> function to read MCP JSON-RPC requests from android studio IDE (via stdio) and forward it to remote MCP server (via HTTPs)</li><li>updated <code>is_managed_server</code> function to accept <code>server_http_url</code> instead of entire block</li><li>renamed <code>ensure_config_dir</code> to <code>ensure_configs_exist</code> that always creates config files for <code>gemini-cli</code> and optionally for as/asfp only if the environment is as/asfp based</li><li>renamed <code>update_gemini_config</code> to <code>update_gemini_cli_settings_file</code></li><li>added new env var ENV_FILE_PATH to store env file path</li><li>added new func <code>load_env_config</code> to load env vars from <code>ENV_FILE_PATH</code> or <code>.env</code> file in current dir or global fallback dir of <code>~/.gemini/.env</code></li><li>updated func <code>update_android_studio_mcp_file</code> to store env vars into mcp.json file for mcp-client-bridge processes to use them</li></ul></td>
</tr>
<tr>
  <td valign="top">TAA-1334</td>
  <td valign="top">Generate GitHub App private key PKCS#8 format via Terraform</td>
  <td valign="top">Extension to the new simplified deployment flow for Horizon SDV introduced in Rel.3.0.0.<br><br><ul><li>PKCS#8 format of the GitHub App private key is created automatically by terraform.</li><li>The variable <code>sdv_github_app_private_key_pkcs8</code> is removed.</li><li>PKCS#8 format of the GitHub App private key is stored in the GCP Secret Manager</li></ul></td>
</tr>
</table>

***

## GCP changes [Google]

Google has changed [Client Secret Handling and Visibility](https://support.google.com/cloud/answer/15549257#client-secret-hashing "https://support.google.com/cloud/answer/15549257#client-secret-hashing") . This affects redeployments of the Horizon SDV platform if the _Client Secret_ was not securely stored previously.

This secret is required by Keycloak for the Google Identity Provider (Client Secret). If the secrets do not match, OAuth 2.0 authentication will fail and users will lose access.

### **Solution:**

- Create a new secret in Google Cloud:
    
    - In Credentials, select the Horizon client secret
        
    - Disable the old secret and create a new one.
        
    - Download or copy the new secret and store it securely.
        
- Verify login (for apps from Landing Page) fail.
    
- Update Keycloak:
    
    - Go to Identity Provider → Google.
        
    - Update the Client Secret and save.
        
- Verify login works as expected.

***

## Documentation update

- Rel.3.1.0 provides with several updates in Horizon documentation including e.g. **Horizon Deployment Guide** (/docs/deployment_guide.md).
    
- The new **contributing.md** document (/doc/contributing.md) defines rules for Partner Contributions Repository integration and recommended directory structure for third party modules provided from external Horizon Partners.
    
- The new Upgrade Guide (/docs/guides/upgrade_guide_3_0_0_to_3_1_0.md) provide guideline for Rel.3.0.0 -> Rel.3.1.0 upgrade.

***

### Bug Fixes

<table>
<tr>
  <th>ID</th>
  <th>Bug</th>
  <th>Description</th>
  <th>SHA</th>
</tr>
<tr>
  <td valign="top">TAA-1236</td>
  <td valign="top">[Volvo] Google platform failures on jenkins-mtk-connect-apikey</td>
  <td valign="top"><ul><li>mtk-connect-post-key: add create_or_update_jenkins_secret() so the jenkins-mtk-connect-apikey secret is created if absent (CronJob or one-off can now establish the credential; previously only updated existing secret, causing "Could not find credentials entry" when mtk-connect-post-job had not run or had failed).</li><li>mtk-connect-post configure.sh: make DELETE curls non-fatal (| true) so 404 on first run does not exit; remove if block so any real failure exits the job visibly.</li></ul></td>
  <td valign="top"><code>ea84ef88c7236d582707601e368fd1803a3345c4</code></td>
</tr>
<tr>
  <td valign="top">TAA-1260</td>
  <td valign="top">Sync Mirror pipeline hangs after modifying MIRROR_VOLUME_CAPACITY_GB during Infra creation</td>
  <td valign="top"><ul><li>Fixed issue where Filestore expansion (e.g., 4TB → 5TB) caused PVCs to remain stuck in <code>Pending</code> state with 0 capacity</li><li>Resolved Kubernetes binding conflicts caused by static PV/PVC provisioning without a StorageClass or CSI driver</li><li>Eliminated race conditions during resize where old PVCs were not released and PVs entered <code>Failed</code> state</li><li>Removed incompatible <code>ReclaimPolicy=Delete</code> usage on statically‑provisioned NFS volumes</li><li>Migrated Mirror storage from static PV/PVC management to <strong>Filestore CSI driver–based dynamic provisioning</strong></li><li>Introduced new StorageClass with:</li><li><code>filestore.csi.storage.gke.io</code> provisioner</li><li><code>allowVolumeExpansion=true</code> for online resize</li><li><code>ReclaimPolicy=Retain</code> for data safety</li><li>Simplified Terraform to manage only the PVC; CSI driver now owns PV lifecycle</li><li>Added safeguards to <strong>prevent volume downsizing</strong>, avoiding potential data loss</li><li>Standardized naming by removing legacy <code>aosp</code> references across configs and scripts</li></ul></td>
  <td valign="top"><code>86bee3badf422614629752a19bcf19d8555789ef</code></td>
</tr>
<tr>
  <td valign="top">TAA-1326</td>
  <td valign="top">Cloud WS: Create Configuration fails for region other than europe-west1</td>
  <td valign="top"><ul><li>Parameter WS_REPLICA_ZONES as default value was partially hardcoded ({CLOUD_REGION}-b, -d) )For some zones eg “us-central1-d” is not existing ( currently us-central1-a, b, c, f) .</li><li>Implemented solution: If user will not add any replica_zone values The default value will retrieve all zones in region and automatically select the first two zones in current region</li></ul></td>
  <td valign="top"><ul><li><code>1ea0c42ed4ccc2adcbae0126d34664af9599b79e</code></li><li><code>71a7316c70873e57da6395ee51a0a87684fe5d08</code></li><li><code>73d4f09c55f4130e1023df7546b53a37c42118cf</code></li><li><code>b8caa3676843d104b1e4fa7120dc76dbd6c9acfa</code></li></ul></td>
</tr>
<tr>
  <td valign="top">TAA-1327</td>
  <td valign="top">Cloud WS: Create Workstation pipeline fails (WS created but IAM user add fails)</td>
  <td valign="top"><ul><li>Fix: Ensure the workstation is fully created and ready before applying IAM bindings.</li></ul><br><br>This helps prevent concurrent IAM policy modification conflicts (409 errors)</td>
  <td valign="top"><ul><li><code>818bda3e6d5580c8b339b26dfe4b8dad5f28fdac</code></li><li><code>18ee772625d5abd7377906c6c9865c7be91dec0f</code></li></ul></td>
</tr>
<tr>
  <td valign="top">TAA-1340</td>
  <td valign="top">[Jenkins] ABFS license no longer applied in deployment</td>
  <td valign="top"><ul><li>Simplified Horizon deployment dropped support of creating the ABFS license and as such, this must now be applied via Jenkins ABFS server and uploaders when action is APPLY.</li><li>Mask the license for security reasons.</li></ul></td>
  <td valign="top"><code>290bf5dea46d4f058d3fc96f8b67881c1efbdf9c</code></td>
</tr>
<tr>
  <td valign="top">TAA-1416</td>
  <td valign="top">Remove obsolete ABFS secrets created via Terraform and GitOps</td>
  <td valign="top">This PR removes deprecated <strong>ABFS license resources</strong> that were previously managed through Terraform and GitOps. The ABFS license is now <strong>exclusively managed by Jenkins</strong>, and all unused license-related resources and references have been cleaned up accordingly.<br><br><strong>Details</strong>:<br><br><ul><li>Removed the Terraform variable and references for <code>sdv_abfs_license_key_b64</code>.</li><li>Removed the Kubernetes/secret resources and references for <code>jenkins-abfs-license-b64</code>.</li><li>Cleaned up all dependent configurations and references to ensure no residual usage of the removed license resources.</li></ul><br><br><strong>Verification</strong><br><br><ul><li>Deployed the platform after removing the deprecated ABFS license resources.</li><li>Confirmed no deployment or runtime issues related to ABFS licensing.</li></ul><br><br><strong>Purpose</strong><br><br>These changes simplify license management by consolidating ABFS license handling within Jenkins, reduce configuration complexity in Terraform and GitOps, and prevent confusion caused by unused or legacy license resources.</td>
  <td valign="top"><code>a7c2bbbf6e1189b6a5119c983183bfb7001133e6</code></td>
</tr>
<tr>
  <td valign="top">TAA-1418</td>
  <td valign="top">Fails on pkcs8_converter (jq missing)</td>
  <td valign="top">TAA-1418: install jq dependency for pkcs8 conversion<br><br><ul><li>Resolves deployment failures in TAA-1418</li><li>Adds missing 'jq' binary required by the external terraform data source</li></ul></td>
  <td valign="top"><code>b80c14290470ac483b8d1eb587acc20084b3a422</code></td>
</tr>
<tr>
  <td valign="top">TAA-1428</td>
  <td valign="top">Password check incorrect (12 should mean 12)</td>
  <td valign="top">TAA-1428: Correct password length check<br><br>If it states it should be at least 12 characters, ensure the check is correct, ie >= 12 not > 12!</td>
  <td valign="top"><code>f29c70246fe52a4f880a2e332660157e1459af2e</code></td>
</tr>
<tr>
  <td valign="top">TAA-1429</td>
  <td valign="top">argocd namespace stuck in 'Terminating'</td>
  <td valign="top">Update deployment script with deletion of resources which cause the namespace <code>argocd</code> to be stuck in <code>terminating</code> state indefinitely.<br><br><strong>Changes</strong><br><br>deploy.sh<br><br>File path: <code>tools/scripts/deployment/deploy.sh</code><br><br><ul><li>Added two new functions</li><li><code>cleanup_gateways()</code> - Deletes the GKE Gateway which triggers the deletion of backends, load balancers and NEGs.</li><li><code>cleanup_argocd()</code> - Deletes all Apps created by <code>horizon-sdv</code> app to prevent it from being stuck in terminating state.</li></ul></td>
  <td valign="top"><code>d2d32295bc4580bf77fc6f59cb11301de1451636</code></td>
</tr>
<tr>
  <td valign="top">TAA-1430</td>
  <td valign="top">Enable 'force_destroy' on buckets</td>
  <td valign="top">Enable <code>force_destroy</code> for GCS buckets to destroy the buckets on Terraform destroy workflow even if it contains objects.<br><br><strong>Changes</strong><br><br>main.tf<br><br>File path: <code>terraform/modules/sdv-gcs/main.tf</code><br><br><ul><li>Add <code>force_destroy = true</code> to enable force destruction of GCS buckets.</li></ul></td>
  <td valign="top"><code>211d4564d0265b38ee789dddca7708a8982502af</code></td>
</tr>
<tr>
  <td valign="top">TAA-1432</td>
  <td valign="top">landingpage 'exec format error'</td>
  <td valign="top">landingpage 'exec format error' fix<br><br>Ensure docker images are built for the target platform, not the architecture of the platform they are deployed on.</td>
  <td valign="top"><code>4322698a334d01c2c84ab72967537063b3c557ca</code></td>
</tr>
<tr>
  <td valign="top">TAA-1435</td>
  <td valign="top">Cross architecture support</td>
  <td valign="top">Cross architecture support fix.<br><br>Explicitly set Docker base image platform to linux/amd64 to ensure cross-architecture deployment consistency.</td>
  <td valign="top"><code>3ef9eb0b71f45bb920a9d62606118ee130895f76</code></td>
</tr>
<tr>
  <td valign="top">TAA-1438</td>
  <td valign="top">Cuttlefish SSH key incorrectly created (blocks CF jobs)</td>
  <td valign="top"><strong>Cuttlefish SSH Key Update: Regenerate VM Templates</strong><br><br>This fix updates the SSH key generation algorithm used by Cuttlefish VM instances. To avoid any impact, regenerate the VM instance templates.<br><br>In Jenkins:<br><br><ul><li><code>Android Workflow → Environment → Docker Image Template → Build with Parameters</code></li><li>Deselect <code>NO_PUSH</code> to ensure image is uploaded to registry.</li><li>Click <code>Build</code></li><li><code>Android Workflow → Environment → CF Instance Template → Build with Parameters</code></li><li>Set <code>ANDROID_CUTTLEFISH_REVISION=main</code></li><li>Click <code>Build</code></li><li>Repeat for the tagged version of Android Cuttlefish</li><li><code>Android Workflow → Environment → CF Instance Template ARM64 → Build with Parameters</code></li><li>Repeat for ARM64 if enabled.</li><li>Set <code>ANDROID_CUTTLEFISH_REVISION=main</code></li><li>Click <code>Build</code></li><li>Repeat for the tagged version of Android Cuttlefish</li></ul><br><br>If SSH key issues appear in any of the following jobs, regenerate the instance templates to ensure the latest keys are installed:<br><br><ul><li><code>Android Workflow → Environment → Development Test Instance</code></li><li><code>Android Workflow → Builds → Gerrit</code></li><li><code>Android Workflow → Tests → CVD Launcher</code></li><li><code>Android Workflow → Tests → CTS Execution</code></li></ul></td>
  <td valign="top"><ul><li><code>eb61aefb3e86a1e16022708a13b0657eaf5b79f0</code></li><li><code>03f52993fbf637c084e1db0f61be65f21f5c2853</code></li><li><code>172781210fba6573434ba8e9b6da2b68b0b206d3</code></li><li><code>501e12e97e89e26eb74fa7c855ca15b3e03921a0</code></li><li><code>d80ccf7323c22d2b85a2f4a8d09be4b1983c95e9</code></li><li><code>5442aecc9a0cd98ef7b98699f095b0b9332f3e9e</code></li></ul></td>
</tr>
<tr>
  <td valign="top">TAA-1441</td>
  <td valign="top">Finalize cross architecture support - R31.0</td>
  <td valign="top">Updates in deployment scripts and containers to emulate <code>linux/amd64</code><br><br><strong>Changes</strong><br><br><strong>container-deploy.sh</strong><br><br>File path: <code>tools/scripts/deployment/container-deploy.sh</code><br><br><ul><li>Update the script to run the deployment container with <code>linux/amd64</code> emulation pinned.</li></ul><br><br><strong>Dockerfile</strong><br><br>File path: <code>tools/scripts/deployment/container/Dockerfile</code><br><br><ul><li>Update the Dockerfile to be built for <code>linux/amd64</code>.</li></ul></td>
  <td valign="top"><code>076c2c57434c2596e2db44ffb60e4c435f55b1a6</code></td>
</tr>
<tr>
  <td valign="top">TAA-1443</td>
  <td valign="top">Gerrit MCP Server issues</td>
  <td valign="top">Fix syntax error for <code>gerrit-mcp-server-config</code> causing <code>gerrit-mcp-server</code> deployment errors.<br><br><strong>Changes</strong><br><br>gerrit-mcp-server.yaml<br><br>File path: <code>gitops/apps/gerrit-mcp-server/templates/gerrit-mcp-server.yaml</code><br><br><ul><li>Remove <code>-</code> causing syntax issues.</li></ul></td>
  <td valign="top"><code>e6e2375372b4b16ce8d78a017818989ee911d954</code></td>
</tr>
<tr>
  <td valign="top">TAA-1446</td>
  <td valign="top">TF OpenSSH conversion failing</td>
  <td valign="top">Fixed a bug where the OpenSSH key was not being updated after the initial RSA key creation.<br><br>Replaced null_resource with terraform_data and added a timestamp trigger to force an idempotent conversion check on every run. This ensures that if an RSA key exists without the OpenSSH format, the conversion logic is triggered, while the grep check protects against unnecessary overwrites.</td>
  <td valign="top"><code>a1f7ce4beaa59dd9acbd09a5c2571cbb8b5af2b8</code></td>
</tr>
<tr>
  <td valign="top">TAA-1447</td>
  <td valign="top">Shell Script Permission Denied</td>
  <td valign="top">Update Dockerfiles for <code>sdv-container-images</code> module which when built with Terraform as a non-root user causes <code>permission denied</code> error for <code>configure.sh</code><br><br><strong>Changes</strong><br><br>Resolve permission related issues.<br><br><strong>File paths:</strong><br><br><ul><li>Grafana Post: <code>terraform/modules/sdv-container-images/images/grafana/grafana-post/Dockerfile</code></li><li>Keycloak Post Argo CD: <code>terraform/modules/sdv-container-images/images/keycloak/keycloak-post-argocd/Dockerfile</code></li><li>Keycloak Post Gerrit: <code>terraform/modules/sdv-container-images/images/keycloak/keycloak-post-gerrit/Dockerfile</code></li><li>Keycloak Post Grafana: <code>terraform/modules/sdv-container-images/images/keycloak/keycloak-post-grafana/Dockerfile</code></li><li>Keycloak Post Headlamp: <code>terraform/modules/sdv-container-images/images/keycloak/keycloak-post-headlamp/Dockerfile</code></li><li>Keycloak Post Jenkins: <code>terraform/modules/sdv-container-images/images/keycloak/keycloak-post-jenkins/Dockerfile</code></li><li>Keycloak Post MCP Gateway Resgistry: <code>terraform/modules/sdv-container-images/images/keycloak/keycloak-post-mcp-gateway-registry/Dockerfile</code></li><li>Keycloak Post MTK Connect: <code>terraform/modules/sdv-container-images/images/keycloak/keycloak-post-mtk-connect/Dockerfile</code></li><li>Keycloak Post: <code>terraform/modules/sdv-container-images/images/keycloak/keycloak-post/Dockerfile</code></li><li>MTK Connect Post Key: <code>terraform/modules/sdv-container-images/images/mtk-connect/mtk-connect-post-key/Dockerfile</code></li><li>LandingPage App: <code>terraform/modules/sdv-container-images/images/landingpage/landingpage-app/Dockerfile</code></li></ul></td>
  <td valign="top"><code>1e1532c5ca5a2a41f8a20ceaf9012f868947aed4</code></td>
</tr>
<tr>
  <td valign="top">TAA-1450</td>
  <td valign="top">High severity violation of security rules - "GCP DNS zones DNSSEC disabled" #4</td>
  <td valign="top">DNSSEC support in GCP DNS zones enabled by default.</td>
  <td valign="top"><code>363659c78c41d6a3db7cf6877ec7320eb2b443a0</code></td>
</tr>
<tr>
  <td valign="top">TAA-1453</td>
  <td valign="top">Vulnerabilities in /horizon-sdv/landingpage-app container</td>
  <td valign="top"><ul><li>CVE-2025-48174 is fixed in 1.3.0 for libavif</li><li>CVE-2026-22801 is fixed in 1.6.54-r0 for libpng</li><li>CVE-2026-22695 is fixed in 1.6.54-r0 for libpng</li></ul></td>
  <td valign="top"><code>a2b3bbb91091cc3c9e99014c1acacac6855bce3a</code></td>
</tr>
<tr>
  <td valign="top">TAA-1457</td>
  <td valign="top">Vulnerabilities in /horizon-sdv/keycloak-post-headlamp container</td>
  <td valign="top">32 Vulnerabilities fixed fixed in keycloak-post-headlamp container. Base OS Change - node:22.13.0 → node:22-bookworm<br><br>Base Image Changes:<br><br><ul><li><code>debian:12.12</code> → <code>debian:12.13</code></li><li><code>node:22.13.0</code> → <code>node:22-bookworm</code> (includes Debian 12.13)</li><li><code>python:3.9-slim</code> → <code>python:3.9-slim-bookworm</code> (explicit)</li></ul></td>
  <td valign="top"><code>a2b3bbb91091cc3c9e99014c1acacac6855bce3a</code></td>
</tr>
<tr>
  <td valign="top">TAA-1458</td>
  <td valign="top">Vulnerabilities in /horizon-sdv/keycloak-post-grafana container</td>
  <td valign="top">32 Vulnerabilities fixed in keycloak-post-grafana container. Base OS Change - Node:22.13.0 → node:22-bookworm<br><br>Base Image Changes:<br><br><ul><li><code>debian:12.12</code> → <code>debian:12.13</code></li><li><code>node:22.13.0</code> → <code>node:22-bookworm</code> (includes Debian 12.13)</li><li><code>python:3.9-slim</code> → <code>python:3.9-slim-bookworm</code> (explicit)</li></ul></td>
  <td valign="top"><code>a2b3bbb91091cc3c9e99014c1acacac6855bce3a</code></td>
</tr>
<tr>
  <td valign="top">TAA-1459</td>
  <td valign="top">Vulnerabilities in /horizon-sdv/keycloak-post-gerrit container</td>
  <td valign="top">33 Vulnerabilities fixed in keycloak-post-gerrit container. Base OS Change - Node:22.13.0 → node:22-bookworm<br><br>Base Image Changes:<br><br><ul><li><code>debian:12.12</code> → <code>debian:12.13</code></li><li><code>node:22.13.0</code> → <code>node:22-bookworm</code> (includes Debian 12.13)</li><li><code>python:3.9-slim</code> → <code>python:3.9-slim-bookworm</code> (explicit)</li></ul></td>
  <td valign="top"><code>a2b3bbb91091cc3c9e99014c1acacac6855bce3a</code></td>
</tr>
<tr>
  <td valign="top">TAA-1460</td>
  <td valign="top">Vulnerabilities in /horizon-sdv/keycloak-post-argocd container</td>
  <td valign="top">33 Vulnerabilities fixed in keycloak-post-argocd container. Base OS Change - Node:22.13.0 → node:22-bookworm<br><br>Base Image Changes:<br><br><ul><li><code>debian:12.12</code> → <code>debian:12.13</code></li><li><code>node:22.13.0</code> → <code>node:22-bookworm</code> (includes Debian 12.13)</li><li><code>python:3.9-slim</code> → <code>python:3.9-slim-bookworm</code> (explicit)</li></ul></td>
  <td valign="top"><code>a2b3bbb91091cc3c9e99014c1acacac6855bce3a</code></td>
</tr>
<tr>
  <td valign="top">TAA-1461</td>
  <td valign="top">Vulnerabilities in /horizon-sdv/keycloak-post container</td>
  <td valign="top">33 Vulnerabilities fixed in keycloak-post container. Base OS Change - Node:22.13.0 → node:22-bookworm<br><br>Base Image Changes:<br><br><ul><li><code>debian:12.12</code> → <code>debian:12.13</code></li><li><code>node:22.13.0</code> → <code>node:22-bookworm</code> (includes Debian 12.13)</li><li><code>python:3.9-slim</code> → <code>python:3.9-slim-bookworm</code> (explicit)</li></ul></td>
  <td valign="top"><code>a2b3bbb91091cc3c9e99014c1acacac6855bce3a</code></td>
</tr>
<tr>
  <td valign="top">TAA-1462</td>
  <td valign="top">Vulnerabilities in /horizon-sdv/grafana-post container</td>
  <td valign="top">33 Vulnerabilities fixed in keycloak-post container. Base OS Change-Node:22.13.0 → node:22-bookworm<br><br>Base Image Changes:<br><br><ul><li><code>debian:12.12</code> → <code>debian:12.13</code></li><li><code>node:22.13.0</code> → <code>node:22-bookworm</code> (includes Debian 12.13)</li><li><code>python:3.9-slim</code> → <code>python:3.9-slim-bookworm</code> (explicit)</li></ul></td>
  <td valign="top"><code>a2b3bbb91091cc3c9e99014c1acacac6855bce3a</code></td>
</tr>
<tr>
  <td valign="top">TAA-1463</td>
  <td valign="top">Vulnerabilities in /horizon-sdv/gerrit-post container</td>
  <td valign="top">7 Vulnerabilities fixed in gerrit-post container. Base OS Change - Debian 12.12 → Debian 12.13<br><br>Base Image Changes:<br><br><ul><li><code>debian:12.12</code> → <code>debian:12.13</code></li><li><code>node:22.13.0</code> → <code>node:22-bookworm</code> (includes Debian 12.13)</li><li><code>python:3.9-slim</code> → <code>python:3.9-slim-bookworm</code> (explicit)</li></ul></td>
  <td valign="top"><code>a2b3bbb91091cc3c9e99014c1acacac6855bce3a</code></td>
</tr>
<tr>
  <td valign="top">TAA-1455</td>
  <td valign="top">Vulnerabilities in /horizon-sdv/keycloak-post-mtk-connect container</td>
  <td valign="top">32 Vulnerabilities fixed fixed in keycloak-post-mtk-connect container. Base OS Change - node:22.13.0 → node:22-bookworm<br><br>Base Image Changes:<br><br><ul><li><code>debian:12.12</code> → <code>debian:12.13</code></li><li><code>node:22.13.0</code> → <code>node:22-bookworm</code> (includes Debian 12.13)</li><li><code>python:3.9-slim</code> → <code>python:3.9-slim-bookworm</code> (explicit)</li></ul></td>
  <td valign="top"><code>a2b3bbb91091cc3c9e99014c1acacac6855bce3a</code></td>
</tr>
<tr>
  <td valign="top">TAA-1452</td>
  <td valign="top">Vulnerabilities in /horizon-sdv/mtk-connect-post container</td>
  <td valign="top">5 Vulnerabilities fixed in gerrit-post container. Base OS Change - Debian 12.12 → Debian 12.13<br><br>Base Image Changes:<br><br><ul><li><code>debian:12.12</code> → <code>debian:12.13</code></li><li><code>node:22.13.0</code> → <code>node:22-bookworm</code> (includes Debian 12.13)</li><li><code>python:3.9-slim</code> → <code>python:3.9-slim-bookworm</code> (explicit)</li></ul></td>
  <td valign="top"><code>a2b3bbb91091cc3c9e99014c1acacac6855bce3a</code></td>
</tr>
<tr>
  <td valign="top">TAA-1468</td>
  <td valign="top">High severity violation of security rules "GCP GKE Application-layer Secrets encryption disabled " #7</td>
  <td valign="top">KMS can be deployed based on settings in <strong>terraform.tfvars</strong> - (sdv_enable_kms_encryption = false).<br><br>KMS implementation details:<br><br><ul><li>It is possible to use KMS to encrypt kubernetes secrets (“Application-layer secrets encryption” option in GKE)</li><li>If enabled – a KMS keyring is created, then a symmetric key (at version 1) is created inside the keyring</li><li>Encryption is fully transparent to the cluster</li><li>Once key is created – it is not easy to destroy it, it is rather that version 2 of the key will be created, and previous version 1 even if marked “destroy” – will be gone after 30 days.</li><li>Once keyring is created – IT IS NOT POSSIBLE TO DESTROY IT , so it makes trouble in terraform state when created and tried to delete it later on</li><li>KMS feature is disabled by default.</li><li>Keyring can easily be deleted only if entire GCP project is deleted.</li></ul></td>
  <td valign="top"><code>4ea1c55f90d22d77d74a2206c7c326c3dfeef495</code></td>
</tr>
<tr>
  <td valign="top">TAA-1475</td>
  <td valign="top">[Cuttlefish] OS Login Cleanup Script Errors - Improper Parsing & Excessive Latency</td>
  <td valign="top">Avoid issues with using table that can lead to erroneous values leading to us delaying 1m per loop and taking too long.<br><br>Make it a function so we can use elsewhere if required.</td>
  <td valign="top"><code>5442aecc9a0cd98ef7b98699f095b0b9332f3e9e</code></td>
</tr>
<tr>
  <td valign="top">TAA-1481</td>
  <td valign="top">mtk-connect-post-key Post-job container image build fails</td>
  <td valign="top">The permission issue which causes the container image build to fail has been resolved.<br><br><strong>Changes</strong><br><br>Dockerfile<br><br>File path: <code>terraform/modules/sdv-container-images/images/mtk-connect/mtk-connect-post-key/Dockerfile</code><br><br><ul><li>Add <code>--chown=appuser:appuser</code> to fix permission issues.</li></ul></td>
  <td valign="top"><code>ef72216ba232586dea96306431a8860b64b9d5e5</code></td>
</tr>
<tr>
  <td valign="top">TAA-1482</td>
  <td valign="top">Terraform destroy fails to delete VPC</td>
  <td valign="top">This merge fixes the issue which cause terraform destroy to fail due to the failure in deletion of the VPC <code>sdv-network</code> caused due to remaining NEGs (Network Endpoint Groups).<br><br><strong>Changes</strong><br><br>deploy.sh<br><br>File path: <code>tools/scripts/deployment/deploy.sh</code><br><br><ul><li>Update the script's <code>cleanup_gateways()</code> function to also remove <code>http-routes</code> which triggers the deletion of NEGs.</li></ul></td>
  <td valign="top"><code>d24100db5874a9591404fe522be1f39617448831</code></td>
</tr>
<tr>
  <td valign="top">TAA-1492</td>
  <td valign="top">Refactor Argo CD Application Lifecycle to Terraform-Native Cascading Delete</td>
  <td valign="top">Update the Terraform module <code>sdv-gke-apps</code> module to enable cascading delete for the App of Apps <code>horizon-sdv</code> (<code>argocd_application</code>) and update dependency chain for the module <code>sdv-gke-cluster</code>.<br><br><strong>Changes</strong><br><br><strong>main.tf</strong><br><br>File path: <code>terraform/modules/base/main.tf</code><br><br><ul><li>Update the module <code>sdv-gke-cluster</code> with depency on <code>sdv_certificate_manager</code> and <code>sdv_ssl_policy</code> to enable deletion of GKE cluster before deletion of SSL Policy and Certificate Manager Certificates to avoid issues or errors while running Terraform destroy workflow.</li></ul><br><br><strong>main.tf</strong><br><br>File path: <code>terraform/modules/sdv-gke-apps/main.tf</code><br><br><ul><li>Update dependency, add required finalizer to enable cascading delete for the <code>horizon-sdv</code> app.</li><li>Add <code>wait= true</code> to ensure complete deletion of <code>horizon-sdv</code> app before Terraform destroy workflow proceeds to destroy other resources in the module.</li></ul><br><br><strong>Dockerfile</strong><br><br>File path: <code>tools/scripts/deployment/container/Dockerfile</code><br><br><ul><li>Remove <code>kubectl</code> from Dockerfile as it is no longer required.</li></ul><br><br><strong>deploy.sh</strong><br><br>File path: <code>tools/scripts/deployment/deploy.sh</code><br><br><ul><li>Remove <code>kubectl</code> operation from <code>deploy.sh</code> as it is no longer required to perform clean-up activities.</li></ul></td>
  <td valign="top"><ul><li><code>d438544bd1469a8aec19bf31fa35ecdfbb3648d1</code></li><li><code>7f1486291a1e81bb4fdd1d55c77c54d05097ec5c</code></li><li><code>f81ba04d48ab5b7b9f8f59cd85b2acc14252116c</code></li></ul></td>
</tr>
<tr>
  <td valign="top">TAA-1493</td>
  <td valign="top">Cloud-WS Image Builds: Yarn GPG Key Issue</td>
  <td valign="top">Added Yarn GPG key refresh before first <code>apt-get update</code> in all Dockerfiles</td>
  <td valign="top"></td>
</tr>
<tr>
  <td valign="top">TAA-1494</td>
  <td valign="top">Kubernetes NetworkPolicies update breaks deployment</td>
  <td valign="top">Missing closing brace breaking deployment.</td>
  <td valign="top"><code>c95c4c1cbb6ff7f1e47a296868fbc094aa9b619b</code></td>
</tr>
<tr>
  <td valign="top">TAA-1495</td>
  <td valign="top">Security hardening breaks deployment</td>
  <td valign="top">An input variable with the name "sdv_dns_dnssec_enabled" has not been declared. This variable can be declared with a variable "sdv_dns_dnssec_enabled" {} block.</td>
  <td valign="top"><code>781c30d3e9c9f76c52e508cb4da2f0e7cf0fc1eb</code></td>
</tr>
<tr>
  <td valign="top">TAA-1498</td>
  <td valign="top">Terraform local-exec fails because gcloud project is not explicitly set in script</td>
  <td valign="top">Gcloud project is explicitly set in script</td>
  <td valign="top"><code>4114bbaefb3305216541cce6a21f5874ff647de8</code></td>
</tr>
<tr>
  <td valign="top">TAA-1499</td>
  <td valign="top">Terraform destroy blocks redeployment when KMS is enabled (sdv_enable_kms_encryption = true)</td>
  <td valign="top">Several fixes for KMS deployment</td>
  <td valign="top"><code>fe8c58c57f440cbebb32d6ad48b567245f3a07e6</code></td>
</tr>
<tr>
  <td valign="top">TAA-1507</td>
  <td valign="top">[Jenkins] CF instances - Fails to connect via ssh</td>
  <td valign="top"><ul><li>Firewall: allow SSH to Cuttlefish from GKE node range (10.1.0.0/24).</li><li>Jenkins: allow controller egress SSH to Cuttlefish (22); allow agent</li></ul><br><br>SSH to Cuttlefish.</td>
  <td valign="top"><code>b65cda8a4af97e788af259396445415c243d0919</code></td>
</tr>
<tr>
  <td valign="top">TAA-1508</td>
  <td valign="top">[Jenkins] Fix Jenkins startup and Gerrit connectivity</td>
  <td valign="top">Set noConnectionOnStartup: true for Gerrit so Jenkins starts and the UI is available without waiting for Gerrit; the plugin connects when Gerrit is reachable.<br><br>Add allow-jenkins-controller-egress-to-gerrit NetworkPolicy so the<br><br>controller can reach Gerrit on 29418 (SSH) and 8080 (HTTP). Default-deny had limited controller egress to 80/443, so the Gerrit Trigger never connected.</td>
  <td valign="top"><ul><li><code>b6cb82e5122502f2225d2511d227e6715074e8f2</code></li><li><code>667a01271394ac723922cc321da365a78f62b915</code></li></ul></td>
</tr>
<tr>
  <td valign="top">TAA-1517</td>
  <td valign="top">[Cloud-WS] terminal monospace rendering & gemini-mcp-agent executable broken entrypoint</td>
  <td valign="top"><strong>Fixes applied</strong><br><br><ul><li>move gemini-mcp-agent shebang to line 1 so the binary executes with python</li><li>install fonts-dejavu-core in android-studio, asfp, and code-oss images</li><li>set GNOME Terminal dconf defaults (DejaVu Sans Mono 12, cell width/height scale 1.0) for desktop images</li><li>run dconf update during image setup to apply terminal defaults</li></ul><br><br><strong>Minor changes</strong><br><br><ul><li>updated docs/guides/mcp_setup.md for clear info on gemini-mcp-agent and mcp servers settings in android studio IDE</li></ul></td>
  <td valign="top"><ul><li><code>101a10e02cca3979f2d3633f28ccd33fef69e39d</code></li><li><code>9f8f771b984319b687eb9d0739be2ae725094444</code></li></ul></td>
</tr>
<tr>
  <td valign="top">TAA-1528</td>
  <td valign="top">ABFS server and uploader: SSH on port 22 blocked; get_server_details / get_uploader_details and Console SSH fail.</td>
  <td valign="top">Code in this PR fixes port 22 opening.<br><br>And deployment issue which fixes "Error: googleapi: Error 400: The network policy addon must be enabled before updating the nodes." in file terraform/modules/sdv-gke-cluster/main.tf</td>
  <td valign="top"><ul><li><code>f8758c356c6e376c2548340614f6fcdd3fe56232</code></li><li><code>4e974f84bb0c6ea5c209ec9e14e918ba25260a3c</code></li></ul></td>
</tr>
<tr>
  <td valign="top">TAA-1529</td>
  <td valign="top">Pin ABFS build node pool to a fixed GKE version so CASFS kernel module stays compatible</td>
  <td valign="top">This PR pins the <strong>ABFS build node pool</strong> to a configurable GKE version to ensure <strong>CASFS kernel compatibility</strong> and prevent breakage caused by automatic node upgrades.<br><br><strong>Details</strong><br><br><ul><li>Introduced <code>sdv_abfs_build_node_pool_version</code> variable to configure the ABFS build node pool GKE version.</li><li>Set the node pool <code>version</code> attribute using this variable to pin the node image and kernel.</li><li>Replaced release channel usage with an explicit cluster version (<code>sdv_cluster_version</code>) to allow disabling auto-upgrade on the ABFS node pool.</li><li>Updated <code>terraform.tfvars</code> and <code>terraform.tfvars.sample</code> with pinned values (e.g. <code>1.32.7-gke.1079000</code>).</li></ul><br><br><strong>Purpose</strong><br><br>CASFS is a kernel module and must match the running node kernel. By pinning the ABFS node pool GKE version, we ensure the kernel remains stable and compatible, preventing unexpected failures caused by GKE auto-upgrades.</td>
  <td valign="top"><ul><li><code>f81bc7a22a434fa578190b2c28b03f5c0a9d23b6</code></li><li><code>be32e04e32df4098ffb8b27bea745008feb44916</code></li><li><code>5f2625760dabe05e85e3936cef0823161163a4ae</code></li><li><code>f4d7724799bcb36732cfcd2d56ff2468ee1f1900</code></li><li><code>44ae1d9a659a9d49f8f3dba32c791caa57b52440</code></li><li><code>30d8eb8d3309306cfb8e37e021f18c44e80b1bcc</code></li><li><code>f04bf569d1d0e08cdb3d5e6040b0e1c3ecdb35d2</code></li></ul></td>
</tr>
<tr>
  <td valign="top">TAA-1535</td>
  <td valign="top">GKE deployment fails on first run due to STABLE release channel conflict</td>
  <td valign="top">Fix the error <code>Error: error creating NodePool: googleapi: Error 400: Auto_upgrade must be true when release_channel STABLE is set.</code><br><br>GCP requires <code>auto_upgrade = true</code> on node pools when a named release channel (STABLE/REGULAR/RAPID with REGULAR being the default option if release channel is unset) is active.<br><br>Setting <code>channel = "UNSPECIFIED"</code> explicitly opts the cluster out of any release channel, removing this constraint and allowing Terraform to pin versions directly.<br><br>Also formatted all Terraform files in <code>terraform/</code> for alignment consistency (no logic changes).<br><br><strong>Changes</strong><br><br><strong>terraform/modules/sdv-gke-cluster/main.tf</strong><br><br><ul><li>Add <code>release_channel { channel = "UNSPECIFIED" }</code> block so the GCP API treats the cluster as unenrolled from any release channel.</li></ul><br><br><strong>tools/scripts/deployment/deploy.sh</strong><br><br><ul><li>Remove the <code>unenroll_cluster_release_channel</code> function as the release channel is now managed declaratively by Terraform, making the <code>gcloud</code> workaround obsolete.</li></ul></td>
  <td valign="top"><code>4a81e523ede0e405465dbe366148a866f571b624</code></td>
</tr>
<tr>
  <td valign="top">TAA-1569</td>
  <td valign="top">Gerrit-Operator in ArgoCD application goes into Unknown sync state and the Gerrit application fails to sync</td>
  <td valign="top">Update <code>gerrit-operator</code> <code>repoURL</code> from Googlesource to GitHub, avoiding rate limits and fixing issues with <code>gerrit-operator</code> deployment on fresh platforms.<br><br><strong>Changes</strong><br><br>gerrit-operator.yaml<br><br>File path: <code>gitops/templates/gerrit-operator.yaml</code><br><br><ul><li>Update <code>repoURL</code></li></ul></td>
  <td valign="top"><code>37709c24d51326d61cd2da2c833a56af2b0e29b0</code></td>
</tr>
<tr>
  <td valign="top">TAA-1570</td>
  <td valign="top">Terraform workloads Service Account name mismatch in GCP and k8s</td>
  <td valign="top">Service Account <code>sa7</code> name in <code>terraform/env/main.tf</code> should be <code>gke-tf-wl-sa</code> instead of current value of <code>gke-terraform-workloads-sa</code> to match with other instances of the SA in yaml files.</td>
  <td valign="top"><code>d055ccc982ff4ced993dd99a6a359cda5b6b571d</code></td>
</tr>
<tr>
  <td valign="top">TAA-1573</td>
  <td valign="top">terraform apply fails with Error 400 when removing a sub-environment due to cert map referenced by TargetHTTPSProxy</td>
  <td valign="top">This PR resolves two issues affecting the sandbox environment:<br><br><ul><li><strong>Fix</strong> <code>terraform apply</code> <strong>Error 400 on sub-environment removal</strong> - Previously, each environment (main + each sub-env) created its own <code>google_certificate_manager_certificate_map</code> via a <code>for_each</code> loop. When a sub-environment was removed, Terraform would attempt to delete its cert map while it was still referenced by the <code>TargetHTTPSProxy</code>, causing a <code>400</code> error. All certificates (main env + sub-envs) are now consolidated into a single cert map (<code>horizon-sdv-map</code>), eliminating the per-environment map lifecycle issue.</li><li><strong>Enable GKE main node pool autoscaling</strong> - The <code>sdv_main_node_pool</code> previously had a static node count with no autoscaling. Autoscaling has been enabled to allow the cluster to scale up when resource pressure occurs (e.g. Gerrit pod scheduling failures), with a configurable min/max range (default: 1-6 nodes).</li></ul><br><br><strong>Changes:</strong><br><br><strong>Certificate Manager Consolidation</strong><br><br><ul><li><code>terraform/modules/base/locals.tf</code> - Replaced per-environment <code>cert_domains_per_env</code> map with a single flat <code>cert_domains</code> map merging main and sub-env domains.</li><li><code>terraform/modules/base/main.tf</code> - Removed <code>for_each</code> from <code>module.sdv_certificate_manager</code>, calling it once with all domains. Updated <code>dns_auth_records</code> reference accordingly.</li><li><code>terraform/modules/sdv-certificate-manager/main.tf</code> - Hardcoded cert map name to <code>horizon-sdv-map</code> so it is stable across all environments.</li><li><code>gitops/templates/gateway.yaml</code> - Updated <code>networking.gke.io/certmap</code> annotation to reference the fixed name <code>horizon-sdv-map</code> instead of the namespaced name.</li></ul><br><br><strong>Main Node Pool Autoscaling</strong><br><br><ul><li><code>terraform/modules/sdv-gke-cluster/main.tf</code> - Enabled <code>autoscaling</code> block on <code>sdv_main_node_pool</code> using <code>min_node_count</code> / <code>max_node_count</code> variables.</li><li><code>terraform/modules/sdv-gke-cluster/variables.tf</code> - Added <code>node_pool_min_node_count</code> (default: 1) and <code>node_pool_max_node_count</code> (default: 6).</li><li><code>terraform/modules/base/variables.tf</code> - Added <code>sdv_cluster_node_pool_min_node_count</code> and <code>sdv_cluster_node_pool_max_node_count</code> to expose these as configurable inputs.</li></ul></td>
  <td valign="top"><ul><li><code>b010250548f9df5ff7db2afd89da96acfbfa5174</code></li><li><code>831a59f8e9c4f8f8de5b5b9d525acb3b29426641</code></li></ul></td>
</tr>
<tr>
  <td valign="top">TAA-1579</td>
  <td valign="top">Cloud WS: Create Config pipeline fails due to inconsistent order of resource creation</td>
  <td valign="top"><ul><li>Fixed Terraform apply failures caused by <code>google_workstations_workstation_config_iam_binding</code> executing before the target workstation config was fully created</li><li>Resolved consistent <code>404 Resource Not Found</code> errors from GCP IAM API due to premature policy application</li><li>Identified missing dependency in Terraform graph caused by using <code>each.key</code> (raw input string) for <code>workstation_config_id</code></li><li>Corrected implicit dependency handling by replacing hardcoded <code>each.key</code> with a direct reference to the workstation config resource attribute</li><li>Ensured Terraform now waits for successful workstation config provisioning before applying IAM bindings</li><li>Eliminated parallel execution race condition between workstation config creation and IAM policy attachment</li></ul></td>
  <td valign="top"><code>06bbd1cf74d6e47993c0d394e441ae96ea722c8c</code></td>
</tr>
<tr>
  <td valign="top">TAA-1601</td>
  <td valign="top">AAOS Builder: Build that uses mirror for repo sync fails because of empty variable `MIRROR_DIR_NAME`</td>
  <td valign="top">Fixes AOSP mirror path resolution in Android Jenkins pipelines by using <code>AOSP_MIRROR_DIR_NAME</code> when constructing <code>MIRROR_DIR_FULL_PATH</code>.<br><br>Pipeline parameters are defined as <code>AOSP_MIRROR_DIR_NAME</code>, but Jenkinsfiles were reading <code>MIRROR_DIR_NAME</code>.<br><br>This mismatch could produce an invalid mirror path when <code>USE_LOCAL_AOSP_MIRROR=true</code>.<br><br><strong>Change</strong><br><br>Updated Jenkinsfiles to build mirror path with:<br><br><code>.../${AOSP_MIRROR_DIR_NAME}</code> (instead of <code>.../${MIRROR_DIR_NAME}</code>).</td>
  <td valign="top"><code>952611a5c6e8ee26ff25488e03904bbe5822cc73</code></td>
</tr>
<tr>
  <td valign="top">TAA-1602</td>
  <td valign="top">ExternalDNS does not update apex A record when load balancer IP changes</td>
  <td valign="top">ExternalDNS was not updating the apex domain A record (e.g. <code><env_name>.horizon-sdv.com</code>) when the Gateway load balancer was recreated, only subdomains such as <code>mcp.<env_name>.horizon-sdv.com</code> were updated. ExternalDNS only updates records it owns, and ownership is stored in TXT records. With the default TXT registry, no valid ownership TXT was created for the zone apex, so the apex A record was never updated. This change sets <code>txtPrefix: "%{record_type}-."</code> so the ownership TXT is created in the same zone and ExternalDNS can own and update the apex A record.<br><br><strong>Changes</strong><br><br>external-dns.yaml<br><br>File path: <code>gitops/templates/external-dns.yaml</code><br><br><ul><li>Add <code>txtPrefix: "%{record_type}-."</code> so ExternalDNS can create the heritage TXT for the apex and update the apex A record when the LB IP changes.</li></ul></td>
  <td valign="top"><code>5e585c4f1e9548a7dbc616fc990d6313725a480f</code></td>
</tr>
<tr>
  <td valign="top">TAA-1605</td>
  <td valign="top">cloud-ws/gemini-cli/gemini-mcp-agent: MCP tool calls fail after some time in gemini-cli due to JWT token caching</td>
  <td valign="top">This fix hardens and standardizes how MCP authentication is handled across Gemini clients by using <code>mcp-client-bridge</code> for <strong>registry-managed</strong> servers, instead of relying on cached config tokens.<br><br>It also updates setup documentation to reflect the actual runtime model and adds clearer operational guidance for Android Studio/ASfP cache reload behavior.<br><br><strong>Changes</strong><br><br><strong>Command-based MCP entries for registry-managed servers</strong><br><br><ul><li>Registry-managed servers are now written as <code>command + args + env</code> bridge entries instead of static <code>httpUrl + headers</code> token entries.</li><li>This is applied in both:</li><li><code>update_gemini_cli_settings_file(...)</code></li><li><code>update_android_studio_mcp_file(...)</code></li></ul><br><br>Unified bridge entry generation<br><br><ul><li>Added reusable helpers:</li><li><code>build_bridge_env_payload()</code></li><li><code>build_bridge_server_entry(...)</code></li><li><code>get_entry_http_url(...)</code></li><li>Added managed-entry marker: <code>MCP_GATEWAY_REGISTRY_MANAGED=1</code>.</li></ul><br><br><strong>Bridge now injects auth from token file, not config headers</strong><br><br><ul><li><code>run_mcp_client_bridge(...)</code> now obtains auth via token file flow (<code>~/.gemini/mcp-gateway-registry-token.json</code>) using non-interactive refresh path.</li><li>Removed dependency on cached <code>settings.json</code> bearer values for bridge auth.</li></ul><br><br><strong>Transport compatibility for Gemini clients</strong><br><br><ul><li>Bridge now supports both:</li><li>MCP stdio framed protocol (<code>Content-Length</code> headers)</li><li>NDJSON mode (legacy behavior)</li><li>Added:</li><li><code>_bridge_read_message(...)</code></li><li><code>_bridge_write_message(...)</code></li></ul><br><br><strong>Security hardening and JSON-RPC protocol correctness (id handling)\</strong><br><br><ul><li>Added guard in bridge to refuse token injection for non-registry URLs</li><li>Added strict ID validation via <code>_is_valid_jsonrpc_id(...)</code>.</li><li>Bridge no longer emits error responses for notifications/no-id messages</li></ul></td>
  <td valign="top"><code>6438c8f1b428d01fa0f296c24810e71f9c96992d</code></td>
</tr>
<tr>
  <td valign="top">TAA-1608</td>
  <td valign="top">Cloud WS: Add Users to WS and Remove Users from WS fail due to inconsistent way of fetching WS state</td>
  <td valign="top">This fixe corrects a state-validation issue in Cloud Workstation admin pipelines (<code>add user</code> / <code>remove user</code>).<br><br>Previously, these pipelines validated workstation state from Terraform state (<code>terraform show -json</code>), which can be stale when users start/stop workstations via <code>gcloud</code> (user pipelines).<br><br>Now, validation uses live workstation state from GCP API (<code>gcloud workstations describe</code>) to make decisions based on current runtime reality.<br><br><strong>Key Changes</strong><br><br><ul><li>Renamed and refactored utility function:</li><li><code>validate_workstation_state</code> -> <code>assert_workstation_state</code></li><li><code>assert_workstation_state</code> now:</li><li>Accepts: <code><workstation> <config> <cluster> <region> [expected_state]</code></li><li>Uses <code>get_current_workstation_state</code> (live <code>gcloud</code> lookup)</li><li>Defaults <code>expected_state</code> to <code>STATE_STOPPED</code></li><li>Fails fast for transitional states (<code>STATE_STARTING</code>, <code>STATE_STOPPING</code>, <code>STATE_REPAIRING</code>, <code>STATE_RECONCILING</code>) with retry guidance</li><li>Updated admin scripts to pass full workstation context:</li><li><code>workstation-admin-operations/add-workstation-user/add-workstation-user.sh</code></li><li><code>workstation-admin-operations/remove-workstation-user/remove-workstation-user.sh</code></li><li>In add/remove scripts:</li><li>Workstation config is read from generated workstation map (<code>output.tfvars.json</code>)</li><li>Cluster and region are read from input tfvars</li><li>State check is now: <code>assert_workstation_state ...</code></li></ul></td>
  <td valign="top"><code>0bbeb90f60c9c3b904dae53c2c46c3bc271450ea</code></td>
</tr>
</table>

***

## Horizon SDV - Release 3.0.0 (2025-12-19) 

### Summary

Horizon SDV 3.0.0 extends platform capabilities with support for Android 15 and the latest extensions of OpenBSW. Horizon 3.0.0 also delivers multiple new feature and several improvements over Rel. 2.0.1 along with critical bug fixes.

The set of new features in version 3.0.0 includes, among others:

- **Simplified Deployment Flow :** We have overhauled the deployment process to make it more intuitive and efficient. The new flow reduces complexity, minimizing the steps required to get your environment up and running.

- **ARM64 Support (Bare Metal) :** We have expanded our infrastructure support to include ARM64 Bare Metal. This allows you to run your workloads natively on ARM architecture, ensuring higher performance and closer parity with automotive edge hardware.

- **Gemini Code Assist :** Supercharge your development with the integration of **Gemini Code Assist** and the Gerrit MCP Server. You can now leverage Google's state-of-the-art AI to generate code, explain complex logic, debug issues faster and make use of agentic code review workflows directly within your development environment.

- **Advanced Monitoring with Grafana :** Gain deeper insights into your infrastructure with our new Grafana integration. You can now visualize and monitor POD and Instance metrics in real-time, helping you optimize resource usage and diagnose performance bottlenecks quickly.

***
### New Features

| ID | Feature | Description |
|----|--------|-------------|
| TAA-924 | Simplified Horizon Deployment Flow | Simplified and automated the Horizon SDV platform deployment by removing GitHub Actions, enabling faster adoption by community teams and reducing human error. |
| TAA-511 | Gemini Code Assist in R3 – Gerrit MCP Server integration | Use company’s codebase as a knowledge base for Gemini Code Assist within the IDE to receive code suggestions & explanations tailored to known codebase, libraries and corporate standards. |
| TAA-365 | ARM64 GCP VM (Bare Metal) support for Cuttlefish | ARM64 GCP VM support for Android builds and testing with Cuttlefish |
| TAA-595 | Monitoring of POD/Instance metrics with Grafana | Access to CPU/Memory/Storage metrics for pods and instances, to more easily investigate and debug container, pod and instance related problems and its impact on platform performance. |
| TAA-944 | Android pipeline update to Android 16 | Support for Android16 for AAOS, CF and CTS in Horizon pipelines. |
| TAA-946 | Extend OpenBSW support with additional features | Support for Eclipse Foundation OpenBSW workload features that were not included in Horizon-SDV R2.0.0 |
| TAA-889 | Horizon R3 Security update | Selected open-source applications and tools which are part of Horizon SDV platform are updated to the latest stable versions |
| TAA-377 | Google AOSP Repo Mirroring | NFS based mirror of AOSP repos deployed in the K8s cluster. |
| TAA-947 | ABFS update for R3 | Corrections and minor ABFS updates delivered from Google in Release 3.0.0 timeframe. |
| TAA-1072 | Cloud Artefact storage management | Android and OpenBSW build jobs have been modified to allow the user to specify metadata to be added to the stored artifacts during the upload process. Implementation is supported for GCP storage option only |
| TAA-1001 | Kubernetes Dashboard SSO integration | Kubernetes Dashboard SSO integration |
| TAA-945 | Replace deprecated Kaniko tool | Replace deprecated Google Kaniko tool for building container images with new Buildkit tool. |
| TAA-941 | IAA demo case. | Support for Partner demo in IAA Messe show. The main technical scope is to apply a binary APK file to the Android code, help building it and flash it to selected targets (Cuttlefish and potentially Pixel) according to Partner specification. |

***

### Improved Features

See details in `horizon-sdv/docs/release-notes-3-0-0.md`

| ID | Summary |
|----|-------------|
| TAA-1171 | Create Workloads area in Gitops section |
| TAA-862 | Improvements Structure of Test pipelines |
| TAA-1111 | Unified CTS Build process |
| TAA-1265 | [Gerrit] Support GERRIT_TOPIC with existing gerrit-triggers plugin |
| TAA-1271 | Support custom machine types for Cuttlefish |
| TAA-1269 | Adjust CTS/CVD options |

***

### Bug Fixes

| ID        | Summary |
|-----------|-------------|
| TAA-993   | [ABFS] Missing permission for jenkins-sa for ABFS server |
| TAA-1063  | [Security] Axios Security update 1.12.0 (dependabot) |
| TAA-904   | ABFS unmount doesn't work |
| TAA-1090  | [Android 16] Cuttlefish builds fail (x86/arm) |
| TAA-1080  | [OpenBSW] Builds no longer functional (main) |
| TAA-1110  | [OpenBSW] pyTest failure |
| TAA-1103  | [Android 16] CTS 16_r2 reports 15_r5 |
| TAA-1145  | Update filter (gcloud compute instance-templates list) |
| TAA-1161  | [ARM64] Subnet working utils too quiet |
| TAA-1113  | [ABFS] COS Images no longer available |
| TAA-1118  | [ABFS] CASFS kernel module update required (6.8.0-1029-gke) |
| TAA-1176  | [CF] CTS CtsDeqpTestCases execution on main not completing in reasonable time (x86) |
| TAA-1186  | Incorrect Headlamp Token Injector Argo CD App Project |
| TAA-1196  | AOSP Mirror changes break standard builds |
| TAA-1201  | AOSP Mirror sync failures |
| TAA-1200  | AOSP Mirror URLs and branches incorrect |
| TAA-1203  | AOSP Mirror repo sync failing on HTTP 429 (rate limits) |
| TAA-1205  | AOSP Mirror - no support for dev build instance |
| TAA-1198  | AOSP Mirror does not support Warm nor Gerrit Builds |
| TAA-1204  | AOSP Mirror repo sync failing - SyncFailFastError |
| TAA-1214  | AOSP Mirror ab is an |
| TAA-1219  | [Cuttlefish] Host installer failures masked |
| TAA-1202  | AOSP Mirror blocking concurrent jobs incorrectly configured |
| TAA-1238  | [Cuttlefish] Update to v1.31.0 - v1.30.0 has changed from stable to unstable. |
| TAA-1241  | [Android] Mirror should not be using OpenBSW nodes for jobs AM |
| TAA-1247  | [Workloads] Remove chmod and use git executable bit |
| TAA-1249  | [GCP] Client Secret now masked (security clarification) |
| TAA-1264  | [CVD] Logs are no longer being archived |
| TAA-1261  | [Cuttlefish] gnu.org down blocking builds |
| TAA-1266  | Pipeline does not fail when IMAGE_TAG is empty and NO_PUSH=true |
| TAA-1267  | [CWS] OSS Workstation blocking regex incorrect (non-blocking) |
| TAA-1258  | [Cuttlefish] VM instance template default disk too small. |
| TAA-1233  | [Jenkins] Plugin updates for fixes |
| TAA-1278  | [Cuttlefish] SSH/SCP errors on VM instance creation |
| TAA-1283  | Mismatch in githubApp secrets (TAA-1054) |
| TAA-1277  | [Jenkins] Plugin updates for fixes |
| TAA-1279  | [RPI] Android 16 RPI builds now failing |
| TAA-1282  | [GCP] Cluster deletion not removing load balancers |
| TAA-1257  | [Cuttlefish] android-cuttlefish build failure (regression) |
| TAA-1273  | [Cuttlefish] android-cuttlefish CVD device issues (regression) |
| TAA-1149  | [K8S] Reduce parallel jobs to reduce costs |
| TAA-1162  | [K8S] Revert parallel jobs change to reduce costs |
| TAA-1191  | Monitoring deployment related hotfixes |
| TAA-1114  | [ABFS] Update env/dev license (Oct'25) |
| TAA-1116  | [Android] Android 15 and 16 AVD missing SPDX BOM |
| TAA-1192  | [MTKC] Support additional hosts for dev and test instances |
| TAA-1207  | Mirror/Create-Mirror: Add parameter for size of the mirror NFS PVC |
| TAA-1208  | Mirror/Sync-Mirror: Sync all mirrors when SYNC_ALL_EXISTING_MIRRORS is selected |
| TAA-1211  | [Android] Simplify Dev Build instance job |
| TAA-1218  | [Grafana] ArgoCD on Dev shows 'Out Of Sync' |
| TAA-1231  | R2 - GitHub Actions workflow fails |
| TAA-1038  | [Jenkins] CF scripts - update to retain color |
| TAA-907   | Multibranch is not supported in ABFS |
| TAA-862   | Improvement to structure of Test pipelines |
| TAA-788   | Jenkins AAOS Build failure - Gerrit secrets/tokens mismatch |
| TAA-1088  | [NPM] Move wait-on post node install |
| TAA-1115  | [STORAGE] Override default paths |
| TAA-1160  | [ARM64] Lack of available instances on us-central1-b/f zone |
| TAA-1274  | [Cuttlefish] CTS hangs - android-cuttlefish issues |
| TAA-1290  | [Cuttlefish] ARM64 builds broken on f2fs-tools (missing) |
| TAA-1253  | [MTK Connect] ERROR: script returned exit code 92/1 |

***
## Horizon SDV - Release 2.0.1 (2025-09-24) 

### Summary
Hot fix release for Rel.2.0.1 with emergency fix for Helm repo endpoint issues, and minor documentation updates.

### New Features
N/A

### Improved Features
- New simplified Release Notes format.

### Bug Fixes

|  ID       | Summary                                                      |
|-----------|--------------------------------------------------------------|
| TAA-1002  | [Jenkins] Install ansicolor plugin for CWS                   |
| TAA-1005  | Horizon provisioning failure - Due to outdated Helm install steps |
| TAA-1007  | Cloud WS - Workstation Image builds fail due to Helm Debian repo (OSS) migration |
| TAA-1040  | Remove references to private repo in Horizon files           |
| TAA-1045  | OSS Bitnami helm charts EOL       

***

## Horizon SDV - Release 2.0.1 (2025-09-24) 

### Summary
Hot fix release for Rel.2.0.1 with emergency fix for Helm repo endpoint issues, and minor documentation updates.

### New Features
N/A

### Improved Features
- New simplified Release Notes format.

### Bug Fixes

|  ID       | Summary                                                      |
|-----------|--------------------------------------------------------------|
| TAA-1002  | [Jenkins] Install ansicolor plugin for CWS                   |
| TAA-1005  | Horizon provisioning failure - Due to outdated Helm install steps |
| TAA-1007  | Cloud WS - Workstation Image builds fail due to Helm Debian repo (OSS) migration |
| TAA-1040  | Remove references to private repo in Horizon files           |
| TAA-1045  | OSS Bitnami helm charts EOL       

***
## Horizon SDV  - Release 2.0.0 (2025-09-01) 

### Summary
Horizon SDV 2.0.0 extends Android build capabilities with the integration of Google ABFS and introduces support for Android 15. This release also adds support for OpenBSW, the first non-Android automotive software platform in Horizon. Other major enhancements include Google Cloud Workstations with access to browser based IDEs Code-OSS, Android Studio (AS), and Android Studio for Platforms (ASfP). In addition, Horizon 2.0.0 delivers multiple feature improvements over Rel. 1.1.0 along with critical bug fixes.

### New Features

| ID       | Feature                           | Description                                                                                                                                                                                                                  |
|----------|----------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| TAA-8    | ABFS for Build Workloads          | The Horizon-SDV platform now integrates Google's Android Build Filesystem (ABFS), a filesystem and caching solution designed to accelerate AOSP source code checkouts and builds.                                           |
| TAA-9    | Cloud Workstation integration     | The Horizon-SDV platform now includes GCP Cloud Workstations, enabling users to launch pre-configured, and ready-to-use development environments directly in browser.                                                         |
| TAA-375  | Android 15 Support                | Horizon previously supported Android 15 in Horizon-SDV but by default Android 14 was selected. In this release, Android 15 android-15.0.0_r36 is now the default revision.                                                 |
| TAA-381  | Add OpenBSW build targets         | Eclipse Foundation OpenBSW Workload: As part of the R2.0.0 delivery, a new workload has been introduced to support the Eclipse Foundation OpenBSW within the Horizon SDV platform. This workload enables users to work on the OpenBSW stack for build and testing. |
| TAA-915  | Cloud Android Orchestration - Pt.1| In R2.0.0 Horizon platform introduces significant improvements to Cuttlefish Virtual Devices (CVD). These enhancements include increased support for a larger number of devices, optimized device startup processes, a more robust recovery mechanism, and updated CTS Test Plans and Modules to ensure seamless integration and compatibility with CVD. |
| TAA-623  | Management of Jenkins Jobs using CasC | The CasC configuration has been updated to include a single job in the jenkins.yaml file, automatically started on each Jenkins restart. This job provides the "Build with Parameters" option for users. |
| TAA-462  | Kubernetes Dashboard              | The Horizon platform now includes the Headlamp application, a web-based tool to browse Kubernetes resources and diagnose problems.                                                                                            |
| TAA-717  | Multiple pre-warmed disk pools    | Horizon is changing to persistent volume storage for build caches to improve build times, cost, and efficiency. Pools are separated by Android major version and Raspberry Vanilla targets now have their own smaller pools. |
| TAA-596  | Jenkins RBAC                      | Jenkins has been configured with RBAC capability using the Role-based Authorization Strategy plugin.                                                                                                                        |
| TAA-611  | Argo CD SSO                       | Argo CD has been configured with SSO capabilities. Users can login either with admin credentials or via Keycloak.                                                                                                           |
| TAA-837  | Access Control tool               | Additional Access Control functionality provides a Python script tool and classes for managing user and access control on GCP level.    

### Improved Features
N/A

### Bug Fixes

|  ID      | Summary |
|----------|---------|
| TAA-980  | Access control issue: Workstation User Operations succeed for non-owned workstations                             |
| TAA-984  | [Kaniko] Increase CPU resource limits                                                                            |
| TAA-982  | [ABFS] Uploaders not seeding new branch/tag correctly                                                            |
| TAA-981  | [ABFS] CASFS kernel module update required (6.8.0-1027-gke)                                                      |
| TAA-977  | New Cloud Workstation configuration is created successfully, but user details are not added to the configuration |
| TAA-974  | kube-state-metrics Service Account missing causes StatefulSet pod creation failure                               |
| TAA-968  | [IAA] Elektrobit patches remain in PV and break gerrit0                                                          |
| TAA-966  | [ABFS] Kaniko out of memory                                                                                      |
| TAA-953  | Android CF/CTS: update revisions                                                                                 |
| TAA-964  | [Gerrit] Propagate seed values                                                                                   |
| TAA-959  | Reduce number of GCE CF VMs on startup                                                                           |
| TAA-932  | ABFS_LICENSE_B64 not propagated to k8s secrets correctly                                                         |
| TAA-958  | [Gerrit] repo sync - ensure we reset local changes before fetch                                                  |
| TAA-781  | GitHub environment secrets do not update when Terraform workload is executed                                     |
| TAA-933  | Failure to access ABFS artifact repository                                                                       |
| TAA-905  | AAOS build does not work with ABFS                                                                               |
| TAA-931  | Create common storage script                                                                                     |
| TAA-930  | Investigate build issues when using MTK Connect as HOST                                                          |
| TAA-923  | Cuttlefish limited to 10 devices                                                                                 |
| TAA-921  | [Cuttlefish] Building android-cuttlefish failing on The GNU Operating System and the Free Software Movement      |
| TAA-922  | MTK Connect device creation assumes sequential adb ports                                                         |
| TAA-920  | Android Developer Build and Test instances leave MTK Connect testbenches in place when aborted                   |
| TAA-563  | [Jenkins] Replace gsutils with gcloud storage                                                                    |
| TAA-886  | Conflict Between Role Strategy Plugin and Authorize Project Plugin                                               |
| TAA-814  | Android RPi builds failing: requires MESON update                                                                |
| TAA-863  | Workloads Guide: updates for R2.0.0                                                                              |
| TAA-867  | Gerrit triggers plugin deprecated                                                                                |
| TAA-890  | Persistent Storage Audit: Internal tool removal                                                                  |
| TAA-618  | MTK Connect access control for Cuttlefish Devices                                                                |
| TAA-711  | [Qwiklabs][Jenkins] GCE limits - VM instances blocked                                                            |

***
## Horizon SDV - Release 1.1.0 (2025-04-14)   

### Summary
Minor improvements in Jenkins configuration, additional pipelines implemented for massive build cache pre-warming simplification required for Hackathon and Gerrit post jobs cleanup.

### New Features

| ID       | Feature                   | Description                                                                                   |
|----------|---------------------------|-----------------------------------------------------------------------------------------------|
| TAA-431  | Jenkins R1 deployment extensions | Jenkins extensions to Platform Foundation deployment in Rel.1.0.0. Includes new job to pre-warm build volumes. |
| TAA-346  | Support Pixel devices     | Support for Google Pixel tablet hardware, full integration with MTK Connect.                  |

### Improved Features
N/A

### Bug Fixes

|   ID     | Summary                                                                                  |
|----------|------------------------------------------------------------------------------------------|
| TAA-683  | Change MTK Connect application version to 1.8.0 in helm chart                            |
| TAA-644  | self-hosted runners                                                                      |
| TAA-641  | [Jenkins] Horizon Gerrit URL path breaks upstream Gerrit FETCH                           |
| TAA-639  | Keycloak Sign-in Failure: Non-Admin Users Stuck on Loading Screen                        |
| TAA-631  | MTK Connect license file in wrong location                                               |
| TAA-628  | [Jenkins] CF instance creation (connection loss)                                         |
| TAA-627  | [Jenkins][Dev] Investigate build nodes not scaling past 13                               |
| TAA-622  | Workloads documentation - wrong paths                                                    |
| TAA-615  | Improve the Gerrit post job                                                              |
| TAA-401  | [Jenkins] Agent losing connection to instance                                            |
| TAA-309  | [Jenkins] 'Build Now' post restart    

***
## Horizon SDV - Release 1.0.0 (2025-03-18)    

### Summary
The main objective for Release 1.0.0 is to achieve Minimal Viable Product level for Horizon SDV platform where orchestration will be done using Terraform on GCP with the intention of deploying the tooling on the platform using a simple provisioner. Horizon SDV platform in Rel.1.0.0 supports:

- GCP platform / services.
- Terraform orchestration (IaC).
- IaC stored in GitHub repo and provisioned either via CLI or GitHub actions.
- Platform supports Gerrit to host Android (AAOS) repos and manifests, and allows users to create their own repos.
    - With some pre-submit checks: e.g., voting labels: code review and manual vs automated triggered builds.
    - Will mirror and fork AAOSP manifests repo, and one additional code repo for demonstrating the SDV Tooling pipeline. Locally mirrored/forked manifest will be updated to point to the internally mirrored code repo, all other repos will remain using the external OSS AAOS repos hosted by Google.
- Platform supports Jenkins to allow for concurrent, multiple builds for iterative builds from changes in open review in Gerrit, full builds (manually, when user requests) and CTS testing.
- Platform supports an artefact registry to hold all build artefacts and test results.
- Platform supports a means to run CTS tests and use the Accenture MTK Connect solution for UI/UX testing.

### New Features

| ID       | Feature                   | Description                                                                                   |
|----------|---------------------------|-----------------------------------------------------------------------------------------------|
| TAA-6    | Platform foundation       | Platform foundation including support for: GCP, Terraform workflow, Stage 1 and Stage 2 deployment with ArgoCD, Jenkins Orchestration and Authentication support through Keycloak. |
| TAA-12   | Github Setup              | Github support for Horizon SDV platform repositories.                                         |
| TAA-67   | Tooling for tooling       | Android build pipelines support.                                                              |
| TAA-5    | Gerrit                    | Gerrit support.                                                                               |
| TAA-61   | MTK Connect               | Test connections to CVD with MTK Connect support.                                             |
| TAA-2    | Android Virtual Devices   | Pipelines for Android Virtual Devices CVD and AVD.                                            |

### Improved Features
N/A

### Bug Fixes

|   ID     | Summary                                                                                  |
|----------|------------------------------------------------------------------------------------------|
| TAA-608  | MTK Connect - testbench registration failing                                             |
| TAA-593  | [Jenkins] Jenkins config auto reload affecting builds                                    |
| TAA-590  | [Jenkins] CTS_DOWNLOAD_URL : strip trailing slashes                                      |
| TAA-589  | [Jenkins] computeEngine: cuttlefish-vm-v110 points to incorrect instance template        |
| TAA-577  | [Jenkins] CF CVD launcher fails to boot devices                                          |
| TAA-562  | [Jenkins] Warnings from pipeline (Pipeline Groovy)                                       |
| TAA-532  | [Jenkins] Stage View bug (display pipeline)                                              |
| TAA-530  | [Jenkins] Regression: Exceptions raised on connection/instance loss                      |
| TAA-528  | [MTK Connect] node warnings: MaxListenersExceededWarning                                 |
| TAA-520  | [Jenkins] Reinstate cuttlefish-vm termination                                            |
| TAA-519  | TAA-518[Jenkins] Reinstate MTKC Test bench deletion env pipeline                         |
| TAA-518  | [Jenkins] Reinstate MTKC Test bench deletion env pipeline                                |
| TAA-518  | [Jenkins] CVD / CTS - hudson exceptions reported and jobs fail                           |
| TAA-516  | [Jenkins] Make test jobs more defensive + improvements                                   |
| TAA-508  | [MTK Connect] Not terminating                                                            |
| TAA-507  | [Jenkins] CVD/CTS test run: times out on android-14.0.0_r74                              |
| TAA-502  | Re-apply pull-request trigger to GitHub workflows                                        |
| TAA-501  | Invent a solution for restricting GitHub workflows to a given branch                     |
| TAA-498  | Gerrit-admin password is not created in Keycloak                                         |
| TAA-496  | [Android Studio] Arm builds throw an error due to config                                 |
| TAA-490  | [RPi] RPi4 again broken                                                                  |
| TAA-478  | [Jenkins] CLEAN_ALL: rsync errors                                                        |
| TAA-477  | [Gerrit] Branch name revision incorrect for 15 - build failures                          |
| TAA-425  | [Jenkins] Native Linux install of MTKC fails (unattended-upgr)                           |
| TAA-412  | [Jenkins] Russian Roulette with cache instance causing build failures                    |
| TAA-400  | [Jenkins] SSH issues                                                                     |
| TAA-398  | [Jenkins] GCE plugin losing connection with VM instance                                  |
| TAA-394  | [Gerrit] Admin password stored in secrets with newline                                   |
| TAA-354  | [Jenkins] CVD adb devices not always working as expected                                 |

***
