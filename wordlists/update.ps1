param(
    [switch]$Clean = $False
)

function Update-WordListFromHawDict {
    param(
        [string]$InputPath,
        [string]$OutputPath
    )

    $InputData = Import-Csv -Delimiter `t -Path $InputPath -Header @('Term', 'Definition')

    Write-Host Found $InputData.Length raw entries in $InputPath

    Write-Host Updating $OutputPath...
    $InputData | Select-Object -ExpandProperty Term -Unique | Sort-Object | Set-Content -Path $OutputPath
}

[string] $RepoRoot = Resolve-Path "$PSScriptRoot\.."

[string] $OutputRoot = "bld"

$StartingLocation = Get-Location
Set-Location -Path $RepoRoot

try
{
    New-Item -Path $OutputRoot -Type Directory -Force | Out-Null

    $HawDictUrl = "https://github.com/jonthysell/HawDict/releases/latest/download/HawDict.Unpacked.zip"
    $HawDictZipFile = Join-Path $OutputRoot "HawDict.Unpacked.zip"

    if ((Test-Path $HawDictZipFile) -and $Clean) {
        Write-Host Cleaning $HawDictZipFile...
        Remove-Item $HawDictZipFile | Out-Null
    }

    if (-not (Test-Path $HawDictZipFile)) {
        Write-Host Downloading $HawDictUrl...
        Invoke-WebRequest -Uri $HawDictUrl -OutFile $HawDictZipFile
    }

    $HawDictDir = Join-Path $OutputRoot "HawDict.Unpacked"
    if ((Test-Path $HawDictDir) -and $Clean) {
        Write-Host Cleaning $HawDictDir...
        Remove-Item $HawDictDir -Recurse | Out-Null
    }

    if (-not (Test-Path $HawDictDir)) {
        Write-Host Expanding $HawDictZipFile...
        Expand-Archive -Path $HawDictZipFile -DestinationPath $OutputRoot -Force
    }

    $WordListDir = "wordlists"

    Write-Host Running HawDict...
    $HawDictDir = Join-Path $OutputRoot "HawDict.Unpacked"
    & dotnet (Join-Path $HawDictDir "HawDict.dll") $HawDictDir

    Update-WordListFromHawDict -InputPath (Join-Path $HawDictDir "PukuiElbert/PukuiElbert.HawToEng.clean.txt") -OutputPath (Join-Path $WordListDir "PukuiElbert.txt")
    Update-WordListFromHawDict -InputPath (Join-Path $HawDictDir "MamakaKaiao/MamakaKaiao.HawToEng.clean.txt") -OutputPath (Join-Path $WordListDir "MamakaKaiao.txt")
}
finally
{
    Set-Location -Path "$StartingLocation"
}
