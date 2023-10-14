function Get-Timestamp {
    <#
    .SYNOPSIS
    Return a date formatted
    .EXAMPLE
    2023-07-03T17.37.29.6735970+02.00
    #>
    return Get-Date -Format o | ForEach-Object { $_ -replace ":", "." }
}

function Write-TraceWithTimestamp {
    <#
    .SYNOPSIS
    Writes to a log file with a message preceeded by a timestamp. 
    #
        
    .PARAMETER logFullPath
    The path to the log
    
    .PARAMETER message
    The message to write
    
    .PARAMETER LogMessageType
    The type of message to 

    .NOTES
    The message will receive a simple split (in the middle of the word, as opposed to with word boundraies)  based on the length of the line. 
    #>
    param(
        [Parameter(Mandatory = $true)][string]$logFullPath,
        [Parameter(Mandatory = $true)][string]$message,
        [Parameter(Mandatory = $true)][LogMessageType]$logMessageType
    )
    
    $timestamp = Get-Timestamp
    $maxLineLengthWithTimeStamp = ((Get-TitleHeaderLength) - ($timestamp.ToString().length))
    $maxLineLength = (Get-TitleHeaderLength)
    $fullStampPrefix = "$($timestamp) - $($logMessageType.ToString())"

    # Split the message every $maxLineLength characters
    $linesSize1 = $message -split "(.{$maxLineLengthWithTimeStamp})" | Where-Object { $_ }
    $linesSize2 = $message -split "(.{$maxLineLength})" | Where-Object { $_ }
    
    if ($linesSize1.Count -ge 2) {
        # Split lines based on max length
        Add-Content -Path $gLogFullPath -Value "$($fullStampPrefix):"
        $linesSize2 = $message -split "(.{$maxLineLength})" | Where-Object { $_ } | ForEach-Object {
            Add-Content -Path $gLogFullPath -Value $_ -ErrorAction Stop
        }      
    
    }
    elseif ($linesSize1.Count -eq 1) {
        # The message and timestamp go on the same line
        Add-Content -Path $gLogFullPath -Value "$($fullStampPrefix): $($linesSize1)" -ErrorAction Stop
    }
}

function Write-LogPreamble {
    <#
    .SYNOPSIS
    Set up the log with a preamble
       
    .PARAMETER logFullPath
    Path to the log file
    #>
    param(
        [Parameter(Mandatory = $true)][string]$logFullPath
    )
    $tz = Get-TimeZone
    [string]$preamble = @"
$(Get-TitleHeader -RepeatedCharacter "#" -TotalLength (Get-TitleHeaderLength) -TitleValue " Script Preamble: Start ")
Author:                             Sage Software
Script Description:                 This script will help create and install security certificates that are then used 
                                    within the encryption process of a connection between a SQL client application 
                                    and a SQL Server. 
Script Path:                        $gScriptFullPath

Machine:                            $($env:COMPUTERNAME)
Timezone:                           $($tz.DisplayName)
Log file:                           $gLogFullPath
Log Date:                           $((Get-Date))

Script Input Parameters
$(Get-TitleHeader -repeatedCharacter "_" -totalLength (Get-TitleHeaderLength) -titleValue "_")
Certificate Expiration Date:        $certExpirationDate
Instance Name:                      $instanceName
Additional DNS Names:               $additionalDnsNames


Validated Script Parameters
$(Get-TitleHeader -repeatedCharacter "_" -totalLength (Get-TitleHeaderLength) -titleValue "_")
Certificate Expiration Date:        {##gCertificateExpiryDate##}
Instance Name:                      {##gSelectedInstances##}
FQDN Sql Instance Name:             {##FqdnSqlInstanceName##}
Silent Mode:                        {##gSilentMode##}

$(Get-TitleHeader -repeatedCharacter "#" -totalLength (Get-TitleHeaderLength) -titleValue " Script Preamble: End ")

"@
    # Add-Content -Value $step_descriptions -PassThru $gLogFullPath
    Add-Content -Value $preamble -Path $gLogFullPath

}

function Get-TitleHeader {
    param (
        [char]$repeatedCharacter,
        [int]$totalLength = (Get-TitleHeaderLength),
        [string]$titleValue
    )

    # Calculate the length of the repeated characters on both sides
    $repeatedLength = [Math]::Floor(($totalLength - $titleValue.Length) / 2)

    # Create the left and right parts of the header
    $leftPart = $repeatedCharacter.ToString() * $repeatedLength
    $rightPart = $repeatedCharacter.ToString() * $repeatedLength

    # Adjust the right part if total length is not a multiple of 2
    if (($totalLength - $titleValue.Length) % 2 -ne 0) {
        $rightPart += $repeatedCharacter
    }

    # Create the final title header string
    $header = $leftPart + $titleValue + $rightPart

    return $header
}

function Get-TitleHeaderLength {
    return 160
}

function Get-FQDN() {
    return $([System.Net.Dns]::GetHostByName($env:computerName)).HostName
}

function Build-LogSuffix() {

    # Title header and Step Tracker
    $stepSummary = @"
Step Summary:
$(Get-TitleHeader -repeatedCharacter "_" -totalLength (Get-TitleHeaderLength) -titleValue "_")
"@

    $stepTrackerMsg = $(Get-TrackerSummary -tracker $gStepTracker)
    Write-TraceWithTimestamp -logFullPath $gLogFullPath -message "All steps complete" -LogMessageType Info

    # Error Messaging
    $myErrorMessage = @"
********** ERROR START **********
Error Message: '$gErrMsg'
Occured At step: $($gStepTracker.CurrentStep)

Stack Trace: 
$gScriptStackTrace
********** ERROR END   **********
"@


    # Script Status
    $scriptStats = @"
Script Execution Statistics:
$(Get-TitleHeader -repeatedCharacter "_" -totalLength (Get-TitleHeaderLength) -titleValue "_")
Start Time:                 $gStartDatetime
End Time:                   $gEndDatetime
Duration Total Seconds:     $($gStopWatch.Elapsed.TotalSeconds)

"@

    $titleSuffix = (Get-TitleHeader -repeatedCharacter "#" -totalLength (Get-TitleHeaderLength) -titleValue " Script Results: End ")
    
    $retVal = ""
    if (-not ([string]::IsNullOrWhiteSpace($gErrMsg))) {
        $retVal = @"
$myErrorMessage

$stepSummary
$stepTrackerMsg
$scriptStats
$titleSuffix
"@
        

    }
    else {        
        $retVal = @"
$stepSummary
$stepTrackerMsg
$scriptStats
$titleSuffix        
"@        
    }


    return $retVal
}

function Get-CRLF {
    <#
        .SYNOPSIS 
        Detects the operating system and sends back the proper carriage return, or carriage return line feed
		https://docs.microsoft.com/en-us/dotnet/api/system.environment.newline?view=net-6.0
    #>
    return [Environment]::NewLine
}

function Set-LogTag {
    param(
        [Parameter(Mandatory = $true)][string]$tag,
        [Parameter(Mandatory = $true)][string]$value,
        [Parameter(Mandatory = $true)][string]$logFullPath
    )

    $content = Get-Content $logFullPath
    $content = $content -replace $tag, $value
    $content | Set-Content $logFullPath
}


function Get-TrackerSummary {
    <#
    .SYNOPSIS
    Returns a string containing the formatted output of any given input tracker object meant to be used by a logger.
    
    .PARAMETER tracker
    An object derived from the New-Tracker function
    #>
    param (
        [PSObject]$tracker
    )

    $outputData = foreach ($key in $tracker.StepStatuses.Keys) {
        # Create a custom object for each pair of StepStatus and StepDescription
        $customObject = New-Object PSObject -Property @{
            Step        = $key
            Status      = $tracker.StepStatuses[$key]
            Description = $tracker.StepDescriptions[$key]
        }
        # Order the properties of the custom object
        $customObject | Select-Object -Property Step, Description, Status
    }

    # Convert the array of custom objects to a table string
    $outputString = $outputData | Format-Table -AutoSize | Out-String -Width 4096

    Write-TraceWithTimestamp -logFullPath $gLogFullPath -message "Get-TrackerSummary completed" -LogMessageType Info
    return $outputString
}

function New-Tracker {
    <#
    .SYNOPSIS
    An object that contains an "at a glance", high level overview of the statuses of each step that was performed. 
    This information would help someone easily know what the next steps are should a failure occur. 
    #>
    param(
        [Parameter(Mandatory=$true)][object]$stepDescriptions
    )
   
    # Initialize the steps status based on the step descriptions order
    $stepStatus = [ordered]@{}
    $stepDescriptions.Keys | ForEach-Object {
        $stepStatus[$_] = [Status]::NotStarted
    }

    # Create a new tracker object
    $tracker = New-Object PSObject -Property @{
        CurrentStep      = $null
        StepStatuses     = $stepStatus
        StepDescriptions = $stepDescriptions
    }

    # Add a method to get the description for the current step
    $tracker | Add-Member -MemberType ScriptMethod -Name "GetCurrentStepDescription" -Value {
        return $this.StepDescriptions[$this.CurrentStep.ToString()]
    }    

    # Add a method to set the step and its status
    $tracker | Add-Member -MemberType ScriptMethod -Name "SetStep" -Value {
        param (
            [Step]$Step,
            [Status]$Status
        )
        
        $this.CurrentStep = $Step
        $this.StepStatuses[$Step.ToString()] = $Status
    }

    Write-TraceWithTimestamp -logFullPath $gLogFullPath -message "New-Tracker successfully created" -LogMessageType Info
    return $tracker
}
