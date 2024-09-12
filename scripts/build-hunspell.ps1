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

    # Read PukuiElbert word list, split multiple words, and exlude known problems
    $PukuiElbertExclueRegex = "\(noun|\(or|phrase|\(verb"
    $PukuiElbertFile = "src/wordlists/PukuiElbert.txt"
    Write-Host Reading $PukuiElbertFile...
    $PukuiElbertRaw = Get-Content -Path $PukuiElbertFile
    $PukuiElbertClean = ($PukuiElbertRaw -Replace $PukuiElbertExclueRegex,"") -Split ",| |…|\(|\)|\?" | ForEach-Object { return $_.Replace(".", "").Trim() } | Where-Object { -not [String]::IsNullOrWhiteSpace($_) }

    # Read MamakaKaiao word list, split multiple words, and exlude known problems
    $MamakaKaiaoExclueRegex = "\(i\/iā\)"
    $MamakaKaiaoExclude = @("pepa 11`" X 17`"")
    $MamakaKaiaoFile = "src/wordlists/MamakaKaiao.txt"
    Write-Host Reading $MamakaKaiaoFile...
    $MamakaKaiaoRaw = Get-Content -Path $MamakaKaiaoFile
    $MamakaKaiaoClean = (($MamakaKaiaoRaw -Replace $MamakaKaiaoExclueRegex,"") | Where-Object { -not $MamakaKaiaoExclude.Contains($_) }) -Split " |\(|\)" | ForEach-Object { return $_.Replace("·", "").Trim() } | Where-Object { -not [String]::IsNullOrWhiteSpace($_) }

    # Read numbers word list, split multiple words, and exlude known problems
    $NumbersFile = "src/wordlists/numbers.txt"
    Write-Host Reading $NumbersFile...
    $NumbersRaw = Get-Content -Path $NumbersFile
    $NumbersClean = $NumbersRaw -Split ",| " | ForEach-Object { return $_.Trim() } | Where-Object { -not [String]::IsNullOrWhiteSpace($_) }

    Write-Host Parsing word lists...
    $WordSet = [System.Collections.Generic.HashSet[string]]@()
    $PrefixSet = [System.Collections.Generic.HashSet[string]]@()
    $SuffixSet = [System.Collections.Generic.HashSet[string]]@()

    $($PukuiElbertClean; $MamakaKaiaoClean; $NumbersClean) | ForEach-Object {
        # Normalize word removing syllables denoted by hyphens
        $cleaned = $_.Replace("-", "")

        # Normalize word by fixing capitalization
        $capitalized = ""
        $firstAlphaChar = 0
        if ($cleaned[$firstAlphaChar] -eq 'ʻ') {
            # Need to make sure we capitalize the letter *after* the ʻokina
            $firstAlphaChar++
        }
        if ($cleaned.Length -gt $firstAlphaChar + 1) {
            # Normalize the word maintaining its existing "first-letter" capitalization
            $cleaned = $cleaned.Substring(0, $firstAlphaChar + 1) + $cleaned.Substring($firstAlphaChar + 1).ToLower()
            if ($firstAlphaChar -eq 1) {
                # Word started with ʻokina, add capitalized version with
                $capitalized = $cleaned.Substring(0, $firstAlphaChar + 1).ToUpper() + $cleaned.Substring($firstAlphaChar + 1).ToLower()
            }
        }

        $affix = $False
        if ($_.StartsWith("-")) {
            $PrefixSet.Add($cleaned)
            $affix = $True
        }
        if ($_.EndsWith("-")) {
            $SuffixSet.Add($cleaned)
            $affix = $True
        }

        if (-not $affix) {
            $WordSet.Add($cleaned)
            if ($capitalized -ne "") {
                $WordSet.Add($capitalized)
            }
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
    Write-Host "Adding $TryDirective to $HawAffFile..."
    "`r`n$TryDirective" | Add-Content -Path $HawAffFile
}
finally
{
    Set-Location -Path "$StartingLocation"
}
