<#
.SYNOPSIS
    Returns true if a required module exists.
.PARAMETER name
    Module name.
.LINK
   https://blogs.technet.com/b/heyscriptingguy/archive/2010/07/11/hey-scripting-guy-weekend-scripter-checking-for-module-dependencies-in-windows-powershell.aspx
    http://technet.microsoft.com/en-us/library/hh847765.aspx
.NOTES
    Extracted from "Hey, Scripting Guy!" Microsoft Technet Blog
#>
Function Get-MyModule {
    Param([string]$name)
  
    if(-not(Get-Module -name $name)) 
    {
        if(Get-Module -ListAvailable | Where-Object { $_.name -eq $name })
        {
            Import-Module -Name $name
            $true
        } #end if module available then import
        else { $false } #module not available
    } # end if not module
    else { $true } #module already loaded
} #end function get-MyModule 

<#
.SYNOPSIS
    This function is a wrapper of the Get-Hash cmdlet of the PSCX Module and generates
    an output file using hash-check format.
.DESCRIPTION
    This function generates the hash of a given file or the files contained in a given 
    folder (and subfolders) and saves it in a file, following hash-check format.
    If a folder is given as an input, the output file is generated in the parent folder.
.PARAMETER source
    The path to folder/file to which it will generate the hash-check format file.
.PARAMETER algorithm
    Specifies the hashing algorithm to use. Valid values are "SHA1", "MD5", 
    "SHA256", "SHA512", "RIPEMD160". If omited, SHA1 algorithm is used by default.
.EXAMPLE
    C:\PS>hash-check.ps1 -source "C:\My Files" -algorithm "SHA256"
    It generates the output file "C:\My Files.sha256" that will contain all the SHA256
    hashes of the different files contained in "My Files" folder and subfolders.
.EXAMPLE
    C:\PS>hash-check.ps1 -source "C:\My Files"
    It generates the output file "C:\My Files.sha1" that will contain all the SHA1
    hashes of the different files contained in "My Files" folder and subfolders.
.EXAMPLE
    C:\PS>hash-check.ps1 -source "C:\My Files\my_file.txt" -algorithm "MD5"
    It generates the output file "C:\My Files\my_file.txt.md5" that will contain 
    the MD5 hash of the file "my_file.txt".
.EXAMPLE
    C:\PS>hash-check.ps1 -source "C:\My Files\my_file.txt"
    It generates the output file "C:\My Files\my_file.txt.sha1" that will contain 
    the SHA1 hash of the file "my_file.txt".
.LINK
   http://code.kliu.org/hashcheck/
    http://pscx.codeplex.com/
    Get-Hash
.NOTES
    Author: Dario B. (darizotas at gmail dot com)
    Date:   July 11, 2013
        
    Copyright 2013 Dario B. darizotas at gmail dot com
    This software is licensed under a new BSD License.
    Unported License. http://opensource.org/licenses/BSD-3-Clause
#>
Function Get-HashCheck {
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory=$true)]
      [string]$source,

      #[Parameter(Mandatory=$True)] 
      [ValidateSet("SHA1", "MD5", "SHA256", "SHA512", "RIPEMD160")]
      [string]$algorithm = "SHA1"
    )

    # Checks the existance of PSCX module
    Write-Host "Checking for PSCX module..."
    if (Get-MyModule -name "PSCX")
    {
        Write-Host "PSCX module available! Let's use it."
        
        # Does the path given exists?
        if (Test-Path -Path $source) {
            Write-Host "Generating $algorithm hashes..."
          
            # Calculate the hashes of the files contained in the given path
            $hashes = dir $source -Recurse | Where-Object {!$_.psiscontainer} | Get-Hash -Algorithm $algorithm
          
            # Output path and file where to write those hashes.
            if (Test-Path -Path $source -PathType leaf) 
            {
                $parent = Split-Path $source -parent
                $outfile = $source + '.' + $algorithm
            } else {
                $parent = Split-Path $source -parent
                $outfile = $parent + '\' + (Split-Path $source -Leaf) + '.' + $algorithm
            }
            $stream = [System.IO.StreamWriter] $outfile

            # Loop the hashes and writes them using hash-check format.
            foreach ($h in $hashes) 
            {
                $path = $h.Path.Replace($parent + '\', "*")
                $stream.WriteLine($h.HashString + "`t" + $path)
            }
            $stream.close()
          
            Write-Host "HashCheck file [$outfile] has been successfully created."
        } else {
            Write-Host "The given path $source does not exist"
        }
    } else {
        Write-Host "PSCX module is not available"
    }
}