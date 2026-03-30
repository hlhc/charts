# @hlhc/Helm Charts

Helm charts maintained by @hlhc.

## Charts

Charts are published from the `charts/` directory in this repository.

| Chart | Description |
| ----- | ----------- |
| [cloudflared](charts/cloudflared/) | Lightweight daemon that creates outbound-only encrypted tunnels from your cluster to the Cloudflare network |
| [headscale](charts/headscale/) | Open source, self-hosted implementation of the Tailscale control server |

## TL;DR

```console
helm install my-release oci://ghcr.io/hlhc/charts/<chart-name>
```

## Versioning Policy

> [!WARNING]
> All chart versions in the `0.x.x` range are unstable.
> Breaking changes may be introduced in any `0.x.x` release, including minor and patch bumps.
> Use exact pinning in production and review release notes carefully before upgrading.

## Prerequisites

- Kubernetes 1.21+
- Helm 4.0+

## Installation

Install a chart:

```console
helm install my-release oci://ghcr.io/hlhc/charts/<chart-name>
```

Install with custom values:

```console
helm install my-release oci://ghcr.io/hlhc/charts/<chart-name> -f values.yaml
```

## Upgrade

```console
helm upgrade my-release oci://ghcr.io/hlhc/charts/<chart-name>
```

## Uninstall

```console
helm uninstall my-release
```

## Development

From a chart directory:

```console
helm lint .
helm template test-release .
```

For charts using dependencies:

```console
helm dependency update
```

## License

Copyright (c) 2026 Cyrus Ho.

Licensed under the Apache License, Version 2.0.
