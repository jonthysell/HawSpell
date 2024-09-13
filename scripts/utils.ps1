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