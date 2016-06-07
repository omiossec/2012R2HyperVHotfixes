<#
.Synopsis
   Expand-ZipFile will extract zip files to the specified location
.DESCRIPTION
   Expand-ZipFile will extract a zip file and put the extracted contents in the specified location.
#>
function Expand-ZipFile {
	#.Synopsis
	#  Expand a zip file, ensuring it's contents go to a single folder ...
	[CmdletBinding()]
	param(
		# The path of the zip file that needs to be extracted
		[Parameter(ValueFromPipelineByPropertyName=$true, Position=0, Mandatory=$true)]
		[Alias("PSPath")]
		$FilePath,
 
		# The path where we want the output folder to end up
		[Parameter(Position=1)]
		$OutputPath = $Pwd,
 
		# Make sure the resulting folder is always named the same as the archive
		[Switch]$Force
	)
	process {
        Add-Type -Path "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\System.IO.Compression.FileSystem.dll"
		$ZipFile = Get-Item $FilePath
		$Archive = [System.IO.Compression.ZipFile]::Open( $ZipFile, "Read" )
 
		# Figure out where we'd prefer to end up
		if(Test-Path $OutputPath) {
			# If they pass a path that exists, we want to create a new folder
			$Destination = Join-Path $OutputPath $ZipFile.BaseName
		} else {
			# Otherwise, since they passed a folder, they must want us to use it
			$Destination = $OutputPath
		}
 
		# The root folder of the first entry ...
		$ArchiveRoot = ($Archive.Entries[0].FullName -Split "/|\\")[0]
 
		Write-Verbose "Desired Destination: $Destination"
		Write-Verbose "Archive Root: $ArchiveRoot"
 
		# If any of the files are not in the same root folder ...
		if($Archive.Entries.FullName | Where-Object { @($_ -Split "/|\\")[0] -ne $ArchiveRoot }) {
			# extract it into a new folder:
			New-Item $Destination -Type Directory -Force
			[System.IO.Compression.ZipFileExtensions]::ExtractToDirectory( $Archive, $Destination )
		} else {
			# otherwise, extract it to the OutputPath
			[System.IO.Compression.ZipFileExtensions]::ExtractToDirectory( $Archive, $OutputPath )
 
			# If there was only a single file in the archive, then we'll just output that file...
			if($Archive.Entries.Count -eq 1) {
				# Except, if they asked for an OutputPath with an extension on it, we'll rename the file to that ...
				if([System.IO.Path]::GetExtension($Destination)) {
					Move-Item (Join-Path $OutputPath $Archive.Entries[0].FullName) $Destination
				} else {
					Get-Item (Join-Path $OutputPath $Archive.Entries[0].FullName)
				}
			} elseif($Force) {
				# Otherwise let's make sure that we move it to where we expect it to go, in case the zip's been renamed
				if($ArchiveRoot -ne $ZipFile.BaseName) {
					Move-Item (join-path $OutputPath $ArchiveRoot) $Destination
					Get-Item $Destination
				}
			} else {
				Get-Item (Join-Path $OutputPath $ArchiveRoot)
			}
		}
 
		$Archive.Dispose()
	}
}
<#
.Synopsis
    Test-Hotfixes is a test function that checks for a custom defined set of 2012R2 Hyper-V hotfixes
.DESCRIPTION
    Test-Hotfixes is a parent function for checking to ensure that all specified hotfixes are installed. It uses the child function Get-MissingHotFixList to determine which hotfixe to check for and develop a list of missing hotfixes
.EXAMPLE
	Test-Hotfixes
.EXAMPLE
	Test-Hotfixes -prettyreport $true
.PARAMETER prettyreport
    If true will generate a pretty report to copy for wherever you want pretty information
.NOTES
    Hotfixes are needed on every configuration. Just because something is missing doesn't mean it's required.
#>
function Test-Hotfixes {
	param
	(
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $false,
				   ValueFromPipelineByPropertyName = $false)]
		[boolean]$prettyreport
	)
	$test = $null
	if ($prettyreport -eq $true) {
		$test = Get-MissingHotFixList -prettyreport $true
	}
	else {
		$test = Get-MissingHotFixList
	}
	
	if ($test -eq $null) {
		Write-Host "GOOD - All hotfixes are installed" -ForegroundColor Green
	}
	else {
        Write-Host "The following hotfixes are missing:" -ForegroundColor Yellow
        $test
        Write-Host "Missing hotfixes are not necessarily an issue as not all hotfixes apply to every server." -ForegroundColor Gray
        Write-Host "Run: Install-Hotfixes to install all applicable hotfixes" -ForegroundColor Gray
    }
}
<#
.Synopsis
   Get-MissingHotFixList is a child function of Test-Hotfixes and will return a list of missing hotfixes
.DESCRIPTION
   Get-MissingHotFixList is a child function of Test-Hotfixes and will return a list of missing hotfixes
#>
function Get-MissingHotFixList {
	param
	(
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $false,
				   ValueFromPipelineByPropertyName = $false)]
		[boolean]$prettyreport
	)
	#specify the list of hotfixes we want to check for
	if ($prettyreport -eq $true) {
		$hotFixes = @{
			"KB3093899" = "VMs that run on CSVs fail if DCM can't query volumes in Windows Server 2012 R2";
			"KB3091057" = "Cluster validation fails in the Validate Simultaneous Failover test in a Windows Server 2012 R2-based failover cluster";
			"KB3076953" = "Cluster services go offline when there's a connectivity issue in Windows Server 2012 R2 or Windows Server 2012";
			"KB3068445" = "Virtual machines that host on Windows Server 2012 R2 may crash or restart unexpectedly";
			"KB3068444" = "An unrecoverable failure occurred inside the filter manager error on a failover cluster node that hosts shared VHDx files";
			"KB3090343" = "Cluster service stops during the VSS backup in a Windows Server 2012 R2-based Hyper-V cluster";
			"KB3060678" = "Snapshots are not deleted after you perform a backup operation by using VSS in Windows Server";
			"KB3063283" = "Update to improve the backup of Hyper-V Integrated components in Hyper-V Server 2012 R2";
			"KB3130944" = "March 2016 update for Windows Server 2012 R2 clusters to fix several issues";
			"KB3139896" = "Hyper-V guest may freeze when it is running failover cluster service together with shared VHDX in Windows Server 2012 R2";
			"KB3130939" = "Nonpaged pool memory leak occurs in a Windows Server 2012 R2-based failover cluster";
			"KB3141074" = "0x00000001 Stop error when a shared VHDX file is accessed in Windows Server 2012 R2-based Hyper-V guest";
			"KB3072380" = "Hyper-V cluster unnecessarily recovers the virtual machine resources in Windows Server 2012 R2";
			"KB3031598" = "Hyper-V host crashes and has errors when you perform a VM live migration in Windows 8.1 and Windows Server 2012 R2";
			"KB3095308" = "VMs may not get additional memory although they're set to use Dynamic Memory in Windows Server 2012 R2";
			"KB3027108" = "0x0000003B or 0x0000007E Stop error on a Windows-based computer that has 4K sector disks";
			"KB3037313" = "Old files are not removed after a migration of virtual machine storage in Windows 8.1 or Windows Server 2012 R2";
			"KB3025091" = "Shared Hyper-V virtual disk is inaccessible when it's located in Storage Spaces on a Windows Server 2012 R2-based computer";
			"KB3018489" = "No host bus adapter is present error when querying SAS cable issues in Windows Server 2012 R2 or Windows Server 2012";
			"KB3046826" = "You cannot upgrade Hyper-V integration components or back up Windows virtual machines";
			"KB3020717" = "VMMS crashes when you perform live migration and request VM information at the same time in Windows Server 2012 R2";
			"KB3044457" = "STATUS_PURGE_FAILED error when you perform VM replications by using SCVMM in Windows Server 2012 R2";
			"KB3036173" = "0x00000050 Stop error when Hyper-V host crashes in Windows Server 2012 R2";
			"KB3049443" = "Live migration of virtual machine to another host fails on a Windows Server 2012 R2-based Hyper-V host server";
			"KB3102354" = "Hyper-V generation 2 virtual machines can't start with some pass-through disks in Windows Server 2012 R2"
			"KB3137691" = "LBFO Dynamic Teaming mode may drop packets in Windows Server 2012 R2"
		}
		#create the array to hold missing hotfixes
		$failed = New-Object System.Collections.ArrayList
		$failed.Clear() #reset array to null
		$Data = @()
		$HotFixes.GetEnumerator() | %{
			$Header = "" | Select-Object HotFixID, Description
			$Header.HotfixID = $_.Key
			$Header.Description = $_.value
			$Data += $Header
		}
		foreach ($Item in $Data) {
			try {
				$Item | %{ get-hotfix -Id $_.hotfixid -ErrorAction Stop | Out-Null }
			}
			catch {
				$failed.add($item) | Out-Null
			}
		}
		return $failed | fl
	}
	else {
		$hotfixes = (
		#all clusters	
		"3093899", #VMs that run on CSVs fail if DCM can't query volumes in Windows Server 2012 R2
		"3091057", #Cluster validation fails in the "Validate Simultaneous Failover" test in a Windows Server 2012 R2-based failover cluster
		"3076953", #Cluster services go offline when there's a connectivity issue in Windows Server 2012 R2 or Windows Server 2012
		"3068445", #Virtual machines that host on Windows Server 2012 R2 may crash or restart unexpectedly
		"3068444", #An unrecoverable failure occurred inside the filter manager" error on a failover cluster node that hosts shared VHDx files
		"3090343", #Cluster service stops during the VSS backup in a Windows Server 2012 R2-based Hyper-V cluster
		"3060678", #Snapshots are not deleted after you perform a backup operation by using VSS in Windows Server
		"3063283",#Update to improve the backup of Hyper-V Integrated components in Hyper-V Server 2012 R2
		"3130944", #"March 2016 update for Windows Server 2012 R2 clusters to fix several issues"
		"3139896", #"Hyper-V guest may freeze when it is running failover cluster service together with shared VHDX in Windows Server 2012 R2"
		"3130939", #"Nonpaged pool memory leak occurs in a Windows Server 2012 R2-based failover cluster"
		"3141074", #""0x00000001" Stop error when a shared VHDX file is accessed in Windows Server 2012 R2-based Hyper-V guest"
		"3072380", #Hyper-V cluster unnecessarily recovers the virtual machine resources in Windows Server 2012 R2
		"3031598", #Hyper-V host crashes and has errors when you perform a VM live migration in Windows 8.1 and Windows Server 2012 R2	
		"3095308", #VMs may not get additional memory although they're set to use Dynamic Memory in Windows Server 2012 R2 
		"3027108", #"0x0000003B" or "0x0000007E" Stop error on a Windows-based computer that has 4K sector disks 
		"3037313", #Old files are not removed after a migration of virtual machine storage in Windows 8.1 or Windows Server 2012 R2 
		"3025091", #Shared Hyper-V virtual disk is inaccessible when it's located in Storage Spaces on a Windows Server 2012 R2-based computer
		"3018489", #"No host bus adapter is present" error when querying SAS cable issues in Windows Server 2012 R2 or Windows Server 2012
		"3046826", #You cannot upgrade Hyper-V integration components or back up Windows virtual machines
		"3020717", #VMMS crashes when you perform live migration and request VM information at the same time in Windows Server 2012 R2	
		"3044457", #"STATUS_PURGE_FAILED" error when you perform VM replications by using SCVMM in Windows Server 2012 R2
		"3036173", #"0x00000050" Stop error when Hyper-V host crashes in Windows Server 2012 R2
		"3049443", #"Live migration of virtual machine to another host fails on a Windows Server 2012 R2-based Hyper-V host server
		"3102354", #Hyper-V generation 2 virtual machines can't start with some pass-through disks in Windows Server 2012 R2
		"3137691"  #LBFO Dynamic Teaming mode may drop packets in Windows Server 2012 R2
		)
		#create the array to hold missing hotfixes
		$failed = New-Object System.Collections.ArrayList
		$failed.Clear() #reset array to null
		foreach ($kb in $hotfixes) {
			try {
				$hotfix = get-hotfix -Id "KB$kb" -ErrorAction Stop
			}
			catch {
				$failed.Add($kb) | Out-Null
			}
		}
		return $failed
	}
}
<#
.Synopsis
   Install-Hotfixes is the parent function for installing all missing hotfixes
.DESCRIPTION
   Install-Hotfixes will install any missing hotfixes specified in Get-MissingHotFixList. This functions uses two other functions: Get-MissingHotFixList to determine which hotfixes require install, and Expand-ZipFile to extract the downloaded hotfix .zip file. It will then install all missing hotfixes. 
.EXAMPLE
   Install-Hotfixes
.NOTES
   This function assumes that the hotfix .zip file location is relative to the current directory path. You will need to CD to the location of the .zip file before running this function
#>
function Install-Hotfixes{
	$wd = Get-Location
    $zipLocation = "$wd\Hyper-V_2012R2_hotfixes_06_2016.zip"
    $hotfixDir = "$wd\hotfixes\"
	#verify if hotfix .zip file can be found
    if(Test-Path $zipLocation){
        #do nothing, the zip file is already there
    }
    else{
        Write-Host "The hotfix .zip file could not be located." -ForegroundColor Yellow
		Write-Host "Change directory to the location of the hotfix .zip file before running the function again." -ForegroundColor Gray
		Write-Host "Goodbye."
		return
    }
	#check if .zip file is already extracted
    if(Test-Path $zipLocation){
        if(!(Test-Path "$wd\hotfixes\Windows8.1-KB3068444-x64.msu")){
            Write-Host "Expanding .zip file..." -ForegroundColor Gray
            try{
                Expand-ZipFile -FilePath $zipLocation -OutputPath $hotfixDir
            }
            catch{
                Write-Host "There was an error expanding the Hotfixes .zip file" -ForegroundColor Red
                Return
            }
        }
        Write-Host "Installing Hotfixes..." -ForegroundColor Gray
        $hotfixList = Get-MissingHotFixList
        try{
            $hotfixFiles = Get-ChildItem $hotfixDir
            #install the ones passed in
            foreach ($hotfix in $hotfixList){
                $file = $hotfixFiles | Where-Object {$_.Name -like "*$hotfix*"}
                $fileName = $file.FullName
                Write-Host "Installing $fileName" -ForegroundColor Gray
                Start-Process wusa -ArgumentList "$fileName /quiet /norestart" -Wait
            }
			Write-Host "All missing hotfixes were successfully attempted to install." -ForegroundColor Cyan
        }
        catch{
            Write-Host "An error was encountered installing Hotfixes" -ForegroundColor Red
			Write-Error $_
        }
    }
    else{
        Write-Host "The hotfixes .zip file could not be located so the installation will not proceed" -ForegroundColor Red
    }
    #lets see if it worked
    Test-Hotfixes
}