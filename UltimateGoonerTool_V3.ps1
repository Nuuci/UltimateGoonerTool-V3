# ============================================================
# UltimateGoonerTool V3 - Final Portable Edition
# Version: v.1.24
# ============================================================

Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")] public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);'
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0) | Out-Null

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

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

function Write-Log($m) { Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $m" }
function Save-LastSession($u) { $u | Set-Content $lastSession }

# ---------- Settings ----------
$autoClearOnExit        = $false
$hornyLevel             = 3
$isDarkTheme            = $false
$startWithWindows       = $false
$suppressGalleryWarning = $false

if (Test-Path $settingsFile) {
    foreach ($line in (Get-Content $settingsFile)) {
        if ($line -match "AutoClear=(True|False)")              { $autoClearOnExit        = [bool]::Parse($Matches[1]) }
        if ($line -match "HornyLevel=(\d+)")                     { $hornyLevel             = [int]$Matches[1] }
        if ($line -match "DarkTheme=(True|False)")               { $isDarkTheme            = [bool]::Parse($Matches[1]) }
        if ($line -match "StartWithWindows=(True|False)")        { $startWithWindows       = [bool]::Parse($Matches[1]) }
        if ($line -match "SuppressGalleryWarning=(True|False)")  { $suppressGalleryWarning = [bool]::Parse($Matches[1]) }
    }
}

function Save-Settings {
    @"
AutoClear=$autoClearOnExit
HornyLevel=$hornyLevel
DarkTheme=$isDarkTheme
StartWithWindows=$startWithWindows
SuppressGalleryWarning=$suppressGalleryWarning
"@ | Set-Content $settingsFile
}

$favorites = @()
if (Test-Path $favoritesFile) {
    $favorites = @(Get-Content $favoritesFile | Where-Object { $_ -ne "" })
}
function Save-Favorites { $favorites | Set-Content $favoritesFile }

# Improved detection - works even when Scripts folder is not in PATH
function Test-GalleryDL {
    try {
        $null = Get-Command gallery-dl -ErrorAction Stop
        return $true
    } catch {}
    try {
        $out = & python -m gallery_dl --version 2>$null
        if ($LASTEXITCODE -eq 0 -or $out) { return $true }
    } catch {}
    try {
        $out = & py -m gallery_dl --version 2>$null
        if ($LASTEXITCODE -eq 0 -or $out) { return $true }
    } catch {}
    return $false
}

function Test-Ytdlp {
    try {
        $null = Get-Command yt-dlp -ErrorAction Stop
        return $true
    } catch {}
    try {
        $out = & python -m yt_dlp --version 2>$null
        if ($LASTEXITCODE -eq 0 -or $out) { return $true }
    } catch {}
    try {
        $out = & py -m yt_dlp --version 2>$null
        if ($LASTEXITCODE -eq 0 -or $out) { return $true }
    } catch {}
    return $false
}

# Soft warning dialog
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
    $chk.Font = New-Object System.Drawing.Font("Segoe UI", 9)
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

# ---------- REAL UNIQUE SITES ----------
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

# ---------- First-time setup ----------
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

# ---------- Main Form ----------
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

# ===== SIDEBAR =====
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
$btnSideExit     = New-SideBtn "Exit" 740

# ===== CONTENT PANELS =====
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

# ========== HOME ==========
$lblHomeTitle = New-Object System.Windows.Forms.Label
$lblHomeTitle.Text = "Working Sites • Click any to open"
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

# Version label
$lblVersion = New-Object System.Windows.Forms.Label
$lblVersion.Text = "v.1.24"
$lblVersion.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblVersion.ForeColor = [System.Drawing.Color]::Black
$lblVersion.BackColor = [System.Drawing.Color]::Transparent
$lblVersion.Location = New-Object System.Drawing.Point(1180, 785)
$lblVersion.AutoSize = $true
$form.Controls.Add($lblVersion)

# ========== DOWNLOAD ==========
$lblDL = New-Object System.Windows.Forms.Label
$lblDL.Text = "Download Center • yt-dlp (main) → gallery-dl (fallback)"
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
$btnOneUrl.Text = "Paste URL →"; $btnOneUrl.Location = New-Object System.Drawing.Point(18,80)
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

# ========== TOOLS ==========
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

# ========== FAVORITES ==========
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

# ---------- HANDLERS ----------
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

    $hasY = Test-Ytdlp
    $hasG = Test-GalleryDL

    if (-not $hasY -and -not $hasG) {
        if (-not (Show-GalleryWarning)) { return }
    }

    # Prefer yt-dlp, fall back to gallery-dl (including python -m versions)
    if ($hasY) {
        $cmd = @"
`$ErrorActionPreference = 'Continue'
try { yt-dlp -o `"$downloadPath\%(title)s.%(ext)s`" `"$url`" } catch {}
if (`$LASTEXITCODE -ne 0) {
    try { python -m yt_dlp -o `"$downloadPath\%(title)s.%(ext)s`" `"$url`" } catch {}
}
if (`$LASTEXITCODE -ne 0) {
    try { gallery-dl -d `"$downloadPath`" `"$url`" } catch {}
    if (`$LASTEXITCODE -ne 0) { python -m gallery_dl -d `"$downloadPath`" `"$url`" }
}
pause
"@
        Start-Process powershell -ArgumentList "-NoExit","-Command",$cmd
    } else {
        $cmd = @"
`$ErrorActionPreference = 'Continue'
try { gallery-dl -d `"$downloadPath`" `"$url`" } catch {}
if (`$LASTEXITCODE -ne 0) { python -m gallery_dl -d `"$downloadPath`" `"$url`" }
pause
"@
        Start-Process powershell -ArgumentList "-NoExit","-Command",$cmd
    }
})

$btnQueue.Add_Click({
    $input = [Microsoft.VisualBasic.Interaction]::InputBox("Paste multiple links (one per line):","Queue")
    if ([string]::IsNullOrWhiteSpace($input)) { return }
    $urls = $input -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ }

    $hasY = Test-Ytdlp
    $hasG = Test-GalleryDL

    if (-not $hasY -and -not $hasG) {
        if (-not (Show-GalleryWarning)) { return }
    }

    foreach ($u in $urls) {
        $cmd = @"
`$ErrorActionPreference = 'Continue'
try { yt-dlp -o `"$downloadPath\%(title)s.%(ext)s`" `"$u`" } catch {}
if (`$LASTEXITCODE -ne 0) {
    try { python -m yt_dlp -o `"$downloadPath\%(title)s.%(ext)s`" `"$u`" } catch {}
}
if (`$LASTEXITCODE -ne 0) {
    try { gallery-dl -d `"$downloadPath`" `"$u`" } catch {}
    if (`$LASTEXITCODE -ne 0) { python -m gallery_dl -d `"$downloadPath`" `"$u`" }
}
"@
        Start-Process powershell -ArgumentList "-Command",$cmd
        Start-Sleep -Milliseconds 600
    }
})

$btnOpenFold.Add_Click({ Start-Process $downloadPath })
$btnPlay.Add_Click({
    $f = Get-ChildItem "$downloadPath\*.mp4" -EA SilentlyContinue | Sort LastWriteTime -Desc | Select -First 1
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

$btnGoonTo.Add_Click({
    $files = Get-ChildItem "$downloadPath\*.mp4" -EA SilentlyContinue
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
        "Local Video" { $f = Get-ChildItem "$downloadPath\*.mp4" -EA SilentlyContinue; if ($f) { Start-Process (Get-Random $f).FullName } }
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

# ---------- Form Closing ----------
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

# Navigation
function Show-Panel($p) {
    $panelHome.Visible = $false
    $panelDownload.Visible = $false
    $panelTools.Visible = $false
    $panelFavs.Visible = $false
    $p.Visible = $true
    $p.BringToFront()
}

$btnSideHome.Add_Click({ Show-Panel $panelHome })
$btnSideDownload.Add_Click({ Show-Panel $panelDownload })
$btnSideTools.Add_Click({ Show-Panel $panelTools })
$btnSideFavs.Add_Click({ Refresh-Favorites; Show-Panel $panelFavs })
$btnSidePrivacy.Add_Click({
    try { Set-Clipboard $null } catch {}
    Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\*" -Force -EA SilentlyContinue
    [System.Windows.Forms.MessageBox]::Show("Clipboard + Recent files wiped")
})
$btnSideExit.Add_Click({ $form.Close() })

Show-Panel $panelHome
[void]$form.ShowDialog()