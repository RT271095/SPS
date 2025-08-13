<#
	.SYNOPSIS
	Function used to create new keys for each secure command
	
	.EXAMPLE
	# To generate a key with a size of 16 and a max number of 32
	New-Key
	
	.EXAMPLE
	# To generate a key with a custom size and max number
	New-Key -Size $Size -Max $Max
#>
Function New-Key {
	param([Int]$Size=16,[Int]$Max=32)
	$res = get-random -count $Size -Maximum $Max
	return $res -join "-"
}

<#
	.SYNOPSIS
	Function used to create new LicenseFile
	
	.EXAMPLE
	New-SPSLicenseFile -Name "SomeLicenseName" -Company "RPT" -Expiry "2025-08-20" -Path .\
	
#>
Function New-SPSLicenseFile {
	param(
	[Parameter(Position=0,mandatory=$true)]
	[String]$Name,
	[Parameter(Position=1,mandatory=$true)]
	[String]$Company,
	[Parameter(Position=2,mandatory=$true)]
	[String]$Expiry,
	[Parameter(Position=3,mandatory=$true)]
	[String]$Path
	)
	$key = New-Key
	
	$SPSLicenseFile = @{
		id = $key
		company=$Company
		expiry=[Datetime](get-date -date "$Expiry" -format "yyyy-MM-dd")
		key = ConvertTo-SecureString "[$Company]-[$Expiry]" -AsPlainText -Force | convertfrom-securestring -key $key.split("-")
	}
	
	$SPSLicenseFile | convertto-json | out-file "$($Path)/$($name).lic" -encoding default
}

<#
	.SYNOPSIS
	Set environment variable SPS_LICENSE_PATH with the directory containing all SPS licenses
	
	.EXAMPLE
	Set-SPSLicensePath -Path .\
	
#>
Function Set-SPSLicensePath {
	param(
	[Parameter(Position=0,mandatory=$true)]
	[String]$Path
	)
	if(test-path $Path){
		$env:SPS_LICENSE_PATH = (resolve-path "$Path").path
	}
}

<#
	.SYNOPSIS
	Get a license file's content from $env:SPS_LICENSE_PATH location
	
	.EXAMPLE
	Get-SPSLicenseFile -Name "SomeLicenseName"
	
#>
Function Get-SPSLicenseFile {
	param(
	[Parameter(Position=0,mandatory=$true)]
	[String]$Name
	)
	
	if(test-path "$($env:SPS_LICENSE_PATH)/$($Name).lic"){
		return get-content "$($env:SPS_LICENSE_PATH)/$($Name).lic" -raw | convertfrom-JSON	
	}
}

<#
	.SYNOPSIS
	Tests if a license file if valid or not from $env:SPS_LICENSE_PATH location 
	
	.EXAMPLE
	Test-SPSLicenseFile -Name "SomeLicenseName"
	
#>
Function Test-SPSLicenseFile {
	param(
	[Parameter(Position=0,mandatory=$true)]
	[String]$Name
	)
	
	if(test-path "$($env:SPS_LICENSE_PATH)/$($Name).lic"){
		
		$SPSLicenseFile = get-content "$($env:SPS_LICENSE_PATH)/$($Name).lic" -raw | convertfrom-JSON
		
		$sstr = convertto-securestring $SPSLicenseFile.key -key $SPSLicenseFile.id.split("-") | convertfrom-securestring -asplaintext
		
		$exp = $SPSLicenseFile.expiry
		
		if((get-date) -gt $exp){
			return $false
		}
		
		$date = get-date $exp -format "yyyy-MM-dd"
		"[$($SPSLicenseFile.Company)]-[$date]" -eq $sstr
		
	}else{
		
		return $false
	
	}
}

<#
	.SYNOPSIS
	To add a new SPS command and group to $global:SPS group list
	
	.EXAMPLE
	Add-SPSCommand -group main -name ipconfig -License "SomeLicenseName" -command "ipconfig"
	
	.EXAMPLE
	Add-SPSCommand -group main -name show -License "SomeLicenseName" -command @"
	param([String]`$show)
	write-output  "Let's show this : `$show"
"@
	
#>
Function Add-SPSCommand {
	param(
	[Parameter(Position=0,mandatory=$true)]
	[String]$Group,
	[Parameter(Position=1,mandatory=$true)]
	[String]$Name,
	[Parameter(Position=2,mandatory=$true)]
	[String]$License,
	[Parameter(Position=3,mandatory=$true)]
	[AllowEmptyString()]
	[string]$Command)
	if($null -eq $global:SPS){
		$global:SPS = @{}
	}
	if($null -eq $global:SPS["$Group"]){
		$global:SPS["$Group"] = [PSCustomObject]@()
	}
	
	if(Test-SPSLicenseFile -Name $License){ 
		$SPSLicenseFile = Get-SPSLicenseFile -Name $License
	}
	
	$SecureCommand = convertto-securestring $Command -asplaintext | convertfrom-securestring -key $SPSLicenseFile.id.split("-")
	$global:SPS["$Group"] += @(@{name=$Name; SecureCommand=$SecureCommand; license=$License})
}

<#
	.SYNOPSIS
	To remove a SPS command or empty group from $global:SPS group list
	
	.EXAMPLE
	Remove-SPSCommand -Group main -Name ipconfig
	
#>
Function Remove-SPSCommand {
	param(
	[Parameter(Position=0,mandatory=$true)]
	[String]$Group,
	[Parameter(Position=1,mandatory=$true)]
	[String]$Name
	)
	$tosave = @()
	foreach($elem in $global:SPS["$Group"]){
		if($elem.Name -ne $Name){
			$tosave += @($elem)
		}
	}
	$global:SPS["$Group"] = $tosave
	
	if($global:SPS["$Group"].keys.length -eq 0){
		$SPS.remove("$Group")
	}
}

<#
	.SYNOPSIS
	To invoke a SPS command from $global:SPS group list
	
	.EXAMPLE
	# to execute without parameters
	Invoke-SPSCommand -Group main -Name ipconfig
	
	.EXAMPLE
	# to execute with parameters
	Invoke-SPSCommand -Group main -Name show -Parameters @{show="I show that :) !!!"}
#>
Function Invoke-SPSCommand {
	param(
	[Parameter(Position=0,mandatory=$true)]
	[String]$Group,
	[Parameter(Position=1,mandatory=$true)]
	[String]$Name,
	[Parameter(Position=2)]
	[PSObject]$Parameters=@{})
	$my_sps = $global:SPS["$Group"] | where {$_.Name -eq $Name}
	
	if(Test-SPSLicenseFile -Name $my_sps.license){ 
		$SPSLicenseFile = Get-SPSLicenseFile -Name $my_sps.license
	}
	
	if($null -ne $my_sps){
		$command = convertto-securestring $my_sps.SecureCommand -key $SPSLicenseFile.id.split("-") | convertfrom-securestring -asplaintext
		$ScriptBlock =[System.Management.Automation.ScriptBlock]::Create($Command)
		. $ScriptBlock @Parameters
	}else{
		Write-output "Secured command $Name not found ..."
	}
}

<#
	.SYNOPSIS
	To save $global:SPS into JSON file
	
	.EXAMPLE
	Save-SPS -Path .\securecommands.json
#>
Function Save-SPS {
	param([String]$Path)
	$JSON = $global:SPS | convertto-json
	$JSON | out-file "$Path" -encoding default
}

<#
	.SYNOPSIS
	To import a JSON file into $global:SPS
	
	.EXAMPLE
	Import-SPS -Path .\securecommands.json
#>
Function Import-SPS {
	param([String]$Path)
	$global:SPS = get-content $Path -raw | convertfrom-json -ashashtable
	return $global:SPS
}

<#
	.SYNOPSIS
	To import all ps1 script from a folder into $global:SPS
	
	.EXAMPLE
	Add-SPSFolder -Group folder -Path "C:\path\to\folder" -License "SomeLicenseName"
#>
Function Add-SPSFolder {
	param(
	[Parameter(Position=0,mandatory=$true)]
	[String]$Group,
	[Parameter(Position=1,mandatory=$true)]
	[String]$Path,
	[Parameter(Position=2,mandatory=$true)]
	[String]$License
	)
	
	$list = (get-childitem "$Path" -Recurse -File | where {$_.Name -match ".ps1"}).FullName.replace("$Path","")
	foreach($elem in $list){
		$c = get-content "$($Path)/$($elem)" -Raw
		Add-SPSCommand -Group "$Group" -name "$elem" -License "$License" -command @"
$c
"@
	}
}