# SPS - Secured Powershell
This module is an evolution to my previous module PSSecureCommands (https://github.com/RT271095/PSSecureCommands)

It Allows to generate licenses and encrypt powershell commands with it

# Example of use
```powershell
PS C:\Users\rpt> # Import Module
PS C:\Users\rpt> Import-Module SPS
PS C:\Users\rpt> # Create new license
PS C:\Users\rpt> New-SPSLicenseFile -Name "SomeLicenseName" -Company "RPT" -Expiry "2025-08-20" -Path .\
PS C:\Users\rpt> cat .\SomeLicenseName.lic
{
  "key": "76492d1116743f0423413b16050a5345MgB8AEYAZQB2AFQATAA0ADcAbABpAEoARQBoAEoAKwBQAHIAMgBHAEkAcgBYAHcAPQA9AHwAOQBmAGQAMwA5AGMAMgBiADQAYQAyAGEAMwA3ADYANgAxADEAYQAzADMAOABkADcAMwA2ADAAZQA4ADYAZQBhADkAYwBiADkANwAzAGUAMwAwADkAMgBmAGQAZAA1ADIAMQA3ADgAMwBmADMAZABmADgAMAA4AGIAOABmADkAOAA0ADgAOAAwAGQAYgAxADEAZAAzADcAYgA1AGMANgBjADAAOAA3ADUAZQAwADMAOQA3ADgAOABkADYAOQAyADgA",
  "expiry": "2025-08-20T00:00:00",
  "company": "RPT",
  "id": "19-31-6-3-29-15-16-15-11-13-2-16-8-9-15-9"
}
PS C:\Users\rpt> # set the variable $env:SPS_LICENSE_PATH containing the root directory containing all licenses
PS C:\Users\rpt> Set-SPSLicensePath -Path .\
PS C:\Users\rpt> $env:SPS_LICENSE_PATH
C:\Users\claud
PS C:\Users\rpt> # get license from $env:SPS_LICENSE_PATH directory
PS C:\Users\rpt> Get-SPSLicenseFile -Name "SomeLicenseName"

key
---
76492d1116743f0423413b16050a5345MgB8AEYAZQB2AFQATAA0ADcAbABpAEoARQBoAEoAKwBQAHIAMgBHAEkAcgBYAHcAPQA9AHwAOQBmAGQAMwA5AG…

PS C:\Users\rpt> # Test if a license is valid
PS C:\Users\rpt> Test-SPSLicenseFile -Name "SomeLicenseName"
True
PS C:\Users\rpt> # create $global:SPS and add some commands
PS C:\Users\rpt> Add-SPSCommand -group main -name ipconfig -License "SomeLicenseName" -command "ipconfig"
PS C:\Users\rpt> Add-SPSCommand -group main -name show -License "SomeLicenseName" -command @"
>> param([String]`$show)
>> write-output  "Let's show this : `$show"
>> "@
PS C:\Users\rpt> $global:SPS["main"]

Name                           Value
----                           -----
SecureCommand                  76492d1116743f0423413b16050a5345MgB8AHIAdABiADIAZABHAEQAWABPAFAAUABmADEAbwAxAE4ANgBkAFU…
name                           ipconfig
license                        SomeLicenseName
SecureCommand                  76492d1116743f0423413b16050a5345MgB8AEMAOQBkAHcAVQA1AFkAMQBXAEMAaQAxAHEAQgA5AEkAQQBwAEc…
name                           show
license                        SomeLicenseName

PS C:\Users\rpt> # remove SPS command from $global:SPS variable
PS C:\Users\rpt> Remove-SPSCommand -Group main -Name ipconfig
PS C:\Users\rpt> $global:SPS["main"]

Name                           Value
----                           -----
SecureCommand                  76492d1116743f0423413b16050a5345MgB8AEMAOQBkAHcAVQA1AFkAMQBXAEMAaQAxAHEAQgA5AEkAQQBwAEc…
name                           show
license                        SomeLicenseName

PS C:\Users\rpt> # Execute SPS command
PS C:\Users\rpt> Invoke-SPSCommand -Group main -Name show -Parameters @{show="I show that :) !!!"}
Let's show this : I show that :) !!!
PS C:\Users\rpt> # save $global:SPS into JSON file
PS C:\Users\rpt> Save-SPS -Path .\securecommands.json
PS C:\Users\rpt> cat .\securecommands.json
{
  "main": [
    {
      "SecureCommand": "76492d1116743f0423413b16050a5345MgB8AEMAOQBkAHcAVQA1AFkAMQBXAEMAaQAxAHEAQgA5AEkAQQBwAEcAbQAvAGcAPQA9AHwAYgA3ADUAOAAyADQAMABlADUAZgA1AGYAYQA2ADkAYgA0ADMAMgA2ADkAMgA0AGQAMAA1AGEAMwBhADUANQBhADIANwA1ADIAMgBiAGMAOAAyAGMANABmADYAZABlADQANQAxAGYAMgBlADYANwBiAGEAYwBjADcANQA3ADIAYQA2ADMAZgAzAGIAYgBlADYAMAA2ADAAOAA2AGEAMAAxAGEAMgBlADgAYQA5ADcAYQA5ADQAOAA1AGUAMwBmAGQANQA1AGMAZAA5AGUAMgAxAGUAOQBiADYAMQAwADEAMgAyADgAZAA2AGIANQAxADcANwA0AGQANQA4ADkANQBjADAAMwBlAGQAYwA1AGIANQBhADYAOQA1ADIANQA3ADcAZAA5ADAAOQA4AGUAMgBiADcAMQA5ADAAZQA3AGIANgA3AGYAOAAyADkANAA1ADgAMwA2ADQANwA3AGQAZgAzADAAMgBmADEAOQAxADcAMwBmAGEAMQBiADQAZQA5ADkAOAAzADMANwAxADQAYgBhADkAYwBmADAAYwA5ADkAMwA4ADgAZgA1ADMAMABmADUAYQA2ADcAZgA1ADcAMwAxAGYAMgAzAGYAMgBlADMAMQBhAGEANABmADkANABmADcAOAA0AGIANwA1AGUAMwA5AGEAZQBiADIAZQBiADAAMQA=",
      "name": "show",
      "license": "SomeLicenseName"
    }
  ]
}
PS C:\Users\rpt> # import JSON file to build $global:SPS
PS C:\Users\rpt> $global:SPS = $null
PS C:\Users\rpt> Import-SPS -Path .\securecommands.json

Name                           Value
----                           -----
main                           {show}

PS C:\Users\rpt> # Create a new SPS group by importing an entire folder
PS C:\Users\rpt> Add-SPSFolder -Group folder -Path "C:\path\to\folder" -License "SomeLicenseName"
PS C:\Users\rpt> 
```
