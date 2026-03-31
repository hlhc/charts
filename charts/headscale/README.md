<!--- app-name: headscale -->

# headscale

A Helm chart for [headscale](https://headscale.net), an open source, self-hosted implementation of the Tailscale control server, with optional [headplane](https://github.com/tale/headplane) web UI.

## Versioning policy

> [!WARNING]
> All chart versions in the `0.x.x` range are unstable.
> Breaking changes may happen in any `0.x.x` release, including minor and patch updates.
> Pin an exact version in production and test upgrades before rollout.

## TL;DR

```console
helm install my-release oci://ghcr.io/hlhc/charts/headscale
```

## Introduction

This chart bootstraps headscale as a StatefulSet on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager. It optionally deploys [headplane](https://github.com/tale/headplane) — a web UI for managing headscale — as a second StatefulSet in the same release.

## Prerequisites

- Kubernetes 1.21+
- Helm 3.8.0+

## Installing the Chart

To install the chart with the release name my-release:

```console
helm install my-release oci://REGISTRY_NAME/REPOSITORY_NAME/headscale
```

> Note: You need to substitute the placeholders REGISTRY_NAME and REPOSITORY_NAME with a reference to your Helm chart registry and repository. For example, for this chart use REGISTRY_NAME=ghcr.io and REPOSITORY_NAME=hlhc/charts.

The command deploys headscale on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

### Server URL

headscale requires a public server URL. Set it at install time:

```console
helm install my-release oci://ghcr.io/hlhc/charts/headscale \
  --set headscale.config.serverUrl=https://headscale.example.com
```

### OIDC authentication

Enable OIDC by providing the provider settings and a client secret:

```yaml
headscale:
  config:
    serverUrl: https://headscale.example.com
  oidc:
    enabled: true
    issuer: https://auth.example.com
    clientId: headscale
    clientSecret: my-secret
```

Or reference an existing Secret containing the `client_secret` key:

```yaml
headscale:
  oidc:
    enabled: true
    issuer: https://auth.example.com
    clientId: headscale
    existingSecret: my-oidc-secret
```

### Exposing headscale

Use a standard Ingress:

```yaml
ingress:
  enabled: true
  hostname: headscale.example.com
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  tls: true
```

Or a Gateway API HTTPRoute:

```yaml
route:
  main:
    parentRefs:
      - name: my-gateway
        namespace: kube-system
    hostnames:
      - headscale.example.com
```

### Additional environment variables

Use headscale.extraEnvVars to add extra environment variables:

```yaml
headscale:
  extraEnvVars:
    - name: HEADSCALE_LOG_LEVEL
      value: debug
```

You can also reference an existing ConfigMap or Secret using headscale.extraEnvVarsCM or headscale.extraEnvVarsSecret.

### Sidecars and init containers

If you need extra containers in the same pod, use headscale.sidecars and headscale.initContainers:

```yaml
headscale:
  sidecars:
    - name: debug-shell
      image: busybox
      command: ["sleep", "infinity"]

  initContainers:
    - name: wait-for-db
      image: busybox
      command: ["sh", "-c", "until test -d /var/lib/headscale; do sleep 1; done"]
```

Learn more about [sidecar containers](https://kubernetes.io/docs/concepts/workloads/pods/) and [init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/).

### Pod affinity

This chart allows custom affinity with headscale.affinity, or preset affinity settings with headscale.podAffinityPreset, headscale.podAntiAffinityPreset, and headscale.nodeAffinityPreset.

## headplane

[headplane](https://github.com/tale/headplane) is a web UI for managing headscale. When enabled it runs as a separate StatefulSet and shares the same ingress/HTTPRoute as headscale, with headscale traffic routed to `/` and headplane traffic to `/admin` (configurable via `headplane.adminPath`).

### Enabling headplane

```yaml
headscale:
  config:
    serverUrl: https://headscale.example.com

headplane:
  enabled: true
  config:
    headscale:
      url: https://headscale.example.com

ingress:
  enabled: true
  hostname: headscale.example.com
  tls: true
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
```

This exposes:
- `https://headscale.example.com/` → headscale API
- `https://headscale.example.com/admin` → headplane UI

### headplane API key

headplane needs a headscale API key to manage the server. Provide it directly or reference an existing Secret:

```yaml
headplane:
  enabled: true
  apiKey:
    value: my-api-key
```

Or use an existing Secret with the key `HEADPLANE_OIDC__HEADSCALE_API_KEY`:

```yaml
headplane:
  enabled: true
  apiKey:
    existingSecret: my-headplane-api-key-secret
```

### headplane cookie secret

By default a random 32-character cookie secret is generated on each `helm upgrade`, which invalidates all active headplane sessions. Set `headplane.cookieSecret` explicitly to preserve sessions across upgrades:

```yaml
headplane:
  cookieSecret: a-stable-32-character-secret-here
```

### headplane OIDC

headplane supports OIDC for user authentication. Supply provider credentials via an existing Secret:

```yaml
headplane:
  oidc:
    enabled: true
    issuer: https://auth.example.com
    client_id: headplane
    redirect_uri: https://headscale.example.com/admin/oidc/callback
    existingSecret: my-oidc-secret  # must contain OIDC client_secret env var
    disable_api_key_login: true
```

### Routing headplane with Gateway API

```yaml
headplane:
  enabled: true
  adminPath: /admin

route:
  main:
    enabled: true
    parentRefs:
      - name: my-gateway
        namespace: kube-system
    hostnames:
      - headscale.example.com
```

The HTTPRoute will include two rules: `/` → headscale and `/admin` → headplane.

## Upgrading

```console
helm upgrade my-release oci://ghcr.io/hlhc/charts/headscale
```

## Uninstalling the Chart

```console
helm uninstall my-release
```

## Parameters

### Global parameters

| Name                                                  | Description                                                                                                   | Value   |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- | ------- |
| `global.imageRegistry`                                | Global Docker Image registry                                                                                  | `""`    |
| `global.imagePullSecrets`                             | Global Docker registry secret names as an array                                                               | `[]`    |
| `global.defaultStorageClass`                          | Global default StorageClass for Persistent Volume(s)                                                          | `""`    |
| `global.security.allowInsecureImages`                 | Allows skipping image verification                                                                            | `false` |
| `global.compatibility.openshift.adaptSecurityContext` | Adapt the securityContext sections of the deployment to make them compatible with Openshift restricted-v2 SCC | `auto`  |
| `global.compatibility.omitEmptySeLinuxOptions`        | If set to true, removes the seLinuxOptions from the securityContexts when it is set to an empty object        | `false` |

### Common parameters

| Name                     | Description                                                      | Value           |
| ------------------------ | ---------------------------------------------------------------- | --------------- |
| `kubeVersion`            | Override Kubernetes version reported by .Capabilities            | `""`            |
| `apiVersions`            | Override Kubernetes API versions reported by .Capabilities       | `[]`            |
| `nameOverride`           | String to partially override common.names.name                   | `""`            |
| `fullnameOverride`       | String to fully override common.names.fullname                   | `""`            |
| `namespaceOverride`      | String to fully override common.names.namespace                  | `""`            |
| `commonLabels`           | Labels to add to all deployed objects                            | `{}`            |
| `commonAnnotations`      | Annotations to add to all deployed objects                       | `{}`            |
| `clusterDomain`          | Kubernetes cluster domain name                                   | `cluster.local` |
| `extraDeploy`            | Array of extra objects to deploy with the release                | `[]`            |
| `diagnosticMode.enabled` | Enable diagnostic mode (all probes disabled, command overridden) | `false`         |
| `diagnosticMode.command` | Command to override all containers in the chart release          | `["sleep"]`     |
| `diagnosticMode.args`    | Args to override all containers in the chart release             | `["infinity"]`  |

### Headscale Parameters

| Name                                                              | Description                                                                                                                                                                                                                                     | Value                                                    |
| ----------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| `headscale.image.registry`                                        | headscale image registry                                                                                                                                                                                                                        | `ghcr.io`                                                |
| `headscale.image.repository`                                      | headscale image repository                                                                                                                                                                                                                      | `juanfont/headscale`                                     |
| `headscale.image.digest`                                          | headscale image digest in the way sha256:aa.... Please note this parameter, if set, will override the tag                                                                                                                                       | `""`                                                     |
| `headscale.image.pullPolicy`                                      | headscale image pull policy                                                                                                                                                                                                                     | `IfNotPresent`                                           |
| `headscale.image.pullSecrets`                                     | headscale image pull secrets                                                                                                                                                                                                                    | `[]`                                                     |
| `headscale.image.debug`                                           | Enable headscale image debug mode                                                                                                                                                                                                               | `false`                                                  |
| `headscale.replicaCount`                                          | Number of headscale replicas to deploy                                                                                                                                                                                                          | `1`                                                      |
| `headscale.containerPorts.http`                                   | headscale HTTP container port                                                                                                                                                                                                                   | `8080`                                                   |
| `headscale.containerPorts.grpc`                                   | headscale gRPC container port                                                                                                                                                                                                                   | `50443`                                                  |
| `headscale.containerPorts.metrics`                                | headscale metrics container port                                                                                                                                                                                                                | `9090`                                                   |
| `headscale.extraContainerPorts`                                   | Optionally specify extra list of additional ports for headscale containers                                                                                                                                                                      | `[]`                                                     |
| `headscale.livenessProbe.enabled`                                 | Enable livenessProbe on headscale containers                                                                                                                                                                                                    | `true`                                                   |
| `headscale.livenessProbe.initialDelaySeconds`                     | Initial delay seconds for livenessProbe                                                                                                                                                                                                         | `10`                                                     |
| `headscale.livenessProbe.periodSeconds`                           | Period seconds for livenessProbe                                                                                                                                                                                                                | `10`                                                     |
| `headscale.livenessProbe.timeoutSeconds`                          | Timeout seconds for livenessProbe                                                                                                                                                                                                               | `5`                                                      |
| `headscale.livenessProbe.failureThreshold`                        | Failure threshold for livenessProbe                                                                                                                                                                                                             | `3`                                                      |
| `headscale.livenessProbe.successThreshold`                        | Success threshold for livenessProbe                                                                                                                                                                                                             | `1`                                                      |
| `headscale.readinessProbe.enabled`                                | Enable readinessProbe on headscale containers                                                                                                                                                                                                   | `true`                                                   |
| `headscale.readinessProbe.initialDelaySeconds`                    | Initial delay seconds for readinessProbe                                                                                                                                                                                                        | `10`                                                     |
| `headscale.readinessProbe.periodSeconds`                          | Period seconds for readinessProbe                                                                                                                                                                                                               | `10`                                                     |
| `headscale.readinessProbe.timeoutSeconds`                         | Timeout seconds for readinessProbe                                                                                                                                                                                                              | `5`                                                      |
| `headscale.readinessProbe.failureThreshold`                       | Failure threshold for readinessProbe                                                                                                                                                                                                            | `3`                                                      |
| `headscale.readinessProbe.successThreshold`                       | Success threshold for readinessProbe                                                                                                                                                                                                            | `1`                                                      |
| `headscale.startupProbe.enabled`                                  | Enable startupProbe on headscale containers                                                                                                                                                                                                     | `false`                                                  |
| `headscale.startupProbe.initialDelaySeconds`                      | Initial delay seconds for startupProbe                                                                                                                                                                                                          | `10`                                                     |
| `headscale.startupProbe.periodSeconds`                            | Period seconds for startupProbe                                                                                                                                                                                                                 | `10`                                                     |
| `headscale.startupProbe.timeoutSeconds`                           | Timeout seconds for startupProbe                                                                                                                                                                                                                | `5`                                                      |
| `headscale.startupProbe.failureThreshold`                         | Failure threshold for startupProbe                                                                                                                                                                                                              | `10`                                                     |
| `headscale.startupProbe.successThreshold`                         | Success threshold for startupProbe                                                                                                                                                                                                              | `1`                                                      |
| `headscale.customLivenessProbe`                                   | Custom livenessProbe that overrides the default one                                                                                                                                                                                             | `{}`                                                     |
| `headscale.customReadinessProbe`                                  | Custom readinessProbe that overrides the default one                                                                                                                                                                                            | `{}`                                                     |
| `headscale.customStartupProbe`                                    | Custom startupProbe that overrides the default one                                                                                                                                                                                              | `{}`                                                     |
| `headscale.resourcesPreset`                                       | Set headscale container resources according to one common preset (allowed values: none, nano, micro, small, medium, large, xlarge, 2xlarge). This is ignored if headscale.resources is set (headscale.resources is recommended for production). | `small`                                                  |
| `headscale.resources`                                             | Set headscale container requests and limits for different resources like CPU or memory (essential for production workloads)                                                                                                                     | `{}`                                                     |
| `headscale.podSecurityContext.enabled`                            | Enable headscale pods' Security Context                                                                                                                                                                                                         | `true`                                                   |
| `headscale.podSecurityContext.fsGroupChangePolicy`                | Set filesystem group change policy for headscale pods                                                                                                                                                                                           | `Always`                                                 |
| `headscale.podSecurityContext.sysctls`                            | Set kernel settings using the sysctl interface for headscale pods                                                                                                                                                                               | `[]`                                                     |
| `headscale.podSecurityContext.supplementalGroups`                 | Set filesystem extra groups for headscale pods                                                                                                                                                                                                  | `[]`                                                     |
| `headscale.podSecurityContext.fsGroup`                            | Set fsGroup in headscale pods' Security Context                                                                                                                                                                                                 | `65532`                                                  |
| `headscale.containerSecurityContext.enabled`                      | Enabled headscale container' Security Context                                                                                                                                                                                                   | `true`                                                   |
| `headscale.containerSecurityContext.seLinuxOptions`               | Set SELinux options in headscale container                                                                                                                                                                                                      | `{}`                                                     |
| `headscale.containerSecurityContext.runAsUser`                    | Set runAsUser in headscale container' Security Context                                                                                                                                                                                          | `65532`                                                  |
| `headscale.containerSecurityContext.runAsGroup`                   | Set runAsGroup in headscale container' Security Context                                                                                                                                                                                         | `65532`                                                  |
| `headscale.containerSecurityContext.runAsNonRoot`                 | Set runAsNonRoot in headscale container' Security Context                                                                                                                                                                                       | `true`                                                   |
| `headscale.containerSecurityContext.readOnlyRootFilesystem`       | Set readOnlyRootFilesystem in headscale container' Security Context                                                                                                                                                                             | `true`                                                   |
| `headscale.containerSecurityContext.privileged`                   | Set privileged in headscale container' Security Context                                                                                                                                                                                         | `false`                                                  |
| `headscale.containerSecurityContext.allowPrivilegeEscalation`     | Set allowPrivilegeEscalation in headscale container' Security Context                                                                                                                                                                           | `false`                                                  |
| `headscale.containerSecurityContext.capabilities.drop`            | List of capabilities to be dropped in headscale container                                                                                                                                                                                       | `["ALL"]`                                                |
| `headscale.containerSecurityContext.seccompProfile.type`          | Set seccomp profile in headscale container                                                                                                                                                                                                      | `RuntimeDefault`                                         |
| `headscale.config.serverUrl`                                      | Public URL for the headscale server (required)                                                                                                                                                                                                  | `https://headscale.example.com`                          |
| `headscale.config.listenAddr`                                     | Address headscale listens on                                                                                                                                                                                                                    | `0.0.0.0:8080`                                           |
| `headscale.config.metricsListenAddr`                              | Address headscale listens on for Prometheus metrics                                                                                                                                                                                             | `0.0.0.0:9090`                                           |
| `headscale.config.grpcListenAddr`                                 | Address headscale listens on for gRPC                                                                                                                                                                                                           | `0.0.0.0:50443`                                          |
| `headscale.config.grpcAllowInsecure`                              | Allow insecure gRPC connections                                                                                                                                                                                                                 | `false`                                                  |
| `headscale.config.randomizeClientPort`                            | Enable randomizing client ports                                                                                                                                                                                                                 | `false`                                                  |
| `headscale.config.policy.mode`                                    | Policy mode: 'file' or 'database'                                                                                                                                                                                                               | `database`                                               |
| `headscale.config.policy.path`                                    | Path to the ACL policy file (used when mode is 'file')                                                                                                                                                                                          | `/etc/headscale/acl.hujson`                              |
| `headscale.config.prefixes.v4`                                    | IPv4 prefix for Tailscale nodes                                                                                                                                                                                                                 | `100.64.0.0/10`                                          |
| `headscale.config.prefixes.v6`                                    | IPv6 prefix for Tailscale nodes                                                                                                                                                                                                                 | `fd7a:115c:a1e0::/48`                                    |
| `headscale.config.prefixes.allocation`                            | IP allocation mode: 'sequential' or 'random'                                                                                                                                                                                                    | `sequential`                                             |
| `headscale.config.database.type`                                  | Database type: 'sqlite' or 'postgres'                                                                                                                                                                                                           | `sqlite`                                                 |
| `headscale.config.database.debug`                                 | Enable database debug logging                                                                                                                                                                                                                   | `false`                                                  |
| `headscale.config.database.sqlite.path`                           | Path to the SQLite database file                                                                                                                                                                                                                | `/var/lib/headscale/db.sqlite`                           |
| `headscale.config.noise.privateKeyPath`                           | Path to the Noise protocol private key                                                                                                                                                                                                          | `/var/lib/headscale/noise_private.key`                   |
| `headscale.config.derp.server.enabled`                            | Enable the embedded DERP server                                                                                                                                                                                                                 | `false`                                                  |
| `headscale.config.derp.server.regionId`                           | DERP region ID for the embedded server                                                                                                                                                                                                          | `999`                                                    |
| `headscale.config.derp.server.regionCode`                         | DERP region code for the embedded server                                                                                                                                                                                                        | `headscale`                                              |
| `headscale.config.derp.server.regionName`                         | DERP region name for the embedded server                                                                                                                                                                                                        | `Headscale Embedded DERP`                                |
| `headscale.config.derp.server.stunListenAddr`                     | STUN listen address for the embedded DERP server                                                                                                                                                                                                | `0.0.0.0:3478`                                           |
| `headscale.config.derp.server.privateKeyPath`                     | Path to the DERP server private key                                                                                                                                                                                                             | `/var/lib/headscale/derp_server_private.key`             |
| `headscale.config.derp.server.automaticallyAddEmbeddedDerpRegion` | Automatically add the embedded DERP region to the DERP map                                                                                                                                                                                      | `true`                                                   |
| `headscale.config.derp.server.ipv4`                               | IPv4 address of the embedded DERP server (required if enabled)                                                                                                                                                                                  | `""`                                                     |
| `headscale.config.derp.server.ipv6`                               | IPv6 address of the embedded DERP server                                                                                                                                                                                                        | `""`                                                     |
| `headscale.config.derp.urls`                                      | List of DERP map URLs                                                                                                                                                                                                                           | `["https://controlplane.tailscale.com/derpmap/default"]` |
| `headscale.config.derp.paths`                                     | List of local DERP map files                                                                                                                                                                                                                    | `[]`                                                     |
| `headscale.config.derp.autoUpdate`                                | Enable automatic DERP map updates                                                                                                                                                                                                               | `true`                                                   |
| `headscale.config.derp.updateFrequency`                           | Frequency to check for DERP map updates                                                                                                                                                                                                         | `24h`                                                    |
| `headscale.config.dns.magicDns`                                   | Enable MagicDNS                                                                                                                                                                                                                                 | `true`                                                   |
| `headscale.config.dns.baseDomain`                                 | Base domain for MagicDNS                                                                                                                                                                                                                        | `headscale.vpn`                                          |
| `headscale.config.dns.nameservers.global`                         | Global DNS nameservers                                                                                                                                                                                                                          | `["1.1.1.1","8.8.8.8"]`                                  |
| `headscale.config.log.level`                                      | Log level (trace, debug, info, warn, error)                                                                                                                                                                                                     | `info`                                                   |
| `headscale.config.log.format`                                     | Log format (text or json)                                                                                                                                                                                                                       | `text`                                                   |
| `headscale.oidc.enabled`                                          | Enable OIDC authentication                                                                                                                                                                                                                      | `false`                                                  |
| `headscale.oidc.issuer`                                           | OIDC issuer URL                                                                                                                                                                                                                                 | `""`                                                     |
| `headscale.oidc.clientId`                                         | OIDC client ID                                                                                                                                                                                                                                  | `""`                                                     |
| `headscale.oidc.clientSecret`                                     | OIDC client secret (stored in a managed Secret). Ignored if existingSecret is set.                                                                                                                                                              | `""`                                                     |
| `headscale.oidc.existingSecret`                                   | Name of an existing secret containing the OIDC client secret                                                                                                                                                                                    | `""`                                                     |
| `headscale.oidc.existingSecretKey`                                | Key in the existing secret containing the OIDC client secret                                                                                                                                                                                    | `client_secret`                                          |
| `headscale.oidc.scope`                                            | OIDC scopes to request                                                                                                                                                                                                                          | `["openid","profile","email"]`                           |
| `headscale.oidc.pkce.enabled`                                     | Enable PKCE                                                                                                                                                                                                                                     | `false`                                                  |
| `headscale.oidc.pkce.method`                                      | PKCE method (S256)                                                                                                                                                                                                                              | `S256`                                                   |
| `headscale.existingConfigmap`                                     | Name of an existing ConfigMap with the headscale config. If set, the managed configmap.yaml is skipped.                                                                                                                                         | `""`                                                     |
| `headscale.command`                                               | Override default headscale container command (useful when using custom images)                                                                                                                                                                  | `[]`                                                     |
| `headscale.args`                                                  | Override default headscale container args (useful when using custom images)                                                                                                                                                                     | `[]`                                                     |
| `headscale.automountServiceAccountToken`                          | Mount Service Account token in headscale pods                                                                                                                                                                                                   | `false`                                                  |
| `headscale.hostAliases`                                           | headscale pods host aliases                                                                                                                                                                                                                     | `[]`                                                     |
| `headscale.statefulsetAnnotations`                                | Annotations for headscale StatefulSet                                                                                                                                                                                                           | `{}`                                                     |
| `headscale.podLabels`                                             | Extra labels for headscale pods                                                                                                                                                                                                                 | `{}`                                                     |
| `headscale.podAnnotations`                                        | Annotations for headscale pods                                                                                                                                                                                                                  | `{}`                                                     |
| `headscale.podAffinityPreset`                                     | Pod affinity preset. Ignored if `headscale.affinity` is set. Allowed values: `soft` or `hard`                                                                                                                                                   | `""`                                                     |
| `headscale.podAntiAffinityPreset`                                 | Pod anti-affinity preset. Ignored if `headscale.affinity` is set. Allowed values: `soft` or `hard`                                                                                                                                              | `soft`                                                   |
| `headscale.nodeAffinityPreset.type`                               | Node affinity preset type. Ignored if `headscale.affinity` is set. Allowed values: `soft` or `hard`                                                                                                                                             | `""`                                                     |
| `headscale.nodeAffinityPreset.key`                                | Node label key to match. Ignored if `headscale.affinity` is set                                                                                                                                                                                 | `""`                                                     |
| `headscale.nodeAffinityPreset.values`                             | Node label values to match. Ignored if `headscale.affinity` is set                                                                                                                                                                              | `[]`                                                     |
| `headscale.affinity`                                              | Affinity for headscale pods assignment                                                                                                                                                                                                          | `{}`                                                     |
| `headscale.nodeSelector`                                          | Node labels for headscale pods assignment                                                                                                                                                                                                       | `{}`                                                     |
| `headscale.tolerations`                                           | Tolerations for headscale pods assignment                                                                                                                                                                                                       | `[]`                                                     |
| `headscale.updateStrategy.type`                                   | headscale statefulset strategy type                                                                                                                                                                                                             | `RollingUpdate`                                          |
| `headscale.podManagementPolicy`                                   | Pod management policy for headscale statefulset                                                                                                                                                                                                 | `OrderedReady`                                           |
| `headscale.priorityClassName`                                     | headscale pods' priorityClassName                                                                                                                                                                                                               | `""`                                                     |
| `headscale.topologySpreadConstraints`                             | Topology Spread Constraints for headscale pod assignment                                                                                                                                                                                        | `[]`                                                     |
| `headscale.schedulerName`                                         | Name of the k8s scheduler (other than default) for headscale pods                                                                                                                                                                               | `""`                                                     |
| `headscale.terminationGracePeriodSeconds`                         | Seconds headscale pods need to terminate gracefully                                                                                                                                                                                             | `30`                                                     |
| `headscale.lifecycleHooks`                                        | for headscale containers to automate configuration before or after startup                                                                                                                                                                      | `{}`                                                     |
| `headscale.extraEnvVars`                                          | Array with extra environment variables to add to headscale containers                                                                                                                                                                           | `[]`                                                     |
| `headscale.extraEnvVarsCM`                                        | Name of existing ConfigMap containing extra env vars for headscale containers                                                                                                                                                                   | `""`                                                     |
| `headscale.extraEnvVarsSecret`                                    | Name of existing Secret containing extra env vars for headscale containers                                                                                                                                                                      | `""`                                                     |
| `headscale.extraVolumes`                                          | Optionally specify extra list of additional volumes for the headscale pods                                                                                                                                                                      | `[]`                                                     |
| `headscale.extraVolumeMounts`                                     | Optionally specify extra list of additional volumeMounts for the headscale containers                                                                                                                                                           | `[]`                                                     |
| `headscale.sidecars`                                              | Add additional sidecar containers to the headscale pods                                                                                                                                                                                         | `[]`                                                     |
| `headscale.initContainers`                                        | Add additional init containers to the headscale pods                                                                                                                                                                                            | `[]`                                                     |
| `headscale.pdb.create`                                            | Enable/disable a Pod Disruption Budget creation                                                                                                                                                                                                 | `true`                                                   |
| `headscale.pdb.minAvailable`                                      | Minimum number/percentage of pods that should remain scheduled                                                                                                                                                                                  | `""`                                                     |
| `headscale.pdb.maxUnavailable`                                    | Maximum number/percentage of pods that may be made unavailable. Defaults to `1` if both `headscale.pdb.minAvailable` and `headscale.pdb.maxUnavailable` are empty.                                                                              | `""`                                                     |
| `headscale.autoscaling.vpa.enabled`                               | Enable VPA for headscale pods                                                                                                                                                                                                                   | `false`                                                  |
| `headscale.autoscaling.vpa.annotations`                           | Annotations for VPA resource                                                                                                                                                                                                                    | `{}`                                                     |
| `headscale.autoscaling.vpa.controlledResources`                   | VPA List of resources that the vertical pod autoscaler can control                                                                                                                                                                              | `[]`                                                     |
| `headscale.autoscaling.vpa.maxAllowed`                            | VPA Max allowed resources for the pod                                                                                                                                                                                                           | `{}`                                                     |
| `headscale.autoscaling.vpa.minAllowed`                            | VPA Min allowed resources for the pod                                                                                                                                                                                                           | `{}`                                                     |
| `headscale.autoscaling.vpa.updatePolicy.updateMode`               | Autoscaling update policy                                                                                                                                                                                                                       | `Auto`                                                   |
| `headscale.autoscaling.hpa.enabled`                               | Enable HPA for headscale pods                                                                                                                                                                                                                   | `false`                                                  |
| `headscale.autoscaling.hpa.minReplicas`                           | Minimum number of headscale replicas                                                                                                                                                                                                            | `1`                                                      |
| `headscale.autoscaling.hpa.maxReplicas`                           | Maximum number of headscale replicas                                                                                                                                                                                                            | `3`                                                      |
| `headscale.autoscaling.hpa.targetCPU`                             | Target CPU utilization percentage                                                                                                                                                                                                               | `75`                                                     |
| `headscale.autoscaling.hpa.targetMemory`                          | Target Memory utilization percentage                                                                                                                                                                                                            | `""`                                                     |

### Traffic Exposure Parameters

| Name                                    | Description                                                                                                   | Value                    |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------- | ------------------------ |
| `service.type`                          | headscale service type                                                                                        | `ClusterIP`              |
| `service.ports.http`                    | headscale service HTTP port                                                                                   | `8080`                   |
| `service.ports.grpc`                    | headscale service gRPC port                                                                                   | `50443`                  |
| `service.nodePorts.http`                | Node port for HTTP                                                                                            | `""`                     |
| `service.nodePorts.grpc`                | Node port for gRPC                                                                                            | `""`                     |
| `service.clusterIP`                     | headscale service Cluster IP                                                                                  | `""`                     |
| `service.loadBalancerIP`                | headscale service Load Balancer IP                                                                            | `""`                     |
| `service.loadBalancerSourceRanges`      | headscale service Load Balancer sources                                                                       | `[]`                     |
| `service.externalTrafficPolicy`         | headscale service external traffic policy                                                                     | `Cluster`                |
| `service.annotations`                   | Additional custom annotations for headscale service                                                           | `{}`                     |
| `service.extraPorts`                    | Extra ports to expose in headscale service (normally used with the `sidecars` value)                          | `[]`                     |
| `service.sessionAffinity`               | Control where client requests go, to the same pod or round-robin                                              | `None`                   |
| `service.sessionAffinityConfig`         | Additional settings for the sessionAffinity                                                                   | `{}`                     |
| `networkPolicy.enabled`                 | Specifies whether a NetworkPolicy should be created                                                           | `true`                   |
| `networkPolicy.allowExternal`           | Don't require server label for connections                                                                    | `true`                   |
| `networkPolicy.allowExternalEgress`     | Allow the pod to access any range of port and all destinations.                                               | `true`                   |
| `networkPolicy.addExternalClientAccess` | Allow access from pods with client label set to "true". Ignored if `networkPolicy.allowExternal` is true.     | `true`                   |
| `networkPolicy.extraIngress`            | Add extra ingress rules to the NetworkPolicy                                                                  | `[]`                     |
| `networkPolicy.extraEgress`             | Add extra egress rules to the NetworkPolicy (ignored if allowExternalEgress=true)                             | `[]`                     |
| `networkPolicy.ingressPodMatchLabels`   | Labels to match to allow traffic from other pods. Ignored if `networkPolicy.allowExternal` is true.           | `{}`                     |
| `networkPolicy.ingressNSMatchLabels`    | Labels to match to allow traffic from other namespaces. Ignored if `networkPolicy.allowExternal` is true.     | `{}`                     |
| `networkPolicy.ingressNSPodMatchLabels` | Pod labels to match to allow traffic from other namespaces. Ignored if `networkPolicy.allowExternal` is true. | `{}`                     |
| `ingress.enabled`                       | Enable ingress record generation for headscale                                                                | `false`                  |
| `ingress.pathType`                      | Ingress path type                                                                                             | `ImplementationSpecific` |
| `ingress.apiVersion`                    | Force Ingress API version (automatically detected if not set)                                                 | `""`                     |
| `ingress.hostname`                      | Default host for the ingress record                                                                           | `headscale.local`        |
| `ingress.ingressClassName`              | IngressClass that will be be used to implement the Ingress (Kubernetes 1.18+)                                 | `""`                     |
| `ingress.path`                          | Default path for the ingress record                                                                           | `/`                      |
| `ingress.annotations`                   | Additional annotations for the Ingress resource                                                               | `{}`                     |
| `ingress.tls`                           | Enable TLS configuration for the host defined at `ingress.hostname` parameter                                 | `false`                  |
| `ingress.selfSigned`                    | Create a TLS secret for this ingress record using self-signed certificates generated by Helm                  | `false`                  |
| `ingress.extraHosts`                    | An array with additional hostname(s) to be covered with the ingress record                                    | `[]`                     |
| `ingress.extraPaths`                    | An array with additional arbitrary paths that may need to be added to the ingress under the main host         | `[]`                     |
| `ingress.extraTls`                      | TLS configuration for additional hostname(s) to be covered with this ingress record                           | `[]`                     |
| `ingress.secrets`                       | Custom TLS certificates as secrets                                                                            | `[]`                     |
| `ingress.extraRules`                    | Additional rules to be covered with this ingress record                                                       | `[]`                     |
| `route`                                 | Map of HTTPRoute configurations. Each key is a route name; "main" omits the suffix from the resource name.    | `{}`                     |

### Persistence Parameters

| Name                        | Description                                                            | Value                |
| --------------------------- | ---------------------------------------------------------------------- | -------------------- |
| `persistence.enabled`       | Enable persistence using Persistent Volume Claims                      | `true`               |
| `persistence.mountPath`     | Path to mount the volume at (headscale data directory)                 | `/var/lib/headscale` |
| `persistence.subPath`       | The subdirectory of the volume to mount to                             | `""`                 |
| `persistence.storageClass`  | Storage class of backing PVC                                           | `""`                 |
| `persistence.annotations`   | Persistent Volume Claim annotations                                    | `{}`                 |
| `persistence.accessModes`   | Persistent Volume Access Modes                                         | `["ReadWriteOnce"]`  |
| `persistence.size`          | Size of data volume                                                    | `1Gi`                |
| `persistence.dataSource`    | Custom PVC data source                                                 | `{}`                 |
| `persistence.existingClaim` | The name of an existing PVC to use for persistence                     | `""`                 |
| `persistence.selector`      | Selector to match an existing Persistent Volume for headscale data PVC | `{}`                 |

### Default init containers Parameters

| Name                                                                                        | Description                                                                                              | Value              |
| ------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | ------------------ |
| `defaultInitContainers.volumePermissions.enabled`                                           | Enable init container that adapts the owner/group of the PV mount point(s)                               | `false`            |
| `defaultInitContainers.volumePermissions.image.registry`                                    | OS Shell image registry                                                                                  | `docker.io`        |
| `defaultInitContainers.volumePermissions.image.repository`                                  | OS Shell image repository                                                                                | `bitnami/os-shell` |
| `defaultInitContainers.volumePermissions.image.tag`                                         | OS Shell image tag                                                                                       | `12-debian-12-r46` |
| `defaultInitContainers.volumePermissions.image.digest`                                      | OS Shell image digest in the way sha256:aa.... Please note this parameter, if set, will override the tag | `""`               |
| `defaultInitContainers.volumePermissions.image.pullPolicy`                                  | OS Shell image pull policy                                                                               | `IfNotPresent`     |
| `defaultInitContainers.volumePermissions.image.pullSecrets`                                 | OS Shell image pull secrets                                                                              | `[]`               |
| `defaultInitContainers.volumePermissions.containerSecurityContext.enabled`                  | Enable init container Security Context                                                                   | `true`             |
| `defaultInitContainers.volumePermissions.containerSecurityContext.seLinuxOptions`           | Set SELinux options in init container                                                                    | `{}`               |
| `defaultInitContainers.volumePermissions.containerSecurityContext.runAsUser`                | Set runAsUser in init container Security Context                                                         | `0`                |
| `defaultInitContainers.volumePermissions.containerSecurityContext.privileged`               | Set privileged in init container Security Context                                                        | `false`            |
| `defaultInitContainers.volumePermissions.containerSecurityContext.allowPrivilegeEscalation` | Set allowPrivilegeEscalation in init container Security Context                                          | `false`            |
| `defaultInitContainers.volumePermissions.containerSecurityContext.capabilities.add`         | List of capabilities to add in init container                                                            | `[]`               |
| `defaultInitContainers.volumePermissions.containerSecurityContext.capabilities.drop`        | List of capabilities to drop in init container                                                           | `["ALL"]`          |
| `defaultInitContainers.volumePermissions.containerSecurityContext.seccompProfile.type`      | Set seccomp profile in init container                                                                    | `RuntimeDefault`   |
| `defaultInitContainers.volumePermissions.resourcesPreset`                                   | Set init container resources according to one of the preset                                              | `nano`             |
| `defaultInitContainers.volumePermissions.resources`                                         | Set init container requests and limits for different resources like CPU or memory                        | `{}`               |

### Other Parameters

| Name                                          | Description                                                                                            | Value   |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------ | ------- |
| `rbac.create`                                 | Specifies whether RBAC resources should be created                                                     | `false` |
| `rbac.rules`                                  | Custom RBAC rules to set                                                                               | `[]`    |
| `serviceAccount.create`                       | Specifies whether a ServiceAccount should be created                                                   | `true`  |
| `serviceAccount.name`                         | The name of the ServiceAccount to use.                                                                 | `""`    |
| `serviceAccount.annotations`                  | Additional Service Account annotations (evaluated as a template)                                       | `{}`    |
| `serviceAccount.automountServiceAccountToken` | Automount service account token for the server service account                                         | `false` |
| `metrics.enabled`                             | Enable the export of Prometheus metrics                                                                | `true`  |
| `metrics.serviceMonitor.enabled`              | if `true`, creates a Prometheus Operator ServiceMonitor (also requires `metrics.enabled` to be `true`) | `false` |
| `metrics.serviceMonitor.namespace`            | Namespace in which Prometheus is running                                                               | `""`    |
| `metrics.serviceMonitor.annotations`          | Additional custom annotations for the ServiceMonitor                                                   | `{}`    |
| `metrics.serviceMonitor.labels`               | Extra labels for the ServiceMonitor                                                                    | `{}`    |
| `metrics.serviceMonitor.jobLabel`             | The name of the label on the target service to use as the job name in Prometheus                       | `""`    |
| `metrics.serviceMonitor.honorLabels`          | honorLabels chooses the metric's labels on collisions with target labels                               | `false` |
| `metrics.serviceMonitor.tlsConfig`            | TLS configuration used for scrape endpoints used by Prometheus                                         | `{}`    |
| `metrics.serviceMonitor.interval`             | Interval at which metrics should be scraped.                                                           | `""`    |
| `metrics.serviceMonitor.scrapeTimeout`        | Timeout after which the scrape is ended                                                                | `""`    |
| `metrics.serviceMonitor.metricRelabelings`    | Specify additional relabeling of metrics                                                               | `[]`    |
| `metrics.serviceMonitor.relabelings`          | Specify general relabeling                                                                             | `[]`    |
| `metrics.serviceMonitor.selector`             | Prometheus instance selector labels                                                                    | `{}`    |

### Headplane Parameters

| Name                                                        | Description                                                                                                                                 | Value                           |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- |
| `headplane.enabled`                                         | Enable headplane as a sidecar container alongside headscale                                                                                 | `false`                         |
| `headplane.image.registry`                                  | headplane image registry                                                                                                                    | `ghcr.io`                       |
| `headplane.image.repository`                                | headplane image repository                                                                                                                  | `tale/headplane`                |
| `headplane.image.tag`                                       | headplane image tag                                                                                                                         | `0.6.0`                         |
| `headplane.image.digest`                                    | headplane image digest in the way sha256:aa....                                                                                             | `""`                            |
| `headplane.image.pullPolicy`                                | headplane image pull policy                                                                                                                 | `IfNotPresent`                  |
| `headplane.image.pullSecrets`                               | headplane image pull secrets                                                                                                                | `[]`                            |
| `headplane.containerPort`                                   | headplane container port                                                                                                                    | `3000`                          |
| `headplane.config.server.host`                              | Server host address                                                                                                                         | `0.0.0.0`                       |
| `headplane.config.server.port`                              | Server port                                                                                                                                 | `3000`                          |
| `headplane.config.server.cookie_secure`                     | Use secure cookies (set to false for HTTP)                                                                                                  | `true`                          |
| `headplane.config.headscale.url`                            | URL of the headscale server                                                                                                                 | `https://headscale.example.com` |
| `headplane.config.headscale.config_path`                    | Path to headscale config file inside the container                                                                                          | `/etc/headscale/config.yaml`    |
| `headplane.config.headscale.config_strict`                  | Enable strict config parsing                                                                                                                | `true`                          |
| `headplane.config.integration.kubernetes.enabled`           | Enable Kubernetes integration                                                                                                               | `true`                          |
| `headplane.config.integration.kubernetes.validate_manifest` | Validate Kubernetes manifests on config write                                                                                               | `true`                          |
| `headplane.oidc.enabled`                                    | Enable OIDC authentication for headplane                                                                                                    | `false`                         |
| `headplane.oidc.issuer`                                     | OIDC issuer URL                                                                                                                             | `""`                            |
| `headplane.oidc.disable_api_key_login`                      | Disable API key login when OIDC is enabled                                                                                                  | `true`                          |
| `headplane.oidc.token_endpoint_auth_method`                 | OIDC token endpoint auth method                                                                                                             | `client_secret_post`            |
| `headplane.oidc.redirect_uri`                               | OIDC redirect URI (e.g. https://headplane.example.com/admin/oidc/callback)                                                                  | `""`                            |
| `headplane.oidc.client_id`                                  | OIDC client ID                                                                                                                              | `""`                            |
| `headplane.oidc.existingSecret`                             | Name of an existing secret containing OIDC credentials (mounted as envFrom)                                                                 | `""`                            |
| `headplane.apiKey.value`                                    | Headscale API key value (stored in a managed Secret). Ignored if existingSecret is set.                                                     | `""`                            |
| `headplane.apiKey.existingSecret`                           | Name of an existing secret containing the API key.                                                                                          | `""`                            |
| `headplane.cookieSecret`                                    | Cookie secret for headplane sessions.                                                                                                       | `""`                            |
| `headplane.extraEnvVars`                                    | Array with extra environment variables to add to the headplane container                                                                    | `[]`                            |
| `headplane.extraEnvVarsCM`                                  | Name of existing ConfigMap containing extra env vars for headplane                                                                          | `""`                            |
| `headplane.extraEnvVarsSecret`                              | Name of existing Secret containing extra env vars for headplane                                                                             | `""`                            |
| `headplane.resourcesPreset`                                 | Set headplane container resources according to one common preset (allowed values: none, nano, micro, small, medium, large, xlarge, 2xlarge) | `nano`                          |
| `headplane.resources`                                       | Set headplane container requests and limits for different resources like CPU or memory                                                      | `{}`                            |
| `headplane.containerSecurityContext.enabled`                | Enable headplane container Security Context                                                                                                 | `false`                         |
| `headplane.serviceAccount.create`                           | Create a dedicated ServiceAccount for headplane                                                                                             | `true`                          |
| `headplane.serviceAccount.name`                             | Name of the ServiceAccount to use. Defaults to "<fullname>-headplane".                                                                      | `""`                            |
| `headplane.serviceAccount.annotations`                      | Additional annotations for the headplane ServiceAccount                                                                                     | `{}`                            |
| `headplane.serviceAccount.automountServiceAccountToken`     | Automount service account token (required for Kubernetes integration)                                                                       | `true`                          |
| `headplane.rbac.create`                                     | Create Role and RoleBinding for headplane (required for Kubernetes integration)                                                             | `true`                          |
| `headplane.service.type`                                    | headplane service type                                                                                                                      | `ClusterIP`                     |
| `headplane.service.port`                                    | headplane service port                                                                                                                      | `3000`                          |
| `headplane.service.nodePort`                                | headplane service node port (for NodePort/LoadBalancer type)                                                                                | `""`                            |
| `headplane.service.clusterIP`                               | headplane service Cluster IP                                                                                                                | `""`                            |
| `headplane.service.annotations`                             | Additional custom annotations for the headplane service                                                                                     | `{}`                            |
| `headplane.adminPath`                                       | Path prefix routed to headplane in the shared ingress/httproute                                                                             | `/admin`                        |

See <https://github.com/bitnami/readme-generator-for-helm> to regenerate this section from values.yaml and values.schema.json.

Specify each parameter using the --set key=value[,key=value] argument to helm install. For example:

```console
helm install my-release \
  --set headscale.config.serverUrl=https://headscale.example.com \
  oci://REGISTRY_NAME/REPOSITORY_NAME/headscale
```

> Note: You need to substitute the placeholders REGISTRY_NAME and REPOSITORY_NAME with a reference to your Helm chart registry and repository. For example, for this chart use REGISTRY_NAME=ghcr.io and REPOSITORY_NAME=hlhc/charts.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing:

```console
helm install my-release -f values.yaml oci://REGISTRY_NAME/REPOSITORY_NAME/headscale
```

## Troubleshooting

### headscale not starting

```console
kubectl logs -l app.kubernetes.io/name=headscale --tail=100
```

Check that `headscale.config.serverUrl` is set to a valid public HTTPS URL.

### Health check

headscale exposes a health endpoint on `headscale.containerPorts.http` (default 8080):

```console
kubectl port-forward svc/my-release-headscale 8080:8080
curl http://localhost:8080/health
```

### headscale CLI

```console
kubectl exec -it statefulset/my-release-headscale -- headscale --help
```

### headplane not loading

```console
kubectl logs -l app.kubernetes.io/component=headplane --tail=100
```

Common causes:
- `headplane.config.headscale.url` does not match the public URL headscale is reachable at.
- The headscale API key is missing or incorrect — check `headplane.apiKey.value` or `headplane.apiKey.existingSecret`.
- `headplane.cookieSecret` is unset and sessions are being invalidated on every upgrade.

### Access headplane locally

```console
kubectl port-forward svc/my-release-headscale-headplane 3000:3000
```

Then open `http://localhost:3000/admin` in your browser.

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
