param(
    # Dump mode: ecl, msg, msg_ending, std
    [Parameter(
        Mandatory = $true,
        Position = 0,
        HelpMessage = "Dump mode: ecl, msg, msg_ending, std")]
    [ValidateNotNullOrEmpty()]
    [string]
    $DumpMode,
    # Path to Touhou data file
    [Parameter(
        Mandatory = $true,
        Position = 0,
        HelpMessage = "Path to file")]
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
        HelpMessage = "Output file. Empty = {Input file}.txt")]
    [AllowEmptyString()]
    [string]
    $OutputFile
)

function dump {
    param (
        [Parameter(Position = 0)]
        [string] $DumpMode,
        [Parameter(Position = 0)]
        [string] $File,
        [Parameter(Position = 0)]
        [string] $Version,
        [Parameter(Position = 0)]
        [string] $OutputFile
    )
    . ("$PSScriptRoot/maplist.ps1")
    $prev_path = $Env:Path
    $thtk_dir = "$PSScriptRoot\thtk\bin"
    if (-not (Test-Path $thtk_dir)) {
        Write-Error "Cannot find thtk!" -ErrorAction Stop
    }
    $Env:Path += ";$thtk_dir"
    $DumpCommand = @{
        "ecl"        = "thecl.exe -d {0} `"{1}`" `"{2}`" -m `"{3}`""
        "msg"        = "thmsg.exe -d {0} `"{1}`" `"{2}`""
        "msg_ending" = "thmsg.exe -e -d {0} `"{1}`" `"{2}`""
        "std"        = "thstd.exe -d {0} `"{1}`" `"{2}`""
    }
    if (-not (Test-Path $File)) {
        Write-Error "Cannot find $File!" -ErrorAction Stop 
    }
    $eclmap_file_path = $eclmaps[$Version]
    $eclmap_name = Split-Path -LeafBase $eclmap_file_path
    if ("" -eq $OutputFile) {
        $OutputFile = $File + ".txt"
    }
    $file_name = Split-Path $File -Leaf
    $output_file_name = Split-Path $OutputFile -Leaf
    $expression = $DumpCommand[$DumpMode] -f $Version, $File, $OutputFile, $eclmap_file_path
    Write-Host -NoNewLine "Dumping: $file_name --> $output_file_name "
    if ("ecl" -eq $DumpMode) {
        Write-Host -NoNewline ("using ecl map " + $eclmap_name)
    }
    Write-Host ""
    Invoke-Expression $expression
    $Env:Path = $prev_path
}

dump `
    -DumpMode $DumpMode `
    -File $File `
    -Version $Version `
    -OutputFile $OutputFile