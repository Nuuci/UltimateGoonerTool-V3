Critical URL injection fixed with Test-SafeUrl + proper escaping so a malicious paste cannot break out of the generated PowerShell and run arbitrary commands.
Converter no longer force-deletes originals unless you explicitly check the new “Delete originals” box (off by default).
Duplicate cleaner now uses real SHA-256 content hashes instead of filename similarity — different edits/qualities stay safe.
--cookies-from-browser completely removed; only your exported cookies*.txt files are used.
Privacy Wipe can now also wipe the tool’s own logs, last session, favorites, and cookie files.
Close-All-Browsers now requires confirmation before force-killing process trees.

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
