param(
    # Path to Touhou data folder
    [Parameter(
        Mandatory = $true,
        Position = 0,
        HelpMessage = "Path to data folder")]
    [ValidateNotNullOrEmpty()]
    [string]
    $Folder,
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
        HelpMessage = "Path to output file. Empty = thxx repack.dat")]
    [AllowEmptyString()]
    [string]
    $OutputFile
)

function prepare_texture {
    param(
        [Parameter(Position = 0)]
        [string] $Version,
        [Parameter(Position = 0)]
        [string] $AnmFile,
        [Parameter(Position = 0)]
        [switch] $UndoRename
    )
    . ("$PSScriptRoot/conflicting-files.ps1")
    if ($conflicting_files[$Version].ContainsKey($AnmFile)) {
        if (-not $UndoRename) {
            $file_processing = $conflicting_files[$Version][$AnmFile]
            $new_name = Split-Path -Leaf $file_processing
            $old_name = $(Split-Path $file_processing) + '\' `
                + $(Split-Path $new_name -LeafBase) `
                + " ($AnmFile)" `
                + $(Split-Path $new_name -Extension)
            Write-Host "Preparing $file_processing for repacking"
            Rename-Item $old_name $new_name
        }
        else {
            $file_processing = $conflicting_files[$Version][$AnmFile]
            $new_name = Split-Path -Leaf $file_processing
            $old_name = $(Split-Path $new_name -LeafBase) `
                + " ($AnmFile)" `
                + $(Split-Path $new_name -Extension)
            Rename-Item $file_processing $old_name
        }
    }
}

$previous_location = (Get-Location).Path

if ("" -eq $OutputFile) {
    $OutputFile = "th" + $Version + " repack.dat"
}
New-Item $OutputFile -ItemType File -Force | Out-Null
$output_file_absolute = Resolve-Path $OutputFile
Set-Location $Folder
$anm_spec_files = @(Get-ChildItem "anm spec file" -File -Filter "*.anm.txt" -Name)
foreach ($anm_spec_file in $anm_spec_files) {
    $anm_file = Split-Path $anm_spec_file -LeafBase
    prepare_texture `
        -Version $Version `
        -AnmFile $anm_file
    & "$PSScriptRoot/repack.ps1" `
        -FileType "anm" `
        -Folder "." `
        -ArchiveContent "anm spec file/$anm_spec_file" `
        -Version $Version `
        -OutputFile $anm_file
    prepare_texture `
        -Version $Version `
        -AnmFile $anm_file `
        -UndoRename
}
$text_file_ext = @{
    "ecl"        = "*.ecl.txt"
    "msg"        = "st*.msg.txt"
    "msg_ending" = "e*.msg.txt"
    "std"        = "*.std.txt"
}
foreach ($file_type in "ecl", "msg", "msg_ending") {
    $undump_files = @(Get-ChildItem -Filter $text_file_ext[$file_type] -File -Name)
    foreach ($undump_file in $undump_files) {
        $undump_output_file_name = Split-Path $undump_file -LeafBase
        & "$PSScriptRoot/undump.ps1" `
            -FileType $file_type `
            -File $undump_file `
            -Version $Version `
            -OutputFile $undump_output_file_name
    }
}
& "$PSScriptRoot/repack.ps1" `
    -FileType "dat" `
    -Folder "." `
    -ArchiveContent $(Get-ChildItem -Filter "*.dat.txt" -File -Name) `
    -Version $Version `
    -OutputFile $output_file_absolute
Set-Location $previous_location