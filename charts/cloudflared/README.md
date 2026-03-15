<!--- app-name: cloudflared -->

# cloudflared

A Helm chart for [Cloudflare Tunnel (cloudflared)](https://github.com/cloudflare/cloudflared), a lightweight daemon that creates outbound-only encrypted tunnels from your Kubernetes cluster to the Cloudflare network so you can expose services without opening inbound firewall ports.

## TL;DR

```console
helm install my-release oci://ghcr.io/hlhc/charts/cloudflared
```

## Introduction

This chart bootstraps cloudflared as a Deployment (default) or a [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/) on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.21+
- Helm 3.8.0+
- A [Cloudflare account](https://www.cloudflare.com) with at least one zone
- A locally managed Cloudflare Tunnel credential (`cert.pem` and tunnel credentials JSON). See [Create a local managed tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/do-more-with-tunnels/local-management/create-local-tunnel/)

## Installing the Chart

To install the chart with the release name my-release:

```console
helm install my-release oci://REGISTRY_NAME/REPOSITORY_NAME/cloudflared
```

> Note: You need to substitute the placeholders REGISTRY_NAME and REPOSITORY_NAME with a reference to your Helm chart registry and repository. For example, for this chart use REGISTRY_NAME=ghcr.io and REPOSITORY_NAME=hlhc/charts.

The command deploys cloudflared on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

### Tunnel credentials

Create a Secret containing your tunnel certificate and credentials JSON:

```console
kubectl create secret generic cloudflared-tunnel \
  --from-file=cert.pem="${HOME}/.cloudflared/cert.pem" \
  --from-file=credentials.json="${HOME}/.cloudflared/<TUNNEL_ID>.json"
```

Then install the chart and reference that Secret:

```console
helm install my-release oci://ghcr.io/hlhc/charts/cloudflared \
  --set cloudflared.tunnelConfig.name=my-tunnel \
  --set cloudflared.tunnelSecrets.existingConfigJsonFileSecret.name=cloudflared-tunnel \
  --set cloudflared.tunnelSecrets.existingPemFileSecret.name=cloudflared-tunnel
```

You can also provide base64-encoded values directly (the chart creates the Secret):

```console
helm install my-release oci://ghcr.io/hlhc/charts/cloudflared \
  --set cloudflared.tunnelConfig.name=my-tunnel \
  --set cloudflared.tunnelSecrets.base64EncodedPemFile="$(base64 -w0 ~/.cloudflared/cert.pem)" \
  --set cloudflared.tunnelSecrets.base64EncodedConfigJsonFile="$(base64 -w0 ~/.cloudflared/*.json)"
```

### Routing traffic

Define ingress routing rules with cloudflared.routes. The final rule must be a catch-all.

```yaml
cloudflared:
  tunnelConfig:
    name: my-tunnel
  routes:
    - hostname: app.example.com
      service: http://my-app.default.svc.cluster.local:80
    - hostname: "*.example.com"
      service: http://traefik.kube-system.svc.cluster.local:80
    - service: http_status:404
```

### DaemonSet vs Deployment

By default, the chart uses a Deployment. If you want one pod per node, switch to DaemonSet:

```console
helm install my-release oci://ghcr.io/hlhc/charts/cloudflared \
  --set cloudflared.kind=DaemonSet
```

### Additional environment variables

Use cloudflared.extraEnvVars to add extra environment variables:

```yaml
cloudflared:
  extraEnvVars:
    - name: TUNNEL_LOGLEVEL
      value: debug
```

You can also reference an existing ConfigMap or Secret using cloudflared.extraEnvVarsCM or cloudflared.extraEnvVarsSecret.

### Sidecars and init containers

If you need extra containers in the same pod, use cloudflared.sidecars and cloudflared.initContainers:

```yaml
cloudflared:
  sidecars:
    - name: log-shipper
      image: fluent/fluent-bit:latest
      ports:
        - name: http
          containerPort: 2020

  initContainers:
    - name: wait-for-dns
      image: busybox
      command: ["sh", "-c", "until nslookup cloudflare.com; do sleep 2; done"]
```

Learn more about [sidecar containers](https://kubernetes.io/docs/concepts/workloads/pods/) and [init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/).

### Pod affinity

This chart allows custom affinity with cloudflared.affinity, or preset affinity settings with cloudflared.podAffinityPreset, cloudflared.podAntiAffinityPreset, and cloudflared.nodeAffinityPreset.

## Upgrading

```console
helm upgrade my-release oci://ghcr.io/hlhc/charts/cloudflared
```

## Uninstalling the Chart

```console
helm uninstall my-release
```

## Parameters

### Global parameters

| Name                                                  | Description                                                                                                                                                                                                                                                                                                                                                         | Value   |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `global.imageRegistry`                                | Global Docker image registry                                                                                                                                                                                                                                                                                                                                        | `""`    |
| `global.imagePullSecrets`                             | Global Docker registry secret names as an array                                                                                                                                                                                                                                                                                                                     | `[]`    |
| `global.security.allowInsecureImages`                 | Allows skipping image verification                                                                                                                                                                                                                                                                                                                                  | `false` |
| `global.compatibility.openshift.adaptSecurityContext` | Adapt the securityContext sections of the deployment to make them compatible with Openshift restricted-v2 SCC: remove runAsUser, runAsGroup and fsGroup and let the platform use their allowed default IDs. Possible values: auto (apply if the detected running cluster is Openshift), force (perform the adaptation always), disabled (do not perform adaptation) | `auto`  |
| `global.compatibility.omitEmptySeLinuxOptions`        | If set to true, removes the seLinuxOptions from the securityContexts when it is set to an empty object                                                                                                                                                                                                                                                              | `false` |

### Common parameters

| Name                     | Description                                                                             | Value           |
| ------------------------ | --------------------------------------------------------------------------------------- | --------------- |
| `kubeVersion`            | Override Kubernetes version reported by .Capabilities                                   | `""`            |
| `apiVersions`            | Override Kubernetes API versions reported by .Capabilities                              | `[]`            |
| `nameOverride`           | String to partially override common.names.name                                          | `""`            |
| `fullnameOverride`       | String to fully override common.names.fullname                                          | `""`            |
| `namespaceOverride`      | String to fully override common.names.namespace                                         | `""`            |
| `commonLabels`           | Labels to add to all deployed objects                                                   | `{}`            |
| `commonAnnotations`      | Annotations to add to all deployed objects                                              | `{}`            |
| `clusterDomain`          | Kubernetes cluster domain name                                                          | `cluster.local` |
| `extraDeploy`            | Array of extra objects to deploy with the release                                       | `[]`            |
| `diagnosticMode.enabled` | Enable diagnostic mode (all probes will be disabled and the command will be overridden) | `false`         |
| `diagnosticMode.command` | Command to override all containers in the chart release                                 | `["sleep"]`     |
| `diagnosticMode.args`    | Args to override all containers in the chart release                                    | `["infinity"]`  |

### cloudflared Parameters

| Name                                                            | Description                                                                                                                                                                                                                                           | Value                    |
| --------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------ |
| `cloudflared.image.registry`                                    | cloudflared image registry                                                                                                                                                                                                                            | `docker.io`              |
| `cloudflared.image.repository`                                  | cloudflared image repository                                                                                                                                                                                                                          | `cloudflare/cloudflared` |
| `cloudflared.image.digest`                                      | cloudflared image digest in the way sha256:aa.... Please note this parameter, if set, will override the tag                                                                                                                                           | `""`                     |
| `cloudflared.image.pullPolicy`                                  | cloudflared image pull policy                                                                                                                                                                                                                         | `IfNotPresent`           |
| `cloudflared.image.pullSecrets`                                 | cloudflared image pull secrets                                                                                                                                                                                                                        | `[]`                     |
| `cloudflared.image.debug`                                       | Enable cloudflared image debug mode                                                                                                                                                                                                                   | `false`                  |
| `cloudflared.kind`                                              | Workload type: DaemonSet (deploy to all nodes) or Deployment                                                                                                                                                                                          | `Deployment`             |
| `cloudflared.replicaCount`                                      | Number of cloudflared replicas to deploy (only used when kind=Deployment)                                                                                                                                                                             | `1`                      |
| `cloudflared.containerPorts.metrics`                            | cloudflared metrics/health container port                                                                                                                                                                                                             | `2000`                   |
| `cloudflared.extraContainerPorts`                               | Optionally specify extra list of additional ports for cloudflared containers                                                                                                                                                                          | `[]`                     |
| `cloudflared.livenessProbe.enabled`                             | Enable livenessProbe on cloudflared containers                                                                                                                                                                                                        | `true`                   |
| `cloudflared.livenessProbe.httpGet.path`                        | Path for livenessProbe                                                                                                                                                                                                                                | `/ready`                 |
| `cloudflared.livenessProbe.httpGet.port`                        | Port for livenessProbe                                                                                                                                                                                                                                | `2000`                   |
| `cloudflared.livenessProbe.initialDelaySeconds`                 | Initial delay seconds for livenessProbe                                                                                                                                                                                                               | `10`                     |
| `cloudflared.livenessProbe.periodSeconds`                       | Period seconds for livenessProbe                                                                                                                                                                                                                      | `10`                     |
| `cloudflared.livenessProbe.timeoutSeconds`                      | Timeout seconds for livenessProbe                                                                                                                                                                                                                     | `5`                      |
| `cloudflared.livenessProbe.failureThreshold`                    | Failure threshold for livenessProbe                                                                                                                                                                                                                   | `1`                      |
| `cloudflared.livenessProbe.successThreshold`                    | Success threshold for livenessProbe                                                                                                                                                                                                                   | `1`                      |
| `cloudflared.readinessProbe.enabled`                            | Enable readinessProbe on cloudflared containers                                                                                                                                                                                                       | `true`                   |
| `cloudflared.readinessProbe.httpGet.path`                       | Path for readinessProbe                                                                                                                                                                                                                               | `/ready`                 |
| `cloudflared.readinessProbe.httpGet.port`                       | Port for readinessProbe                                                                                                                                                                                                                               | `2000`                   |
| `cloudflared.readinessProbe.initialDelaySeconds`                | Initial delay seconds for readinessProbe                                                                                                                                                                                                              | `10`                     |
| `cloudflared.readinessProbe.periodSeconds`                      | Period seconds for readinessProbe                                                                                                                                                                                                                     | `10`                     |
| `cloudflared.readinessProbe.timeoutSeconds`                     | Timeout seconds for readinessProbe                                                                                                                                                                                                                    | `5`                      |
| `cloudflared.readinessProbe.failureThreshold`                   | Failure threshold for readinessProbe                                                                                                                                                                                                                  | `3`                      |
| `cloudflared.readinessProbe.successThreshold`                   | Success threshold for readinessProbe                                                                                                                                                                                                                  | `1`                      |
| `cloudflared.startupProbe.enabled`                              | Enable startupProbe on cloudflared containers                                                                                                                                                                                                         | `false`                  |
| `cloudflared.startupProbe.httpGet.path`                         | Path for startupProbe                                                                                                                                                                                                                                 | `/ready`                 |
| `cloudflared.startupProbe.httpGet.port`                         | Port for startupProbe                                                                                                                                                                                                                                 | `2000`                   |
| `cloudflared.startupProbe.initialDelaySeconds`                  | Initial delay seconds for startupProbe                                                                                                                                                                                                                | `10`                     |
| `cloudflared.startupProbe.periodSeconds`                        | Period seconds for startupProbe                                                                                                                                                                                                                       | `10`                     |
| `cloudflared.startupProbe.timeoutSeconds`                       | Timeout seconds for startupProbe                                                                                                                                                                                                                      | `5`                      |
| `cloudflared.startupProbe.failureThreshold`                     | Failure threshold for startupProbe                                                                                                                                                                                                                    | `3`                      |
| `cloudflared.startupProbe.successThreshold`                     | Success threshold for startupProbe                                                                                                                                                                                                                    | `1`                      |
| `cloudflared.customLivenessProbe`                               | Custom livenessProbe that overrides the default one                                                                                                                                                                                                   | `{}`                     |
| `cloudflared.customReadinessProbe`                              | Custom readinessProbe that overrides the default one                                                                                                                                                                                                  | `{}`                     |
| `cloudflared.customStartupProbe`                                | Custom startupProbe that overrides the default one                                                                                                                                                                                                    | `{}`                     |
| `cloudflared.resourcesPreset`                                   | Set cloudflared container resources according to one common preset (allowed values: none, nano, micro, small, medium, large, xlarge, 2xlarge). This is ignored if cloudflared.resources is set (cloudflared.resources is recommended for production). | `nano`                   |
| `cloudflared.resources`                                         | Set cloudflared container requests and limits for different resources like CPU or memory (essential for production workloads)                                                                                                                         | `{}`                     |
| `cloudflared.podSecurityContext.enabled`                        | Enable cloudflared pods' Security Context                                                                                                                                                                                                             | `true`                   |
| `cloudflared.podSecurityContext.fsGroupChangePolicy`            | Set filesystem group change policy for cloudflared pods                                                                                                                                                                                               | `OnRootMismatch`         |
| `cloudflared.podSecurityContext.sysctls`                        | Set kernel settings using the sysctl interface for cloudflared pods                                                                                                                                                                                   | `[]`                     |
| `cloudflared.podSecurityContext.supplementalGroups`             | Set filesystem extra groups for cloudflared pods                                                                                                                                                                                                      | `[]`                     |
| `cloudflared.podSecurityContext.fsGroup`                        | Set fsGroup in cloudflared pods' Security Context                                                                                                                                                                                                     | `65532`                  |
| `cloudflared.containerSecurityContext.enabled`                  | Enabled cloudflared container' Security Context                                                                                                                                                                                                       | `true`                   |
| `cloudflared.containerSecurityContext.seLinuxOptions`           | Set SELinux options in cloudflared container                                                                                                                                                                                                          | `{}`                     |
| `cloudflared.containerSecurityContext.runAsUser`                | Set runAsUser in cloudflared container' Security Context                                                                                                                                                                                              | `65532`                  |
| `cloudflared.containerSecurityContext.runAsGroup`               | Set runAsGroup in cloudflared container' Security Context                                                                                                                                                                                             | `65532`                  |
| `cloudflared.containerSecurityContext.runAsNonRoot`             | Set runAsNonRoot in cloudflared container' Security Context                                                                                                                                                                                           | `true`                   |
| `cloudflared.containerSecurityContext.readOnlyRootFilesystem`   | Set readOnlyRootFilesystem in cloudflared container' Security Context                                                                                                                                                                                 | `true`                   |
| `cloudflared.containerSecurityContext.privileged`               | Set privileged in cloudflared container' Security Context                                                                                                                                                                                             | `false`                  |
| `cloudflared.containerSecurityContext.allowPrivilegeEscalation` | Set allowPrivilegeEscalation in cloudflared container' Security Context                                                                                                                                                                               | `false`                  |
| `cloudflared.containerSecurityContext.capabilities.drop`        | List of capabilities to be dropped in cloudflared container                                                                                                                                                                                           | `["ALL"]`                |
| `cloudflared.containerSecurityContext.seccompProfile.type`      | Set seccomp profile in cloudflared container                                                                                                                                                                                                          | `RuntimeDefault`         |
| `cloudflared.tunnelSecrets.base64EncodedPemFile`                | Base64 encoded tunnel certificate PEM file                                                                                                                                                                                                            | `""`                     |
| `cloudflared.tunnelSecrets.base64EncodedConfigJsonFile`         | Base64 encoded tunnel credentials JSON file                                                                                                                                                                                                           | `""`                     |
| `cloudflared.tunnelSecrets.existingPemFileSecret.name`          | Name of an existing secret containing the tunnel certificate PEM file. If set, base64EncodedPemFile is ignored.                                                                                                                                       | `""`                     |
| `cloudflared.tunnelSecrets.existingPemFileSecret.key`           | Key of the certificate PEM file in the existing secret                                                                                                                                                                                                | `cert.pem`               |
| `cloudflared.tunnelSecrets.existingConfigJsonFileSecret.name`   | Name of an existing secret containing the tunnel credentials JSON file. If set, base64EncodedConfigJsonFile is ignored.                                                                                                                               | `""`                     |
| `cloudflared.tunnelSecrets.existingConfigJsonFileSecret.key`    | Key of the credentials JSON file in the existing secret                                                                                                                                                                                               | `credentials.json`       |
| `cloudflared.tunnelConfig.name`                                 | Cloudflare tunnel name (required)                                                                                                                                                                                                                     | `""`                     |
| `cloudflared.tunnelConfig.metricsUpdateFrequency`               | Frequency to update tunnel metrics                                                                                                                                                                                                                    | `5s`                     |
| `cloudflared.tunnelConfig.autoUpdateFrequency`                  | Frequency to check for cloudflared updates                                                                                                                                                                                                            | `24h`                    |
| `cloudflared.tunnelConfig.noAutoUpdate`                         | Disable auto-update of cloudflared binary                                                                                                                                                                                                             | `true`                   |
| `cloudflared.tunnelConfig.gracePeriod`                          | Grace period before tunnel shutdown                                                                                                                                                                                                                   | `30s`                    |
| `cloudflared.tunnelConfig.retries`                              | Number of retries for cloudflared connections                                                                                                                                                                                                         | `5`                      |
| `cloudflared.tunnelConfig.protocol`                             | Tunnel protocol (auto, http2, h2mux, quic)                                                                                                                                                                                                            | `auto`                   |
| `cloudflared.tunnelConfig.logLevel`                             | Tunnel log level (info, warn, error, fatal, panic)                                                                                                                                                                                                    | `info`                   |
| `cloudflared.tunnelConfig.transportLogLevel`                    | Tunnel transport log level (info, warn, error, fatal, panic)                                                                                                                                                                                          | `warn`                   |
| `cloudflared.tunnelConfig.connectTimeout`                       | Timeout for establishing new connections                                                                                                                                                                                                              | `30s`                    |
| `cloudflared.tunnelConfig.warpRouting`                          | Enable warp routing                                                                                                                                                                                                                                   | `false`                  |
| `cloudflared.routes`                                            | Cloudflare tunnel ingress routing rules                                                                                                                                                                                                               | `[]`                     |
| `cloudflared.existingConfigmap`                                 | Name of an existing ConfigMap with the cloudflared config. If set, the configmap.yaml template is skipped.                                                                                                                                            | `""`                     |
| `cloudflared.command`                                           | Override default cloudflared container command (useful when using custom images)                                                                                                                                                                      | `[]`                     |
| `cloudflared.args`                                              | Override default cloudflared container args (useful when using custom images)                                                                                                                                                                         | `[]`                     |
| `cloudflared.automountServiceAccountToken`                      | Mount Service Account token in cloudflared pods                                                                                                                                                                                                       | `false`                  |
| `cloudflared.hostAliases`                                       | cloudflared pods host aliases                                                                                                                                                                                                                         | `[]`                     |
| `cloudflared.daemonsetAnnotations`                              | Annotations for cloudflared DaemonSet                                                                                                                                                                                                                 | `{}`                     |
| `cloudflared.deploymentAnnotations`                             | Annotations for cloudflared Deployment                                                                                                                                                                                                                | `{}`                     |
| `cloudflared.podLabels`                                         | Extra labels for cloudflared pods                                                                                                                                                                                                                     | `{}`                     |
| `cloudflared.podAnnotations`                                    | Annotations for cloudflared pods                                                                                                                                                                                                                      | `{}`                     |
| `cloudflared.podAffinityPreset`                                 | Pod affinity preset. Ignored if `cloudflared.affinity` is set. Allowed values: `soft` or `hard`                                                                                                                                                       | `""`                     |
| `cloudflared.podAntiAffinityPreset`                             | Pod anti-affinity preset. Ignored if `cloudflared.affinity` is set. Allowed values: `soft` or `hard`                                                                                                                                                  | `soft`                   |
| `cloudflared.nodeAffinityPreset.type`                           | Node affinity preset type. Ignored if `cloudflared.affinity` is set. Allowed values: `soft` or `hard`                                                                                                                                                 | `""`                     |
| `cloudflared.nodeAffinityPreset.key`                            | Node label key to match. Ignored if `cloudflared.affinity` is set                                                                                                                                                                                     | `""`                     |
| `cloudflared.nodeAffinityPreset.values`                         | Node label values to match. Ignored if `cloudflared.affinity` is set                                                                                                                                                                                  | `[]`                     |
| `cloudflared.affinity`                                          | Affinity for cloudflared pods assignment                                                                                                                                                                                                              | `{}`                     |
| `cloudflared.nodeSelector`                                      | Node labels for cloudflared pods assignment                                                                                                                                                                                                           | `{}`                     |
| `cloudflared.tolerations`                                       | Tolerations for cloudflared pods assignment                                                                                                                                                                                                           | `[]`                     |
| `cloudflared.updateStrategy.type`                               | cloudflared deployment/daemonset strategy type                                                                                                                                                                                                        | `RollingUpdate`          |
| `cloudflared.priorityClassName`                                 | cloudflared pods' priorityClassName                                                                                                                                                                                                                   | `""`                     |
| `cloudflared.topologySpreadConstraints`                         | Topology Spread Constraints for cloudflared pod assignment spread across your cluster among failure-domains                                                                                                                                           | `[]`                     |
| `cloudflared.schedulerName`                                     | Name of the k8s scheduler (other than default) for cloudflared pods                                                                                                                                                                                   | `""`                     |
| `cloudflared.terminationGracePeriodSeconds`                     | Seconds cloudflared pods need to terminate gracefully                                                                                                                                                                                                 | `30`                     |
| `cloudflared.lifecycleHooks`                                    | for cloudflared containers to automate configuration before or after startup                                                                                                                                                                          | `{}`                     |
| `cloudflared.extraEnvVars`                                      | Array with extra environment variables to add to cloudflared containers                                                                                                                                                                               | `[]`                     |
| `cloudflared.extraEnvVarsCM`                                    | Name of existing ConfigMap containing extra env vars for cloudflared containers                                                                                                                                                                       | `""`                     |
| `cloudflared.extraEnvVarsSecret`                                | Name of existing Secret containing extra env vars for cloudflared containers                                                                                                                                                                          | `""`                     |
| `cloudflared.extraVolumes`                                      | Optionally specify extra list of additional volumes for the cloudflared pods                                                                                                                                                                          | `[]`                     |
| `cloudflared.extraVolumeMounts`                                 | Optionally specify extra list of additional volumeMounts for the cloudflared containers                                                                                                                                                               | `[]`                     |
| `cloudflared.sidecars`                                          | Add additional sidecar containers to the cloudflared pods                                                                                                                                                                                             | `[]`                     |
| `cloudflared.initContainers`                                    | Add additional init containers to the cloudflared pods                                                                                                                                                                                                | `[]`                     |
| `cloudflared.pdb.create`                                        | Enable/disable a Pod Disruption Budget creation                                                                                                                                                                                                       | `true`                   |
| `cloudflared.pdb.minAvailable`                                  | Minimum number/percentage of pods that should remain scheduled                                                                                                                                                                                        | `""`                     |
| `cloudflared.pdb.maxUnavailable`                                | Maximum number/percentage of pods that may be made unavailable. Defaults to `1` if both `cloudflared.pdb.minAvailable` and `cloudflared.pdb.maxUnavailable` are empty.                                                                                | `""`                     |

### ServiceAccount parameters

| Name                                          | Description                                                                                                            | Value   |
| --------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- | ------- |
| `serviceAccount.create`                       | Specifies whether a ServiceAccount should be created                                                                   | `true`  |
| `serviceAccount.name`                         | The name of the ServiceAccount to use. If not set and create is true, a name is generated using the fullname template. | `""`    |
| `serviceAccount.annotations`                  | Additional Service Account annotations (evaluated as a template)                                                       | `{}`    |
| `serviceAccount.automountServiceAccountToken` | Automount ServiceAccount token                                                                                         | `false` |

See <https://github.com/bitnami/readme-generator-for-helm> to regenerate this section from values.yaml and values.schema.json.

Specify each parameter using the --set key=value[,key=value] argument to helm install. For example:

```console
helm install my-release \
  --set cloudflared.tunnelConfig.name=my-tunnel \
  --set cloudflared.tunnelSecrets.existingConfigJsonFileSecret.name=cloudflared-tunnel \
  --set cloudflared.tunnelSecrets.existingPemFileSecret.name=cloudflared-tunnel \
  oci://REGISTRY_NAME/REPOSITORY_NAME/cloudflared
```

> Note: You need to substitute the placeholders REGISTRY_NAME and REPOSITORY_NAME with a reference to your Helm chart registry and repository. For example, for this chart use REGISTRY_NAME=ghcr.io and REPOSITORY_NAME=hlhc/charts.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing:

```console
helm install my-release -f values.yaml oci://REGISTRY_NAME/REPOSITORY_NAME/cloudflared
```

## Troubleshooting

### Tunnel not connecting

```console
kubectl logs -l app.kubernetes.io/name=cloudflared --tail=100
```

Check that cloudflared.tunnelConfig.name matches the tunnel name in your credentials JSON, and verify the Secret keys are correct.

### Metrics endpoint

cloudflared exposes a Prometheus-compatible metrics endpoint on cloudflared.containerPorts.metrics (default 2000):

```console
kubectl port-forward daemonset/my-release-cloudflared 2000:2000
curl http://localhost:2000/metrics
```

## License

Copyright &copy; 2026 Cyrus Ho.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
