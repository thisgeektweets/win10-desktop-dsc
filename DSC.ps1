Configuration Win10Desktop

{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DSCResource -ModuleName xCertificate
    Import-DSCResource -ModuleName cChoco
    Import-DSCResource -ModuleName Carbon
    Import-DSCResource -ModuleName ComputerManagementDSC
    Import-DSCResource -ModuleName cDTC
    Import-DscResource -ModuleName NetworkingDsc
    Import-DscResource -Module xWebAdministration
    Import-DscResource -Module cNtfsAccessControl
    Import-DscResource -Name MSFT_xSmbShare
    Import-DscResource -Name VSS
    Import-DscResource -Name VSSTaskScheduler
    Import-DscResource -Name xDSCDomainJoin
    Import-DscResource -Name UserRightsAssignment

    Node 'localhost'
{
<#Install Client Hyper-V Role#>
    Script Hyper-V
    {
        GetScript  = {
            Write-Verbose "Get current status for Microsoft-Hyper-V Feature"
            $hyperVFeatureState = Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V -Online -ErrorAction SilentlyContinue
            return @{
                Result = $hyperVFeatureState
            }
        }

        SetScript  = {
            Write-Verbose "Activating Microsoft-Hyper-V Feature"
            Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
        }

        TestScript = {
            Write-Verbose "Test the current status for Microsoft-Hyper-V Feature"
            $hyperVFeatureState = & ([ScriptBlock]::Create($GetScript))

            Write-Verbose "Current status is: $($hyperVFeatureState.Result.State)"

            return $hyperVFeatureState.Result.State -eq 'Enabled'
        }
    }

<#Create and Share Custom Directories#>
    File Share
        {
            DestinationPath="C:\Share"
            Ensure="Present"
            Type="Directory"
        }
	cNtfsPermissionEntry ShareAdministrators
    <#Uses cNtfsAccessControl from https://www.powershellgallery.com/packages/cNtfsAccessControl/1.4.1#>
        {
            Ensure                   = 'Present'
            Path                     = 'C:\Share'
            Principal                = 'Administrators'
            AccessControlInformation = 
            @(
                cNtfsAccessControlInformation {
                AccessControlType = 'Allow'
                FileSystemRights = 'Full'
                Inheritance = 'ThisFolderSubfoldersAndFiles'
                NoPropagateInherit = $false
            })
            Dependson="[File]Share" 
        }
	cNtfsPermissionEntry ShareUsers
    <#Uses cNtfsAccessControl from https://www.powershellgallery.com/packages/cNtfsAccessControl/1.4.1#>
        {
            Ensure                   = 'Present'
            Path                     = 'C:\Share'
            Principal                = 'Users'
            AccessControlInformation = 
            @(
                cNtfsAccessControlInformation {
                AccessControlType = 'Allow'
                FileSystemRights = 'Read'
                Inheritance = 'ThisFolderSubfoldersAndFiles'
                NoPropagateInherit = $false
            })
            Dependson="[File]Share" 
        }

    File GIT
        {
            DestinationPath="C:\GIT"
            Ensure="Present"
            Type="Directory"
        }
	cNtfsPermissionEntry GITAdministrators
    <#Uses cNtfsAccessControl from https://www.powershellgallery.com/packages/cNtfsAccessControl/1.4.1#>
        {
            Ensure                   = 'Present'
            Path                     = 'C:\GIT'
            Principal                = 'Administrators'
            AccessControlInformation = 
            @(
                cNtfsAccessControlInformation {
                AccessControlType = 'Allow'
                FileSystemRights = 'Full'
                Inheritance = 'ThisFolderSubfoldersAndFiles'
                NoPropagateInherit = $false
            })
            Dependson="[File]GIT" 
        }
	cNtfsPermissionEntry GITUsers
    <#Uses cNtfsAccessControl from https://www.powershellgallery.com/packages/cNtfsAccessControl/1.4.1#>
        {
            Ensure                   = 'Present'
            Path                     = 'C:\GIT'
            Principal                = 'Users'
            AccessControlInformation = 
            @(
                cNtfsAccessControlInformation {
                AccessControlType = 'Allow'
                FileSystemRights = 'Read'
                Inheritance = 'ThisFolderSubfoldersAndFiles'
                NoPropagateInherit = $false
            })
            Dependson="[File]GIT" 
        }

<#Install Apps with Choco#>
	cChocoInstaller installChoco
        {
            InstallDir = "c:\choco"
        }
	cChocoPackageInstaller vcredist2008
        {
            Name="vcredist2008"
            DependsOn = "[cChocoInstaller]installChoco"
        }
	cChocoPackageInstaller vcredist2010
        {
            Name="vcredist2010"
            DependsOn = "[cChocoInstaller]installChoco"
        }
	cChocoPackageInstaller vcredist2013
        {
            Name="vcredist2013"
            DependsOn = "[cChocoInstaller]installChoco"
        }
	cChocoPackageInstaller vcredist2017
        {
            Name="vcredist2017"
            DependsOn = "[cChocoInstaller]installChoco"
        }
	cChocoPackageInstaller dotnet472 
        {
            Name="dotnet4.7.2"
            DependsOn = "[cChocoInstaller]installChoco"
        }
    cChocoPackageInstaller libreoffice-fresh
        {
            Name="libreoffice-fresh"
            DependsOn = "[cChocoInstaller]installChoco"
        }
    cChocoPackageInstaller spotify
        {
            Name="spotify"
            DependsOn = "[cChocoInstaller]installChoco"
        }
    cChocoPackageInstaller vscode
        {
            Name="vscode"
            DependsOn = "[cChocoInstaller]installChoco"
        }
    cChocoPackageInstaller firefox
        {
            Name="firefox"
            DependsOn = "[cChocoInstaller]installChoco"
        }
    cChocoPackageInstaller sourcetree
        {
            Name="sourcetree"
            DependsOn = "[cChocoInstaller]installChoco"
        }
    cChocoPackageInstaller notepadplusplus
        {
            Name="notepadplusplus.install"
            DependsOn = "[cChocoInstaller]installChoco"
        }

<#Disables Obsolete Cipher Suites#>
    Registry RegKeyTLS12ClientDisabledDefault
    {
        Ensure      = "Present" 
        Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client"
        ValueName   = "DisabledByDefault"
        ValueData   = "0"
        ValueType   = "DWORD"
    }

    Registry RegKeyTLSTLS12ClientEnabled
    {
        Ensure      = "Present" 
        Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client"
        ValueName   = "enabled"
        ValueData   = "1"
        ValueType   = "DWORD"
    }

    Registry RegKeyTLS12ServerDisabledDefault
    {
        Ensure      = "Present" 
        Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server"
        ValueName   = "DisabledByDefault"
        ValueData   = "0"
        ValueType   = "DWORD"
    }

    Registry RegKeyTLSTLS12ServerEnabled
    {
        Ensure      = "Present" 
        Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server"
        ValueName   = "enabled"
        ValueData   = "1"
        ValueType   = "DWORD"
    }

    LocalConfigurationManager
    {
        RebootNodeIfNeeded = $True
    }
}
}

$ConfigData = @{
    AllNodes = @(
    @{
        NodeName = "localhost";
        PSDscAllowPlainTextPassword = $true;
        PSDscAllowDomainUser = $true;
    }
)}

Win10Desktop -ConfigurationData $ConfigData

start-dscConfiguration -path ./Win10Desktop -wait -force -verbose