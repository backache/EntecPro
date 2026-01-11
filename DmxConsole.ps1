param (
    [string]$ComPort = "COM3"
)

$BaudRate = 57600
$Channels = 512
$CueFile = "cues.json"

# ------------------------------
# Open Serial Port
# ------------------------------
$serial = New-Object System.IO.Ports.SerialPort $ComPort, $BaudRate, "None", 8, "One"
$serial.Open()

Write-Host "Connected to ENTTEC DMX USB Pro Mk2 on $ComPort"

# ------------------------------
# DMX Universe
# ------------------------------
$DmxBuffer = New-Object byte[] ($Channels + 1)
$DmxBuffer[0] = 0

# ------------------------------
# Cue Store
# ------------------------------
$Cues = @{}

if (Test-Path $CueFile) {
    $json = Get-Content $CueFile -Raw | ConvertFrom-Json
    foreach ($prop in $json.PSObject.Properties) {
        $Cues[$prop.Name] = [byte[]]$prop.Value
    }
}


function Save-Cues {
    $Cues | ConvertTo-Json -Depth 5 | Set-Content $CueFile
}

# ------------------------------
# Send DMX Frame
# ------------------------------
function Send-DMX {
    param ([byte[]]$Data)

    $length = $Data.Length
    $bytes = New-Object System.Collections.Generic.List[byte]
    $bytes.Add(0x7E)
    $bytes.Add(6)
    $bytes.Add($length -band 0xFF)
    $bytes.Add(($length -shr 8) -band 0xFF)
    $bytes.AddRange($Data)
    $bytes.Add(0xE7)

    $serial.Write($bytes.ToArray(), 0, $bytes.Count)
}

# ------------------------------
# Channel Control
# ------------------------------
function Set-Channel {
    param ([int]$Channel, [int]$Value)

    if ($Channel -lt 1 -or $Channel -gt 512) { return }
    if ($Value -lt 0 -or $Value -gt 255) { return }

    $DmxBuffer[$Channel] = [byte]$Value
    Send-DMX $DmxBuffer
}

# ------------------------------
# Fade Channel
# ------------------------------
function Fade-Channel {
    param ([int]$Channel, [int]$From, [int]$To, [int]$Ms)

    $steps = 50
    $delay = [int]($Ms / $steps)

    for ($i = 0; $i -le $steps; $i++) {
        $val = [int]($From + (($To - $From) * ($i / $steps)))
        Set-Channel $Channel $val
        Start-Sleep -Milliseconds $delay
    }
}

# ------------------------------
# Cue Operations
# ------------------------------
function Cue-Save {
    param ([string]$Name)

    $Cues[$Name] = $DmxBuffer.Clone()
    Save-Cues
    Write-Host "Cue '$Name' saved"
}

function Cue-Load {
    param ([string]$Name)

    if (-not $Cues.ContainsKey($Name)) {
        Write-Host "Cue not found"
        return
    }

    $Cues[$Name].CopyTo($DmxBuffer, 0)
    Send-DMX $DmxBuffer
    Write-Host "Cue '$Name' loaded"
}

function Cue-Fade {
    param ([string]$Name, [int]$Ms)

    if (-not $Cues.ContainsKey($Name)) {
        Write-Host "Cue not found"
        return
    }

    $target = $Cues[$Name]
    $steps = 50
    $delay = [int]($Ms / $steps)

    for ($i = 0; $i -le $steps; $i++) {
        for ($ch = 1; $ch -le 512; $ch++) {
            $from = $DmxBuffer[$ch]
            $to = $target[$ch]
            $DmxBuffer[$ch] = [byte]($from + (($to - $from) * ($i / $steps)))
        }
        Send-DMX $DmxBuffer
        Start-Sleep -Milliseconds $delay
    }

    $target.CopyTo($DmxBuffer, 0)
}

function Cue-List {
    if ($Cues.Count -eq 0) {
        Write-Host "No cues stored"
        return
    }
    $Cues.Keys | Sort-Object | ForEach-Object { Write-Host $_ }
}

function Cue-Delete {
    param ([string]$Name)

    if ($Cues.Remove($Name)) {
        Save-Cues
        Write-Host "Cue '$Name' deleted"
    } else {
        Write-Host "Cue not found"
    }
}

# ------------------------------
# Blackout
# ------------------------------
function Blackout {
    for ($i = 1; $i -le 512; $i++) {
        $DmxBuffer[$i] = 0
    }
    Send-DMX $DmxBuffer
}

# ------------------------------
# Console Loop
# ------------------------------
Write-Host ""
Write-Host "DMX Console Commands:"
Write-Host " set <ch> <val>"
Write-Host " fade <ch> <from> <to> <ms>"
Write-Host " show <ch>"
Write-Host " blackout"
Write-Host " cue save <name>"
Write-Host " cue load <name>"
Write-Host " cue fade <name> <ms>"
Write-Host " cue list"
Write-Host " cue delete <name>"
Write-Host " exit"
Write-Host ""

$running = $true

while ($running) {
    $input = Read-Host "dmx"
    $a = $input -split "\s+"

    switch ($a[0].ToLower()) {

        "set"      { Set-Channel $a[1] $a[2] }
        "fade"     { Fade-Channel $a[1] $a[2] $a[3] $a[4] }
        "show"     { Write-Host "Channel $($a[1]) = $($DmxBuffer[$a[1]])" }
        "blackout" { Blackout }

        "cue" {
            switch ($a[1].ToLower()) {
                "save"   { Cue-Save $a[2] }
                "load"   { Cue-Load $a[2] }
                "fade"   { Cue-Fade $a[2] $a[3] }
                "list"   { Cue-List }
                "delete" { Cue-Delete $a[2] }
            }
        }

        "exit" {
            $running = $false
        }

        default {
            Write-Host "Unknown command"
        }
    }
}

# Cleanup happens AFTER loop exits
Blackout
$serial.Close()
Write-Host "Disconnected"

