UltimateGoonerTool v.1.28.7-sec — Changelog
UI / Display

Enabled process DPI awareness + visual styles so text and controls stay sharp on high-DPI displays (no blurry upscaling)
Main window set to a compact fixed size (similar to original layout)
Window resize/maximize disabled (FixedSingle) for a stable layout
Confirm Download dialog enlarged — full URL, estimate count, and YES/NO buttons no longer clipped
Download progress dialog enlarged — status text, progress bar, and CANCEL DOWNLOAD fully visible
Convert Videos dialog enlarged and re-laid out:
Radio options stacked vertically (no overlap)
Format dropdown shows full “MP4 (recommended)” text
Delete-originals checkbox text fully visible


Convert

“Delete originals after successful convert” is ON by default (still can be unchecked)

Confirm Download

Removed “Do not show this again” checkbox
Confirmation dialog always appears on every single/queue/OnlyFans download

Auto-organize downloads (new)

New checkbox in Tools & Sliders:
“Auto-organize downloads by site + username”
When enabled:
Files save under DownloadFolder\SiteName\
If a username is detected in the URL → DownloadFolder\SiteName\Username\
Examples: RedGifs /users/vixenp → ...\RedGifs\vixenp\

Supported site name mapping for common hosts (RedGifs, Pornhub, Xvideos, OnlyFans, Fansly, etc.)
Bugfix: organize failed because $host is a reserved PowerShell variable — renamed to $siteHost

Other

Version label updated to v.1.28.7-sec
Settings persist AutoOrganize in settings.txt


Convert

“Delete originals after successful convert” is ON by default (still can be unchecked)

Confirm Download

Removed “Do not show this again” checkbox
Confirmation dialog always appears on every single/queue/OnlyFans download

Auto-organize downloads (new)

New checkbox in Tools & Sliders:
“Auto-organize downloads by site + username”
When enabled:
Files save under DownloadFolder\SiteName\
If a username is detected in the URL → DownloadFolder\SiteName\Username\
Examples: RedGifs /users/vixenp → ...\RedGifs\vixenp\

Supported site name mapping for common hosts (RedGifs, Pornhub, Xvideos, OnlyFans, Fansly, etc.)
Bugfix: organize failed because $host is a reserved PowerShell variable — renamed to $siteHost

Other

Version label updated to v.1.28.7-sec
Settings persist AutoOrganize in settings.txt

---

## Recommended Way to Get the Tool

If downloading the file keeps failing or the script opens and closes immediately, use this method:

1. Open the `.ps1` file on GitHub
2. Click the **Raw** button
3. Select all the code (`Ctrl + A`) and copy it (`Ctrl + C`)
4. Open **Notepad**
5. Paste the code (`Ctrl + V`)
6. Click **File → Save As**
7. Set these options:
   - **File name:** `UltimateGoonerTool_V3.ps1`
   - **Save as type:** All Files (*.*)
   - **Encoding:** UTF-8
8. Save it to your Desktop

Then right-click the file → **Run with PowerShell**

---

## Alternative Download Methods

**Option A – Direct file**
1. Go to the repository
2. Click the `.ps1` file
3. Click **Raw**
4. Right-click the page → **Save as...**

**Option B – ZIP**
1. Click the green **Code** button
2. Click **Download ZIP**
3. Extract the file

---

## How to Run

- Right-click the `.ps1` file
- Select **Run with PowerShell**

Or open PowerShell and run:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Path\To\UltimateGoonerTool_V3.ps1"

First Launch
The first time you run it, Windows may ask for permission to run scripts.
Click Continue. After that the tool should open normally.
If you have any problems, message me.
