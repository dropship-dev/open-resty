{{/*
Expand the name of the chart.
*/}}
{{- define "openresty.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "openresty.fullname" -}}
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
{{- define "openresty.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "openresty.labels" -}}
helm.sh/chart: {{ include "openresty.chart" . }}
{{ include "openresty.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "openresty.selectorLabels" -}}
app.kubernetes.io/name: {{ include "openresty.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "openresty.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "openresty.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the config map
*/}}
{{- define "openresty.configMapName" -}}
{{- printf "%s-config" (include "openresty.fullname" .) }}
{{- end }}

{{/*
Create the name of the lua config map
*/}}
{{- define "openresty.luaConfigMapName" -}}
{{- printf "%s-lua" (include "openresty.fullname" .) }}
{{- end }}

{{/*
Create the name of the PVC
*/}}
{{- define "openresty.pvcName" -}}
{{- printf "%s-pvc" (include "openresty.fullname" .) }}
{{- end }}

{{/*
Create the image name
*/}}
{{- define "openresty.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}
