{{/*
Expand the name of the chart.
*/}}
{{- define "nixon-external-secrets-resources.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "nixon-external-secrets-resources.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nixon-external-secrets-resources.labels" -}}
helm.sh/chart: {{ include "nixon-external-secrets-resources.chart" . }}
{{ include "nixon-external-secrets-resources.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nixon-external-secrets-resources.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nixon-external-secrets-resources.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "nixon-external-secrets-resources.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nixon-external-secrets-resources.name" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
