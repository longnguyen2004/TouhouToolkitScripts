param(
    [Parameter(
        Mandatory = $true,
        Position = 0,
        HelpMessage = "File format: ecl, msg, msg_ending, std")]
    [ValidateNotNullOrEmpty()]
    [string]
    $FileType,
    [Parameter(
        Mandatory = $true,
        Position = 0,
        HelpMessage = "Input file")]
    [ValidateNotNullOrEmpty()]
    [string]
    $File,
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

function undump {
    param (
        [Parameter(Position = 0)]
        [string] $FileType,
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
    $UndumpCommand = @{
        "ecl"        = "thecl.exe -c {0} `"{1}`" `"{2}`" -m `"{3}`""
        "msg"        = "thmsg.exe -c {0} `"{1}`" `"{2}`""
        "msg_ending" = "thmsg.exe -e -c {0} `"{1}`" `"{2}`""
        "std"        = "thstd.exe -c {0} `"{1}`" `"{2}`""
    }
    $Env:Path += ";$thtk_dir"
    if (-not (Test-Path $File)) {
        Write-Error "Cannot find $File!" -ErrorAction Stop 
    }
    $eclmap_file_path = $eclmaps[$Version]
    $eclmap_name = Split-Path -LeafBase $eclmap_file_path
    $file_name = Split-Path $File -Leaf
    $output_file_name = Split-Path $OutputFile -Leaf
    $expression = $UndumpCommand[$FileType] -f $Version, $File, $OutputFile, $eclmap_file_path
    Write-Host -NoNewLine "Creating: $file_name --> $output_file_name "
    if ("ecl" -eq $FileType) {
        Write-Host -NoNewline ("using ecl map " + $eclmap_name)
    }
    Write-Host ""
    Invoke-Expression $expression
    $Env:Path = $prev_path
}

undump `
    -FileType $FileType `
    -File $File `
    -Version $Version `
    -OutputFile $OutputFile