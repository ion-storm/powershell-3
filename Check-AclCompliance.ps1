# Generic Rights enum type
Add-Type -TypeDefinition @"
   public enum GenericRights
   {
      GENERIC_READ = 1 << 31,
      GENERIC_WRITE = 1 << 30,
      GENERIC_EXECUTE = 1 << 29,
      GENERIC_ALL = 1 << 28
   }
"@


<#
.SYNOPSIS
    This function returns the mapping of the File System Rights corresponding to the given
    Generic Rights.
.DESCRIPTION
    This function returns the mapping of the File System Rights corresponding to the given
    Generic Rights.
    Generic Rights mask are defined in the 4 highest order bits. They are mapped to the File 
    System Rights as follows:

    GENERIC_EXECUTE  FILE_EXECUTE (ExecuteFile)
                     FILE_READ_ATTRIBUTES (ReadAttributes)
                     STANDARD_RIGHTS_EXECUTE (ReadPermissions)
                     SYNCHRONIZE (Synchronize) 
    
    GENERIC_READ     FILE_READ_ATTRIBUTES (ReadAttributes)
                     FILE_READ_DATA (ReadData)
                     FILE_READ_EA (ReadExtendedAttributes)
                     STANDARD_RIGHTS_READ (ReadPermissions)
                     SYNCHRONIZE (Synchronize)

    GENERIC_WRITE    FILE_APPEND_DATA (AppendData)
                     FILE_WRITE_ATTRIBUTES (WriteAttributes)
                     FILE_WRITE_DATA (WriteData)
                     FILE_WRITE_EA (WriteExtendedAttributes)
                     STANDARD_RIGHTS_WRITE (ReadPermissions)
                     SYNCHRONIZE (Synchronize)

    GENERIC_ALL      FullControl

    The implementation of this method is based on the source code from
    http://blog.cjwdev.co.uk/2011/06/28/permissions-not-included-in-net-accessrule-filesystemrights-enum/

.PARAMETER right
    32bit access mask
    https://msdn.microsoft.com/en-us/library/aa374896%28v=vs.85%29.aspx
.EXAMPLE
    C:\PS>$rights = Get-FileSystemRightsFromGenericRights -right ([int]–1610612736)
    C:\PS>[System.Security.AccessControl.FileSystemRights]$rights
    ReadAndExecute, Synchronize
.EXAMPLE
    C:\PS>$rights = Get-FileSystemRightsFromGenericRights -right ([int]268435456)
    C:\PS>[System.Security.AccessControl.FileSystemRights]$rights
    FullControl
.LINK
   http://blog.cjwdev.co.uk/2011/06/28/permissions-not-included-in-net-accessrule-filesystemrights-enum/
    https://msdn.microsoft.com/en-us/library/aa374896%28v=vs.85%29.aspx
    https://msdn.microsoft.com/en-us/library/aa364399.aspx
    https://rohnspowershellblog.wordpress.com/2015/01/16/what-does-the-synchronize-file-system-right-mean/
.NOTES
    Author: Dario B. (darizotas at gmail dot com)
    Date:   May 26, 2015
        
    Copyright 2015 Dario B. darizotas at gmail dot com
    This software is licensed under a new BSD License.
    Unported License. http://opensource.org/licenses/BSD-3-Clause
#>
Function Get-FileSystemRightsFromGenericRights {
    Param(
        [Parameter(Mandatory=$true)]
        [int]$right
    )
    $mappedRights = 0

    if (($right -band [GenericRights]::GENERIC_READ) -eq [GenericRights]::GENERIC_READ) {
        $mappedRights = $mappedRights -bor [System.Security.AccessControl.FileSystemRights]::ReadAttributes `
           -bor [System.Security.AccessControl.FileSystemRights]::ReadData `
           -bor [System.Security.AccessControl.FileSystemRights]::ReadExtendedAttributes `
           -bor [System.Security.AccessControl.FileSystemRights]::ReadPermissions `
           -bor [System.Security.AccessControl.FileSystemRights]::Synchronize
    }
    if (($right -band [GenericRights]::GENERIC_WRITE) -eq [GenericRights]::GENERIC_WRITE) {
        $mappedRights = $mappedRights -bor [System.Security.AccessControl.FileSystemRights]::AppendData `
           -bor [System.Security.AccessControl.FileSystemRights]::WriteAttributes `
           -bor [System.Security.AccessControl.FileSystemRights]::WriteData `
           -bor [System.Security.AccessControl.FileSystemRights]::WriteExtendedAttributes `
           -bor [System.Security.AccessControl.FileSystemRights]::ReadPermissions `
           -bor [System.Security.AccessControl.FileSystemRights]::Synchronize
    }
    if (($right -band [GenericRights]::GENERIC_EXECUTE) -eq [GenericRights]::GENERIC_EXECUTE) {
        $mappedRights = $mappedRights -bor [System.Security.AccessControl.FileSystemRights]::ExecuteFile  `
           -bor [System.Security.AccessControl.FileSystemRights]::ReadPermissions `
           -bor [System.Security.AccessControl.FileSystemRights]::ReadAttributes `
           -bor [System.Security.AccessControl.FileSystemRights]::Synchronize
    }
    if (($right -band [GenericRights]::GENERIC_ALL) -eq [GenericRights]::GENERIC_ALL) {
        $mappedRights = $mappedRights -bor [System.Security.AccessControl.FileSystemRights]::FullControl
    }

    return $mappedRights
}

<#
.SYNOPSIS
    This function checks that the given folders and their corresponding baseline ACLs match
    against the existing ACLs.
.DESCRIPTION
    This function checks that the given folders and their corresponding baseline ACLs match
    against the existing ACLs. It makes use of Check-Acl.
    
    The folders and baseline ACLs must have the following properties:
    Folder : Path to the folder to check ACLs.
    Owner  : User or group account owner of the folder. Only the first appearance of this
             attribute will be taken into account.
    IdentityReference : User or group account associated to the access rule.
    FileSystemRights : Type of operation associated with the access rule.
    AccessControlType : Specifies whether to allow or deny the operation.
    
    All these headers will allow to build the security descriptor and, specifically the last
    three, the access rules (ACLs).
.PARAMETER config
    Array of objects that contains the folders and their corresponding baseline ACLs 
    that they must comply with.
.PARAMETER tofile
    The path to the file to export (CSV) the check.
.EXAMPLE
    C:\PS>Import-Csv "C:\My baseline.csv" | Check-AclBatch
.EXAMPLE
    C:\PS>Import-Csv "C:\My baseline.csv" | Check-AclBatch -tofile "C:\My baseline - results.csv"
.EXAMPLE
    C:\PS>$baseline = @(
      @{
        Folder = "\\SHARE\Folder";
        Owner = "DOMAIN\Owner";
        IdentityReference = "DOMAIN\UserGroupWithReadAndExecute";
        FileSystemRights = "ReadAndExecute";
        AccessControlType = "Allow"
      },
      @{
        Folder = "\\SHARE\Folder";
        Owner = "";
        IdentityReference = "DOMAIN\UserGroupWithFullControl";
        FileSystemRights = "FullControl";
        AccessControlType = "Allow"
      }
    )
    C:\PS>$baseline | Check-AclBatch 
.EXAMPLE
    C:\PS>$baseline = @(
      @{
        Folder = "\\SHARE\Folder";
        Owner = "DOMAIN\Owner";
        IdentityReference = "DOMAIN\UserGroupWithReadAndExecute";
        FileSystemRights = "ReadAndExecute";
        AccessControlType = "Allow"
      },
      @{
        Folder = "\\SHARE\Folder";
        Owner = "";
        IdentityReference = "DOMAIN\UserGroupWithFullControl";
        FileSystemRights = "FullControl";
        AccessControlType = "Allow"
      }
    )
    C:\PS>$baseline | Check-AclBatch -tofile "C:\My baseline - results.csv"
.LINK
   Check-Acl
    Get-FileSystemRightsFromGenericRights
    https://msdn.microsoft.com/en-us/library/system.security.principal.ntaccount(v=vs.110).aspx
    https://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights(v=vs.110).aspx
    https://msdn.microsoft.com/en-us/library/w4ds5h86(v=vs.110).aspx
    http://blogs.technet.com/b/heyscriptingguy/archive/2011/05/10/use-the-pipeline-to-create-robust-powershell-functions.aspx
    https://technet.microsoft.com/en-us/magazine/hh413265.aspx

.NOTES
    Author: Dario B. (darizotas at gmail dot com)
    Date:   May 26, 2015
        
    Copyright 2015 Dario B. darizotas at gmail dot com
    This software is licensed under a new BSD License.
    Unported License. http://opensource.org/licenses/BSD-3-Clause
#>
Function Check-AclBatch {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [object[]]$config,
        [string]$tofile
    )
    BEGIN {
        $baseline = @{}
    }

    PROCESS {
        Write-Verbose "[-] Importing baseline..."
        try {
            foreach ($rule in $config) {
                # Only created the first time.
                if ($baseline[$rule.Folder] -ne $null) {
                    $sd = $baseline[$rule.Folder]
                } else {
                    Write-Verbose "[-] Creating security descriptor for $($rule.Folder) ..."
                    $sd = New-Object System.Security.AccessControl.DirectorySecurity
                    # Owner
                    if ($rule.Owner) {
                        Write-Verbose "`tSetting owner..."
                        $owner = New-Object System.Security.Principal.NTAccount($rule.Owner)
                        $sd.setOwner($owner)
                    }
                    
                    $baseline[$rule.Folder] = $sd
                }
                Write-Verbose "`tAdding ACL..."
                # ACL
                $user = New-Object System.Security.Principal.NTAccount($rule.IdentityReference)
                # It can be an integer or a string. In case it is an integer let's check for
                # generic rights.
                $fullRights = 0
                if ($rule.FileSystemRights -match "\d+") {
                    $fullRights = Get-FileSystemRightsFromGenericRights($rule.FileSystemRights)
                }
                if ($fullRights) {
                    Write-Verbose "`t`tGeneric Rights detected, transformed to File System Rights"
                    $rights = [System.Security.AccessControl.FileSystemRights]$fullRights
                } else {
                    $rights = [System.Security.AccessControl.FileSystemRights]$rule.FileSystemRights
                }
                $type = [System.Security.AccessControl.AccessControlType]$rule.AccessControlType
                # Hardcoded
                $InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit" 
                $PropagationFlag = [System.Security.AccessControl.PropagationFlags]::None
                $ace = New-Object System.Security.AccessControl.FileSystemAccessRule `
                    ($user, $rights, $InheritanceFlag, $PropagationFlag, $type)
                $sd.AddAccessRule($ace)
            }
            Write-Verbose "[+] Baseline imported"

        } Catch [system.exception] {
            $msg = "[!] Baseline format is incorrect.`n"+
                "`tHeaders expected:`n"+
                "`tFolder`t: Path to the folder to check ACLs`n"+
                "`tOwner`t: User or group account owner of the folder`n"+
                "`t`thttps://msdn.microsoft.com/en-us/library/system.security.principal.ntaccount(v=vs.110).aspx`n"+
                "`tIdentityReference`t: User or group account associated to the access rule`n"+
                "`t`thttps://msdn.microsoft.com/en-us/library/system.security.principal.ntaccount(v=vs.110).aspx`n"+
                "`tFileSystemRights`t: type of operation associated with the access rule`n"+
                "`t`thttps://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights(v=vs.110).aspx`n"+
                "`tAccessControlType`t: specifies whether to allow or deny the operation`n"+
                "`t`thttps://msdn.microsoft.com/en-us/library/w4ds5h86(v=vs.110).aspx"
            Write-Warning $msg
            Write-Debug $_
        }
    }

    END {
        Write-Verbose "[+] $($baseline.Count) security descriptors imported"
        Write-Verbose "[-] Checking compliance against imported baseline..."
        $baseline.GetEnumerator() | foreach { 
            if ($tofile) {
                Check-Acl -path $_.key -baseline $_.value -tofile $tofile -append
            } else {
                Check-Acl -path $_.key -baseline $_.value
            }
        }
        Write-Verbose "[+] done"
    }
}

<#
.SYNOPSIS
    This function checks that the existing ACLs of the given folder comply with the 
    given baseline ACLs.
.DESCRIPTION
    This function checks that the existing ACLs (access rules) defined in the given folder 
    comply with the given baseline ACLs.
    The check focuses on validating the properties: IdentityReference, FileSystemRights and 
    AccessControlType of the access rule are exactly the same. 
    If included in the baseline, it also checks for the Owner.
    
    It will warn for those baseline ACLs that do not match.
    It will warn for the existing ACLs that do not belong to the baseline.
    It also provides the capability of exporting the differences in CSV format. Indicating
    by:
    - '>>' as baseline not implemented.
    - '<<' as existing rule not defined in baseline.
    - 'ok' as correct rule.
.PARAMETER path
    The path to the folder/file to check.
.PARAMETER baseline
    Baseline security descriptor to comply with.
    https://msdn.microsoft.com/en-us/library/system.security.accesscontrol.directorysecurity(v=vs.110).aspx
.PARAMETER tofile
    The path to the file to export (CSV) the check.
.PARAMETER append
    Use in conjunction with 'tofile' parameter. It appends data to avoid overwriting the export file
.EXAMPLE
    C:\PS>$owner = New-Object System.Security.Principal.NTAccount("BUILTIN\Administrators") 
    C:\PS>$securityDescriptor = New-Object System.Security.AccessControl.DirectorySecurity
    C:\PS>$securityDescriptor.setOwner($owner)
    C:\PS>$InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit" 
    C:\PS>$PropagationFlag = [System.Security.AccessControl.PropagationFlags]::None 
    C:\PS>$user = New-Object System.Security.Principal.NTAccount("DOMAIN\OtherAccount") 
    C:\PS>$rights = [System.Security.AccessControl.FileSystemRights]"ReadAndExecute" 
    C:\PS>$objType =[System.Security.AccessControl.AccessControlType]::Allow 
    C:\PS>$objACE = New-Object System.Security.AccessControl.FileSystemAccessRule `
    ($user, $rights, $InheritanceFlag, $PropagationFlag, $objType) 
    C:\PS>$securityDescriptor.AddAccessRule($objACE) 
    C:\PS>C:\PS>$user = New-Object System.Security.Principal.NTAccount("DOMAIN\YourAccount") 
    C:\PS>$rights = [System.Security.AccessControl.FileSystemRights]"Write" 
    C:\PS>$objType =[System.Security.AccessControl.AccessControlType]::Allow 
    C:\PS>$objACE = New-Object System.Security.AccessControl.FileSystemAccessRule `
    ($user, $rights, $InheritanceFlag, $PropagationFlag, $objType) 
    C:\PS>$securityDescriptor.AddAccessRule($objACE) 
    C:\PS>Check-Acl -path "C:\My_Folder" -baseline $securityDescriptor
.EXAMPLE
    C:\PS>$owner = New-Object System.Security.Principal.NTAccount("BUILTIN\Administrators") 
    C:\PS>$securityDescriptor = New-Object System.Security.AccessControl.DirectorySecurity
    C:\PS>$securityDescriptor.setOwner($owner)
    C:\PS>$user = New-Object System.Security.Principal.NTAccount("DOMAIN\YourAccount") 
    C:\PS>$rights = [System.Security.AccessControl.FileSystemRights]"FullControl" 
    C:\PS>$InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit" 
    C:\PS>$PropagationFlag = [System.Security.AccessControl.PropagationFlags]::None 
    C:\PS>$objType =[System.Security.AccessControl.AccessControlType]::Allow 
    C:\PS>$objACE = New-Object System.Security.AccessControl.FileSystemAccessRule `
    ($user, $rights, $InheritanceFlag, $PropagationFlag, $objType) 
    C:\PS>$securityDescriptor.AddAccessRule($objACE) 
    C:\PS>Check-Acl -path "\\My_Remote_Folder" -baseline $securityDescriptor
.EXAMPLE
    C:\PS>$owner = New-Object System.Security.Principal.NTAccount("BUILTIN\Administrators") 
    C:\PS>$securityDescriptor = New-Object System.Security.AccessControl.DirectorySecurity
    C:\PS>$securityDescriptor.setOwner($owner)
    C:\PS>$user = New-Object System.Security.Principal.NTAccount("DOMAIN\YourAccount") 
    C:\PS>$rights = [System.Security.AccessControl.FileSystemRights]"FullControl" 
    C:\PS>$InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit" 
    C:\PS>$PropagationFlag = [System.Security.AccessControl.PropagationFlags]::None 
    C:\PS>$objType =[System.Security.AccessControl.AccessControlType]::Allow 
    C:\PS>$objACE = New-Object System.Security.AccessControl.FileSystemAccessRule `
    ($user, $rights, $InheritanceFlag, $PropagationFlag, $objType) 
    C:\PS>$securityDescriptor.AddAccessRule($objACE) 
    C:\PS>Check-Acl -path "\\My_Remote_Folder" -baseline $securityDescriptor -tofile "C:\Exported_check-acl.csv"
.LINK
   https://technet.microsoft.com/en-us/library/ff730951
    https://technet.microsoft.com/en-us/library/cc781716(v=ws.10).aspx
    http://blogs.technet.com/b/josebda/archive/2010/11/09/how-to-handle-ntfs-folder-permissions-security-descriptors-and-acls-in-powershell.aspx
    Get-Acl
    Set-Acl
    Get-FileSystemRightsFromGenericRights
.NOTES
    Author: Dario B. (darizotas at gmail dot com)
    Date:   May 26, 2015
        
    Copyright 2015 Dario B. darizotas at gmail dot com
    This software is licensed under a new BSD License.
    Unported License. http://opensource.org/licenses/BSD-3-Clause
#>
Function Check-Acl {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$path,
        [Parameter(Mandatory=$true)]
        [System.Security.AccessControl.DirectorySecurity]$baseline,
        [string]$tofile,
        [switch]$append
    )
    
    Write-Verbose "[-] Checking ACLs for $path"
    # Flags with counters for deviations
    $deviation = @{ 'owner' = 0; 'result' = @()}
    # First things, first. The ACL.
    $acl = Get-Acl -Path $path 
    # Ownership
    if ($baseline.Owner) {
        Write-Verbose "[>>] Validating baseline Owner: $($baseline.Owner)"
        if ($acl.Owner -eq $baseline.Owner) {
            Write-Verbose "[ok]"
        } else {
            Write-Warning "[err] defined Owner is different: $($acl.Owner)"
            # Deviation registered
            $deviation['owner'] = 1
        }
    }
    # Array that saves those rules processed.
    $matches = @()
    # Access
    foreach ($rule in $baseline.Access) {
        $msg = "[>>] Validating baseline DACL:`n"+
            "`tFileSystemRights`t: $($rule.FileSystemRights)`n"+
            "`tAccessControlType`t: $($rule.AccessControlType)`n"+
            "`tIdentityReference`t: $($rule.IdentityReference)"
        Write-Verbose $msg
        # Search each rule defined in the baseline within the current DACLs
        # It takes into account those rules that are defined through Generic Rights.
        $r = $acl.Access | where {$_.IdentityReference -eq $rule.IdentityReference -and `
            $_.AccessControlType -eq $rule.AccessControlType -and `
            (($_.FileSystemRights -eq $rule.FileSystemRights) -or `
            ((Get-FileSystemRightsFromGenericRights($_.FileSystemRights)) -eq $rule.FileSystemRights)) }

        if ($r -ne $null) {
            Write-Verbose "[ok]"
            $matches += $r
            $r | %{            
                $deviation['result'] += New-Object –TypeName PSObject –Prop @{
                    'Compliance' = 'ok';
                    'Folder' = $path;
                    'Owner' = $acl.Owner;
                    'IdentityReference' = $_.IdentityReference;
                    'FileSystemRights' = $_.FileSystemRights;
                    'AccessControlType' = $_.AccessControlType
                }
            }

        } else {
            Write-Warning "[err] it does not exist"
            # Deviation registered
            # Owner is not extracted.
            $deviation['result'] += New-Object –TypeName PSObject –Prop @{
                'Compliance' = '>>';
                'Folder' = $path;
                'Owner' = $acl.Owner;
                'IdentityReference' = $rule.IdentityReference;
                'FileSystemRights' = $rule.FileSystemRights;
                'AccessControlType' = $rule.AccessControlType
            }
        }

    }
    # cheRemaining rules
    foreach ($rule in $acl.Access) {
        # Only those rules not existing previously
        $r = $matches | where {$_.IdentityReference -eq $rule.IdentityReference -and `
            $_.AccessControlType -eq $rule.AccessControlType -and `
            $_.FileSystemRights -eq $rule.FileSystemRights }
        if ($r -eq $null) {
            $msg = "[<<] Existing DACL:`n"+
                "`tFileSystemRights`t: $($rule.FileSystemRights)`n"+
                "`tAccessControlType`t: $($rule.AccessControlType)`n"+
                "`tIdentityReference`t: $($rule.IdentityReference)`n"+
                "`t[warn] it is not defined in the baseline"
            Write-Warning $msg
            # Deviation registered
            # Owner is not extracted.
            $deviation['result'] += New-Object –TypeName PSObject –Prop @{
                'Compliance' = '<<';
                'Folder' = $path;
                'Owner' = $acl.Owner;
                'IdentityReference' = $rule.IdentityReference;
                'FileSystemRights' = $rule.FileSystemRights;
                'AccessControlType' = $rule.AccessControlType
            }
        }
    }
    # Result summary
    $deviationBaseline = $($deviation['result'] | where { $_.Compliance -eq '>>'}).count
    $deviationExisting = $($deviation['result'] | where { $_.Compliance -eq '<<'}).count
    if ($deviation['owner'] -or $deviationBaseline -or $deviationExisting) {
        if ($deviation['owner']) {
            $summary = "Ownership not compliant. "
        }
        if ($deviationBaseline) {
            $summary += "$deviationBaseline baseline ACLs not implemented. "
        }
        if ($deviationExisting) {
            $summary += "$deviationExisting existing ACLs not compliant. "
        }

        Write-Warning "[!] done. Deviations found. $summary"
    } else {
        Write-Verbose "[+] done. No deviations found"
    }
    
    if ($tofile) {
        Write-Verbose "[-] Exporting results..."
        # Append parameter to Export-CSV is broken
        # http://stackoverflow.com/questions/9220239/powershell-export-csv-and-append
        # https://dmitrysotnikov.wordpress.com/2010/01/19/export-csv-append/
        if ($append) {
            if (Test-Path $tofile) {
                $null, $export = $deviation['result'] | ConvertTo-Csv -NoTypeInformation
                Out-File -FilePath $tofile -InputObject $export -Append
            } else {
                $deviation['result'] | export-csv $tofile -NoTypeInformation
            }
        } else {
            $deviation['result'] | export-csv $tofile -NoTypeInformation
        }
        Write-Verbose "[+] done"
        
    }
}
