# EvalToModule

Pre-renders a shell-integration "eval" snippet into a **signed, versioned PowerShell module**
so the profile doesn't have to spawn the tool and `Invoke-Expression` its output on every start.

Instead of this in the profile:

```powershell
starship.exe init powershell --print-full-init | Out-String | Invoke-Expression   # spawns starship every start
op completion powershell | Out-String | Invoke-Expression                         # spawns op every start
```

you run `EvalToModule.ps1` once per tool, then the profile just does:

```powershell
Import-Module StarshipInit
Import-Module ZoxideInit
Import-Module OpInit
```

The rendered module lands in `Modules\<EvalType>Init\<Version>\` and PowerShell auto-discovers it
(this folder is on `$env:PSModulePath` because the profile lives in the PowerShell user dir).

## Supported tools (`-EvalType`)

| `-EvalType` | Init command captured                              | Module produced |
|-------------|----------------------------------------------------|-----------------|
| `Starship`  | `starship.exe init powershell --print-full-init`   | `StarshipInit`  |
| `Zoxide`    | `zoxide init powershell --cmd cd`                  | `ZoxideInit`    |
| `Mise`      | `mise activate pwsh`                               | `MiseInit`      |
| `Op`        | `op completion powershell`                         | `OpInit`        |

To add another tool, add one entry to `$script:EvalDefinitions` in `EvalToModule.ps1`
(`Init`, `VersionCmd`, `Description`) and add its name to the `-EvalType` `ValidateSet`.

## Usage

```powershell
# Regenerate a module at the tool's *current* version (auto-detected), unsigned:
.\EvalToModule.ps1 -EvalType Starship

# Generate the 1Password completion module:
.\EvalToModule.ps1 -EvalType Op

# Generate and sign in one go:
.\EvalToModule.ps1 -EvalType Starship -CertThumbprint <THUMBPRINT>

# Pin an explicit version instead of auto-detecting:
.\EvalToModule.ps1 -EvalType Zoxide -Version 0.9.9
```

### Re-running after you update a tool (Starship / Zoxide / etc.)

By default `-Version auto` reads the tool's own version (e.g. `starship --version`) and uses it
as the module version. So after `winget upgrade`-ing a tool, just re-run:

```powershell
.\EvalToModule.ps1 -EvalType Starship                 # e.g. now lands in Modules\StarshipInit\1.24.2\
.\EvalToModule.ps1 -EvalType Zoxide
```

A new tool version produces a **new versioned folder**; PowerShell auto-loads the highest version,
so the next shell picks up the update. The module **GUID is preserved** across versions, so the
module identity stays stable. Old version folders are left in place — delete them by hand if you
want to tidy up. Changes take effect in a **new** shell (the current session already imported the
old module).

## Signing

Signing is optional and triggered simply by passing `-CertThumbprint`. By default the cert is
looked up in `Cert:\CurrentUser\My`; override with `-CertStoreLocation`.

```powershell
.\EvalToModule.ps1 -EvalType Op -CertThumbprint A1B2C3... -CertStoreLocation Cert:\CurrentUser\My
```

> Note: signing only *matters* if your `ExecutionPolicy` is `AllSigned` / `RemoteSigned` for local
> scripts. Under `Unrestricted` an unsigned module still imports. Signing your own generated modules
> pairs well with tightening `ExecutionPolicy` to `RemoteSigned`.

### Finding a signing-cert thumbprint

List code-signing certs you already have in your personal store:

```powershell
Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Format-List Subject, Thumbprint, NotAfter
```

Or list everything and filter:

```powershell
Get-ChildItem Cert:\CurrentUser\My |
    Where-Object { $_.EnhancedKeyUsageList.FriendlyName -contains 'Code Signing' } |
    Select-Object Subject, Thumbprint, NotAfter
```

The `Thumbprint` value (40 hex chars, no spaces) is what you pass to `-CertThumbprint`.

### Creating a self-signed code-signing certificate

If you don't have one, create a self-signed cert for personal use:

```powershell
$cert = New-SelfSignedCertificate `
    -Subject "CN=Sohan Fernando Code Signing" `
    -Type CodeSigningCert `
    -KeyUsage DigitalSignature `
    -KeyAlgorithm RSA -KeyLength 2048 `
    -CertStoreLocation Cert:\CurrentUser\My `
    -NotAfter (Get-Date).AddYears(5)

$cert.Thumbprint   # <- pass this to -CertThumbprint
```

For the OS (and PowerShell under `AllSigned`/`RemoteSigned`) to *trust* a self-signed cert, also
copy it into the Trusted Root and Trusted Publisher stores (requires an elevated session):

```powershell
# Export the public cert...
$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Select-Object -First 1
Export-Certificate -Cert $cert -FilePath "$env:TEMP\codesign.cer" | Out-Null

# ...then import it as trusted (run elevated):
Import-Certificate -FilePath "$env:TEMP\codesign.cer" -CertStoreLocation Cert:\CurrentUser\Root
Import-Certificate -FilePath "$env:TEMP\codesign.cer" -CertStoreLocation Cert:\CurrentUser\TrustedPublisher
```

### Verifying a signature

```powershell
Get-AuthenticodeSignature .\Modules\StarshipInit\1.24.2\StarshipInit.psm1 | Format-List
```

`Status` should be `Valid` (or `UnknownError`/`NotTrusted` if the cert isn't in a trusted store).
