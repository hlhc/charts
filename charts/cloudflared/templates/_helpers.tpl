{{/*
Copyright Cyrus Ho. All Rights Reserved.
SPDX-License-Identifier: APACHE-2.0
*/}}

{{/*
Return the proper cloudflared image name.
Defaults tag to .Chart.AppVersion if not set.
*/}}
{{- define "cloudflared.image" -}}
{{- $imageRoot := deepCopy .Values.cloudflared.image -}}
{{- if not $imageRoot.tag -}}
{{- $_ := set $imageRoot "tag" .Chart.AppVersion -}}
{{- end -}}
{{ include "common.images.image" (dict "imageRoot" $imageRoot "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "cloudflared.imagePullSecrets" -}}
{{- include "common.images.renderPullSecrets" (dict "images" (list .Values.cloudflared.image) "context" $) -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "cloudflared.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "common.names.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return the name of the Secret containing the tunnel credentials.
Returns an empty string if both existing secrets are provided (no managed secret needed).
*/}}
{{- define "cloudflared.tunnelCredentialsSecretName" -}}
{{- if and .Values.cloudflared.tunnelSecrets.existingPemFileSecret.name .Values.cloudflared.tunnelSecrets.existingConfigJsonFileSecret.name -}}
    {{- "" -}}
{{- else -}}
    {{- printf "%s-tunnel-credentials" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the ConfigMap name for cloudflared tunnel config.
Uses existingConfigmap if set, otherwise the managed ConfigMap.
*/}}
{{- define "cloudflared.configmapName" -}}
{{- if .Values.cloudflared.existingConfigmap -}}
    {{- .Values.cloudflared.existingConfigmap -}}
{{- else -}}
    {{- include "common.names.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Compile all warnings into a single message.
*/}}
{{- define "cloudflared.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "cloudflared.validateValues.tunnelName" .) -}}
{{- $messages := append $messages (include "cloudflared.validateValues.tunnelCredentials" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}
{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message -}}
{{- end -}}
{{- end -}}

{{/*
Validate that cloudflared.tunnelConfig.name is set
*/}}
{{- define "cloudflared.validateValues.tunnelName" -}}
{{- if empty .Values.cloudflared.tunnelConfig.name -}}
cloudflared: cloudflared.tunnelConfig.name
    A tunnel name is required. Please set cloudflared.tunnelConfig.name in your values.
{{- end -}}
{{- end -}}

{{/*
Validate that tunnel credentials are provided
*/}}
{{- define "cloudflared.validateValues.tunnelCredentials" -}}
{{- if and (empty .Values.cloudflared.tunnelSecrets.existingPemFileSecret.name) (empty .Values.cloudflared.tunnelSecrets.base64EncodedPemFile) -}}
cloudflared: cloudflared.tunnelSecrets
    Either cloudflared.tunnelSecrets.base64EncodedPemFile or cloudflared.tunnelSecrets.existingPemFileSecret.name must be set.
{{- end -}}
{{- if and (empty .Values.cloudflared.tunnelSecrets.existingConfigJsonFileSecret.name) (empty .Values.cloudflared.tunnelSecrets.base64EncodedConfigJsonFile) -}}
cloudflared: cloudflared.tunnelSecrets
    Either cloudflared.tunnelSecrets.base64EncodedConfigJsonFile or cloudflared.tunnelSecrets.existingConfigJsonFileSecret.name must be set.
{{- end -}}
{{- end -}}
