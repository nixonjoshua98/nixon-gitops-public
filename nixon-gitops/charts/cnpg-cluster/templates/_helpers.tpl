{{/*
Expand the name of the chart.
*/}}
{{- define "cnpg-cluster.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cnpg-cluster.fullname" -}}
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
{{- define "cnpg-cluster.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cnpg-cluster.labels" -}}
helm.sh/chart: {{ include "cnpg-cluster.chart" . }}
{{ include "cnpg-cluster.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cnpg-cluster.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "cnpg-cluster.clusterName" -}}
{{- printf "%s-cluster" (include "cnpg-cluster.name" .) | trim -}}
{{- end }}

{{- define "cnpg-cluster.objectStore" -}}
{{- printf "%s-store" (include "cnpg-cluster.name" .) | trim -}}
{{- end }}

{{- define "cnpg-cluster.externalObjectStore" -}}
{{- printf "%s-external-store" (include "cnpg-cluster.name" .) | trim -}}
{{- end }}

{{- define "cnpg-cluster.userSecretName" -}}
{{- printf "%s-%s" (include "cnpg-cluster.name" .root) (replace "_" "-" .name) | trim -}}
{{- end }}