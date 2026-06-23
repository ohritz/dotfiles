<#
.SYNOPSIS
  Create a self-signed code signing certificate, export the public certificate,
  and add it to the LocalMachine Trusted Root Certification Authorities store.

.NOTES
  - Must run PowerShell as Administrator to import into the LocalMachine\Root store.
  - The private key remains in CurrentUser\My. If you need to export the private key,
    change -KeyExportPolicy to Exportable and export a PFX (not shown here).
#>

param(
    [string]$Subject = "CN=MyCodeSigningCert-$env:USERNAME",
    [string]$CertStoreLocation = "Cert:\CurrentUser\My",
    [string]$ExportPath = "$env:USERPROFILE\Documents\MyCodeSigningCert.cer",
    [int]$ValidYears = 5,
    [int]$KeyLength = 4096
)

function Assert-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Error "This script must be run as Administrator. Re-run PowerShell elevated (Run as Administrator)."
        exit 1
    }
}

# We will require admin to import into LocalMachine\Root; creating cert in CurrentUser\My does not require admin.
# Check Admin only when needed (import).
Assert-Admin

try {
    # Create a unique subject with timestamp to avoid collisions
    $timestamp = (Get-Date -Format "yyyyMMddHHmmss")
    $subjectUnique = if ($Subject -match "CN=") { "$Subject-$timestamp" } else { "CN=$Subject-$timestamp" }

    Write-Host "Creating self-signed code-signing certificate for subject: $subjectUnique"
    $notAfter = (Get-Date).AddYears([int]$ValidYears)

    # Create certificate in CurrentUser\My
    $cert = New-SelfSignedCertificate `
        -Type CodeSigningCert `
        -Subject $subjectUnique `
        -CertStoreLocation $CertStoreLocation `
        -KeyAlgorithm RSA `
        -KeyLength $KeyLength `
        -HashAlgorithm SHA256 `
        -NotAfter $notAfter `
        -KeyExportPolicy NonExportable  `
        -FriendlyName "Local Self-Signed CodeSigning Cert ($env:USERNAME)"

    if (-not $cert) {
        throw "Failed to create certificate."
    }

    Write-Host "Certificate created. Thumbprint: $($cert.Thumbprint)"
    Write-Host "Exporting public certificate to: $ExportPath"

    # Ensure the directory exists
    $exportDir = Split-Path -Path $ExportPath -Parent
    if (-not (Test-Path -Path $exportDir)) {
        New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
    }

    # Export the public certificate (DER encoded .cer)
    Export-Certificate -Cert $cert -FilePath $ExportPath -Type CERT -Force | Out-Null

    if (-not (Test-Path -Path $ExportPath)) {
        throw "Export failed; file not found at $ExportPath"
    }

    Write-Host "Public certificate exported."

    # Now import the .cer into LocalMachine\Root (Trusted Root CA)

    Write-Host "Importing the public certificate into LocalMachine\Root (Trusted Root Certification Authorities)..."

    # Use Import-Certificate for the LocalMachine\Root
    $importResult = Import-Certificate -FilePath $ExportPath -CertStoreLocation "Cert:\LocalMachine\Root" -Verbose:$false

    if ($importResult -and $importResult.Certificate) {
        $importedThumb = $importResult.Certificate.Thumbprint
        Write-Host "Successfully imported certificate into LocalMachine\Root. Thumbprint: $importedThumb"
    } else {
        throw "Import-Certificate returned no certificate object. Import might have failed."
    }

    Write-Host ""
    Write-Host "Done."
    Write-Host "Summary:"
    Write-Host " - Created cert (CurrentUser\My) thumbprint: $($cert.Thumbprint)"
    Write-Host " - Exported public cert: $ExportPath"
    Write-Host " - Imported into LocalMachine\Root thumbprint: $importedThumb"
    Write-Host ""
    Write-Host "Notes:"
    Write-Host " - The private key remains in your CurrentUser\My store and is non-exportable by default."
    Write-Host " - If you need to sign scripts from other machines, you'll need to export a PFX (private key) and protect it."
    Write-Host " - WDAC / Constrained Language Mode will still not be bypassed by a local self-signed cert in environments where WDAC enforces a different trust policy."
}
catch {
    Write-Error "Error: $($_.Exception.Message)"
    exit 1
}
