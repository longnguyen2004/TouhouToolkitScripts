param(
    [Parameter(
        Mandatory = $true,
        Position = 0,
        HelpMessage = "File format: dat, anm")]
    [ValidateNotNullOrEmpty()]
    [string]
    $FileType,
    [Parameter(
        Mandatory = $true,
        Position = 0,
        HelpMessage = "Folder input")]
    [ValidateNotNullOrEmpty()]
    [string]
    $Folder,
    [Parameter(
        Mandatory = $true,
        Position = 0,
        HelpMessage = "List of files to repack (anm spec file for anm)")]
    [ValidateNotNullOrEmpty()]
    [string]
    $ArchiveContent,
    [Parameter(
        Mandatory = $true,
        Position = 0,
        HelpMessage = "Touhou version")]
    [ValidateNotNullOrEmpty()]
    [string]
    $Version,
    [Parameter(
        Mandatory = $true,
        Position = 0,
        HelpMessage = "Output file")]
    [ValidateNotNullOrEmpty()]
    [string]
    $OutputFile
)

function repack_anm {
    param(
        [Parameter(Position = 0)]
        [string] $ArchiveContent,
        [Parameter(Position = 0)]
        [string] $OutputFile
    )
    & "thanm" -c $OutputFile $ArchiveContent -m $anmmaps[$Version]
}

function repack_dat {
    param(
        [Parameter(Position = 0)]
        [string] $ArchiveContent,
        [Parameter(Position = 0)]
        [string] $Version,
        [Parameter(Position = 0)]
        [string] $OutputFile
    )
    $file_list = @(Get-Content $ArchiveContent)
    & "thdat" -c $Version $OutputFile @file_list
}

function repack {
    param(
        [Parameter(Position = 0)]
        [string] $FileType,
        [Parameter(Position = 0)]
        [string] $Folder,
        [Parameter(Position = 0)]
        [string] $ArchiveContent,
        [Parameter(Position = 0)]
        [string] $Version,
        [Parameter(Position = 0)]
        [string] $OutputFile
    )
    $prev_path = $Env:Path
    $thtk_dir = "$PSScriptRoot/thtk/bin"
    if (-not (Test-Path $thtk_dir)) {
        Write-Error "Cannot find thtk!" -ErrorAction Stop
    }
    $Env:Path += ";$thtk_dir"
    if (-not (Test-Path $Folder)) {
        Write-Error "Cannot find $Folder!" -ErrorAction Stop 
    }
    $previous_location = (Get-Location).Path
    if (-not (Test-Path $OutputFile)) {
        New-Item $OutputFile -ItemType File -Force | Out-Null
    }
    $archive_content_absolute = Resolve-Path $ArchiveContent
    $output_file_absolute = Resolve-Path $OutputFile
    $folder_name = Split-Path $Folder -Leaf
    $archive_content_name = Split-Path $ArchiveContent -Leaf
    $output_file_name = Split-Path $OutputFile -Leaf
    Write-Host "Repacking: Folder $folder_name + $archive_content_name --> $output_file_name"
    Set-Location $Folder
    Switch ($FileType) {
        "dat" {
            repack_dat `
                -ArchiveContent $archive_content_absolute `
                -Version $Version `
                -OutputFile $output_file_absolute
        }
        "anm" {
            repack_anm `
                -ArchiveContent $archive_content_absolute `
                -OutputFile $output_file_absolute
        }
    }

    Set-Location $previous_location
    $Env:Path = $prev_path
}

repack `
    -FileType $FileType `
    -Folder $Folder `
    -ArchiveContent $ArchiveContent `
    -Version $Version `
    -OutputFile $OutputFile