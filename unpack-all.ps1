param(
    # Path to Touhou data file
    [Parameter(
        Mandatory = $true,
        Position = 0,
        HelpMessage = "Đường dẫn đến file data")]
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
        HelpMessage = "Vị trí unpack. Để trống = tạo thư mục mới")]
    [AllowEmptyString()]
    [string]
    $UnpackLocation
)

function resolve_conflict_between_anms {
    param(
        [Parameter(Position = 0)]
        [string] $Version,
        [Parameter(Position = 0)]
        [string] $ConflictingAnm
    )
    . ("$PSScriptRoot/conflicting-files.ps1")
    if ($conflicting_files[$Version].ContainsKey($ConflictingAnm)) {
        $conflicting_file = $conflicting_files[$Version][$ConflictingAnm]
        Write-Host "Resolving conflict on $conflicting_file"
        $new_file_name = $(Split-Path $conflicting_file -LeafBase) `
            + " ($ConflictingAnm)" `
            + $(Split-Path $conflicting_file -Extension)
        Remove-Item $($(Split-Path $conflicting_file -Parent) + "/" + $new_file_name)
        Rename-Item $conflicting_file $new_file_name
    }
}

if (".dat" -ne [IO.Path]::GetExtension($File)) {
    Write-Error "unpack-all chỉ có thể sử dụng với file .dat"
}

if ("" -eq $UnpackLocation) {
    $UnpackLocation = (Split-Path $File -Parent) `
        + '\' `
        + (Split-Path $File -LeafBase)
    $UnpackLocation = $UnpackLocation.Trim('\')
}
$previous_location = (Get-Location).Path
New-Item $UnpackLocation -ItemType Directory -Force | Out-Null
& "$PSScriptRoot/unpack.ps1" `
    -UnpackMode "dat" `
    -File $File `
    -Version $Version `
    -UnpackLocation $UnpackLocation
Set-Location $UnpackLocation
$file_filter_pattern = @{
    "ecl"        = "*.ecl"
    "msg"        = "st*.msg"
    "msg_ending" = "e*.msg"
    "std"        = "*.std"
}
$anms = Get-ChildItem `
    -File `
    -Filter "*.anm" `
    -Name
foreach ($anm in $anms) {
    & "$PSScriptRoot/unpack.ps1" `
        -UnpackMode "anm" `
        -File $anm `
        -Version $Version `
        -UnpackLocation "." `
        -ListUnpacked "anm spec file/$anm.txt"
    resolve_conflict_between_anms `
        -Version $Version `
        -ConflictingAnm $anm
    Remove-Item $anm
}
foreach ($file_type in "ecl", "msg", "msg_ending") {
    $files = Get-ChildItem `
        -File `
        -Filter $file_filter_pattern[$file_type] `
        -Exclude "staff*.msg" `
        -Name
    foreach ($file in $files) {
        & "$PSScriptRoot\dump.ps1" `
            -DumpMode $file_type `
            -File $file `
            -Version $Version `
            -OutputFile ""
    }
}
Set-Location $previous_location