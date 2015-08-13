#################################################################################
#
# Automatically creates a single Product Backlog Item (PBI) for a team and a workitem for every member within the team.
#
# SPACES IN ARGUMENTS MUST BE ENCLOSED BY SINGLE QUOTES
#
# Example: Create the items with the given title for the given server.
#   .\Create-Team-Work-Items -Url "https://example.visualstudio.com/DefaultCollection" -ProjectName "MyProject" -Team "MyTeam" -Title "My New Work Item Title" -WorkItemType "Requirement"
#
# Known Bugs:
# When your DisplayName's are not unique one of the duplicates with get all workitems. See 
# - http://stackoverflow.com/questions/16295066/not-getting-field-assigned-to-and-last-update-date-of-workitem-from-the-work
# - https://stackoverflow.com/questions/30641279/how-to-set-assigned-to-in-tfs-work-item-through-code#
#
#################################################################################


param(
    [string]$Url,
    [string]$ProjectName,
    [string]$Team,
    [string]$Title,
    [string]$WorkItemType
)

#Load TFS PowerShell Snap-in
if ((Get-PSSnapIn -Name Microsoft.TeamFoundation.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
    Add-PSSnapin Microsoft.TeamFoundation.PowerShell
}

#Set to German culture so we generate German month names later
[System.Threading.Thread]::CurrentThread.CurrentCulture = "de-DE"

#Load Reference Assemblies
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Client")  
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Build.Client")  
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Build.Common") 
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.WorkItemTracking.Client") 
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.VersionControl.Client") 
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.ProjectManagement") 

$TeamProjectCollection = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($Url)
$TeamProjectCollection.EnsureAuthenticated()

# Service instances
$css4 = ($TeamProjectCollection.GetService([type]"Microsoft.TeamFoundation.Server.ICommonStructureService4")) -as 
		[Microsoft.TeamFoundation.Server.ICommonStructureService4]
$teamService = ($TeamProjectCollection.GetService([type]"Microsoft.TeamFoundation.Client.TfsTeamService")) -as 
		[Microsoft.TeamFoundation.Client.TfsTeamService]
$teamConfigService = ($TeamProjectCollection.GetService([type]"Microsoft.TeamFoundation.ProcessConfiguration.Client.TeamSettingsConfigurationService")) -as 
		[Microsoft.TeamFoundation.ProcessConfiguration.Client.TeamSettingsConfigurationService]
$store = ($TeamProjectCollection.GetService([type]"Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore")) -as 
		[Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore]


if ([System.String]::IsNullOrEmpty($ProjectName))
{
	throw "Please enter a ProjectName, as Teams are part of a project!"
}

if ([System.String]::IsNullOrEmpty($Team))
{
	throw "Please enter a Team name!"
}

$proj = $css4.GetProjectFromName($ProjectName)
$allTeams = $teamService.QueryTeams($proj.Uri)

$foundTeam = $null
		
ForEach($t in $allTeams)
{
	if ($t.Name -eq $Team)
	{
		$foundTeam = $t
	}
}
if (!$foundTeam) {
	throw "The Team $Team could not be found!"
}

# Get default area of team
$ids = [System.Linq.Enumerable]::Repeat($foundTeam.Identity.TeamFoundationId, 1)
$teamConfigs = [System.Linq.Enumerable]::ToArray($teamConfigService.GetTeamConfigurations($ids))
$teamConfig = $teamConfigs[0].TeamSettings
$defaultTeamArea = $teamConfig.TeamFieldValues[0].Value

Write-Host "Using default area of team: $defaultTeamArea"


$project = $store.Projects[$ProjectName]

$wit = $project.WorkItemTypes[$WorkItemType]
if (!$wit) {
	throw "The WorkItemType $WorkItemType could not be found in project $ProjectName"
}
$taskType = $project.WorkItemTypes["Task"]

if (!$taskType) {
	throw "The WorkItemType Task could not be found in project $ProjectName"
}

# Create Product Backlog Item (PBI) 
Write-Host "Creating Product Backlog Item"
$pbi = New-Object Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItem ($wit)
$pbi.Title = $Title
$pbi.AreaPath = $defaultTeamArea
$pbi.Save()

$linkType = $store.WorkItemLinkTypes["System.LinkTypes.Hierarchy"]
$pbiId = $pbi.Id

# http://blog.johnsworkshop.net/tfs11-api-query-teams-and-team-members/
$members = $foundTeam.GetMembers($TeamProjectCollection, [Microsoft.TeamFoundation.Framework.Common.MembershipQuery]::Expanded)

ForEach ($member in $members) {
	if(!$member.IsContainer) {
		# Filter out groups
		$user = $member.DisplayName
		if (!$user) { throw "User $member is invalid." }
		Write-Host "Creating Task for user $user"
		$workItem = New-Object Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItem ($taskType)
		$workItem.Title = "$Title"
		# BUG: See http://stackoverflow.com/questions/30641279/how-to-set-assigned-to-in-tfs-work-item-through-code
		# "Assigned To" sadly doesn't accept anything else.
		$workItem["Assigned To"] = $user

		$workItem.AreaPath = $defaultTeamArea
		
		$taskLink = New-Object Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemLink ($linkType.ReverseEnd, $pbiId)
		$workItem.Links.Add($taskLink)
		$workItem.Save()
	}
}