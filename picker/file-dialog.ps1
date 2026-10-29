param(
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$UriArgs,
    [switch]$NoDialog      # test mode: skips the dialog, writes a fake result
)
$ErrorActionPreference = 'Stop'
$NoBom = New-Object System.Text.UTF8Encoding($false)

$uri = ($UriArgs -join ' ')
$ts = if ($uri -match '[?&]ts=(\d+)') { $Matches[1] } else { [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds().ToString() }

function Write-Result($r) {
    $json = $r | ConvertTo-Json -Depth 4 -Compress
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot 'dialog-result.js'), ('window.DIALOG_RESULT = ' + $json + ';'), $NoBom)
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot 'dialog-result.json'), $json, $NoBom)
}

if ($NoDialog) {
    Write-Result ([ordered]@{ ts = $ts; ok = $true; cancelled = $false; error = $null; paths = @((Join-Path $PSScriptRoot 'picker.html')); dir = $PSScriptRoot })
    exit 0
}

if ($uri -match 'save') {
    $r = [ordered]@{ ts = $ts; saved = $false; cancelled = $false; error = $null }
    try {
        $txt = Get-Clipboard -Raw
        $obj = $txt | ConvertFrom-Json
        if (-not $obj.template -or -not $obj.content_files) { throw 'clipboard payload does not look like a selection' }
        [IO.File]::WriteAllText((Join-Path $PSScriptRoot 'selection.json'), $txt, $NoBom)
        $r.saved = $true
    } catch { $r.error = $_.Exception.Message }
    Write-Result $r
    exit 0
}

Add-Type -AssemblyName System.Windows.Forms
$result = [ordered]@{ ts = $ts; ok = $false; cancelled = $false; error = $null; paths = @(); dir = $null }

$dlg = New-Object System.Windows.Forms.OpenFileDialog
$dlg.Title = 'Pick lesson source files for the deck'
$dlg.Multiselect = $true
$dlg.Filter = 'Lesson sources (*.html;*.htm;*.docx;*.pdf;*.pptx;*.md;*.txt)|*.html;*.htm;*.docx;*.pdf;*.pptx;*.md;*.txt|All files (*.*)|*.*'
$last = Join-Path $PSScriptRoot 'dialog-last.txt'
if (Test-Path $last) {
    $prev = (Get-Content $last -Raw).Trim()
    if ($prev -and (Test-Path $prev)) { $dlg.InitialDirectory = $prev }
}
$owner = New-Object System.Windows.Forms.Form
$owner.StartPosition = 'Manual'
$owner.Location = New-Object System.Drawing.Point(-32000, -32000)
$owner.Size = New-Object System.Drawing.Size(1, 1)
$owner.TopMost = $true
$owner.ShowInTaskbar = $false
try {
    $owner.Show()
    $choice = $dlg.ShowDialog($owner)
    if ($choice -eq [System.Windows.Forms.DialogResult]::OK) {
        $result.ok = $true
        $result.paths = @($dlg.FileNames)
        $dir = [IO.Path]::GetDirectoryName($dlg.FileNames[0])
        $result.dir = $dir
        Set-Content -LiteralPath $last -Value $dir -Encoding UTF8
    } else {
        $result.cancelled = $true
    }
} catch {
    $result.error = $_.Exception.Message
} finally {
    $owner.Dispose()
}
Write-Result $result
