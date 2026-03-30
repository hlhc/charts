{{/*
Copyright Cyrus Ho. All Rights Reserved.
SPDX-License-Identifier: APACHE-2.0
*/}}

{{/*
Return the proper headscale image name.
Defaults tag to .Chart.AppVersion if not set.
*/}}
{{- define "headscale.image" -}}
{{- $imageRoot := deepCopy .Values.headscale.image -}}
{{- if not $imageRoot.tag -}}
{{- $_ := set $imageRoot "tag" .Chart.AppVersion -}}
{{- end -}}
{{ include "common.images.image" (dict "imageRoot" $imageRoot "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper image name (for the init container volume-permissions image)
*/}}
{{- define "headscale.volumePermissions.image" -}}
{{- include "common.images.image" ( dict "imageRoot" .Values.defaultInitContainers.volumePermissions.image "global" .Values.global ) -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "headscale.imagePullSecrets" -}}
{{- include "common.images.renderPullSecrets" (dict "images" (list .Values.headscale.image .Values.defaultInitContainers.volumePermissions.image) "context" $) -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "headscale.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "common.names.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return the ConfigMap name for headscale config.
Uses existingConfigmap if set, otherwise the managed ConfigMap.
*/}}
{{- define "headscale.configmapName" -}}
{{- if .Values.headscale.existingConfigmap -}}
    {{- .Values.headscale.existingConfigmap -}}
{{- else -}}
    {{- include "common.names.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Return the name of the Secret containing the OIDC client secret.
Uses existingSecret if set, otherwise the managed Secret.
*/}}
{{- define "headscale.oidcSecretName" -}}
{{- if .Values.headscale.oidc.existingSecret -}}
    {{- .Values.headscale.oidc.existingSecret -}}
{{- else -}}
    {{- printf "%s-oidc" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if cert-manager required annotations for TLS signed certificates are set in the Ingress annotations
Ref: https://cert-manager.io/docs/usage/ingress/#supported-annotations
*/}}
{{- define "headscale.ingress.certManagerRequest" -}}
{{ if or (hasKey . "cert-manager.io/cluster-issuer") (hasKey . "cert-manager.io/issuer") }}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Compile all warnings into a single message.
*/}}
{{- define "headscale.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "headscale.validateValues.serverUrl" .) -}}
{{- $messages := append $messages (include "headscale.validateValues.oidc" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message -}}
{{- end -}}
{{- end -}}

{{/*
Validate that headscale.config.serverUrl is set
*/}}
{{- define "headscale.validateValues.serverUrl" -}}
{{- if empty .Values.headscale.config.serverUrl -}}
headscale: headscale.config.serverUrl
    A public server URL is required. Please set headscale.config.serverUrl in your values.
    Example: headscale.config.serverUrl=https://headscale.example.com
{{- end -}}
{{- end -}}

{{/*
Validate OIDC configuration
*/}}
{{- define "headscale.validateValues.oidc" -}}
{{- if .Values.headscale.oidc.enabled -}}
{{- if empty .Values.headscale.oidc.issuer -}}
headscale: headscale.oidc.issuer
    OIDC issuer URL is required when OIDC is enabled. Please set headscale.oidc.issuer.
{{- end -}}
{{- if empty .Values.headscale.oidc.clientId -}}
headscale: headscale.oidc.clientId
    OIDC client ID is required when OIDC is enabled. Please set headscale.oidc.clientId.
{{- end -}}
{{- if and (empty .Values.headscale.oidc.clientSecret) (empty .Values.headscale.oidc.existingSecret) -}}
headscale: headscale.oidc.clientSecret
    Either headscale.oidc.clientSecret or headscale.oidc.existingSecret must be set when OIDC is enabled.
{{- end -}}
{{- end -}}
{{- end -}}
