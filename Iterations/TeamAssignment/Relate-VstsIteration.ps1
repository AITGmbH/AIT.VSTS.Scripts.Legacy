#
# read a List of iterations and relate to a team
#
#Update 1: insert PSCredential for basic authenification
function Relate-VstsIteration{

	param(
	  [Parameter(Mandatory=$false)]
	  [ValidateNotNullOrEmpty()]
	  [string]$Username,

	  [Parameter(Mandatory=$false)]
	  [ValidateNotNullOrEmpty()]
	  [string]$Token,

	  [Parameter(Mandatory=$false)]
	  [ValidateNotNullOrEmpty()]
	  [PSCredential]$Credential,

	  [Parameter(Mandatory=$true)]
	  [ValidateSet ('Token','Basic')]
	  [ValidateNotNullOrEmpty()]
	  [string]$AuthentificationType,

	  [Parameter(Mandatory=$true)]
	  [ValidateNotNullOrEmpty()]
	  [Uri]$Projecturi,

	  [Parameter(Mandatory=$true)]
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

					if ($AuthentificationType -eq 'Token'){

						$result = Invoke-RestMethod -Method Post -ContentType "application/json" -Uri $addIturl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Body $jsonBody -ErrorAction SilentlyContinue
					}

					if ($AuthentificationType -eq 'Basic')
					{
						Invoke-RestMethod -Method Post -ContentType "application/json" -Uri $addIturl -Credential $Credential -Body $jsonBody -ErrorAction SilentlyContinue
					}

					if ($result -ne $null){
						$success = $false
						break
					}
				}

				if(!$success){
					Write-Verbose "process aborted"
					break;
				}
			}
		}

		. ./GetNextChild.ps1

		. ./GetNodeDepth.ps1

		. ./GetStartRootNode.ps1

		. ./CheckAuthenfication.ps1

		$nodeDepth = GetNodeDepth $StartOfIterationPath
		$root      = GetStartRootNode $StartOfIterationPath

		if($AuthentificationType -eq 'Token')
		{
			$check = CheckAuthenficationVSTS $Username $Token
		} 

		if ($AuthentificationType -eq 'Basic')
		{
			$check = CheckAuthenficationTFS $Credential
		}

		if($check -eq 1){
			return
		}

		#GET Iterations
		$iterationUri = $Projecturi.AbsoluteUri +  "/_apis/wit/classificationNodes/iterations/" + $root + "?api-version=1.0&`$depth=" + $nodeDepth

		if ($AuthentificationType -eq 'Token')
		{
			#credentials with token (VSTS)
			$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$Token)))
			$iterationList = Invoke-RestMethod -Uri $iterationUri -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -ErrorAction Stop
		}

		if ($AuthentificationType -eq 'Basic')
		{
			#credentials with Username and Password (TFS)
			$iterationList = Invoke-RestMethod -Uri $iterationUri -Method Get -Credential $Credential -ErrorAction Stop
		}

		$addList   = GetNextChild $iterationList.children 1 $nodeDepth
		AddIterationToTeamList $addList $TeamList $Projecturi
		}
}