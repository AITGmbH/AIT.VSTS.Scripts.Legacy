#
# read a List of iterations and relate to a team
#
function Relate-VstsIteration{

	param(
	  [Parameter(Mandatory=$true)]
	  [ValidateNotNullOrEmpty()]
	  [string]$Username,

	  [Parameter(Mandatory=$true)]
	  [ValidateNotNullOrEmpty()]
	  [string]$Token,

	  [Parameter(Mandatory=$true)]
	  [ValidateNotNullOrEmpty()]
	  [Uri]$Projecturi,

	  [Parameter(Mandatory=$false)]
	  [ValidateNotNullOrEmpty()]
	  [string[]]$TeamList,

	  [Parameter(Mandatory=$false)]
	  [ValidateNotNullOrEmpty()]
	  [string]$StartOfIterationPath
	)

	process{   
		[int]$nodeDepth  = 0

		function AddIterationToTeamList{
			param ($iterationList, [String[]]$teams, [Uri] $projectUrl )
			$success = $true;

			foreach ($it in $iterationList){
				$body = @{
					id = $it.identifier
				}
	
				$jsonBody = ConvertTo-Json -InputObject  $body
				$query = "/_apis/work/teamsettings/iterations?api-version=v2.0-preview"

				foreach($t in $teams){
					$addIturl = $projectUrl.AbsoluteUri + "/" + $t.trim() + $query
					$result = Invoke-RestMethod -Method Post -ContentType "application/json" -Uri $addIturl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Body $jsonBody -ErrorAction SilentlyContinue

					if (!$result){
						Write-Host "Error: Iteration do not relate to a team"
						Write-Host "Iteration-Path:" $it.url.substring($it.url.IndexOf("Iterations/") + 11)
						Write-Host "Team-Name:" $t
						$success = $false
						break
					}
				}

				if(!$success){
					Write-Host "process aborted"
					break;
				}
			}
		}

		. ./GetNextChild.ps1

		. ./GetNodeDepth.ps1

		. ./GetStartRootNode.ps1

		$nodeDepth = GetNodeDepth $StartOfIterationPath
		$root      = GetStartRootNode $StartOfIterationPath

		$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$Token)))

		#GET Iterations
		$iterationUri = $Projecturi.AbsoluteUri +  "/_apis/wit/classificationNodes/iterations/" + $root + "?api-version=1.0&`$depth=" + $nodeDepth

		$iterationList = Invoke-RestMethod -Uri $iterationUri -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -ErrorAction Stop

		$addList   = GetNextChild $iterationList.children 1 $nodeDepth
		AddIterationToTeamList $addList $TeamList $Projecturi
		}
}