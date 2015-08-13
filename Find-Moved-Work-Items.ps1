#################################################################################
#
# Automatically finds all moved work items.
#
# SPACES IN ARGUMENTS MUST BE ENCLOSED BY SINGLE QUOTES
#
# Example 1: Find all work-items, which have been moved and are part of the given team.
#   .\Find-Moved-Work-Items -$FilterByTeam 'Team.Phoenix' -SaveInFile 'results.csv'
#
# Example 2: Find all work-items, which have been moved (Without filter).
#   .\Find-Moved-Work-Items -ProjectName '' -$FilterByTeam '' -SaveInFile 'results.csv'
#
# Example 3: Specify the server and the project 
#   .\Find-Moved-Work-Items -Url "https://example.visualstudio.com/DefaultCollection/" -ProjectName "MyProject" -$FilterByTeam 'MyTeam' -SaveInFile 'results.csv'

#################################################################################


param(
    [string]$Url,
    [string]$ProjectName,
    [string]$FilterByTeam,
    [string]$SaveInFile = "results.csv"
)

$assignedToFieldName = "Assigned To"
$iterationPathFieldName = "Iteration Path"

#Load TFS PowerShell Snap-in
if ((Get-PSSnapIn -Name Microsoft.TeamFoundation.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
    Add-PSSnapin Microsoft.TeamFoundation.PowerShell
}

#Set to German culture so we generate German month names later
[System.Threading.Thread]::CurrentThread.CurrentCulture = "de-DE"

#Load Reference Assemblies
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Client")
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.WorkItemTracking.Client")
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.ProjectManagement")

#TFS Server Settings
$TeamProjectCollection = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($Url)

# Service instances
$css4 = ($TeamProjectCollection.GetService([type]"Microsoft.TeamFoundation.Server.ICommonStructureService4")) -as [Microsoft.TeamFoundation.Server.ICommonStructureService4]
$teamService = ($TeamProjectCollection.GetService([type]"Microsoft.TeamFoundation.Client.TfsTeamService")) -as [Microsoft.TeamFoundation.Client.TfsTeamService]
$teamConfig = ($TeamProjectCollection.GetService([type]"Microsoft.TeamFoundation.ProcessConfiguration.Client.TeamSettingsConfigurationService")) -as [Microsoft.TeamFoundation.ProcessConfiguration.Client.TeamSettingsConfigurationService]
$store = ($TeamProjectCollection.GetService([type]"Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore")) -as [Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore]

# Find the correct Team and construct a big area filter (for all the areas of that team)
$areaFilter = ""
if ($ProjectName)
{
	$proj = $css4.GetProjectFromName($ProjectName)
	$allTeams = $teamService.QueryTeams($proj.Uri)

	$firstArea = $true
	$areaFilter = "WHERE [System.AreaPath] = """
		
	ForEach($team in $allTeams)
	{
		if (([System.String]::IsNullOrEmpty($FilterByTeam)) -Or $team.Name -eq $FilterByTeam)
		{
			$ids = [System.Linq.Enumerable]::Repeat($team.Identity.TeamFoundationId, 1)
			$teamConfigs = [System.Linq.Enumerable]::ToArray($teamConfig.GetTeamConfigurations($ids))
			$settings = $teamConfigs[0].TeamSettings
			ForEach($tfv in $settings.TeamFieldValues)
			{
				if($firstArea)
				{
					$firstArea = $false
					$areaFilter = $areaFilter + $tfv.Value
				}
				else
				{
					$areaFilter = $areaFilter + """ OR [System.AreaPath] = """ + $tfv.Value
				}
			}
		}
	}
	$areaFilter = $areaFilter + """"
}

# Fetch all the workitem ids
$workItemIdQuery = $store.Query("Select Id From WorkItems " + $areaFilter)
[array]$taskItems = new-object System.Threading.Tasks.Task``1[Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItem][] ($workItemIdQuery.Count)
Write-Host "Requesting workitems..."
$num = 0

# Start simple tasks via C# Tasks
# This is to fetch all the WorkItem information in parallel (drastic speed-up)
# This is NOT trivial/very hard to do in PowerShell.
function CreateTask {
    param(
        $workItemId
    )
    # is this type already defined?    
    if (-not ("TaskRunner" -as [type])) {
		$refs = @(
			"C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.Client.dll",
			"C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.Build.Client.dll",
			"C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.Build.Common.dll",
			"C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.WorkItemTracking.Client.dll",
			"C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.VersionControl.Client.dll",
			"C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v4.5\Microsoft.TeamFoundation.ProjectManagement.dll"
		)

        Add-Type -ReferencedAssemblies $refs @"
            using System;
             
            public sealed class TaskRunner
            {
                public static System.Threading.Tasks.Task<Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItem> Create(Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore store, int workItemId)
                {
                    return
						System.Threading.Tasks.Task.Run<Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItem>(
							() => store.GetWorkItem(workItemId));
                }
            }
"@ 
    }
    return [TaskRunner]::Create($store, $workItemId)
}

ForEach ($workItem in $workItemIdQuery)
{
	Write-Host "Starting... $num / $($workItemIdQuery.Count)"

	# This is an alternative solution which is not running in parallel (= slow)
	#	$task = {
	#		return $store.GetWorkItem($i.Id)
	#}
	#$callBack = New-ScriptBlockCallback $task
	#$taskObj = [System.Threading.Tasks.Task]::Run([System.Func``1[Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItem]]$callBack)
	$taskObj = CreateTask($workItem.Id)
	$taskItems[$num] = $taskObj
	$num = $num + 1
}


# Get all the changes for the given WorkItem and the given fieldName.
function GetChanges ($workItem, $fieldName)
{
	if (!$workItem -or !$fieldName)
	{
		throw "Given workItem is null"
	}
	[array]$changes = @()
	$n = 0
	ForEach($rev in $workItem.Revisions)
	{
		ForEach($field in $rev.Fields)
		{
			# write-Output "Field: $f.Name"

			if (
					$field.Name -eq $fieldName -and 
					$field.OriginalValue -ne $field.Value -and
					!([System.String]::IsNullOrWhiteSpace($field.OriginalValue.ToString())))
			{
				[array]$array = new-object string[] 2
				$array[0] = $field.OriginalValue.ToString()
				$array[1] = $field.Value.ToString()
				$changes += ,$array
				$n = $n + 1
			}
		}
	}
	if ($n -eq 0) 
	{
		return new-object string[][] (0)
	}
	else 
	{
		[array]$ret = new-object string[][] ($n)
		For ($i=0; $i -lt $n; $i++)
		{
			if (! $changes[$i])
			{
				throw "Found a null element. (n $n, i $i )"
			}
			$ret[$i] = $changes[$i]
		}
		return $ret
	}
}

# (unspectacular) function to write out the .csv file.
function Write-Csv
{
	Write-Output "ITEMTITLE;ITEMID;STATE;(Second-)USER;CREATED;FROM;TO;ITERATIONCHANGES;USERCHANGES;TAGS"
	$num = 0
	ForEach ($taskObj in $taskItems)
	{
		$workItem = $taskObj.Result
		$num = $num + 1
		Write-Host "$num / $($workItemIdQuery.Count)"
		# @( to force PowerShell to not unwrap: http://stackoverflow.com/questions/11107428/how-can-i-force-powershell-to-return-an-array-when-a-call-only-returns-one-objec
		$currentIterationChanges = @(GetChanges -workItem $workItem -fieldName $iterationPathFieldName)
		$assignedToChange = @(GetChanges -workItem $workItem -fieldName $assignedToFieldName)
		
		# Remove first if it was initially moved out of root, first check if GetChanges returned null (= empty array at this point)
		if ($currentIterationChanges.Length -gt 0 -and ($currentIterationChanges[0][0] -eq $ProjectName -or !$currentIterationChanges[0]))
		{
			if ($currentIterationChanges.Length -gt 1)
			{
				[array]$currentIterationChanges = $currentIterationChanges[1..($currentIterationChanges.Length - 1)]
			}
			else
			{
				$currentIterationChanges = @()
			}
		}
	
		$user = $workItem.CreatedBy
		$assignedLength = $assignedToChange.Length
		if ($assignedLength -gt 0 -and $assignedToChange[0])
		{
			$from = $assignedToChange[0][0]
			$to_ = $assignedToChange[0][1]
			$isEmpty = [System.String]::IsNullOrEmpty($assignedToChange[0][1])
			
			if ($isEmpty)
			{
				$user = $from
			}
			else
			{
				$user = $to_
			}
		}
		
		
		ForEach($change in $currentIterationChanges)
		{
			Write-Output """$($workItem.Title)"";$($workItem.Id);$($workItem.State);$user;$($workItem.CreatedDate);$($change[0]);$($change[1]);$($currentIterationChanges.Length);$($assignedToChange.Length);""$($workItem.Tags)"""
		}
	}
}

Write-Csv > $SaveInFile

