#################################################################################
#
# Automatically finds all areas for a given team.
#
# SPACES IN ARGUMENTS MUST BE ENCLOSED BY SINGLE QUOTES
#
# Example 1: Find all areas for the given team.
#   .\Team-To-Areas -Team 'Team.Phoenix'
#
# Example 2: Specify Project Url and Name
#   .\Team-To-Areas -Url "https://example.visualstudio.com/DefaultCollection/" -ProjectName "MyProject" -Team "MyTeam"
#
#################################################################################


param(
    [string]$Url,
    [string]$ProjectName,
    [string]$Team
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

# Service instances
$css4 = ($TeamProjectCollection.GetService([type]"Microsoft.TeamFoundation.Server.ICommonStructureService4")) -as [Microsoft.TeamFoundation.Server.ICommonStructureService4]
$teamService = ($TeamProjectCollection.GetService([type]"Microsoft.TeamFoundation.Client.TfsTeamService")) -as [Microsoft.TeamFoundation.Client.TfsTeamService]
$teamConfigService = ($TeamProjectCollection.GetService([type]"Microsoft.TeamFoundation.ProcessConfiguration.Client.TeamSettingsConfigurationService")) -as [Microsoft.TeamFoundation.ProcessConfiguration.Client.TeamSettingsConfigurationService]
$store = ($TeamProjectCollection.GetService([type]"Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore")) -as [Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore]

$foundTeam = $null

$proj = $css4.GetProjectFromName($ProjectName)
$allTeams = $teamService.QueryTeams($proj.Uri)
		
ForEach($t in $allTeams)
{
	if ($t.Name -eq $Team)
	{
		$foundTeam = $t
	}
}

if (!$foundTeam)
{
	throw "The team $Team could not be found!"
}

# Get the areas of the team
$ids = [System.Linq.Enumerable]::Repeat($foundTeam.Identity.TeamFoundationId, 1)
$teamConfigs = [System.Linq.Enumerable]::ToArray($teamConfigService.GetTeamConfigurations($ids))
$teamConfig = $teamConfigs[0].TeamSettings
ForEach ($tfv in $teamConfig.TeamFieldValues) {
	Write-Host "Area $($tfv.Value) is part of team $Team"
}