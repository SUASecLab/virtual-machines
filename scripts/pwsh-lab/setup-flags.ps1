# setup-flags.ps1
# Deploy multiple CTF flags of increasing difficulty.
# Compatible PowerShell 5.1 (Windows 10). Use as Administrator.

$ErrorActionPreference = 'Stop'
$LogFile = 'C:\Windows\Temp\setup-flags.log'

function Log {
    param([string]$msg)
    $ts = (Get-Date).ToString('s')
    $line = "$ts : $msg"
    $line | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

function SafeWriteFile {
    param(
        [string]$Path,
        [string]$Content,
        [switch]$Hidden
    )
    try {
        $dir = Split-Path -Parent $Path
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
        }
        $Content | Out-File -FilePath $Path -Encoding UTF8 -Force
        if ($Hidden) {
            try { (Get-Item $Path).Attributes = 'Hidden' } catch {}
        }
        Log "Wrote flag file: $Path"
    } catch {
        throw "Failed to write file $Path : $($_.Exception.Message)"
    }
}

# Choose base folder for flags
$flagDir = 'C:\CTF'
if (-not (Test-Path $flagDir)) {
    try {
        New-Item -Path $flagDir -ItemType Directory -Force | Out-Null
        Log "Created folder $flagDir"
    } catch {
        Log "ERROR: Cannot create $flagDir : $($_.Exception.Message)"
        throw
    }
}

# If we need to copy helper scripts from A: (floppy) or fallback to C:\Temp\scripts
$sourceScripts = $null
if (Test-Path 'A:\scripts\pwsh-lab') {
    $sourceScripts = 'A:\scripts\pwsh-lab'
    Log "Found scripts on A: ($sourceScripts)"
} else {
    $fallback = 'C:\Temp\scripts\pwsh-lab'
    if (Test-Path $fallback) {
        $sourceScripts = $fallback
        Log "Using fallback script path $fallback"
    } else {
        Log "No script folder found on A: or fallback. ($fallback) - continuing without external scripts."
    }
}
# If found, copy to local (optional)
if ($sourceScripts) {
    try {
        $dest = "C:\Temp\pwsh-lab"
        if (Test-Path $dest) { Remove-Item -Path $dest -Recurse -Force -ErrorAction SilentlyContinue }
        Copy-Item -Path $sourceScripts -Destination $dest -Recurse -Force -ErrorAction Stop
        Log "Copied scripts to $dest"
    } catch {
        Log "WARN: copying scripts failed: $($_.Exception.Message)"
    }
}

# Helper to run a flag block safely
function Run-FlagBlock {
    param(
        [string]$Name,
        [scriptblock]$Block
    )
    try {
        & $Block
    } catch {
        Log "WARN: Flag $Name failed: $($_.Exception.Message)"
    }
}

# Start logging
Log "setup-flags.ps1 started."

# === Define and create flags (each in own try/catch via Run-FlagBlock) ===

# 0) Flag zero (reserved)
Run-FlagBlock -Name 'flag0' -Block {
    $flag0 = "FLAG{LEVEL_00_WINRM_OK}"
    SafeWriteFile -Path "$flagDir\flag0.txt" -Content $flag0
}

# 1) Plain text (very easy)
Run-FlagBlock -Name 'flag1' -Block {
    $flag1 = "FLAG{LEVEL_01_PLAIN}"
    SafeWriteFile -Path "$flagDir\flag1.txt" -Content $flag1
}

# 2) Base64 encoded
Run-FlagBlock -Name 'flag2' -Block {
    $flag2 = "FLAG{LEVEL_02_BASE64}"
    $flag2_b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($flag2))
    SafeWriteFile -Path "$flagDir\flag2_base64.txt" -Content $flag2_b64
}

# 3) Hex encoded (ASCII -> hex)
Run-FlagBlock -Name 'flag3' -Block {
    $flag3 = "FLAG{LEVEL_03_HEX}"
    $bytes3 = [Text.Encoding]::UTF8.GetBytes($flag3)
    $hex3 = ($bytes3 | ForEach-Object { $_.ToString("x2") }) -join " "
    SafeWriteFile -Path "$flagDir\flag3_hex.txt" -Content $hex3
}

# 4) Reversed string (compatible: [array]::Reverse)
Run-FlagBlock -Name 'flag4' -Block {
    $flag4 = "FLAG{LEVEL_04_REVERSED}"
    $chars = $flag4.ToCharArray()
    [array]::Reverse($chars)
    $flag4_rev = -join $chars
    SafeWriteFile -Path "$flagDir\flag4_reversed.txt" -Content $flag4_rev
}

# 5) Split across multiple small files (must concat)
Run-FlagBlock -Name 'flag5' -Block {
    $flag5 = "FLAG{LEVEL_05_SPLIT}"
    $parts = ($flag5 -split '(.{1,4})' ) | Where-Object { $_ -ne '' }
    $i = 1
    foreach ($p in $parts) {
        SafeWriteFile -Path "$flagDir\flag5_part$i.txt" -Content $p
        $i++
    }
}

# 6) Rot13 (example)
Run-FlagBlock -Name 'flag6' -Block {
    $flag6 = "FLAG{LEVEL_06_ROT13}"
    # simple rot13 function
    function rot13($s) { 
        $a = [char[]]$s
        for ($i=0; $i -lt $a.Length; $i++) {
            $c = [int]$a[$i]
            if ( ($c -ge 65 -and $c -le 90) -or ($c -ge 97 -and $c -le 122) ) {
                if ( ($c -ge 65 -and $c -le 77) -or ($c -ge 97 -and $c -le 109) ) { $c += 13 } else { $c -= 13 }
                $a[$i] = [char]$c
            }
        }
        -join $a
    }
    $flag6_rot = rot13 $flag6
    SafeWriteFile -Path "$flagDir\flag6_rot13.txt" -Content $flag6_rot
}

# 7) Reverse then base64
Run-FlagBlock -Name 'flag7' -Block {
    $flag7 = "FLAG{LEVEL_07_REVBASE64}"
    $chars = $flag7.ToCharArray(); [array]::Reverse($chars); $rev = -join $chars
    $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($rev))
    SafeWriteFile -Path "$flagDir\flag7_rev_b64.txt" -Content $b64
}

# You can add more flag blocks (8..15) following the same pattern and increasing complexity.

# === End of flags ===

Log "setup-flags.ps1 ended."
