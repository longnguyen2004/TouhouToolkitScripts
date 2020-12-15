param(
    # Extraction mode: anm, dat
    [Parameter(
        Mandatory = $true,
        Position = 0,
        HelpMessage = "Unpack mode: anm, dat")]
    [ValidateNotNullOrEmpty()]
    [string]
    $UnpackMode,
    # Path to Touhou data file
    [Parameter(
        Mandatory = $true,
        HelpMessage = "Path to data file")]
    [ValidateNotNullOrEmpty()]
    [string]
    $File,
    # Touhou version
    [Parameter(
        Mandatory = $true,
        Position = 0,
        HelpMessage = "Touhou version")]
    [ValidateNotNullOrEmpty()]
    [string]
    $Version,
    # Destination folder
    [Parameter(
        Mandatory = $true,
        Position = 0,
        HelpMessage = "Unpack location. Empty = current directory")]
    [AllowEmptyString()]
    [string]
    $UnpackLocation,
    [AllowEmptyString()]
    [string]
    $ListUnpacked
)

function unpack_dat {
    param(
        [Parameter(Position = 0)]
        [string] $File,
        [Parameter(Position = 0)]
        [string] $Version,
        [Parameter(Position = 0)]
        [string] $ListUnpacked
    )
    & "thdat" -x $Version $File | Tee-Object $ListUnpacked
}
function unpack_anm {
    param(
        [Parameter(Position = 0)]
        [string] $File,
        [Parameter(Position = 0)]
        [string] $Version,
        [Parameter(Position = 0)]
        [string] $ListUnpacked
    )
    . ("$PSScriptRoot/maplist.ps1")
    & "thanm" -l $File -m $anmmaps[$Version] | Out-File $ListUnpacked
    & "thanm" -x $File
}
function unpack {
    param(
        [Parameter(Position = 0)]
        [string] $UnpackMode,
        [Parameter(Position = 0)]
        [string] $File,
        [Parameter(Position = 0)]
        [string] $Version,
        [Parameter(Position = 0)]
        [string] $UnpackLocation = "",
        [Parameter(Position = 0)]
        [string] $ListUnpacked = ""
    )
    $prev_path = $Env:Path
    $thtk_dir = "$PSScriptRoot\thtk\bin"
    if (-not (Test-Path $thtk_dir)) {
        Write-Error "Cannot find thtk!" -ErrorAction Stop
    }
    $Env:Path += ";$thtk_dir"
    if (-not (Test-Path $File)) {
        Write-Error "Cannot find $File!" -ErrorAction Stop 
    }
    $file_absolute = Resolve-Path $File
    $previous_location = (Get-Location).Path
    if ("" -ne $UnpackLocation) {
        New-Item $UnpackLocation -ItemType Directory -Force | Out-Null
        Set-Location $UnpackLocation
    }

    $file_name = Split-Path $File -Leaf
    if ("" -eq $ListUnpacked) {
        $ListUnpacked = $file_name + ".txt"
    }

    Write-Host "Unpacking: $file_name"
    New-Item $ListUnpacked -Force | Out-Null
    Switch ($UnpackMode) {
        "dat" {
            unpack_dat `
                -File $file_absolute `
                -Version $Version `
                -ListUnpacked $ListUnpacked
        }
        "anm" {
            unpack_anm `
                -File $file_absolute `
                -Version $Version `
                -ListUnpacked $ListUnpacked
        }
    }

    Set-Location $previous_location
    $Env:Path = $prev_path
}

unpack `
    -UnpackMode $UnpackMode `
    -File $File `
    -Version $Version `
    -UnpackLocation $UnpackLocation `
    -ListUnpacked $ListUnpacked