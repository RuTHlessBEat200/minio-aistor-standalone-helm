{{/*
Expand the name of the chart.
*/}}
{{- define "minio-aistor.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "minio-aistor.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "minio-aistor.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "minio-aistor.labels" -}}
helm.sh/chart: {{ include "minio-aistor.chart" . }}
{{ include "minio-aistor.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "minio-aistor.selectorLabels" -}}
app.kubernetes.io/name: {{ include "minio-aistor.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Component labels for minio
*/}}
{{- define "minio-aistor.minio.labels" -}}
{{ include "minio-aistor.labels" . }}
app.kubernetes.io/component: minio
{{- end }}

{{/*
Selector labels for minio
*/}}
{{- define "minio-aistor.minio.selectorLabels" -}}
{{ include "minio-aistor.selectorLabels" . }}
app.kubernetes.io/component: minio
app: {{ include "minio-aistor.fullname" . }}-minio
{{- end }}

{{/*
Return the proper MinIO image name
*/}}
{{- define "minio-aistor.minio.image" -}}
{{- $registry := .Values.minio.image.registry -}}
{{- if .Values.global.imageRegistry -}}
  {{- $registry = .Values.global.imageRegistry -}}
{{- end -}}
{{- $repository := .Values.minio.image.repository -}}
{{- $tag := .Values.minio.image.tag | default .Chart.AppVersion -}}
{{- if .Values.global.imageTag -}}
  {{- $tag = .Values.global.imageTag -}}
{{- end -}}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- end }}

{{/*
Return the MinIO root user
*/}}
{{- define "minio-aistor.rootUser" -}}
{{- if .Values.minio.auth.existingSecret -}}
{{- printf "%s" .Values.minio.auth.existingSecret -}}
{{- else -}}
{{- printf "%s-secret" (include "minio-aistor.fullname" .) -}}
{{- end -}}
{{- end }}

{{/*
Return the MinIO root password secret name
*/}}
{{- define "minio-aistor.secretName" -}}
{{- if .Values.minio.auth.existingSecret -}}
{{- printf "%s" .Values.minio.auth.existingSecret -}}
{{- else -}}
{{- printf "%s-secret" (include "minio-aistor.fullname" .) -}}
{{- end -}}
{{- end }}

{{/*
Return the MinIO license secret name
*/}}
{{- define "minio-aistor.licenseSecretName" -}}
{{- if .Values.minio.license.existingSecret -}}
{{- printf "%s" .Values.minio.license.existingSecret -}}
{{- else -}}
{{- printf "%s-license" (include "minio-aistor.fullname" .) -}}
{{- end -}}
{{- end }}

{{/*
Return the storage class
*/}}
{{- define "minio-aistor.storageClass" -}}
{{- $storageClass := .Values.minio.persistence.storageClass -}}
{{- if .Values.global.storageClass -}}
  {{- $storageClass = .Values.global.storageClass -}}
{{- end -}}
{{- if $storageClass -}}
{{- printf "%s" $storageClass -}}
{{- end -}}
{{- end }}
