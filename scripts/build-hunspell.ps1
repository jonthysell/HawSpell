param(
    [switch]$Clean = $False
)

[string] $RepoRoot = Resolve-Path "$PSScriptRoot\.."

[string] $OutputRoot = "bld"

$StartingLocation = Get-Location
Set-Location -Path $RepoRoot

try
{
    New-Item -Path $OutputRoot -Type Directory -Force | Out-Null

    $HunspellOutputDir = Join-Path $OutputRoot "hunspell"
    if ((Test-Path $HunspellOutputDir) -and $Clean) {
        Write-Host Cleaning $HunspellOutputDir...
        Remove-Item $HunspellOutputDir -Recurse
    }
    New-Item -Path $HunspellOutputDir -Type Directory -Force | Out-Null

    $HunspellInputDir = Join-Path $RepoRoot "src/hunspell"

    $PukuiElbertFile = "src/wordlists/PukuiElbert.txt"
    Write-Host Reading $PukuiElbertFile...
    $PukuiElbertRaw = Get-Content -Path $PukuiElbertFile
    $PukuiElbertClean = $PukuiElbertRaw -Split ",| |…" | ForEach-Object { return $_.Replace(".", "").Trim() } | Where-Object { -not [String]::IsNullOrWhiteSpace($_) }

    $MamakaKaiaoExclude = @("pepa 11`" X 17`"")
    $MamakaKaiaoFile = "src/wordlists/MamakaKaiao.txt"
    Write-Host Reading $MamakaKaiaoFile...
    $MamakaKaiaoRaw = Get-Content -Path $MamakaKaiaoFile
    $MamakaKaiaoClean = ($MamakaKaiaoRaw | Where-Object { -not $MamakaKaiaoExclude.Contains($_) }) -Split " " | ForEach-Object { return $_.Replace("·", "").Trim() } | Where-Object { -not [String]::IsNullOrWhiteSpace($_) }

    Write-Host Parsing word lists...
    $WordSet = [System.Collections.Generic.HashSet[string]]@()
    $PrefixSet = [System.Collections.Generic.HashSet[string]]@()
    $SuffixSet = [System.Collections.Generic.HashSet[string]]@()

    $($PukuiElbertClean; $MamakaKaiaoClean) | ForEach-Object {
        $affix = $False;
        if ($_.StartsWith("-")) {
            $PrefixSet.Add($_.Replace("-", ""))
            $affix = $True
        }
        if ($_.EndsWith("-")) {
            $SuffixSet.Add($_.Replace("-", ""))
            $affix = $True
        }

        if (-not $affix) {
            $WordSet.Add($_.Replace("-", ""))
        }
    } | Out-Null

    $FinalWords = $WordSet | Sort-Object

    $HawDicFile = Join-Path $HunspellOutputDir "haw.dic"
    Write-Host Creating $HawDicFile...
    $FinalWords.Length | Set-Content -Path $HawDicFile
    $FinalWords | Add-Content -Path $HawDicFile

    $HawAffFile = Join-Path $HunspellOutputDir "haw.aff"
    Write-Host Creating $HawAffFile...
    Copy-Item -Path (Join-Path $HunspellInputDir "base.aff") -Destination $HawAffFile -Force

    Write-Host Calculating character histogram...
    $CharHistogram = @{}
    $ValidChars = "aāeēiīoōuūhklmnpwʻ"
    $ValidChars.ToCharArray() | ForEach-Object { $CharHistogram.Add($_.ToString(), 0) }
    $FinalWords | ForEach-Object {
        $_.ToCharArray() | ForEach-Object {
            $key = [Char]::ToLower($_).ToString()
            if ($ValidChars.Contains($key)) {
                $CharHistogram[$key]++
            }
        }
    }
    $TryChars = ""
    $CharHistogram.GetEnumerator() | Sort-Object { $_.Value } -Descending | ForEach-Object { $TryChars += $_.Key }

    $TryDirective = "TRY " + $TryChars.Replace("ʻ", "") + $TryChars.ToUpper().Replace("ʻ", "") + "ʻ"
    Write-Host "Adding TRY directive to $HawAffFile..."
    "`r`n$TryDirective" | Add-Content -Path $HawAffFile
}
finally
{
    Set-Location -Path "$StartingLocation"
}
