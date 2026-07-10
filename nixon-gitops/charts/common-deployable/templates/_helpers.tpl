{{/*
Expand the name of the chart.
*/}}
{{- define "common-deployable.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "common-deployable.fullname" -}}
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
{{- define "common-deployable.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "common-deployable.labels" -}}
helm.sh/chart: {{ include "common-deployable.chart" . }}
{{ include "common-deployable.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "common-deployable.selectorLabels" -}}
app.kubernetes.io/name: {{ include "common-deployable.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "common-deployable.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "common-deployable.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Build a semicolon-separated ASPNETCORE_URLS value from enabled containerPorts.
Returns empty string if no ports are enabled.
Usage: include "common-deployable.aspnetcore_urls" .
*/}}
{{- define "common-deployable.aspnetCoreUrlsEnvValue" -}}
{{- $ports := .Values.containerPorts }}
{{- $urls := list }}
{{- if $ports }}
{{- range $name, $port := $ports }}
  {{- if $port.enabled }}
    {{- $u := printf "http://+:%v" $port.containerPort }}
    {{- $urls = append $urls $u }}
  {{- end }}
{{- end }}
{{- end }}
{{- if gt (len $urls) 0 }}
{{- printf "%s" (join ";" $urls) }}
{{- end }}
{{- end }}

