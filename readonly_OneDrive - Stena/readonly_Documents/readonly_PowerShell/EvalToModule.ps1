param (
    $CertThumbprint,
    $CertStoreLocation,
    [Parameter()]
    [ValidateSet("Mise", "Zoxide", "Starship")]
    $EvalType = "Starship",
    $Version = "1.0.0"
)

function EnsureFolderExists {
    param (
        [Parameter()]
        $FilePath
    )

    $FullFilePath = Join-Path -Path $FilePath -ChildPath "Modules\$($EvalType)Init\$Version\"
    if (-not (Test-Path -Path $FullFilePath)) {
        New-Item -Path $FullFilePath -ItemType Directory -Force | Out-Null
    }
}

function PrintModule {
    param (
        [Parameter()]
        $EvalType,
        [Parameter()]
        $FilePath
    )

    switch ($EvalType) {
        "Mise" {
            $module = mise activate pwsh | Out-String
            $filename = "MiseInit.psm1"
        }
        "Zoxide" {
            $module = zoxide init powershell --cmd cd | Out-String
            $filename = "ZoxideInit.psm1"
        }
        "Starship" {
            $module = starship.exe init powershell --print-full-init | Out-String
            $filename = "StarshipInit.psm1"
        }
        default {
            throw "Unsupported EvalType: $EvalType"
        }
    }

    $FullFilePath = Join-Path -Path $FilePath -ChildPath "Modules\$($EvalType)Init\$Version\$filename"

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
        $Version = "1.0"
    )

    switch ($EvalType) {
        "Mise" {
            $filename = "MiseInit.psd1"
        }
        "Zoxide" {
            $filename = "ZoxideInit.psd1"
        }
        "Starship" {
            $filename = "StarshipInit.psd1"
        }
        default {
            throw "Unsupported EvalType: $EvalType"
        }
    }
    $FullFilePath = Join-Path -Path $FilePath -ChildPath "Modules\$($EvalType)Init\$Version\$filename"

    New-ModuleManifest -Path $FullFilePath -RootModule "$($EvalType)Init.psm1" -Author "Sohan Fernando" -Description "$($EvalType) shell prompt init" -ModuleVersion $Version -CompanyName "Unknown" -Copyright "(c) 2025 Sohan Fernando. All rights reserved." -GUID ([guid]::NewGuid()) | Out-Null
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
        [ValidateSet("Mise", "Zoxide", "Starship")]
        $EvalType,
        [Parameter()]
        [string]
        $FilePath
    )

    if (-not $CertThumbprint) {
        throw "CertThumbprint is required for signing the module."
    }

    $cert = Get-ChildItem -Path $CertStoreLocation | Where-Object { $_.Thumbprint -eq $CertThumbprint }

    if (-not $cert) {
        throw "Certificate with thumbprint $CertThumbprint not found in store $CertStoreLocation."
    }

    $modulePath = Join-Path -Path $FilePath -ChildPath "Modules\$($EvalType)Init\$Version\$($EvalType)Init.psm1"
    $manifestPath = Join-Path -Path $FilePath -ChildPath "Modules\$($EvalType)Init\$Version\$($EvalType)Init.psd1"

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

EnsureFolderExists -FilePath $script:CurrentDir

PrintModule -EvalType $EvalType -FilePath $script:CurrentDir

PrintModuleManifest -EvalType $EvalType -FilePath $script:CurrentDir -Version $Version

if ($CertThumbprint) {
    SignModule -CertThumbprint $CertThumbprint -CertStoreLocation $CertStoreLocation -EvalType $EvalType -FilePath $script:CurrentDir
}
