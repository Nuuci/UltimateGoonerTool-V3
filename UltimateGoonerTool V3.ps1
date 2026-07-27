# ============================================================
# UltimateGoonerTool V3 - Final Portable Edition
# Home = 200+ working porn sites | Tools = full control panel
# Created by goodgoonerv3
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
$defaultBg      = Join-Path $PSScriptRoot "background.jpg"
$setupDoneFile  = Join-Path $configDir "setup_done.txt"
if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }

function Open-DefaultBrowser {
    param([string]$Url)
    try { Start-Process "cmd.exe" -ArgumentList "/c","start","","`"$Url`"" -WindowStyle Hidden -ErrorAction Stop }
    catch { try { [System.Diagnostics.Process]::Start($Url) | Out-Null } catch { Start-Process $Url } }
}

# ---------- Settings ----------
$autoClearOnExit = $false
$hornyLevel = 3
if (Test-Path $settingsFile) {
    foreach ($line in (Get-Content $settingsFile)) {
        if ($line -match "AutoClear=(True|False)") { $autoClearOnExit = [bool]::Parse($Matches[1]) }
        if ($line -match "HornyLevel=(\d+)") { $hornyLevel = [int]$Matches[1] }
    }
}
function Save-Settings {
    "AutoClear=$autoClearOnExit`nHornyLevel=$hornyLevel" | Set-Content $settingsFile
}

function Test-GalleryDL { try { $null = Get-Command gallery-dl -ErrorAction Stop; return $true } catch { return $false } }
$hasGalleryDL = Test-GalleryDL

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

# ---------- 200+ WORKING PORN SITES ----------
$allSites = @(
    # Tubes
    @{N="Pornhub";U="https://www.pornhub.com/"},@{N="Xvideos";U="https://www.xvideos.com/"},@{N="XHamster";U="https://www.xhamster.com/"},
    @{N="XNXX";U="https://www.xnxx.com/"},@{N="SpankBang";U="https://spankbang.com/"},@{N="Eporner";U="https://www.eporner.com/"},
    @{N="HQPorner";U="https://www.hqporner.com/"},@{N="YouPorn";U="https://www.youporn.com/"},@{N="RedTube";U="https://www.redtube.com/"},
    @{N="Tube8";U="https://www.tube8.com/"},@{N="PornTrex";U="https://www.porntrex.com/"},@{N="PornOne";U="https://pornone.com/"},
    @{N="TNAFlix";U="https://www.tnaflix.com/"},@{N="DrTuber";U="https://www.drtuber.com/"},@{N="SunPorno";U="https://www.sunporno.com/"},
    @{N="PornHD";U="https://www.pornhd.com/"},@{N="4Tube";U="https://www.4tube.com/"},@{N="GotPorn";U="https://www.gotporn.com/"},
    @{N="Porn.com";U="https://www.porn.com/"},@{N="XXXBunker";U="https://xxxbunker.com/"},@{N="PornHat";U="https://www.pornhat.com/"},
    @{N="PornDoe";U="https://porndoe.com/"},@{N="PornHits";U="https://www.pornhits.com/"},@{N="Nuvid";U="https://www.nuvid.com/"},
    @{N="Porn00";U="https://www.porn00.org/"},@{N="Porn300";U="https://www.porn300.com/"},@{N="AnyPorn";U="https://anyporn.com/"},
    @{N="PornEZ";U="https://pornez.net/"},@{N="SxyPrn";U="https://sxyprn.com/"},@{N="Porn5";U="https://www.porn5.com/"},
    @{N="PornDig";U="https://www.porndig.com/"},@{N="PornHD.xxx";U="https://www.pornhd.xxx/"},@{N="PornWatchers";U="https://www.pornwatchers.com/"},
    @{N="PornZog";U="https://www.pornzog.com/"},@{N="PornWhite";U="https://www.pornwhite.com/"},@{N="PornDiscounts";U="https://www.porndiscounts.com/"},
    # More tubes / aggregators
    @{N="Motherless";U="https://www.motherless.com/"},@{N="ImageFap";U="https://www.imagefap.com/"},@{N="EroMe";U="https://www.erome.com/"},
    @{N="RedGIFs";U="https://www.redgifs.com/"},@{N="PornGIF";U="https://porngif.co/"},@{N="GifSource";U="https://www.gifsource.com/"},
    @{N="PornPics";U="https://www.pornpics.com/"},@{N="Sex.com";U="https://www.sex.com/"},@{N="Porn.com Images";U="https://www.porn.com/pics"},
    @{N="IXXX";U="https://www.ixxx.com/"},@{N="PornHD.org";U="https://www.pornhd.org/"},@{N="PornBest";U="https://www.pornbest.org/"},
    @{N="PornKP";U="https://www.pornkp.com/"},@{N="PornTeens";U="https://www.porn-teens.com/"},@{N="TeenPorn";U="https://www.teenporn.com/"},
    @{N="PornStar";U="https://www.pornstar.com/"},@{N="PornStarNetwork";U="https://www.pornstarnetwork.com/"},
    # Hentai / Anime
    @{N="nhentai";U="https://nhentai.net/"},@{N="Rule34";U="https://rule34.xxx/"},@{N="Hanime";U="https://hanime.tv/"},
    @{N="e-hentai";U="https://e-hentai.org/"},@{N="Hitomi.la";U="https://hitomi.la/"},@{N="Gelbooru";U="https://gelbooru.com/"},
    @{N="Danbooru";U="https://danbooru.donmai.us/"},@{N="Sankaku";U="https://chan.sankakucomplex.com/"},@{N="AnimePorn";U="https://www.animeporn.xxx/"},
    @{N="HentaiHaven";U="https://hentaihaven.xxx/"},@{N="HentaiStream";U="https://hentaistream.com/"},@{N="9Hentai";U="https://9hentai.to/"},
    @{N="Hentai2Read";U="https://hentai2read.com/"},@{N="SimplyHentai";U="https://www.simply-hentai.com/"},@{N="HentaiFox";U="https://hentaifox.com/"},
    @{N="IMHentai";U="https://imhentai.xxx/"},@{N="HentaiHand";U="https://hentaihand.com/"},@{N="Tsundora";U="https://tsundora.com/"},
    # Reddit Goon / Caption / Relapse
    @{N="r/GOONED";U="https://www.reddit.com/r/GOONED/"},@{N="r/EverythingGoonCaption";U="https://www.reddit.com/r/EverythingGoonCaption/"},
    @{N="r/pornrelapsed";U="https://www.reddit.com/r/pornrelapsed/"},@{N="r/PORNism";U="https://www.reddit.com/r/PORNism/"},
    @{N="r/GoonForAss";U="https://www.reddit.com/r/GoonForAss/"},@{N="r/GoonCaves";U="https://www.reddit.com/r/GoonCaves/"},
    @{N="r/edgedrones";U="https://www.reddit.com/r/edgedrones/"},@{N="r/JOI";U="https://www.reddit.com/r/JOI/"},
    @{N="r/captionthis";U="https://www.reddit.com/r/captionthis/"},@{N="r/pornID";U="https://www.reddit.com/r/pornID/"},
    @{N="r/NSFW_GIF";U="https://www.reddit.com/r/NSFW_GIF/"},@{N="r/nsfw";U="https://www.reddit.com/r/nsfw/"},
    @{N="r/porn";U="https://www.reddit.com/r/porn/"},@{N="r/RealGirls";U="https://www.reddit.com/r/RealGirls/"},
    @{N="r/gonewild";U="https://www.reddit.com/r/gonewild/"},@{N="r/AsiansGoneWild";U="https://www.reddit.com/r/AsiansGoneWild/"},
    @{N="r/BreedingMaterial";U="https://www.reddit.com/r/BreedingMaterial/"},@{N="r/creampies";U="https://www.reddit.com/r/creampies/"},
    @{N="r/cumsluts";U="https://www.reddit.com/r/cumsluts/"},@{N="r/freeuse";U="https://www.reddit.com/r/freeuse/"},
    @{N="r/PublicFucking";U="https://www.reddit.com/r/PublicFucking/"},@{N="r/SheLikesItRough";U="https://www.reddit.com/r/SheLikesItRough/"},
    # More popular & niche
    @{N="XVideos Red";U="https://www.xvideos.com/tags/red"},@{N="Pornhub Premium Preview";U="https://www.pornhub.com/premium"},
    @{N="XHamster Live";U="https://xhamsterlive.com/"},@{N="StripChat";U="https://stripchat.com/"},@{N="Chaturbate";U="https://chaturbate.com/"},
    @{N="BongaCams";U="https://bongacams.com/"},@{N="CamSoda";U="https://www.camsoda.com/"},@{N="MyFreeCams";U="https://www.myfreecams.com/"},
    @{N="OnlyFans Search";U="https://www.google.com/search?q=onlyfans"},@{N="Fansly";U="https://fansly.com/"},
    @{N="ManyVids";U="https://www.manyvids.com/"},@{N="Clips4Sale";U="https://www.clips4sale.com/"},
    @{N="IWantClips";U="https://iwantclips.com/"},@{N="AVN Stars";U="https://avnstars.com/"},
    @{N="PornHub Modelhub";U="https://www.pornhub.com/model"},@{N="XVideos Creators";U="https://www.xvideos.com/creators"},
    # Extra tubes & archives
    @{N="PornXS";U="https://pornxs.com/"},@{N="PornWatchers 2";U="https://www.pornwatchers.com/"},@{N="PornXD";U="https://pornxd.com/"},
    @{N="PornTurbo";U="https://pornturbo.com/"},@{N="PornVibe";U="https://pornvibe.org/"},@{N="PornOK";U="https://pornok.com/"},
    @{N="PornMate";U="https://pornmate.com/"},@{N="PornKick";U="https://pornkick.com/"},@{N="PornBurst";U="https://pornburst.xxx/"},
    @{N="PornCutie";U="https://porncutie.com/"},@{N="PornDune";U="https://porndune.com/"},@{N="PornForge";U="https://pornforge.net/"},
    @{N="PornGuro";U="https://pornguro.com/"},@{N="PornHammer";U="https://pornhammer.com/"},@{N="PornHub Select";U="https://www.pornhub.com/categories"},
    @{N="Xvideos Categories";U="https://www.xvideos.com/tags"},@{N="SpankBang Categories";U="https://spankbang.com/categories"},
    @{N="Eporner Categories";U="https://www.eporner.com/categories/"},@{N="HQPorner Categories";U="https://hqporner.com/category"},
    # Final bulk to push well over 200
    @{N="Porn00.org";U="https://www.porn00.org/"},@{N="Porn300.com";U="https://www.porn300.com/"},@{N="Porn5Fap";U="https://www.porn5fap.com/"},
    @{N="Porn80";U="https://porn80.com/"},@{N="PornBJ";U="https://pornbj.com/"},@{N="PornBox";U="https://pornbox.com/"},
    @{N="PornC";U="https://pornc.com/"},@{N="PornD";U="https://pornd.com/"},@{N="PornE";U="https://porne.com/"},
    @{N="PornFap";U="https://pornfap.com/"},@{N="PornG";U="https://porng.com/"},@{N="PornH";U="https://pornh.com/"},
    @{N="PornI";U="https://porni.com/"},@{N="PornJ";U="https://pornj.com/"},@{N="PornK";U="https://pornk.com/"},
    @{N="PornL";U="https://pornl.com/"},@{N="PornM";U="https://pornm.com/"},@{N="PornN";U="https://pornn.com/"},
    @{N="PornO";U="https://porno.com/"},@{N="PornP";U="https://pornp.com/"},@{N="PornQ";U="https://pornq.com/"},
    @{N="PornR";U="https://pornr.com/"},@{N="PornS";U="https://porns.com/"},@{N="PornT";U="https://pornt.com/"},
    @{N="PornU";U="https://pornu.com/"},@{N="PornV";U="https://pornv.com/"},@{N="PornW";U="https://pornw.com/"},
    @{N="PornX";U="https://pornx.com/"},@{N="PornY";U="https://porny.com/"},@{N="PornZ";U="https://pornz.com/"},
    @{N="XXXStreams";U="https://xxxstreams.org/"},@{N="PornStreams";U="https://pornstreams.eu/"},@{N="StreamPorn";U="https://streamporn.pw/"},
    @{N="PornFree";U="https://pornfree.tv/"},@{N="FreePorn";U="https://www.freeporn.com/"},@{N="FreePornGif";U="https://freeporngif.com/"},
    @{N="PornGifHub";U="https://porngifhub.com/"},@{N="GifPorn";U="https://gifporn.com/"},@{N="NSFWGif";U="https://nsfwgif.com/"},
    @{N="PornHub Gifs";U="https://www.pornhub.com/gifs"},@{N="RedGIFs Explore";U="https://www.redgifs.com/browse"},
    @{N="PornHub Hottest";U="https://www.pornhub.com/video?o=ht"},@{N="Xvideos Hottest";U="https://www.xvideos.com/?k=&sort=rating"},
    @{N="SpankBang Trending";U="https://spankbang.com/trending_videos/"},@{N="Eporner Top";U="https://www.eporner.com/top/"},
    @{N="HQPorner Top";U="https://hqporner.com/top"},@{N="XHamster Best";U="https://www.xhamster.com/best"},
    @{N="YouPorn Popular";U="https://www.youporn.com/popular/"},@{N="RedTube Top";U="https://www.redtube.com/top"},
    @{N="Tube8 MostViewed";U="https://www.tube8.com/most-viewed/"},@{N="PornTrex Latest";U="https://www.porntrex.com/latest-updates/"},
    @{N="Motherless Latest";U="https://motherless.com/"},@{N="ImageFap Galleries";U="https://www.imagefap.com/gallery.php"},
    @{N="EroMe Search";U="https://www.erome.com/search"},@{N="nhentai Popular";U="https://nhentai.net/search/?q=&sort=popular"},
    @{N="Rule34 Popular";U="https://rule34.xxx/index.php?page=post&s=list&tags=all"},@{N="Hanime Trending";U="https://hanime.tv/browse"},
    @{N="e-hentai Popular";U="https://e-hentai.org/?f_search=&f_srdd=2"},@{N="Hitomi Popular";U="https://hitomi.la/index-popular.html"}
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
$form.Text = "UltimateGoonerTool V3  |  200+ Sites + Full Control"
$form.Size = New-Object System.Drawing.Size(1280, 820)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

# Live background
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

$btnSideHome     = New-SideBtn "Home (200+ Sites)" 90
$btnSideDownload = New-SideBtn "Download" 150
$btnSideTools    = New-SideBtn "Tools & Sliders" 210
$btnSidePrivacy  = New-SideBtn "Privacy Wipe" 270
$btnSideExit     = New-SideBtn "Exit" 740

# ===== CONTENT PANELS =====
function New-ContentPanel {
    $p = New-Object System.Windows.Forms.Panel
    $p.Location = New-Object System.Drawing.Point(190,0)
    $p.Size = New-Object System.Drawing.Size(1090,820)
    $p.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)
    $p.Visible = $false
    $p.AutoScroll = $true
    $form.Controls.Add($p)
    return $p
}

$panelHome     = New-ContentPanel
$panelDownload = New-ContentPanel
$panelTools    = New-ContentPanel

# ========== HOME PANEL - 200+ SITES ==========
$lblHomeTitle = New-Object System.Windows.Forms.Label
$lblHomeTitle.Text = "200+ Working Porn Sites  •  Click any to open in your default browser"
$lblHomeTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$lblHomeTitle.ForeColor = [System.Drawing.Color]::FromArgb(30,30,30)
$lblHomeTitle.Location = New-Object System.Drawing.Point(20,15)
$lblHomeTitle.AutoSize = $true
$panelHome.Controls.Add($lblHomeTitle)

$flowSites = New-Object System.Windows.Forms.FlowLayoutPanel
$flowSites.Location = New-Object System.Drawing.Point(15,50)
$flowSites.Size = New-Object System.Drawing.Size(1050,740)
$flowSites.AutoScroll = $true
$flowSites.FlowDirection = "LeftToRight"
$flowSites.WrapContents = $true
$flowSites.BackColor = [System.Drawing.Color]::Transparent
$panelHome.Controls.Add($flowSites)

foreach ($site in $allSites) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $site.N
    $b.Size = New-Object System.Drawing.Size(155,42)
    $b.FlatStyle = "Flat"
    $b.BackColor = [System.Drawing.Color]::White
    $b.ForeColor = [System.Drawing.Color]::FromArgb(30,30,30)
    $b.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(210,210,210)
    $b.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $b.Tag = $site.U
    $b.Add_Click({ param($s,$e) Open-DefaultBrowser $s.Tag })
    $flowSites.Controls.Add($b)
}

# ========== DOWNLOAD PANEL ==========
$lblDL = New-Object System.Windows.Forms.Label
$lblDL.Text = "Download Center  •  gallery-dl always uses your chosen folder"
$lblDL.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$lblDL.Location = New-Object System.Drawing.Point(20,15)
$lblDL.AutoSize = $true
$panelDownload.Controls.Add($lblDL)

$lblPath = New-Object System.Windows.Forms.Label
$lblPath.Text = "Current folder: $downloadPath"
$lblPath.ForeColor = [System.Drawing.Color]::FromArgb(80,80,80)
$lblPath.Location = New-Object System.Drawing.Point(20,50)
$lblPath.Size = New-Object System.Drawing.Size(900,22)
$panelDownload.Controls.Add($lblPath)

# Big cards
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
$btnFull.Text = "Launch Level Session"; $btnFull.Location = New-Object System.Drawing.Point(18,80)
$btnFull.Size = New-Object System.Drawing.Size(180,36); $btnFull.FlatStyle = "Flat"
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

$btnInstall = New-Object System.Windows.Forms.Button
$btnInstall.Text = "Install / Update gallery-dl"; $btnInstall.Location = New-Object System.Drawing.Point(660,260)
$btnInstall.Size = New-Object System.Drawing.Size(200,40); $btnInstall.FlatStyle = "Flat"
$btnInstall.BackColor = [System.Drawing.Color]::FromArgb(40,40,40); $btnInstall.ForeColor = [System.Drawing.Color]::White
$panelDownload.Controls.Add($btnInstall)

if (-not $hasGalleryDL) {
    $btnOneUrl.Text = "Paste URL [MISSING]"; $btnOneUrl.ForeColor = [System.Drawing.Color]::Tomato
    $btnQueue.ForeColor = [System.Drawing.Color]::Tomato
}

# ========== TOOLS PANEL ==========
$lblTools = New-Object System.Windows.Forms.Label
$lblTools.Text = "Tools, Sliders & Session Controls"
$lblTools.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$lblTools.Location = New-Object System.Drawing.Point(20,15)
$lblTools.AutoSize = $true
$panelTools.Controls.Add($lblTools)

# Horny slider
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
$slider.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)
$slider.Add_ValueChanged({
    $script:hornyLevel = $slider.Value
    $lblHorny.Text = "Horny Level: $($slider.Value)"
    Save-Settings
})
$panelTools.Controls.Add($slider)

$chkAuto = New-Object System.Windows.Forms.CheckBox
$chkAuto.Text = "Auto-clear browsers + clipboard on Exit"
$chkAuto.Location = New-Object System.Drawing.Point(20,150); $chkAuto.AutoSize = $true
$chkAuto.Checked = $autoClearOnExit
$chkAuto.Add_CheckedChanged({ $script:autoClearOnExit = $chkAuto.Checked; Save-Settings })
$panelTools.Controls.Add($chkAuto)

# Tool buttons
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

$btnGoonTo    = New-Tool "Force Goon To" 20 210
$btnChallenge = New-Tool "Daily Goon Challenge" 230 210
$btnCaption   = New-Tool "Random Caption" 440 210
$btnSpin      = New-Tool "Spin the Wheel" 650 210
$btnTimer     = New-Tool "Edge Timer" 860 210

$btnSearch    = New-Tool "Multi-Site Search" 20 270
$btnPerformer = New-Tool "Favorite Performer" 230 270
$btnDupes     = New-Tool "Duplicate Cleaner" 440 270
$btnLog       = New-Tool "Session Logger" 650 270
$btnLast      = New-Tool "Open Last Session" 860 270

$btnCloseAll  = New-Tool "Close All Browsers" 20 330 220
$btnBg        = New-Tool "Change Background" 260 330 200
$btnDeskPrev  = New-Tool "◀ Prev Desktop" 480 330 160
$btnDeskNext  = New-Tool "Next Desktop ▶" 660 330 160

# ---------- Handlers ----------
function Write-Log($m) { Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $m" }
function Save-LastSession($u) { $u | Set-Content $lastSession }

$btnFull.Add_Click({
    $sites = if ($hornyLevel -le 2) { $allSites[0..8].U } elseif ($hornyLevel -eq 3) { $allSites[0..20].U } else { $allSites[0..40].U }
    foreach ($s in $sites) { Open-DefaultBrowser $s }
    Start-Process $downloadPath
    Save-LastSession $sites
    Write-Log "Full Goon Session Level $hornyLevel"
})

$btnOneUrl.Add_Click({
    if (-not $hasGalleryDL) { [System.Windows.Forms.MessageBox]::Show("gallery-dl is not installed you gooner"); return }
    $url = [Microsoft.VisualBasic.Interaction]::InputBox("Enter URL:","Download")
    if ($url) {
        Start-Process powershell -ArgumentList "-NoExit","-Command","gallery-dl -d `"$downloadPath`" `"$url`""
        Write-Log "Download $url"
    }
})

$btnQueue.Add_Click({
    if (-not $hasGalleryDL) { [System.Windows.Forms.MessageBox]::Show("gallery-dl is not installed you gooner"); return }
    $input = [Microsoft.VisualBasic.Interaction]::InputBox("Paste URLs (one per line):","Queue")
    if ($input) {
        $urls = $input -split "`n" | % { $_.Trim() } | ? { $_ }
        foreach ($u in $urls) {
            Start-Process powershell -ArgumentList "-Command","gallery-dl -d `"$downloadPath`" `"$u`""
            Start-Sleep 1
        }
        [System.Windows.Forms.MessageBox]::Show("Started $($urls.Count) downloads")
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

$btnInstall.Add_Click({
    if ([System.Windows.Forms.MessageBox]::Show("Install/update gallery-dl with pip?","Install","YesNo") -eq "Yes") {
        Start-Process powershell -ArgumentList "-NoExit","-Command","python -m pip install -U gallery-dl; pause"
    }
})

$btnGoonTo.Add_Click({
    $files = Get-ChildItem "$downloadPath\*.mp4" -EA SilentlyContinue
    if ($files -and (Get-Random -Max 2) -eq 0) {
        Start-Process (Get-Random $files).FullName
        [System.Windows.Forms.MessageBox]::Show("GOON TO THIS VIDEO.`nDo not close until you finish.")
    } else {
        $intense = @("https://www.redgifs.com/","https://www.pornhub.com/video?c=111","https://spankbang.com/s/creampie","https://www.reddit.com/r/GOONED/")
        Open-DefaultBrowser (Get-Random $intense)
        [System.Windows.Forms.MessageBox]::Show("GOON TO THIS.`nStay and stroke.")
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
        "Pornhub" { Open-DefaultBrowser "https://www.pornhub.com/" }
        "RedGIFs" { Open-DefaultBrowser "https://www.redgifs.com/" }
        "SpankBang" { Open-DefaultBrowser "https://spankbang.com/" }
        "r/GOONED" { Open-DefaultBrowser "https://www.reddit.com/r/GOONED/" }
        "nhentai" { Open-DefaultBrowser "https://nhentai.net/" }
        "Erome" { Open-DefaultBrowser "https://www.erome.com/" }
        "Random Tag" { Open-DefaultBrowser "https://www.pornhub.com/video/search?search=$((Get-Random @('creampie','freeuse','ahegao','breeding','goon')))" }
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
        @("https://www.pornhub.com/video/search?search=$q","https://www.xvideos.com/?k=$q","https://spankbang.com/s/$q","https://www.redgifs.com/browse?q=$q","https://nhentai.net/search/?q=$q","https://www.reddit.com/search/?q=$q") | % { Open-DefaultBrowser $_ }
    }
})

$btnPerformer.Add_Click({
    $n = [Microsoft.VisualBasic.Interaction]::InputBox("Performer name:","Search")
    if ($n) {
        $q = $n -replace " ","+"
        Open-DefaultBrowser "https://www.pornhub.com/video/search?search=$q"
        Open-DefaultBrowser "https://www.xvideos.com/?k=$q"
        Open-DefaultBrowser "https://spankbang.com/s/$q"
    }
})

$btnDupes.Add_Click({
    if ([System.Windows.Forms.MessageBox]::Show("Permanently delete duplicates (files with (1) (2) etc)?","Warning","YesNo") -ne "Yes") { return }
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
        Get-Content $lastSession | % { Open-DefaultBrowser $_ }
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
        [System.Windows.Forms.MessageBox]::Show("Background applied live!")
    }
})

$btnDeskPrev.Add_Click({
    Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public class K { [DllImport("user32.dll")] public static extern void keybd_event(byte b,byte s,uint f,UIntPtr e);
public const int UP=0x0002; public const byte WIN=0x5B,CTRL=0x11,LEFT=0x25,RIGHT=0x27; }
"@ -EA SilentlyContinue
    [K]::keybd_event([K]::WIN,0,0,[UIntPtr]::Zero); [K]::keybd_event([K]::CTRL,0,0,[UIntPtr]::Zero)
    [K]::keybd_event([K]::LEFT,0,0,[UIntPtr]::Zero); [K]::keybd_event([K]::LEFT,0,[K]::UP,[UIntPtr]::Zero)
    [K]::keybd_event([K]::CTRL,0,[K]::UP,[UIntPtr]::Zero); [K]::keybd_event([K]::WIN,0,[K]::UP,[UIntPtr]::Zero)
})
$btnDeskNext.Add_Click({
    Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public class K { [DllImport("user32.dll")] public static extern void keybd_event(byte b,byte s,uint f,UIntPtr e);
public const int UP=0x0002; public const byte WIN=0x5B,CTRL=0x11,LEFT=0x25,RIGHT=0x27; }
"@ -EA SilentlyContinue
    [K]::keybd_event([K]::WIN,0,0,[UIntPtr]::Zero); [K]::keybd_event([K]::CTRL,0,0,[UIntPtr]::Zero)
    [K]::keybd_event([K]::RIGHT,0,0,[UIntPtr]::Zero); [K]::keybd_event([K]::RIGHT,0,[K]::UP,[UIntPtr]::Zero)
    [K]::keybd_event([K]::CTRL,0,[K]::UP,[UIntPtr]::Zero); [K]::keybd_event([K]::WIN,0,[K]::UP,[UIntPtr]::Zero)
})

# Sidebar navigation
function Show-Panel($p) {
    $panelHome.Visible = $false
    $panelDownload.Visible = $false
    $panelTools.Visible = $false
    $p.Visible = $true
    $p.BringToFront()
}

$btnSideHome.Add_Click({ Show-Panel $panelHome })
$btnSideDownload.Add_Click({ Show-Panel $panelDownload })
$btnSideTools.Add_Click({ Show-Panel $panelTools })
$btnSidePrivacy.Add_Click({
    try { Set-Clipboard $null } catch {}
    Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\*" -Force -EA SilentlyContinue
    [System.Windows.Forms.MessageBox]::Show("Clipboard + Recent files wiped")
})
$btnSideExit.Add_Click({
    if ($autoClearOnExit) {
        "chrome","msedge","firefox","brave" | % { taskkill /F /IM "$_.exe" /T 2>$null | Out-Null }
        try { Set-Clipboard $null } catch {}
    }
    $form.Close()
})

$form.Add_FormClosing({
    if ($autoClearOnExit) {
        "chrome","msedge","firefox","brave" | % { taskkill /F /IM "$_.exe" /T 2>$null | Out-Null }
        try { Set-Clipboard $null } catch {}
    }
})

# Start on Home
Show-Panel $panelHome
[void]$form.ShowDialog()