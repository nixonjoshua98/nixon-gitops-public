{{/*
Expand the name of the chart.
*/}}
{{- define "nixon-argocd-resources.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "nixon-argocd-resources.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nixon-argocd-resources.labels" -}}
helm.sh/chart: {{ include "nixon-argocd-resources.chart" . }}
{{ include "nixon-argocd-resources.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nixon-argocd-resources.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nixon-argocd-resources.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
