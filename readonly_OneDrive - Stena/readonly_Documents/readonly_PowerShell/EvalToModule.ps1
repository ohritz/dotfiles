<#
.SYNOPSIS
    Pre-renders a shell-integration "eval" snippet into a signed, versioned PowerShell module.

.DESCRIPTION
    Tools like Starship, Zoxide, Mise and the 1Password CLI are normally wired into the
    profile with a live `<tool> init ... | Out-String | Invoke-Expression`, which spawns the
    tool and re-evaluates its output on every shell start. This script captures that output
    once into Modules\<EvalType>Init\<Version>\<EvalType>Init.psm1 (plus a manifest), so the
    profile can just `Import-Module <EvalType>Init` with no per-start process spawn.

    Re-run it whenever you update one of the tools — by default the module version is the
    tool's own reported version, so a new tool version produces a new versioned module folder
    and PowerShell auto-loads the highest version. The module GUID is preserved across
    versions so the module identity stays stable.

.EXAMPLE
    .\EvalToModule.ps1 -EvalType Starship
    Regenerate StarshipInit at Starship's current version (unsigned).

.EXAMPLE
    .\EvalToModule.ps1 -EvalType Op -CertThumbprint ABCD...1234
    Generate OpInit (1Password completion) and Authenticode-sign it.

.NOTES
    See README.md for how to find a signing-cert thumbprint or create a self-signed one.
#>
param (
    [Parameter()]
    [string]
    $CertThumbprint,

    [Parameter()]
    [string]
    $CertStoreLocation,

    [Parameter()]
    [ValidateSet("Mise", "Zoxide", "Starship", "Op")]
    [string]
    $EvalType = "Starship",

    # Module version. "auto" (the default) detects the tool's own version so re-running
    # after a tool upgrade lands in a fresh versioned folder. Pass an explicit version to override.
    [Parameter()]
    [string]
    $Version = "auto"
)

# Single source of truth per tool: how to render its init script, how to read its version,
# and the manifest description. Adding a new tool = one entry here.
$script:EvalDefinitions = @{
    Mise     = @{
        Init        = { mise activate pwsh }
        VersionCmd  = { mise --version }
        Description = "Mise runtime/version-manager activation"
    }
    Zoxide   = @{
        Init        = { zoxide init powershell --cmd cd }
        VersionCmd  = { zoxide --version }
        Description = "Zoxide smarter-cd init"
    }
    Starship = @{
        Init        = { starship.exe init powershell --print-full-init }
        VersionCmd  = { starship.exe --version }
        Description = "Starship shell prompt init"
    }
    Op       = @{
        Init        = { op completion powershell }
        VersionCmd  = { op --version }
        Description = "1Password CLI shell completion"
    }
}

function Get-ModuleRoot {
    param ($FilePath, $EvalType)
    Join-Path -Path $FilePath -ChildPath "Modules\$($EvalType)Init"
}

function Get-VersionFolder {
    param ($FilePath, $EvalType, $Version)
    Join-Path -Path (Get-ModuleRoot -FilePath $FilePath -EvalType $EvalType) -ChildPath $Version
}

function ResolveVersion {
    param ($EvalType, $Version)

    if ($Version -and $Version -ne "auto") {
        return $Version
    }

    $def = $script:EvalDefinitions[$EvalType]
    try {
        $raw = (& $def.VersionCmd) | Out-String
        if ($raw -match '(\d+\.\d+\.\d+)') { return $matches[1] }
        if ($raw -match '(\d+\.\d+)') { return $matches[1] }
    }
    catch {
        Write-Warning "Failed to run version command for $($EvalType): $_"
    }

    Write-Warning "Could not auto-detect $EvalType version; defaulting to 1.0.0."
    return "1.0.0"
}

function EnsureFolderExists {
    param (
        [Parameter()]
        $FilePath,
        [Parameter()]
        $EvalType,
        [Parameter()]
        $Version
    )

    $FullFilePath = Get-VersionFolder -FilePath $FilePath -EvalType $EvalType -Version $Version
    if (-not (Test-Path -Path $FullFilePath)) {
        New-Item -Path $FullFilePath -ItemType Directory -Force | Out-Null
    }
}

function PrintModule {
    param (
        [Parameter()]
        $EvalType,
        [Parameter()]
        $FilePath,
        [Parameter()]
        $Version
    )

    $def = $script:EvalDefinitions[$EvalType]
    $module = & $def.Init | Out-String

    if ([string]::IsNullOrWhiteSpace($module)) {
        throw "The init command for '$EvalType' produced no output. Is the tool installed and on PATH?"
    }

    $FullFilePath = Join-Path -Path (Get-VersionFolder -FilePath $FilePath -EvalType $EvalType -Version $Version) -ChildPath "$($EvalType)Init.psm1"
    $module | Out-File -FilePath $FullFilePath -Encoding utf8 -Force
}

function PrintModuleManifest {
    param (
        [Parameter()]
        $EvalType,
        [Parameter()]
        [string]
        $FilePath,
        [Parameter()]
        [string]
        $Version
    )

    $def = $script:EvalDefinitions[$EvalType]
    $FullFilePath = Join-Path -Path (Get-VersionFolder -FilePath $FilePath -EvalType $EvalType -Version $Version) -ChildPath "$($EvalType)Init.psd1"

    # Preserve the module GUID across regenerations / version bumps so the module identity
    # is stable. Reuse the GUID from any existing manifest for this module (any version).
    $guid = [guid]::NewGuid()
    $existingManifest = Get-ChildItem -Path (Get-ModuleRoot -FilePath $FilePath -EvalType $EvalType) `
        -Filter "$($EvalType)Init.psd1" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($existingManifest) {
        try {
            $existing = Import-PowerShellDataFile -Path $existingManifest.FullName
            if ($existing.GUID) { $guid = [guid]$existing.GUID }
        }
        catch {
            Write-Warning "Could not read existing GUID from $($existingManifest.FullName); generating a new one."
        }
    }

    New-ModuleManifest -Path $FullFilePath -RootModule "$($EvalType)Init.psm1" -Author "Sohan Fernando" `
        -Description $def.Description -ModuleVersion $Version -CompanyName "Unknown" `
        -Copyright "(c) 2025 Sohan Fernando. All rights reserved." -GUID $guid | Out-Null
}

function SignModule {
    param (
        [Parameter()]
        [string]
        $CertThumbprint,
        [Parameter()]
        [string]
        $CertStoreLocation,
        [Parameter()]
        [string]
        $EvalType,
        [Parameter()]
        [string]
        $FilePath,
        [Parameter()]
        [string]
        $Version
    )

    if (-not $CertThumbprint) {
        throw "CertThumbprint is required for signing the module."
    }

    $cert = Get-ChildItem -Path $CertStoreLocation | Where-Object { $_.Thumbprint -eq $CertThumbprint }

    if (-not $cert) {
        throw "Certificate with thumbprint $CertThumbprint not found in store $CertStoreLocation."
    }

    $versionFolder = Get-VersionFolder -FilePath $FilePath -EvalType $EvalType -Version $Version
    $modulePath = Join-Path -Path $versionFolder -ChildPath "$($EvalType)Init.psm1"
    $manifestPath = Join-Path -Path $versionFolder -ChildPath "$($EvalType)Init.psd1"

    if (Test-Path -Path $modulePath) {
        Set-AuthenticodeSignature -FilePath $modulePath -Certificate $cert | Out-Null
    }
    else {
        throw "Module file not found at path: $modulePath"
    }

    if (Test-Path -Path $manifestPath) {
        Set-AuthenticodeSignature -FilePath $manifestPath -Certificate $cert | Out-Null
    }
    else {
        throw "Manifest file not found at path: $manifestPath"
    }
}

$script:CurrentDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

if ([string]::IsNullOrEmpty($CertStoreLocation)) {
    $CertStoreLocation = "Cert:\CurrentUser\My"
}

$resolvedVersion = ResolveVersion -EvalType $EvalType -Version $Version
Write-Host "Generating $($EvalType)Init module (version $resolvedVersion)..." -ForegroundColor Cyan

EnsureFolderExists -FilePath $script:CurrentDir -EvalType $EvalType -Version $resolvedVersion

PrintModule -EvalType $EvalType -FilePath $script:CurrentDir -Version $resolvedVersion

PrintModuleManifest -EvalType $EvalType -FilePath $script:CurrentDir -Version $resolvedVersion

if ($CertThumbprint) {
    SignModule -CertThumbprint $CertThumbprint -CertStoreLocation $CertStoreLocation -EvalType $EvalType -FilePath $script:CurrentDir -Version $resolvedVersion
    Write-Host "Signed $($EvalType)Init $resolvedVersion with certificate $CertThumbprint." -ForegroundColor Green
}
else {
    Write-Host "No CertThumbprint supplied - module generated unsigned. See README.md to find or create a signing cert." -ForegroundColor Yellow
}

Write-Host "Done. Import with: Import-Module $($EvalType)Init" -ForegroundColor Green
