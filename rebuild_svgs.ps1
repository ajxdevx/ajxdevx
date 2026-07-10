$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$rawLines = [System.IO.File]::ReadAllLines((Join-Path $root "smiley_ascii.txt"))

function Escape-Xml([string]$s) {
    return $s.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;")
}

# Trim trailing space and strip shared leading indent so the face sits left in the panel
$trimmed = foreach ($line in $rawLines) { $line.TrimEnd() }
$nonEmpty = $trimmed | Where-Object { $_.Trim().Length -gt 0 }
$minIndent = ($nonEmpty | ForEach-Object {
    if ($_ -match '^(\s*)') { $Matches[1].Length } else { 0 }
} | Measure-Object -Minimum).Minimum

$lines = foreach ($line in $trimmed) {
    if ($line.Trim().Length -eq 0) { continue }
    if ($minIndent -gt 0 -and $line.Length -ge $minIndent) {
        $line.Substring($minIndent)
    } else {
        $line
    }
}

$maxLen = ($lines | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum
$lineCount = $lines.Count
$scale = [Math]::Round(360.0 / ($maxLen * 10.5), 3)
if ($scale -gt 0.28) { $scale = 0.28 }
if ($scale -lt 0.12) { $scale = 0.12 }
$lineStep = 14

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('<g transform="translate(8, 8) scale(' + $scale + ')">')
[void]$sb.AppendLine('<text x="0" y="0" fill="{COLOR}" class="ascii">')
for ($i = 0; $i -lt $lineCount; $i++) {
    $y = 16 + ($i * $lineStep)
    $line = Escape-Xml $lines[$i]
    [void]$sb.AppendLine('<tspan x="0" y="' + $y + '">' + $line + '</tspan>')
}
[void]$sb.AppendLine('</text>')
[void]$sb.AppendLine('</g>')
$asciiBlock = $sb.ToString()

$darkProfile = [System.IO.File]::ReadAllText((Join-Path $root "dark_mode.svg"))
$lightProfile = [System.IO.File]::ReadAllText((Join-Path $root "light_mode.svg"))
$darkProfile = $darkProfile.Substring($darkProfile.IndexOf('<text x="390"'))
$lightProfile = $lightProfile.Substring($lightProfile.IndexOf('<text x="390"'))

$headerDark = @'
<?xml version='1.0' encoding='UTF-8'?>
<svg xmlns="http://www.w3.org/2000/svg" font-family="ConsolasFallback,Consolas,monospace" width="985px" height="530px" font-size="16px">
<style>
@font-face {
src: local('Consolas'), local('Consolas Bold');
font-family: 'ConsolasFallback';
font-display: swap;
-webkit-size-adjust: 109%;
size-adjust: 109%;
}
.key {fill: #ffa657;}
.value {fill: #a5d6ff;}
.addColor {fill: #3fb950;}
.delColor {fill: #f85149;}
.cc {fill: #616e7f;}
text, tspan {white-space: pre;}
</style>
<rect width="985px" height="530px" fill="#161b22" rx="15"/>
'@

$headerLight = $headerDark.Replace('#ffa657', '#953800').Replace('#a5d6ff', '#0a3069').Replace('#3fb950', '#1a7f37').Replace('#f85149', '#cf222e').Replace('#616e7f', '#c2cfde').Replace('#161b22', '#f6f8fa')

[System.IO.File]::WriteAllText((Join-Path $root "dark_mode.svg"), $headerDark + ($asciiBlock.Replace('{COLOR}', '#c9d1d9')) + $darkProfile)
[System.IO.File]::WriteAllText((Join-Path $root "light_mode.svg"), $headerLight + ($asciiBlock.Replace('{COLOR}', '#24292f')) + $lightProfile)

Write-Output ("Rebuilt SVGs: {0} lines, max width {1}, scale {2}" -f $lineCount, $maxLen, $scale)
