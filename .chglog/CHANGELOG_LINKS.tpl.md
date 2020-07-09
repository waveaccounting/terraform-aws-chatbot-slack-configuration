{{- if .Versions }}
[Unreleased]: {{ .Info.RepositoryURL }}/compare/{{ $latest := index .Versions 0 }}{{ $latest.Tag.Name }}...HEAD
{{ range .Versions -}}
{{ if .Tag.Previous -}}
[{{ .Tag.Name }}]: {{ $.Info.RepositoryURL }}/compare/{{ .Tag.Previous.Name }}...{{ .Tag.Name }}
{{ else -}}
[{{ .Tag.Name }}]: {{ $.Info.RepositoryURL }}/releases/tag/{{ .Tag.Name }}
{{ end -}}
{{ end -}}
{{ end -}}
