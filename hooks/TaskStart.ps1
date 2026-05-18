#!/usr/bin/env pwsh
# Cline TaskStart hook (Windows PowerShell 5.1+). Cline invokes this script
# when a task begins. The script reads JSON from stdin and writes JSON to
# stdout:
#   {"cancel": false, "contextModification": "<text injected into context>"}
#
# Behavior: read the using-superpowers SKILL.md and inject it so the agent
# always has the skills bootstrap loaded, even if it would otherwise miss
# the .clinerules/00-bootstrap.md rule.

param()

$inputJson = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($inputJson)) {
    [Console]::Out.WriteLine('{"cancel":false}')
    exit 0
}

try {
    $event = $inputJson | ConvertFrom-Json
} catch {
    [Console]::Out.WriteLine('{"cancel":false}')
    exit 0
}

# Resolve workspace root: hook script is at .clinerules/hooks/TaskStart.ps1
# which is a junction to superpower-custom/hooks/. Walk up two levels.
$projectRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$skillPath   = Join-Path $projectRoot '.cline\skills\using-superpowers\SKILL.md'

if (-not (Test-Path $skillPath)) {
    [Console]::Out.WriteLine('{"cancel":false}')
    exit 0
}

$skillContent = Get-Content -Raw $skillPath
$context = @"
<EXTREMELY_IMPORTANT>
You have superpowers.

Below is the full content of your 'using-superpowers' skill - your introduction to using skills.

$skillContent
</EXTREMELY_IMPORTANT>
"@

$result = @{
    cancel              = $false
    contextModification = $context
} | ConvertTo-Json -Depth 8 -Compress

[Console]::Out.WriteLine($result)
