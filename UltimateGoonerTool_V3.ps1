# ============================================================
# UltimateGoonerTool V3 - Final Portable Edition
# Version: v.1.24 (Console Hidden)
# ============================================================

Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")] public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);'
$consolePtr = [Console.Window]::GetConsoleWindow()

# Hide console immediately
try { [Console.Window]::ShowWindow($consolePtr, 0) | Out-Null } catch {}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

$ErrorActionPreference = "Continue"
trap {
    try {
        [System.Windows.Forms.MessageBox]::Show("Fatal error:`n$($_.Exception.Message)`n`nLine: $($_.InvocationInfo.ScriptLineNumber)`n$($_.ScriptStackTrace)", "UltimateGoonerTool Error")
    } catch {
        Write-Host "Fatal error: $_"
        Start-Sleep 8
    }
    continue
}

# ---------- Paths ----------
$configDir      = Join-Path $env:USERPROFILE "Documents\ULTIMATE GOONER TOOL v5"
$configFile     = Join-Path $configDir "config.txt"
$logFile        = Join-Path $configDir "session_log.txt"
$bgConfigFile   = Join-Path $configDir "background.txt"
$lastSession    = Join-Path $configDir "last_session.txt"
$settingsFile   = Join-Path $configDir "settings.txt"
$favoritesFile  = Join-Path $configDir "favorites.txt"
$windowFile     = Join-Path $configDir "window.txt"
$browserFile    = Join-Path $configDir "browser.txt"
$defaultBg      = Join-Path $PSScriptRoot "background.jpg"
$setupDoneFile  = Join-Path $configDir "setup_done.txt"

if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }

# ---------- Browser ----------
$preferredBrowser = $null
if (Test-Path $browserFile) {
    $preferredBrowser = (Get-Content $browserFile -Raw).Trim()
    if ([string]::IsNullOrWhiteSpace($preferredBrowser)) { $preferredBrowser = $null }
}

function Open-Browser {
    param([string]$Url)
    try {
        if ($preferredBrowser) {
            Start-Process $preferredBrowser $Url
        } else {
            Start-Process "cmd.exe" -ArgumentList "/c","start","","`"$Url`"" -WindowStyle Hidden
        }
    } catch {
        try { [System.Diagnostics.Process]::Start($Url) | Out-Null } catch { Start-Process $Url }
    }
}

function Get-CookieBrowserName {
    $b = if ($preferredBrowser) { $preferredBrowser.Trim().ToLowerInvariant() } else { "" }
    if ([string]::IsNullOrWhiteSpace($b)) { return "chrome" }
    if ($b -match 'brave') { return "brave" }
    if ($b -match 'firefox|waterfox|librewolf') { return "firefox" }
    if ($b -match 'msedge|edge') { return "edge" }
    if ($b -match 'opera') { return "opera" }
    if ($b -match 'vivaldi') { return "vivaldi" }
    if ($b -match 'chromium') { return "chromium" }
    if ($b -match 'chrome') { return "chrome" }
    switch -Regex ($b) {
        '^(chrome|google-chrome)$' { return "chrome" }
        '^(firefox)$' { return "firefox" }
        '^(msedge|edge)$' { return "edge" }
        '^(brave)$' { return "brave" }
        '^(opera)$' { return "opera" }
        default { return "chrome" }
    }
}

function Write-Log($m) { Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $m" }
function Save-LastSession($u) { $u | Set-Content $lastSession }

function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Content, $utf8)
}

function Show-DownloadProgress {
    param(
        [string]$Title = "Downloading...",
        [string]$Status = "Starting download...",
        [int]$Current = 0,
        [int]$Total = 0
    )
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = $Title
    $dlg.Size = New-Object System.Drawing.Size(520, 200)
    $dlg.StartPosition = "CenterScreen"
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.MaximizeBox = $false
    $dlg.MinimizeBox = $false
    $dlg.ControlBox = $true
    $dlg.TopMost = $true
    $dlg.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $Status
    $lbl.Location = New-Object System.Drawing.Point(20, 18)
    $lbl.Size = New-Object System.Drawing.Size(470, 25)
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $lbl.ForeColor = [System.Drawing.Color]::White
    $dlg.Controls.Add($lbl)

    $lblDetail = New-Object System.Windows.Forms.Label
    $lblDetail.Text = "Preparing..."
    $lblDetail.Location = New-Object System.Drawing.Point(20, 48)
    $lblDetail.Size = New-Object System.Drawing.Size(470, 40)
    $lblDetail.Font = New-Object System.Drawing.Font("Consolas", 9)
    $lblDetail.ForeColor = [System.Drawing.Color]::FromArgb(0, 220, 120)
    $dlg.Controls.Add($lblDetail)

    $bar = New-Object System.Windows.Forms.ProgressBar
    $bar.Location = New-Object System.Drawing.Point(20, 100)
    $bar.Size = New-Object System.Drawing.Size(470, 28)
    $bar.Minimum = 0
    $bar.Maximum = 100
    $bar.Value = 0
    $bar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
    $dlg.Controls.Add($bar)

    $lblPct = New-Object System.Windows.Forms.Label
    $lblPct.Text = "0%"
    $lblPct.Location = New-Object System.Drawing.Point(20, 135)
    $lblPct.Size = New-Object System.Drawing.Size(470, 20)
    $lblPct.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $lblPct.ForeColor = [System.Drawing.Color]::LightGray
    $dlg.Controls.Add($lblPct)

    return @{ Form = $dlg; Label = $lbl; Detail = $lblDetail; Bar = $bar; Pct = $lblPct }
}

function Update-DownloadProgress {
    param($Prog, [string]$Status, [string]$Detail, [int]$Percent)
    if (-not $Prog) { return }
    if ($Status) { $Prog.Label.Text = $Status }
    if ($Detail) { $Prog.Detail.Text = $Detail }
    if ($Percent -lt 0) { $Percent = 0 }
    if ($Percent -gt 100) { $Percent = 100 }
    $Prog.Bar.Value = $Percent
    $Prog.Pct.Text = "$Percent%  |  $($Prog.Detail.Text)"
    [System.Windows.Forms.Application]::DoEvents()
}

function Get-GalleryDlExpectedCount {
    param(
        [string]$Url,
        [string]$CookieBrowser = "chrome"
    )
    $count = 0
    $cookiesFile = Join-Path $configDir "cookies.txt"
    try {
        $cookieArg = if (Test-Path $cookiesFile) { "--cookies `"$cookiesFile`"" } else { "--cookies-from-browser $CookieBrowser" }
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"& { `$ErrorActionPreference='SilentlyContinue'; if (Get-Command gallery-dl -EA SilentlyContinue) { gallery-dl -g $cookieArg '$Url' } else { python -m gallery_dl -g $cookieArg '$Url' } }`""
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.WorkingDirectory = if (Test-Path $downloadPath) { $downloadPath } else { $env:USERPROFILE }
        $p = [System.Diagnostics.Process]::Start($psi)
        $out = $p.StandardOutput.ReadToEnd()
        $null = $p.StandardError.ReadToEnd()
        $p.WaitForExit(120000) | Out-Null
        if ($out) {
            $count = @($out -split "`r?`n" | Where-Object { $_ -match '^https?://' }).Count
        }
    } catch {}
    return $count
}

function Start-HiddenDownload {
    param(
        [string]$Command,
        [string]$StatusText = "Downloading...",
        [string]$WatchFolder = $null,
        [int]$ExpectedTotal = 0
    )

    if (-not $WatchFolder) { $WatchFolder = $downloadPath }

    $prog = Show-DownloadProgress -Title "Download" -Status $StatusText
    $prog.Form.Show()
    Update-DownloadProgress $prog $StatusText "Starting..." 1

    $tmp = Join-Path $env:TEMP ("ugt_dl_" + [guid]::NewGuid().ToString("N") + ".ps1")
    $outLog = Join-Path $configDir ("last_download_log.txt")

    $wrapped = @"
`$ErrorActionPreference = 'Continue'
`$ProgressPreference = 'SilentlyContinue'
`$log = '$outLog'
function L(`$m) {
    `$line = "`$(Get-Date -Format 'HH:mm:ss') `$m"
    Add-Content -Path `$log -Value `$line -Encoding UTF8
    Write-Host `$line
}
try { '' | Set-Content -Path `$log -Encoding UTF8 } catch {}
L 'Download job started'
try {
$Command
} catch {
    L "ERROR: `$_"
}
L "Finished LASTEXITCODE=`$LASTEXITCODE"
"@
    try {
        Write-Utf8NoBom -Path $tmp -Content $wrapped
    } catch {
        $prog.Form.Close()
        [System.Windows.Forms.MessageBox]::Show("Failed to prepare download script:`n$_")
        return
    }

    $filesBefore = 0
    try {
        if (Test-Path $WatchFolder) {
            $filesBefore = @(Get-ChildItem $WatchFolder -Recurse -File -ErrorAction SilentlyContinue).Count
        }
    } catch {}

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$tmp`""
    $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    $psi.WorkingDirectory = if (Test-Path $downloadPath) { $downloadPath } else { $env:USERPROFILE }

    try {
        $p = [System.Diagnostics.Process]::Start($psi)
    } catch {
        $prog.Form.Close()
        try { Remove-Item $tmp -Force -ErrorAction SilentlyContinue } catch {}
        [System.Windows.Forms.MessageBox]::Show("Failed to start download process:`n$_")
        return
    }

    $lastLine = "Running..."
    while (-not $p.HasExited) {
        $added = 0
        try {
            if (Test-Path $WatchFolder) {
                $nowCount = @(Get-ChildItem $WatchFolder -Recurse -File -ErrorAction SilentlyContinue).Count
                $added = $nowCount - $filesBefore
            }
        } catch {}

        if ($ExpectedTotal -gt 0) {
            $pct = [int][Math]::Min(99, [Math]::Floor(($added / $ExpectedTotal) * 100))
            $lastLine = "Downloaded $added / $ExpectedTotal"
        } else {
            $pct = [int][Math]::Min(90, 5 + $added)
            $lastLine = "Downloaded $added file(s)..."
        }

        try {
            if (Test-Path $outLog) {
                $tail = Get-Content $outLog -Tail 1 -ErrorAction SilentlyContinue
                if ($tail) { $lastLine = "$lastLine  |  $tail" }
            }
        } catch {}

        Update-DownloadProgress $prog $StatusText $lastLine $pct
        Start-Sleep -Milliseconds 500
    }

    $combined = ""
    try { if (Test-Path $outLog) { $combined = Get-Content $outLog -Raw -ErrorAction SilentlyContinue } } catch {}
    try { Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - DL LOG:`n$combined" } catch {}

    $filesAfter = $filesBefore
    try {
        if (Test-Path $WatchFolder) {
            $filesAfter = @(Get-ChildItem $WatchFolder -Recurse -File -ErrorAction SilentlyContinue).Count
        }
    } catch {}
    $newFiles = $filesAfter - $filesBefore

    try { Remove-Item $tmp -Force -ErrorAction SilentlyContinue } catch {}

    if ($newFiles -gt 0 -or $p.ExitCode -eq 0) {
        $msg = if ($ExpectedTotal -gt 0) { "Downloaded $newFiles / $ExpectedTotal" } else { "New files: $newFiles" }
        Update-DownloadProgress $prog "Download finished" $msg 100
        Start-Sleep -Milliseconds 700
        $prog.Form.Close()
        Write-Log "Download OK exit=$($p.ExitCode) newFiles=$newFiles expected=$ExpectedTotal"
    } else {
        Update-DownloadProgress $prog "Download may have failed" "Exit: $($p.ExitCode)  |  New files: $newFiles" 100
        Start-Sleep -Milliseconds 500
        $prog.Form.Close()
        $snippet = if ($combined.Length -gt 800) { $combined.Substring(0, 800) + "..." } else { $combined }
        if ([string]::IsNullOrWhiteSpace($snippet)) { $snippet = "(no output captured)" }
        [System.Windows.Forms.MessageBox]::Show(
            "Download finished with no new files detected.`n`nExit code: $($p.ExitCode)`n`nOutput:`n$snippet`n`nFull log: $logFile",
            "Download"
        )
        Write-Log "Download FAIL exit=$($p.ExitCode) newFiles=$newFiles"
    }
}

# ---------- Settings ----------
$autoClearOnExit        = $false
$hornyLevel             = 3
$isDarkTheme            = $false
$startWithWindows       = $false
$suppressGalleryWarning = $false
$suppressFfmpegWarning  = $false

if (Test-Path $settingsFile) {
    foreach ($line in (Get-Content $settingsFile)) {
        if ($line -match "AutoClear=(True|False)")              { $autoClearOnExit        = [bool]::Parse($Matches[1]) }
        if ($line -match "HornyLevel=(\d+)")                     { $hornyLevel             = [int]$Matches[1] }
        if ($line -match "DarkTheme=(True|False)")               { $isDarkTheme            = [bool]::Parse($Matches[1]) }
        if ($line -match "StartWithWindows=(True|False)")        { $startWithWindows       = [bool]::Parse($Matches[1]) }
        if ($line -match "SuppressGalleryWarning=(True|False)")  { $suppressGalleryWarning = [bool]::Parse($Matches[1]) }
        if ($line -match "SuppressFfmpegWarning=(True|False)")   { $suppressFfmpegWarning  = [bool]::Parse($Matches[1]) }
    }
}

function Save-Settings {
    @"
AutoClear=$autoClearOnExit
HornyLevel=$hornyLevel
DarkTheme=$isDarkTheme
StartWithWindows=$startWithWindows
SuppressGalleryWarning=$suppressGalleryWarning
SuppressFfmpegWarning=$suppressFfmpegWarning
"@ | Set-Content $settingsFile
}

$favorites = @()
if (Test-Path $favoritesFile) {
    $favorites = @(Get-Content $favoritesFile | Where-Object { $_ -ne "" })
}
function Save-Favorites { $favorites | Set-Content $favoritesFile }

function Test-GalleryDL {
    try { $null = Get-Command gallery-dl -ErrorAction Stop; return $true } catch {}
    try { $out = & python -m gallery_dl --version 2>$null; if ($LASTEXITCODE -eq 0 -or $out) { return $true } } catch {}
    try { $out = & py -m gallery_dl --version 2>$null; if ($LASTEXITCODE -eq 0 -or $out) { return $true } } catch {}
    return $false
}

function Test-Ytdlp {
    try { $null = Get-Command yt-dlp -ErrorAction Stop; return $true } catch {}
    try { $out = & python -m yt_dlp --version 2>$null; if ($LASTEXITCODE -eq 0 -or $out) { return $true } } catch {}
    try { $out = & py -m yt_dlp --version 2>$null; if ($LASTEXITCODE -eq 0 -or $out) { return $true } } catch {}
    return $false
}

$script:ffmpegPath = $null

function Find-FFmpeg {
    try {
        $cmd = Get-Command ffmpeg -ErrorAction Stop
        if ($cmd -and $cmd.Source) { return $cmd.Source }
    } catch {}

    try {
        $where = & where.exe ffmpeg 2>$null
        if ($where) {
            $first = ($where | Select-Object -First 1).Trim()
            if (Test-Path $first) { return $first }
        }
    } catch {}

    $candidates = @(
        "$env:LOCALAPPDATA\Microsoft\WinGet\Links\ffmpeg.exe",
        "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Gyan.FFmpeg*\ffmpeg-*\bin\ffmpeg.exe",
        "C:\ffmpeg\bin\ffmpeg.exe",
        "C:\Program Files\ffmpeg\bin\ffmpeg.exe",
        "C:\Program Files (x86)\ffmpeg\bin\ffmpeg.exe",
        "$env:USERPROFILE\scoop\shims\ffmpeg.exe",
        "$env:USERPROFILE\scoop\apps\ffmpeg\current\bin\ffmpeg.exe",
        "$env:ProgramData\chocolatey\bin\ffmpeg.exe",
        "$env:LOCALAPPDATA\Programs\ffmpeg\bin\ffmpeg.exe"
    )
    foreach ($c in $candidates) {
        $resolved = Get-Item $c -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($resolved -and (Test-Path $resolved.FullName)) { return $resolved.FullName }
    }

    return $null
}

function Test-FFmpeg {
    if ($script:ffmpegPath -and (Test-Path $script:ffmpegPath)) { return $true }
    $script:ffmpegPath = Find-FFmpeg
    return [bool]$script:ffmpegPath
}

function Show-GalleryWarning {
    if ($suppressGalleryWarning) { return $true }

    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = "gallery-dl"
    $dlg.Size = New-Object System.Drawing.Size(440, 190)
    $dlg.StartPosition = "CenterParent"
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.MaximizeBox = $false
    $dlg.MinimizeBox = $false
    $dlg.TopMost = $true

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "gallery-dl not installed are you sure you want to proceed?"
    $lbl.Location = New-Object System.Drawing.Point(20, 25)
    $lbl.Size = New-Object System.Drawing.Size(390, 40)
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $dlg.Controls.Add($lbl)

    $chk = New-Object System.Windows.Forms.CheckBox
    $chk.Text = "Do not show error again"
    $chk.Location = New-Object System.Drawing.Point(20, 75)
    $chk.AutoSize = $true
    $dlg.Controls.Add($chk)

    $btnYes = New-Object System.Windows.Forms.Button
    $btnYes.Text = "Yes"
    $btnYes.Size = New-Object System.Drawing.Size(90, 32)
    $btnYes.Location = New-Object System.Drawing.Point(210, 115)
    $btnYes.DialogResult = [System.Windows.Forms.DialogResult]::Yes
    $dlg.Controls.Add($btnYes)

    $btnNo = New-Object System.Windows.Forms.Button
    $btnNo.Text = "No"
    $btnNo.Size = New-Object System.Drawing.Size(90, 32)
    $btnNo.Location = New-Object System.Drawing.Point(310, 115)
    $btnNo.DialogResult = [System.Windows.Forms.DialogResult]::No
    $dlg.Controls.Add($btnNo)

    $dlg.AcceptButton = $btnYes
    $dlg.CancelButton = $btnNo

    $result = $dlg.ShowDialog()

    if ($chk.Checked) {
        $script:suppressGalleryWarning = $true
        Save-Settings
    }

    return ($result -eq [System.Windows.Forms.DialogResult]::Yes)
}

function Show-FfmpegWarning {
    if ($suppressFfmpegWarning) { return $true }

    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = "ffmpeg"
    $dlg.Size = New-Object System.Drawing.Size(440, 190)
    $dlg.StartPosition = "CenterParent"
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.MaximizeBox = $false
    $dlg.MinimizeBox = $false
    $dlg.TopMost = $true

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "ffmpeg is not installed. Are you sure you want to continue anyway?"
    $lbl.Location = New-Object System.Drawing.Point(20, 25)
    $lbl.Size = New-Object System.Drawing.Size(390, 40)
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $dlg.Controls.Add($lbl)

    $chk = New-Object System.Windows.Forms.CheckBox
    $chk.Text = "Do not show this again"
    $chk.Location = New-Object System.Drawing.Point(20, 75)
    $chk.AutoSize = $true
    $dlg.Controls.Add($chk)

    $btnYes = New-Object System.Windows.Forms.Button
    $btnYes.Text = "Yes"
    $btnYes.Size = New-Object System.Drawing.Size(90, 32)
    $btnYes.Location = New-Object System.Drawing.Point(210, 115)
    $btnYes.DialogResult = [System.Windows.Forms.DialogResult]::Yes
    $dlg.Controls.Add($btnYes)

    $btnNo = New-Object System.Windows.Forms.Button
    $btnNo.Text = "No"
    $btnNo.Size = New-Object System.Drawing.Size(90, 32)
    $btnNo.Location = New-Object System.Drawing.Point(310, 115)
    $btnNo.DialogResult = [System.Windows.Forms.DialogResult]::No
    $dlg.Controls.Add($btnNo)

    $dlg.AcceptButton = $btnYes
    $dlg.CancelButton = $btnNo

    $result = $dlg.ShowDialog()

    if ($chk.Checked) {
        $script:suppressFfmpegWarning = $true
        Save-Settings
    }

    return ($result -eq [System.Windows.Forms.DialogResult]::Yes)
}

function Force-Delete($path) {
    if (-not (Test-Path -LiteralPath $path)) { return }
    try { [System.IO.File]::SetAttributes($path, 'Normal') } catch {}
    try { [System.IO.File]::Delete($path) } catch {}
    if (Test-Path -LiteralPath $path) {
        try { Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue } catch {}
    }
    if (Test-Path -LiteralPath $path) {
        try { cmd /c "del /f /q `"$path`"" 2>$null | Out-Null } catch {}
    }
}

function Show-ConvertDialog {
    if (-not (Test-FFmpeg)) {
        if (-not (Show-FfmpegWarning)) { return }
    }

    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = "Convert Videos to MP4"
    $dlg.Size = New-Object System.Drawing.Size(520, 320)
    $dlg.StartPosition = "CenterParent"
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.MaximizeBox = $false
    $dlg.MinimizeBox = $false

    $lblMode = New-Object System.Windows.Forms.Label
    $lblMode.Text = "Choose what to convert:"
    $lblMode.Location = New-Object System.Drawing.Point(20, 20)
    $lblMode.AutoSize = $true
    $dlg.Controls.Add($lblMode)

    $rbFile = New-Object System.Windows.Forms.RadioButton
    $rbFile.Text = "Video file(s) - multi-select OK"
    $rbFile.Location = New-Object System.Drawing.Point(20, 50)
    $rbFile.Checked = $true
    $rbFile.AutoSize = $true
    $dlg.Controls.Add($rbFile)

    $rbFolder = New-Object System.Windows.Forms.RadioButton
    $rbFolder.Text = "Entire folder (incl. subfolders)"
    $rbFolder.Location = New-Object System.Drawing.Point(220, 50)
    $rbFolder.AutoSize = $true
    $dlg.Controls.Add($rbFolder)

    $txtPath = New-Object System.Windows.Forms.TextBox
    $txtPath.Location = New-Object System.Drawing.Point(20, 90)
    $txtPath.Size = New-Object System.Drawing.Size(360, 25)
    $txtPath.ReadOnly = $true
    $dlg.Controls.Add($txtPath)

    $btnBrowse = New-Object System.Windows.Forms.Button
    $btnBrowse.Text = "Browse..."
    $btnBrowse.Location = New-Object System.Drawing.Point(390, 88)
    $btnBrowse.Size = New-Object System.Drawing.Size(90, 28)
    $dlg.Controls.Add($btnBrowse)

    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Text = "Ready - pick one or many files, or a whole folder"
    $lblStatus.Location = New-Object System.Drawing.Point(20, 135)
    $lblStatus.Size = New-Object System.Drawing.Size(460, 20)
    $dlg.Controls.Add($lblStatus)

    $progress = New-Object System.Windows.Forms.ProgressBar
    $progress.Location = New-Object System.Drawing.Point(20, 165)
    $progress.Size = New-Object System.Drawing.Size(460, 25)
    $progress.Minimum = 0
    $progress.Maximum = 100
    $progress.Value = 0
    $dlg.Controls.Add($progress)

    $btnStart = New-Object System.Windows.Forms.Button
    $btnStart.Text = "Start Convert"
    $btnStart.Location = New-Object System.Drawing.Point(250, 220)
    $btnStart.Size = New-Object System.Drawing.Size(120, 35)
    $btnStart.BackColor = [System.Drawing.Color]::FromArgb(0,150,90)
    $btnStart.ForeColor = [System.Drawing.Color]::White
    $btnStart.FlatStyle = "Flat"
    $dlg.Controls.Add($btnStart)

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Close"
    $btnClose.Location = New-Object System.Drawing.Point(380, 220)
    $btnClose.Size = New-Object System.Drawing.Size(100, 35)
    $btnClose.FlatStyle = "Flat"
    $dlg.Controls.Add($btnClose)

    $script:selectedPaths = @()
    $script:isFolder = $false

    $btnBrowse.Add_Click({
        if ($rbFile.Checked) {
            $ofd = New-Object System.Windows.Forms.OpenFileDialog
            $ofd.Filter = "Video files|*.m4v;*.mkv;*.webm;*.avi;*.mov;*.wmv;*.flv|All files|*.*"
            $ofd.Title = "Select one or more video files (Ctrl+click / Shift+click)"
            $ofd.Multiselect = $true
            if ($ofd.ShowDialog() -eq "OK") {
                $script:selectedPaths = @($ofd.FileNames)
                $script:isFolder = $false
                if ($script:selectedPaths.Count -eq 1) {
                    $txtPath.Text = $script:selectedPaths[0]
                } else {
                    $txtPath.Text = "$($script:selectedPaths.Count) files selected"
                }
            }
        } else {
            $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
            $fbd.Description = "Select folder - all videos in folder and subfolders will be converted"
            if ($fbd.ShowDialog() -eq "OK") {
                $script:selectedPaths = @($fbd.SelectedPath)
                $script:isFolder = $true
                $txtPath.Text = $fbd.SelectedPath
            }
        }
    })

    $btnStart.Add_Click({
        if (-not $script:selectedPaths -or $script:selectedPaths.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Please select file(s) or a folder first.")
            return
        }

        $files = @()
        if ($script:isFolder) {
            $folder = $script:selectedPaths[0]
            $files = @(Get-ChildItem -Path $folder -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -match '^\.(m4v|mkv|webm|avi|mov|wmv|flv)$' })
        } else {
            foreach ($p in $script:selectedPaths) {
                if (Test-Path -LiteralPath $p) {
                    $files += Get-Item -LiteralPath $p
                }
            }
        }

        if ($files.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("No convertible video files found.")
            return
        }

        $btnStart.Enabled = $false
        $btnBrowse.Enabled = $false
        $progress.Value = 0
        $progress.Maximum = $files.Count
        $converted = 0
        $failed = 0

        for ($i = 0; $i -lt $files.Count; $i++) {
            $f = $files[$i]
            $lblStatus.Text = "Converting: $($f.Name)  ($($i+1)/$($files.Count))"
            $progress.Value = $i
            [System.Windows.Forms.Application]::DoEvents()

            $sourcePath = $f.FullName
            $out = [System.IO.Path]::ChangeExtension($sourcePath, ".mp4")

            if (Test-Path $out) {
                $converted++
                Force-Delete $sourcePath
                continue
            }

            try {
                $ff = if ($script:ffmpegPath) { $script:ffmpegPath } else { "ffmpeg" }
                $args = "-y -i `"$sourcePath`" -c copy `"$out`""
                $p = Start-Process $ff -ArgumentList $args -Wait -NoNewWindow -PassThru
                if ((Test-Path $out) -and ((Get-Item $out).Length -gt 0)) {
                    $converted++
                    Force-Delete $sourcePath
                } else {
                    $failed++
                }
            } catch {
                $failed++
            }
        }

        $progress.Value = $files.Count
        $lblStatus.Text = "Done! Converted: $converted   Failed: $failed"
        $btnStart.Enabled = $true
        $btnBrowse.Enabled = $true

        [System.Windows.Forms.MessageBox]::Show("Conversion finished.`n`nConverted: $converted`nFailed: $failed`nOriginals force-deleted.")
    })

    $btnClose.Add_Click({ $dlg.Close() })

    $null = $dlg.ShowDialog()
}

$downloadPath = "$configDir\Downloads"
if (Test-Path $configFile) {
    $temp = (Get-Content $configFile -Raw).Trim()
    if ($temp) { $downloadPath = $temp }
}
if (-not (Test-Path $downloadPath)) { New-Item -ItemType Directory -Path $downloadPath -Force | Out-Null }

$bgImage = $defaultBg
if (Test-Path $bgConfigFile) {
    $savedBg = (Get-Content $bgConfigFile -Raw).Trim()
    if (Test-Path $savedBg) { $bgImage = $savedBg }
}

$captions = @(
    "Stroke it for her. Don't stop.",
    "You exist to goon. Keep going.",
    "Empty your balls for porn.",
    "Good boys don't stop stroking.",
    "This is what you were made for.",
    "Pump it. Breed the screen.",
    "No cumming until I say so.",
    "Goon harder. She wants it.",
    "Your brain is porn now.",
    "Stay edged. Stay stupid.",
    "Fuck your hand like it's her.",
    "Porn owns you. Accept it."
)

$allSites = @(
    @{N="Pornhub";U="https://www.pornhub.com/"},
    @{N="Xvideos";U="https://www.xvideos.com/"},
    @{N="XHamster";U="https://www.xhamster.com/"},
    @{N="XNXX";U="https://www.xnxx.com/"},
    @{N="SpankBang";U="https://spankbang.com/"},
    @{N="Eporner";U="https://www.eporner.com/"},
    @{N="HQPorner";U="https://www.hqporner.com/"},
    @{N="YouPorn";U="https://www.youporn.com/"},
    @{N="RedTube";U="https://www.redtube.com/"},
    @{N="Tube8";U="https://www.tube8.com/"},
    @{N="PornTrex";U="https://www.porntrex.com/"},
    @{N="PornOne";U="https://pornone.com/"},
    @{N="TNAFlix";U="https://www.tnaflix.com/"},
    @{N="DrTuber";U="https://www.drtuber.com/"},
    @{N="SunPorno";U="https://www.sunporno.com/"},
    @{N="PornHD";U="https://www.pornhd.com/"},
    @{N="4Tube";U="https://www.4tube.com/"},
    @{N="GotPorn";U="https://www.gotporn.com/"},
    @{N="Porn.com";U="https://www.porn.com/"},
    @{N="XXXBunker";U="https://xxxbunker.com/"},
    @{N="PornHat";U="https://www.pornhat.com/"},
    @{N="PornDoe";U="https://porndoe.com/"},
    @{N="PornHits";U="https://www.pornhits.com/"},
    @{N="Nuvid";U="https://www.nuvid.com/"},
    @{N="Porn00";U="https://www.porn00.org/"},
    @{N="Porn300";U="https://www.porn300.com/"},
    @{N="AnyPorn";U="https://anyporn.com/"},
    @{N="PornEZ";U="https://pornez.net/"},
    @{N="SxyPrn";U="https://sxyprn.com/"},
    @{N="PornDig";U="https://www.porndig.com/"},
    @{N="Pornoxo";U="https://www.pornoxo.com/"},
    @{N="Motherless";U="https://www.motherless.com/"},
    @{N="ImageFap";U="https://www.imagefap.com/"},
    @{N="EroMe";U="https://www.erome.com/"},
    @{N="RedGIFs";U="https://www.redgifs.com/"},
    @{N="PornPics";U="https://www.pornpics.com/"},
    @{N="Sex.com";U="https://www.sex.com/"},
    @{N="IXXX";U="https://www.ixxx.com/"},
    @{N="nhentai";U="https://nhentai.net/"},
    @{N="Rule34";U="https://rule34.xxx/"},
    @{N="Hanime";U="https://hanime.tv/"},
    @{N="e-hentai";U="https://e-hentai.org/"},
    @{N="Hitomi";U="https://hitomi.la/"},
    @{N="Gelbooru";U="https://gelbooru.com/"},
    @{N="Danbooru";U="https://danbooru.donmai.us/"},
    @{N="Sankaku";U="https://chan.sankakucomplex.com/"},
    @{N="HentaiHaven";U="https://hentaihaven.xxx/"},
    @{N="9Hentai";U="https://9hentai.to/"},
    @{N="Hentai2Read";U="https://hentai2read.com/"},
    @{N="HentaiFox";U="https://hentaifox.com/"},
    @{N="IMHentai";U="https://imhentai.xxx/"},
    @{N="r/GOONED";U="https://www.reddit.com/r/GOONED/"},
    @{N="r/EverythingGoonCaption";U="https://www.reddit.com/r/EverythingGoonCaption/"},
    @{N="r/pornrelapsed";U="https://www.reddit.com/r/pornrelapsed/"},
    @{N="r/NSFW_GIF";U="https://www.reddit.com/r/NSFW_GIF/"},
    @{N="r/creampies";U="https://www.reddit.com/r/creampies/"},
    @{N="r/cumsluts";U="https://www.reddit.com/r/cumsluts/"},
    @{N="r/freeuse";U="https://www.reddit.com/r/freeuse/"},
    @{N="r/gonewild";U="https://www.reddit.com/r/gonewild/"},
    @{N="r/RealGirls";U="https://www.reddit.com/r/RealGirls/"},
    @{N="r/AsiansGoneWild";U="https://www.reddit.com/r/AsiansGoneWild/"},
    @{N="r/BreedingMaterial";U="https://www.reddit.com/r/BreedingMaterial/"},
    @{N="Chaturbate";U="https://chaturbate.com/"},
    @{N="Stripchat";U="https://stripchat.com/"},
    @{N="BongaCams";U="https://bongacams.com/"},
    @{N="CamSoda";U="https://www.camsoda.com/"},
    @{N="MyFreeCams";U="https://www.myfreecams.com/"},
    @{N="Fansly";U="https://fansly.com/"},
    @{N="ManyVids";U="https://www.manyvids.com/"},
    @{N="Clips4Sale";U="https://www.clips4sale.com/"},
    @{N="XHamster Live";U="https://xhamsterlive.com/"},
    @{N="PornHub Hottest";U="https://www.pornhub.com/video?o=ht"},
    @{N="Xvideos Hottest";U="https://www.xvideos.com/?k=&sort=rating"},
    @{N="SpankBang Trending";U="https://spankbang.com/trending_videos/"},
    @{N="Eporner Top";U="https://www.eporner.com/top/"},
    @{N="HQPorner Top";U="https://hqporner.com/top"},
    @{N="nhentai Popular";U="https://nhentai.net/search/?q=&sort=popular"},
    @{N="Rule34 Popular";U="https://rule34.xxx/index.php?page=post&s=list&tags=all"},
    @{N="Hanime Trending";U="https://hanime.tv/browse"},
    @{N="RedGIFs Explore";U="https://www.redgifs.com/browse"}
)

if (-not (Test-Path $setupDoneFile)) {
    $f = New-Object System.Windows.Forms.Form
    $f.Text = "Setup"; $f.Size = New-Object System.Drawing.Size(520,280); $f.StartPosition = "CenterScreen"
    $f.FormBorderStyle = "FixedDialog"; $f.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
    $l = New-Object System.Windows.Forms.Label
    $l.Text = "Run once in PowerShell:`nSet-ExecutionPolicy RemoteSigned -Scope CurrentUser`n`nThen click Continue."
    $l.ForeColor = [System.Drawing.Color]::White; $l.Location = New-Object System.Drawing.Point(30,40); $l.Size = New-Object System.Drawing.Size(450,100)
    $f.Controls.Add($l)
    $b = New-Object System.Windows.Forms.Button; $b.Text = "Continue"; $b.Location = New-Object System.Drawing.Point(180,180)
    $b.Size = New-Object System.Drawing.Size(140,40); $b.BackColor = [System.Drawing.Color]::FromArgb(0,160,80); $b.ForeColor = [System.Drawing.Color]::White; $b.FlatStyle = "Flat"
    $b.Add_Click({ $f.Close() }); $f.Controls.Add($b); $null = $f.ShowDialog()
    Set-Content $setupDoneFile "done"
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "UltimateGoonerTool V3"
$form.Size = New-Object System.Drawing.Size(1280, 820)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.MinimizeBox = $true

if (Test-Path $windowFile) {
    try {
        $w = Get-Content $windowFile
        if ($w.Count -ge 4) {
            $x = [int]$w[0]; $y = [int]$w[1]; $width = [int]$w[2]; $height = [int]$w[3]
            if ($width -gt 400 -and $height -gt 300) {
                $form.Location = New-Object System.Drawing.Point($x, $y)
                $form.Size = New-Object System.Drawing.Size($width, $height)
            }
        }
    } catch {}
}

if ($isDarkTheme) { $form.BackColor = [System.Drawing.Color]::FromArgb(30,30,30) }
else { $form.BackColor = [System.Drawing.Color]::FromArgb(245,245,245) }

if (Test-Path $bgImage) {
    try {
        $form.BackgroundImage = [System.Drawing.Image]::FromFile($bgImage)
        $form.BackgroundImageLayout = "Stretch"
    } catch {}
}

$sidebar = New-Object System.Windows.Forms.Panel
$sidebar.Location = New-Object System.Drawing.Point(0,0)
$sidebar.Size = New-Object System.Drawing.Size(190,820)
$sidebar.BackColor = [System.Drawing.Color]::FromArgb(0,160,100)
$form.Controls.Add($sidebar)

$lblLogo = New-Object System.Windows.Forms.Label
$lblLogo.Text = "GOONER V3"
$lblLogo.ForeColor = [System.Drawing.Color]::White
$lblLogo.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$lblLogo.Location = New-Object System.Drawing.Point(18,22)
$lblLogo.AutoSize = $true
$sidebar.Controls.Add($lblLogo)

function New-SideBtn($text, $y) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = "  $text"
    $b.Location = New-Object System.Drawing.Point(12,$y)
    $b.Size = New-Object System.Drawing.Size(166,48)
    $b.FlatStyle = "Flat"
    $b.BackColor = [System.Drawing.Color]::FromArgb(0,145,90)
    $b.ForeColor = [System.Drawing.Color]::White
    $b.FlatAppearance.BorderSize = 0
    $b.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(0,190,120)
    $b.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $b.TextAlign = "MiddleLeft"
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $sidebar.Controls.Add($b)
    return $b
}

$btnSideHome     = New-SideBtn "Home (Sites)" 90
$btnSideDownload = New-SideBtn "Download" 150
$btnSideTools    = New-SideBtn "Tools & Sliders" 210
$btnSideFavs     = New-SideBtn "Favorites" 270
$btnSidePrivacy  = New-SideBtn "Privacy Wipe" 330
$btnSideConsole  = New-SideBtn "Console" 390
$btnSideExit     = New-SideBtn "Exit" 740

function New-ContentPanel {
    $p = New-Object System.Windows.Forms.Panel
    $p.Location = New-Object System.Drawing.Point(190,0)
    $p.Size = New-Object System.Drawing.Size(1090,820)
    $p.BackColor = if ($isDarkTheme) { [System.Drawing.Color]::FromArgb(30,30,30) } else { [System.Drawing.Color]::FromArgb(245,245,245) }
    $p.Visible = $false
    $p.AutoScroll = $true
    $form.Controls.Add($p)
    return $p
}

$panelHome     = New-ContentPanel
$panelDownload = New-ContentPanel
$panelTools    = New-ContentPanel
$panelFavs     = New-ContentPanel

$lblHomeTitle = New-Object System.Windows.Forms.Label
$lblHomeTitle.Text = "Working Sites - Click any to open"
$lblHomeTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$lblHomeTitle.ForeColor = if ($isDarkTheme) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::FromArgb(30,30,30) }
$lblHomeTitle.Location = New-Object System.Drawing.Point(20,15)
$lblHomeTitle.AutoSize = $true
$panelHome.Controls.Add($lblHomeTitle)

$flowSites = New-Object System.Windows.Forms.FlowLayoutPanel
$flowSites.Location = New-Object System.Drawing.Point(15,50)
$flowSites.Size = New-Object System.Drawing.Size(1050,700)
$flowSites.AutoScroll = $true
$flowSites.WrapContents = $true
$panelHome.Controls.Add($flowSites)

foreach ($site in $allSites) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $site.N
    $b.Size = New-Object System.Drawing.Size(155,42)
    $b.FlatStyle = "Flat"
    $b.BackColor = if ($isDarkTheme) { [System.Drawing.Color]::FromArgb(50,50,50) } else { [System.Drawing.Color]::White }
    $b.ForeColor = if ($isDarkTheme) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::FromArgb(30,30,30) }
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $b.Tag = $site.U
    $b.Add_Click({
        param($s,$e)
        Open-Browser $s.Tag
        if ($favorites -notcontains $s.Tag) {
            $script:favorites += $s.Tag
            Save-Favorites
        }
    })
    $flowSites.Controls.Add($b)
}

$lblVersion = New-Object System.Windows.Forms.Label
$lblVersion.Text = "v.1.24"
$lblVersion.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblVersion.ForeColor = [System.Drawing.Color]::Black
$lblVersion.BackColor = [System.Drawing.Color]::Transparent
$lblVersion.Location = New-Object System.Drawing.Point(1180, 785)
$lblVersion.AutoSize = $true
$form.Controls.Add($lblVersion)

$lblDL = New-Object System.Windows.Forms.Label
$lblDL.Text = "Download Center - yt-dlp (main) -> gallery-dl (fallback)"
$lblDL.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$lblDL.ForeColor = if ($isDarkTheme) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::FromArgb(30,30,30) }
$lblDL.Location = New-Object System.Drawing.Point(20,15)
$lblDL.AutoSize = $true
$panelDownload.Controls.Add($lblDL)

$lblPath = New-Object System.Windows.Forms.Label
$lblPath.Text = "Current folder: $downloadPath"
$lblPath.ForeColor = if ($isDarkTheme) { [System.Drawing.Color]::LightGray } else { [System.Drawing.Color]::FromArgb(80,80,80) }
$lblPath.Location = New-Object System.Drawing.Point(20,50)
$lblPath.Size = New-Object System.Drawing.Size(900,22)
$panelDownload.Controls.Add($lblPath)

function New-CardPanel($x,$y,$w,$h,$col,$title) {
    $p = New-Object System.Windows.Forms.Panel
    $p.Location = New-Object System.Drawing.Point($x,$y)
    $p.Size = New-Object System.Drawing.Size($w,$h)
    $p.BackColor = $col
    $panelDownload.Controls.Add($p)
    $t = New-Object System.Windows.Forms.Label
    $t.Text = $title; $t.ForeColor = [System.Drawing.Color]::White
    $t.Font = New-Object System.Drawing.Font("Segoe UI",13,[System.Drawing.FontStyle]::Bold)
    $t.Location = New-Object System.Drawing.Point(18,16); $t.AutoSize = $true
    $p.Controls.Add($t)
    return $p
}

$c1 = New-CardPanel 20 90 320 140 ([System.Drawing.Color]::FromArgb(255,140,40)) "Full Goon Session"
$c2 = New-CardPanel 360 90 320 140 ([System.Drawing.Color]::FromArgb(0,170,110)) "Single URL Download"
$c3 = New-CardPanel 700 90 320 140 ([System.Drawing.Color]::FromArgb(40,120,220)) "Queue + Local"

$btnFull = New-Object System.Windows.Forms.Button
$btnFull.Text = "Launch Random Sites"; $btnFull.Location = New-Object System.Drawing.Point(18,80)
$btnFull.Size = New-Object System.Drawing.Size(200,36); $btnFull.FlatStyle = "Flat"
$btnFull.BackColor = [System.Drawing.Color]::White; $btnFull.ForeColor = [System.Drawing.Color]::FromArgb(30,30,30)
$c1.Controls.Add($btnFull)

$btnOneUrl = New-Object System.Windows.Forms.Button
$btnOneUrl.Text = "Paste URL ->"; $btnOneUrl.Location = New-Object System.Drawing.Point(18,80)
$btnOneUrl.Size = New-Object System.Drawing.Size(180,36); $btnOneUrl.FlatStyle = "Flat"
$btnOneUrl.BackColor = [System.Drawing.Color]::White; $btnOneUrl.ForeColor = [System.Drawing.Color]::FromArgb(30,30,30)
$c2.Controls.Add($btnOneUrl)

$btnQueue = New-Object System.Windows.Forms.Button
$btnQueue.Text = "Multi-URL Queue"; $btnQueue.Location = New-Object System.Drawing.Point(18,80)
$btnQueue.Size = New-Object System.Drawing.Size(180,36); $btnQueue.FlatStyle = "Flat"
$btnQueue.BackColor = [System.Drawing.Color]::White; $btnQueue.ForeColor = [System.Drawing.Color]::FromArgb(30,30,30)
$c3.Controls.Add($btnQueue)

$btnOpenFold = New-Object System.Windows.Forms.Button
$btnOpenFold.Text = "Open Download Folder"; $btnOpenFold.Location = New-Object System.Drawing.Point(20,260)
$btnOpenFold.Size = New-Object System.Drawing.Size(200,40); $btnOpenFold.FlatStyle = "Flat"
$btnOpenFold.BackColor = [System.Drawing.Color]::FromArgb(40,40,40); $btnOpenFold.ForeColor = [System.Drawing.Color]::White
$panelDownload.Controls.Add($btnOpenFold)

$btnPlay = New-Object System.Windows.Forms.Button
$btnPlay.Text = "Play Latest Video"; $btnPlay.Location = New-Object System.Drawing.Point(240,260)
$btnPlay.Size = New-Object System.Drawing.Size(180,40); $btnPlay.FlatStyle = "Flat"
$btnPlay.BackColor = [System.Drawing.Color]::FromArgb(40,40,40); $btnPlay.ForeColor = [System.Drawing.Color]::White
$panelDownload.Controls.Add($btnPlay)

$btnChangeFold = New-Object System.Windows.Forms.Button
$btnChangeFold.Text = "Change Download Folder"; $btnChangeFold.Location = New-Object System.Drawing.Point(440,260)
$btnChangeFold.Size = New-Object System.Drawing.Size(200,40); $btnChangeFold.FlatStyle = "Flat"
$btnChangeFold.BackColor = [System.Drawing.Color]::FromArgb(40,40,40); $btnChangeFold.ForeColor = [System.Drawing.Color]::White
$panelDownload.Controls.Add($btnChangeFold)

$btnConvert = New-Object System.Windows.Forms.Button
$btnConvert.Text = "Convert Videos to MP4"; $btnConvert.Location = New-Object System.Drawing.Point(660,260)
$btnConvert.Size = New-Object System.Drawing.Size(180,40); $btnConvert.FlatStyle = "Flat"
$btnConvert.BackColor = [System.Drawing.Color]::FromArgb(180,80,20); $btnConvert.ForeColor = [System.Drawing.Color]::White
$panelDownload.Controls.Add($btnConvert)

$btnInstallYtdlp = New-Object System.Windows.Forms.Button
$btnInstallYtdlp.Text = "Install yt-dlp"; $btnInstallYtdlp.Location = New-Object System.Drawing.Point(20,320)
$btnInstallYtdlp.Size = New-Object System.Drawing.Size(160,40); $btnInstallYtdlp.FlatStyle = "Flat"
$btnInstallYtdlp.BackColor = [System.Drawing.Color]::FromArgb(30,100,180); $btnInstallYtdlp.ForeColor = [System.Drawing.Color]::White
$panelDownload.Controls.Add($btnInstallYtdlp)

$btnInstallGallery = New-Object System.Windows.Forms.Button
$btnInstallGallery.Text = "Install gallery-dl"; $btnInstallGallery.Location = New-Object System.Drawing.Point(200,320)
$btnInstallGallery.Size = New-Object System.Drawing.Size(160,40); $btnInstallGallery.FlatStyle = "Flat"
$btnInstallGallery.BackColor = [System.Drawing.Color]::FromArgb(30,100,180); $btnInstallGallery.ForeColor = [System.Drawing.Color]::White
$panelDownload.Controls.Add($btnInstallGallery)

$lblTools = New-Object System.Windows.Forms.Label
$lblTools.Text = "Tools, Sliders & Session Controls"
$lblTools.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$lblTools.ForeColor = if ($isDarkTheme) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::FromArgb(30,30,30) }
$lblTools.Location = New-Object System.Drawing.Point(20,15)
$lblTools.AutoSize = $true
$panelTools.Controls.Add($lblTools)

$lblHorny = New-Object System.Windows.Forms.Label
$lblHorny.Text = "Horny Level: $hornyLevel"
$lblHorny.ForeColor = [System.Drawing.Color]::FromArgb(220,40,90)
$lblHorny.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$lblHorny.Location = New-Object System.Drawing.Point(20,60)
$lblHorny.AutoSize = $true
$panelTools.Controls.Add($lblHorny)

$slider = New-Object System.Windows.Forms.TrackBar
$slider.Minimum = 1; $slider.Maximum = 5; $slider.Value = $hornyLevel
$slider.Location = New-Object System.Drawing.Point(20,90); $slider.Size = New-Object System.Drawing.Size(280,45)
$slider.Add_ValueChanged({
    $script:hornyLevel = $slider.Value
    $lblHorny.Text = "Horny Level: $($slider.Value)"
    Save-Settings
})
$panelTools.Controls.Add($slider)

$btnLight = New-Object System.Windows.Forms.Button
$btnLight.Text = "Light"; $btnLight.Location = New-Object System.Drawing.Point(320,95)
$btnLight.Size = New-Object System.Drawing.Size(80,35); $btnLight.FlatStyle = "Flat"
$btnLight.BackColor = [System.Drawing.Color]::FromArgb(0,150,90); $btnLight.ForeColor = [System.Drawing.Color]::White
$panelTools.Controls.Add($btnLight)

$btnNormal = New-Object System.Windows.Forms.Button
$btnNormal.Text = "Normal"; $btnNormal.Location = New-Object System.Drawing.Point(410,95)
$btnNormal.Size = New-Object System.Drawing.Size(80,35); $btnNormal.FlatStyle = "Flat"
$btnNormal.BackColor = [System.Drawing.Color]::FromArgb(0,150,90); $btnNormal.ForeColor = [System.Drawing.Color]::White
$panelTools.Controls.Add($btnNormal)

$btnHeavy = New-Object System.Windows.Forms.Button
$btnHeavy.Text = "Heavy"; $btnHeavy.Location = New-Object System.Drawing.Point(500,95)
$btnHeavy.Size = New-Object System.Drawing.Size(80,35); $btnHeavy.FlatStyle = "Flat"
$btnHeavy.BackColor = [System.Drawing.Color]::FromArgb(0,150,90); $btnHeavy.ForeColor = [System.Drawing.Color]::White
$panelTools.Controls.Add($btnHeavy)

$chkAuto = New-Object System.Windows.Forms.CheckBox
$chkAuto.Text = "Auto-clear browsers + clipboard on Exit"
$chkAuto.ForeColor = if ($isDarkTheme) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::Black }
$chkAuto.Location = New-Object System.Drawing.Point(20,150); $chkAuto.AutoSize = $true
$chkAuto.Checked = $autoClearOnExit
$chkAuto.Add_CheckedChanged({ $script:autoClearOnExit = $chkAuto.Checked; Save-Settings })
$panelTools.Controls.Add($chkAuto)

$chkTheme = New-Object System.Windows.Forms.CheckBox
$chkTheme.Text = "Dark Theme (restart to fully apply)"
$chkTheme.ForeColor = if ($isDarkTheme) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::Black }
$chkTheme.Location = New-Object System.Drawing.Point(20,180); $chkTheme.AutoSize = $true
$chkTheme.Checked = $isDarkTheme
$panelTools.Controls.Add($chkTheme)

$chkStartup = New-Object System.Windows.Forms.CheckBox
$chkStartup.Text = "Start with Windows"
$chkStartup.ForeColor = if ($isDarkTheme) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::Black }
$chkStartup.Location = New-Object System.Drawing.Point(20,210); $chkStartup.AutoSize = $true
$chkStartup.Checked = $startWithWindows
$panelTools.Controls.Add($chkStartup)

$btnSetBrowser = New-Object System.Windows.Forms.Button
$btnSetBrowser.Text = "Set Preferred Browser"
$btnSetBrowser.Location = New-Object System.Drawing.Point(20,250)
$btnSetBrowser.Size = New-Object System.Drawing.Size(200,40)
$btnSetBrowser.FlatStyle = "Flat"
$btnSetBrowser.BackColor = [System.Drawing.Color]::FromArgb(30,100,180)
$btnSetBrowser.ForeColor = [System.Drawing.Color]::White
$panelTools.Controls.Add($btnSetBrowser)

function New-Tool($text,$x,$y,$w=190) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text; $b.Location = New-Object System.Drawing.Point($x,$y)
    $b.Size = New-Object System.Drawing.Size($w,42); $b.FlatStyle = "Flat"
    $b.BackColor = [System.Drawing.Color]::FromArgb(35,35,35); $b.ForeColor = [System.Drawing.Color]::White
    $b.FlatAppearance.BorderSize = 0
    $b.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(0,160,100)
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $panelTools.Controls.Add($b)
    return $b
}

$btnGoonTo    = New-Tool "Force Goon To" 20 310
$btnChallenge = New-Tool "Daily Goon Challenge" 230 310
$btnCaption   = New-Tool "Random Caption" 440 310
$btnSpin      = New-Tool "Spin the Wheel" 650 310
$btnTimer     = New-Tool "Edge Timer" 860 310

$btnSearch    = New-Tool "Multi-Site Search" 20 370
$btnPerformer = New-Tool "Favorite Performer" 230 370
$btnDupes     = New-Tool "Duplicate Cleaner" 440 370
$btnLog       = New-Tool "Session Logger" 650 370
$btnLast      = New-Tool "Open Last Session" 860 370

$btnCloseAll  = New-Tool "Close All Browsers" 20 430 220
$btnBg        = New-Tool "Change Background" 260 430 200
$btnUpdate    = New-Tool "Check for Updates" 480 430 200
$btnDebugger  = New-Tool "Debugger" 700 430 160
$btnConsole   = New-Tool "Console" 880 430 150

$lblFav = New-Object System.Windows.Forms.Label
$lblFav.Text = "Your Favorites"
$lblFav.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$lblFav.ForeColor = if ($isDarkTheme) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::FromArgb(30,30,30) }
$lblFav.Location = New-Object System.Drawing.Point(20,15)
$lblFav.AutoSize = $true
$panelFavs.Controls.Add($lblFav)

$flowFavs = New-Object System.Windows.Forms.FlowLayoutPanel
$flowFavs.Location = New-Object System.Drawing.Point(15,50)
$flowFavs.Size = New-Object System.Drawing.Size(1050,700)
$flowFavs.AutoScroll = $true
$flowFavs.WrapContents = $true
$panelFavs.Controls.Add($flowFavs)

function Refresh-Favorites {
    $flowFavs.Controls.Clear()
    foreach ($fav in $favorites) {
        $b = New-Object System.Windows.Forms.Button
        $b.Text = $fav
        $b.Size = New-Object System.Drawing.Size(220,40)
        $b.FlatStyle = "Flat"
        $b.BackColor = if ($isDarkTheme) { [System.Drawing.Color]::FromArgb(50,50,50) } else { [System.Drawing.Color]::White }
        $b.ForeColor = if ($isDarkTheme) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::FromArgb(30,30,30) }
        $b.Tag = $fav
        $b.Add_Click({ param($s,$e) Open-Browser $s.Tag })
        $flowFavs.Controls.Add($b)
    }
}

$btnFull.Add_Click({
    $input = [Microsoft.VisualBasic.Interaction]::InputBox(
        "How many random sites do you want to open?`n`n(Recommended: 10 - 40)",
        "Full Goon Session",
        "20"
    )
    if ($input -notmatch '^\d+$') {
        [System.Windows.Forms.MessageBox]::Show("Please enter a valid number.")
        return
    }
    $count = [int]$input
    if ($count -lt 1) {
        [System.Windows.Forms.MessageBox]::Show("Number must be at least 1.")
        return
    }
    if ($count -gt $allSites.Count) {
        $count = $allSites.Count
        [System.Windows.Forms.MessageBox]::Show("Only $($allSites.Count) sites available. Opening all of them.")
    }
    $randomSites = $allSites | Get-Random -Count $count
    $urls = $randomSites | ForEach-Object { $_.U }
    foreach ($u in $urls) {
        Open-Browser $u
        Start-Sleep -Milliseconds 300
    }
    Start-Process $downloadPath
    Save-LastSession $urls
    Write-Log "Full Goon Session - $count unique random sites"
})

$btnOneUrl.Add_Click({
    $url = [Microsoft.VisualBasic.Interaction]::InputBox("Paste any video or gallery link:","Download")
    if ([string]::IsNullOrWhiteSpace($url)) { return }

    if (-not (Test-GalleryDL)) {
        if (-not (Show-GalleryWarning)) { return }
    }

    Show-CookiesSetupPrompt

    $cookieBrowser = Get-CookieBrowserName

    $expected = Get-GalleryDlExpectedCount -Url $url -CookieBrowser $cookieBrowser
    if ($expected -le 0) { $expected = 0 }

    $cookiesFile = Join-Path $configDir "cookies.txt"
    $cmd = @"
L "URL: $url"
L "Dest: $downloadPath"
L "Cookies file: $cookiesFile"
L "Expected items: $expected"
Set-Location -LiteralPath '$downloadPath'
L "cwd now: `$(Get-Location)"
if (Get-Command gallery-dl -ErrorAction SilentlyContinue) {
    L 'Running: gallery-dl -D . --cookies "$cookiesFile" "$url"'
    & gallery-dl -D . --cookies "$cookiesFile" "$url"
} else {
    L 'Running: python -m gallery_dl -D . --cookies "$cookiesFile" "$url"'
    & python -m gallery_dl -D . --cookies "$cookiesFile" "$url"
}
if (`$LASTEXITCODE -ne 0) {
    L 'Retry without cookies...'
    if (Get-Command gallery-dl -ErrorAction SilentlyContinue) {
        & gallery-dl -D . "$url"
    } else {
        & python -m gallery_dl -D . "$url"
    }
}
if (`$LASTEXITCODE -ne 0 -and (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
    L 'Fallback yt-dlp...'
    & yt-dlp -f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/best" -o "%(title)s.%(ext)s" "$url"
}
L "Done exit=`$LASTEXITCODE"
"@

    $status = if ($expected -gt 0) { "Downloading 0 / $expected" } else { "Downloading..." }
    Start-HiddenDownload -Command $cmd -StatusText $status -WatchFolder $downloadPath -ExpectedTotal $expected
    Write-Log "Single URL download: $url (cookies=$cookieBrowser expected=$expected)"
})

$btnQueue.Add_Click({
    $input = [Microsoft.VisualBasic.Interaction]::InputBox("Paste multiple links (one per line):","Queue")
    if ([string]::IsNullOrWhiteSpace($input)) { return }
    $urls = @($input -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ($urls.Count -eq 0) { return }

    if (-not (Test-GalleryDL)) {
        if (-not (Show-GalleryWarning)) { return }
    }

    Show-CookiesSetupPrompt

    $cookieBrowser = Get-CookieBrowserName
    $total = $urls.Count
    $n = 0
    foreach ($u in $urls) {
        $n++
        $expected = Get-GalleryDlExpectedCount -Url $u -CookieBrowser $cookieBrowser
        $cookiesFile = Join-Path $configDir "cookies.txt"
        $cmd = @"
L "QUEUE $n / $total"
L "URL: $u"
L "Cookies file: $cookiesFile"
Set-Location -LiteralPath '$downloadPath'
L "cwd now: `$(Get-Location)"
if (Get-Command gallery-dl -ErrorAction SilentlyContinue) {
    L 'Running: gallery-dl -D . --cookies "$cookiesFile" "$u"'
    & gallery-dl -D . --cookies "$cookiesFile" "$u"
} else {
    & python -m gallery_dl -D . --cookies "$cookiesFile" "$u"
}
if (`$LASTEXITCODE -ne 0) {
    if (Get-Command gallery-dl -ErrorAction SilentlyContinue) {
        & gallery-dl -D . "$u"
    } else {
        & python -m gallery_dl -D . "$u"
    }
}
L "Item done exit=`$LASTEXITCODE"
"@
        $status = if ($expected -gt 0) { "Queue $n/$total (0 / $expected)" } else { "Queue $n of $total" }
        Start-HiddenDownload -Command $cmd -StatusText $status -WatchFolder $downloadPath -ExpectedTotal $expected
        Write-Log "Queue download $n/$total : $u expected=$expected"
    }
    [System.Windows.Forms.MessageBox]::Show("Queue finished. Processed $total link(s).")
})

$btnOpenFold.Add_Click({ Start-Process $downloadPath })
$btnPlay.Add_Click({
    $f = Get-ChildItem "$downloadPath\*.*" -Include *.mp4,*.m4v,*.mkv,*.webm -ErrorAction SilentlyContinue | Sort LastWriteTime -Desc | Select -First 1
    if ($f) { Start-Process $f.FullName } else { [System.Windows.Forms.MessageBox]::Show("No videos found") }
})
$btnChangeFold.Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($fbd.ShowDialog() -eq "OK") {
        $script:downloadPath = $fbd.SelectedPath
        Set-Content $configFile $script:downloadPath
        $lblPath.Text = "Current folder: $script:downloadPath"
    }
})

$btnConvert.Add_Click({ Show-ConvertDialog })

$btnInstallYtdlp.Add_Click({
    Start-Process powershell -ArgumentList "-NoExit","-Command","python -m pip install -U yt-dlp; Write-Host ''; Write-Host 'Done. You can close this window.'; pause"
})
$btnInstallGallery.Add_Click({
    Start-Process powershell -ArgumentList "-NoExit","-Command","python -m pip install -U gallery-dl; Write-Host ''; Write-Host 'Done. You can close this window.'; pause"
})

$btnLight.Add_Click({ $slider.Value = 1 })
$btnNormal.Add_Click({ $slider.Value = 3 })
$btnHeavy.Add_Click({ $slider.Value = 5 })

$chkTheme.Add_CheckedChanged({
    $script:isDarkTheme = $chkTheme.Checked
    Save-Settings
    [System.Windows.Forms.MessageBox]::Show("Theme saved. Restart the tool for full effect.")
})

$chkStartup.Add_CheckedChanged({
    $script:startWithWindows = $chkStartup.Checked
    Save-Settings
    $startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\UltimateGoonerTool.lnk"
    if ($startWithWindows) {
        $wsh = New-Object -ComObject WScript.Shell
        $sc = $wsh.CreateShortcut($startupPath)
        $sc.TargetPath = "powershell.exe"
        $sc.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        $sc.Save()
    } else {
        if (Test-Path $startupPath) { Remove-Item $startupPath -Force }
    }
})

$btnSetBrowser.Add_Click({
    $msg = "Enter browser executable name or full path:`n`nExamples:`nchrome`nfirefox`nmsedge`nbrave`nopera`n`nOr full path like:`nC:\Program Files\Google\Chrome\Application\chrome.exe`n`nLeave empty to use system default."
    $input = [Microsoft.VisualBasic.Interaction]::InputBox($msg, "Set Preferred Browser", $preferredBrowser)
    if ($input -ne $null) {
        $script:preferredBrowser = $input.Trim()
        if ([string]::IsNullOrWhiteSpace($script:preferredBrowser)) {
            $script:preferredBrowser = $null
            if (Test-Path $browserFile) { Remove-Item $browserFile -Force }
            [System.Windows.Forms.MessageBox]::Show("Browser set to system default.")
        } else {
            Set-Content $browserFile $script:preferredBrowser
            [System.Windows.Forms.MessageBox]::Show("Browser set to:`n$script:preferredBrowser")
        }
    }
})

$btnUpdate.Add_Click({
    Open-Browser "https://github.com/Nuuci/UltimateGoonerTool-V3"
    [System.Windows.Forms.MessageBox]::Show("Opened GitHub page.")
})

$btnDebugger.Add_Click({
    $debugFile = Join-Path $configDir "debug_log.txt"
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("========== DEBUG DUMP $ts ==========")
    $lines.Add("")
    $lines.Add("--- Environment ---")
    $lines.Add("PSVersion: $($PSVersionTable.PSVersion)")
    $lines.Add("OS: $([Environment]::OSVersion.VersionString)")
    $lines.Add("User: $env:USERNAME")
    $lines.Add("Machine: $env:COMPUTERNAME")
    $lines.Add("Script: $PSCommandPath")
    $lines.Add("WorkingDir: $(Get-Location)")
    $lines.Add("")
    $lines.Add("--- Paths ---")
    $lines.Add("configDir: $configDir (exists=$(Test-Path $configDir))")
    $lines.Add("downloadPath: $downloadPath (exists=$(Test-Path $downloadPath))")
    $lines.Add("configFile: $configFile (exists=$(Test-Path $configFile))")
    $lines.Add("settingsFile: $settingsFile (exists=$(Test-Path $settingsFile))")
    $lines.Add("logFile: $logFile (exists=$(Test-Path $logFile))")
    $lines.Add("bgImage: $bgImage (exists=$(Test-Path $bgImage))")
    $lines.Add("")
    $lines.Add("--- Settings ---")
    $lines.Add("autoClearOnExit=$autoClearOnExit")
    $lines.Add("hornyLevel=$hornyLevel")
    $lines.Add("isDarkTheme=$isDarkTheme")
    $lines.Add("startWithWindows=$startWithWindows")
    $lines.Add("suppressGalleryWarning=$suppressGalleryWarning")
    $lines.Add("suppressFfmpegWarning=$suppressFfmpegWarning")
    $lines.Add("preferredBrowser=$preferredBrowser")
    $lines.Add("")
    $lines.Add("--- Tool Detection ---")
    $hasY = Test-Ytdlp
    $hasG = Test-GalleryDL
    $hasF = Test-FFmpeg
    $lines.Add("yt-dlp found: $hasY")
    $lines.Add("gallery-dl found: $hasG")
    $lines.Add("ffmpeg found: $hasF")
    $lines.Add("ffmpegPath: $script:ffmpegPath")
    try {
        $whereFf = & where.exe ffmpeg 2>$null
        $lines.Add("where.exe ffmpeg: $($whereFf -join ' | ')")
    } catch { $lines.Add("where.exe ffmpeg: failed") }
    try {
        $whereY = & where.exe yt-dlp 2>$null
        $lines.Add("where.exe yt-dlp: $($whereY -join ' | ')")
    } catch { $lines.Add("where.exe yt-dlp: failed") }
    $lines.Add("")
    $lines.Add("--- Download Folder Contents (top 50) ---")
    if (Test-Path $downloadPath) {
        try {
            $dlFiles = Get-ChildItem $downloadPath -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 50
            $lines.Add("Total files listed: $($dlFiles.Count)")
            foreach ($df in $dlFiles) {
                $lines.Add("  $($df.Name) | $($df.Length) bytes | $($df.LastWriteTime)")
            }
        } catch { $lines.Add("Error listing download folder: $_") }
    } else {
        $lines.Add("Download folder missing.")
    }
    $lines.Add("")
    $lines.Add("--- Favorites count ---")
    $lines.Add("favorites: $($favorites.Count)")
    $lines.Add("")
    $lines.Add("--- PATH (truncated) ---")
    $lines.Add(($env:PATH -split ';' | Select-Object -First 30) -join "`n")
    $lines.Add("")
    $lines.Add("--- Last session log tail ---")
    if (Test-Path $logFile) {
        try {
            $tail = Get-Content $logFile -Tail 20 -ErrorAction SilentlyContinue
            $lines.Add(($tail -join "`n"))
        } catch { $lines.Add("Could not read log: $_") }
    } else {
        $lines.Add("(no session log)")
    }
    $lines.Add("")
    $lines.Add("========== END DUMP ==========")
    $lines.Add("")

    try {
        Add-Content -Path $debugFile -Value ($lines -join "`r`n") -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("Debug log written to:`n$debugFile","Debugger")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to write debug log:`n$_","Debugger Error")
    }
})

$btnGoonTo.Add_Click({
    $files = Get-ChildItem "$downloadPath\*.*" -Include *.mp4,*.m4v,*.mkv -ErrorAction SilentlyContinue
    if ($files -and (Get-Random -Max 2) -eq 0) {
        Start-Process (Get-Random $files).FullName
        [System.Windows.Forms.MessageBox]::Show("GOON TO THIS VIDEO.")
    } else {
        $intense = @("https://www.redgifs.com/","https://www.pornhub.com/","https://spankbang.com/","https://www.reddit.com/r/GOONED/")
        Open-Browser (Get-Random $intense)
        [System.Windows.Forms.MessageBox]::Show("GOON TO THIS.")
    }
})

$btnChallenge.Add_Click({
    $ch = @("Edge 20 min no cum.","Open 5 sites, 3 min each.","GIFs only today.","Non-dominant hand only.","New performer only.","Stroke to a song.","No touch 10 min then goon hard.","Local videos only.","Write a caption then goon to it.","45 min continuous goon.")
    $c = $ch[(Get-Date).DayOfYear % $ch.Count]
    [System.Windows.Forms.MessageBox]::Show("DAILY GOON CHALLENGE`n`n$c")
})

$btnCaption.Add_Click({ [System.Windows.Forms.MessageBox]::Show((Get-Random $captions),"Caption") })

$btnSpin.Add_Click({
    $opts = @("Local Video","Pornhub","RedGIFs","SpankBang","r/GOONED","nhentai","Erome","Random Tag")
    $p = Get-Random $opts
    switch ($p) {
        "Local Video" { $f = Get-ChildItem "$downloadPath\*.*" -Include *.mp4,*.m4v -ErrorAction SilentlyContinue; if ($f) { Start-Process (Get-Random $f).FullName } }
        "Pornhub" { Open-Browser "https://www.pornhub.com/" }
        "RedGIFs" { Open-Browser "https://www.redgifs.com/" }
        "SpankBang" { Open-Browser "https://spankbang.com/" }
        "r/GOONED" { Open-Browser "https://www.reddit.com/r/GOONED/" }
        "nhentai" { Open-Browser "https://nhentai.net/" }
        "Erome" { Open-Browser "https://www.erome.com/" }
        "Random Tag" { Open-Browser "https://www.pornhub.com/video/search?search=$((Get-Random @('creampie','freeuse','ahegao','breeding','goon')))" }
    }
    [System.Windows.Forms.MessageBox]::Show("Landed on: $p")
})

$btnTimer.Add_Click({
    $m = [Microsoft.VisualBasic.Interaction]::InputBox("Minutes:","Edge Timer","30")
    if ($m -match '^\d+$') {
        Start-Sleep ([int]$m * 60)
        [System.Windows.Forms.MessageBox]::Show("TIME IS UP - STOP")
    }
})

$btnSearch.Add_Click({
    $q = [Microsoft.VisualBasic.Interaction]::InputBox("Keyword:","Multi Search")
    if ($q) {
        $q = $q -replace " ","+"
        @("https://www.pornhub.com/video/search?search=$q","https://www.xvideos.com/?k=$q","https://spankbang.com/s/$q","https://www.redgifs.com/browse?q=$q","https://nhentai.net/search/?q=$q","https://www.reddit.com/search/?q=$q") | % { Open-Browser $_ }
    }
})

$btnPerformer.Add_Click({
    $n = [Microsoft.VisualBasic.Interaction]::InputBox("Performer name:","Search")
    if ($n) {
        $q = $n -replace " ","+"
        Open-Browser "https://www.pornhub.com/video/search?search=$q"
        Open-Browser "https://www.xvideos.com/?k=$q"
        Open-Browser "https://spankbang.com/s/$q"
    }
})

$btnDupes.Add_Click({
    if ([System.Windows.Forms.MessageBox]::Show("Permanently delete duplicates?","Warning","YesNo") -ne "Yes") { return }
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog; $fbd.SelectedPath = $downloadPath
    if ($fbd.ShowDialog() -eq "OK") {
        $files = Get-ChildItem $fbd.SelectedPath -File -EA SilentlyContinue
        $norm = @{}; $del = @()
        foreach ($f in $files) {
            $clean = if ($f.BaseName -match '^(.*) \(\d+\)$') { $Matches[1] } else { $f.BaseName }
            $key = "$clean$($f.Extension)".ToLower()
            if (-not $norm.ContainsKey($key)) { $norm[$key] = @() }
            $norm[$key] += $f
        }
        foreach ($g in $norm.Values) {
            if ($g.Count -gt 1) {
                $orig = $g | ? { $_.BaseName -notmatch ' \(\d+\)$' } | Select -First 1
                if (-not $orig) { $orig = $g[0] }
                $del += $g | ? { $_.FullName -ne $orig.FullName }
            }
        }
        $cnt = 0; foreach ($d in $del) { try { Remove-Item $d.FullName -Force; $cnt++ } catch {} }
        [System.Windows.Forms.MessageBox]::Show("Deleted $cnt duplicates")
    }
})

$btnLog.Add_Click({
    $lf = New-Object System.Windows.Forms.Form; $lf.Text = "Session Log"; $lf.Size = New-Object System.Drawing.Size(700,500); $lf.StartPosition = "CenterScreen"
    $lf.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
    $tb = New-Object System.Windows.Forms.TextBox; $tb.Multiline = $true; $tb.ScrollBars = "Vertical"; $tb.ReadOnly = $true
    $tb.Dock = "Fill"; $tb.BackColor = [System.Drawing.Color]::FromArgb(15,15,15); $tb.ForeColor = [System.Drawing.Color]::FromArgb(0,220,100)
    $tb.Font = New-Object System.Drawing.Font("Consolas",10)
    if (Test-Path $logFile) { $tb.Text = Get-Content $logFile -Raw } else { $tb.Text = "Empty" }
    $lf.Controls.Add($tb); $null = $lf.ShowDialog()
})

$btnLast.Add_Click({
    if (Test-Path $lastSession) {
        Get-Content $lastSession | % { Open-Browser $_ }
        [System.Windows.Forms.MessageBox]::Show("Last session restored")
    } else { [System.Windows.Forms.MessageBox]::Show("No last session") }
})

$btnCloseAll.Add_Click({
    "chrome","msedge","firefox","brave","opera","opera_gx","vivaldi" | % { taskkill /F /IM "$_.exe" /T 2>$null | Out-Null }
    [System.Windows.Forms.MessageBox]::Show("All browsers closed")
})

$btnBg.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Images|*.jpg;*.jpeg;*.png;*.bmp"
    if ($ofd.ShowDialog() -eq "OK") {
        $newBg = Join-Path $configDir "custom_background.jpg"
        Copy-Item $ofd.FileName $newBg -Force
        Set-Content $bgConfigFile $newBg
        try {
            if ($form.BackgroundImage) { $form.BackgroundImage.Dispose() }
            $form.BackgroundImage = [System.Drawing.Image]::FromFile($newBg)
            $form.BackgroundImageLayout = "Stretch"
        } catch {}
        [System.Windows.Forms.MessageBox]::Show("Background applied!")
    }
})

$form.Add_FormClosing({
    if ($form.WindowState -ne "Minimized") {
        try {
            "$($form.Location.X)`n$($form.Location.Y)`n$($form.Size.Width)`n$($form.Size.Height)" | Set-Content $windowFile
        } catch {}
    }
    if ($autoClearOnExit) {
        "chrome","msedge","firefox","brave" | % { taskkill /F /IM "$_.exe" /T 2>$null | Out-Null }
        try { Set-Clipboard $null } catch {}
    }
})

function Show-Panel($p) {
    $panelHome.Visible = $false
    $panelDownload.Visible = $false
    $panelTools.Visible = $false
    $panelFavs.Visible = $false
    $p.Visible = $true
    $p.BringToFront()
}

function Show-CookiesSetupPrompt {
    $cookiesFile = Join-Path $configDir "cookies.txt"
    if (Test-Path $cookiesFile) { return }

    $msg = @"
cookies.txt is not set up.

Without it you will only be able to download from public sites.
Login-required sites (Luscious members, many galleries, etc.) will fail.

Do you want to set up cookies.txt right now?
"@
    $r = [System.Windows.Forms.MessageBox]::Show(
        $msg,
        "Cookies Setup Needed",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
    if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    # Open the folder
    try { Start-Process explorer.exe $configDir } catch {}

    # Create and open instructions notepad
    $instrPath = Join-Path $configDir "HOW_TO_SETUP_COOKIES.txt"
    $instructions = @"
HOW TO SET UP cookies.txt FOR UltimateGoonerTool
================================================

1. Install the Cookie Exporter Chrome extension:
   https://chromewebstore.google.com/detail/cookie-exporter/fhnmmidekmgocpjdceeffppcodigillk?hl=en

2. Go to the site you want (example: https://members.luscious.net) and LOG IN.

3. Click the Cookie Exporter extension icon.

4. Set Export Format to: Netscape

5. Click Export / Download.

6. Move or save the downloaded file into this exact folder:
   $configDir

7. Rename the file to exactly: cookies.txt
   (must be named cookies.txt - no extra numbers or extensions)

8. Close this UltimateGoonerTool completely and reopen it.

After that, downloads from login-required sites should work.

You can delete this HOW_TO_SETUP_COOKIES.txt file once you are done.
"@
    try {
        Set-Content -Path $instrPath -Value $instructions -Encoding UTF8
        Start-Process notepad.exe $instrPath
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Could not create instructions file.`nJust put cookies.txt in:`n$configDir")
    }
}

$btnSideHome.Add_Click({ Show-Panel $panelHome })
$btnSideDownload.Add_Click({ Show-CookiesSetupPrompt; Show-Panel $panelDownload })
$btnSideTools.Add_Click({ Show-Panel $panelTools })
$btnSideFavs.Add_Click({ Refresh-Favorites; Show-Panel $panelFavs })

function Show-AppConsole {
    try {
        if ($consolePtr -and $consolePtr -ne [IntPtr]::Zero) {
            [Console.Window]::ShowWindow($consolePtr, 5) | Out-Null
            [Console.Window]::ShowWindow($consolePtr, 9) | Out-Null
        }
    } catch {}
    Write-Host ""
    Write-Host "========== ULTIMATE GOONER TOOL CONSOLE =========="
    Write-Host "Download folder: $downloadPath"
    Write-Host "Config folder:   $configDir"
    Write-Host "Cookie browser:  $(Get-CookieBrowserName)"
    Write-Host "yt-dlp:          $(Test-Ytdlp)"
    Write-Host "gallery-dl:      $(Test-GalleryDL)"
    Write-Host "ffmpeg:          $(Test-FFmpeg)  path=$script:ffmpegPath"
    Write-Host "Log file:        $logFile"
    Write-Host "=================================================="
    Write-Host "Tip: leave this window open to see download errors."
    Write-Host ""
    $helpCmd = @"
Write-Host 'UGT Troubleshooting Shell' -ForegroundColor Green
Write-Host "cd to download folder..."
Set-Location -LiteralPath '$downloadPath'
Write-Host "Current: `$(Get-Location)"
Write-Host ''
Write-Host 'Useful commands:'
Write-Host '  yt-dlp -f best -o "%(title)s.%(ext)s" "URL"'
Write-Host '  gallery-dl -D . --cookies (Documents\ULTIMATE GOONER TOOL v5\cookies.txt) "URL"'
Write-Host '  gallery-dl -D . "URL"'
Write-Host '  Get-Command yt-dlp, gallery-dl, ffmpeg'
Write-Host ''
"@
    $tmpHelp = Join-Path $env:TEMP "ugt_console_help.ps1"
    try {
        Write-Utf8NoBom -Path $tmpHelp -Content $helpCmd
        $helpPsi = New-Object System.Diagnostics.ProcessStartInfo
        $helpPsi.FileName = "powershell.exe"
        $helpPsi.Arguments = "-NoExit -ExecutionPolicy Bypass -File `"$tmpHelp`""
        $helpPsi.WorkingDirectory = if (Test-Path $downloadPath) { $downloadPath } else { $env:USERPROFILE }
        [System.Diagnostics.Process]::Start($helpPsi) | Out-Null
    } catch {
        Start-Process powershell.exe -ArgumentList "-NoExit","-Command","Set-Location -LiteralPath '$downloadPath'"
    }
}

$btnSideConsole.Add_Click({ Show-AppConsole })
$btnConsole.Add_Click({ Show-AppConsole })

$btnSidePrivacy.Add_Click({
    $msg = @"
Privacy Wipe will:

- Clear the Windows clipboard
- Delete all items from Windows Recent files

This can freeze the app for an extended time if many recent items exist.

Do you want to proceed?
"@
    $r = [System.Windows.Forms.MessageBox]::Show(
        $msg,
        "Privacy Wipe",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    try { Set-Clipboard $null } catch {}
    Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\*" -Force -EA SilentlyContinue
    [System.Windows.Forms.MessageBox]::Show("Clipboard + Recent files wiped")
})
$btnSideExit.Add_Click({ $form.Close() })

try {
    Show-Panel $panelHome
    [void]$form.ShowDialog()
} catch {
    try {
        [System.Windows.Forms.MessageBox]::Show("Startup error:`n$($_.Exception.Message)`n`n$($_.ScriptStackTrace)", "UltimateGoonerTool Error")
    } catch {
        Write-Host "Startup error: $_"
        Start-Sleep 8
    }
}