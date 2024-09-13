# Copyright (c) Jon Thysell <http://jonthysell.com>
# Licensed under the MIT License.

function CopyAndReplace-TemplateFile {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        $Replacements
    )

    $RawContent = Get-Content -Path $InputPath
    $NewContent = $RawContent | ForEach-Object {
        $line = $_
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            $Replacements.Keys | ForEach-Object {
                $key = $_
                $line = $line.Replace("{$key}", $Replacements[$key])
            }
        }
        return $line
    }
    $NewContent | Set-Content -Path $OutputPath -Force
}

function Get-Version {
    param()

    [string] $RepoRoot = Resolve-Path "$PSScriptRoot/.."

    $VersionFile = Join-Path $RepoRoot "src/version.txt"
    $Version = Get-Content -Path $VersionFile
    return $Version.Trim()
}