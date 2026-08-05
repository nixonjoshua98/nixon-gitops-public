{{/*
Expand the name of the chart.
*/}}
{{- define "nixon-netbird-resources.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "nixon-netbird-resources.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nixon-netbird-resources.labels" -}}
helm.sh/chart: {{ include "nixon-netbird-resources.chart" . }}
{{ include "nixon-netbird-resources.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nixon-netbird-resources.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nixon-netbird-resources.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "nixon-netbird-resources.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nixon-netbird-resources.name" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
