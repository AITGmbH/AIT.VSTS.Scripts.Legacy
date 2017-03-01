<#.AddIterationToTeamWithBasicAuthentificationHelp
.SYNOPSIS	
	A iteration relates to a team on a TFS or VSTS by basic authentification. 
.DESCRIPTION
	The function sends a post request to TFS or VSTS. It uses for the authentification credential with username and password.
.EXAMPLE
    $content = @{ id = "8765" }
	$json = ConvertTo-Json -InputObject  $content
	$cred = Get-Credential -UserName "Domain\User" -Message: "TFS 2015 Login"

	AddIterationToTeamWithBasicAuthentification $json "https://example.visualstudio.com/MyFirstProject/MyFirstTeam" $cred
.PARAMETER JsonBody
	The Json-String includes the id by the iteration add to a team
.PARAMETER TeamUrl
	The URI of Team Project inclusive the name of team  
.PARAMETER Credential
	It is a set of security credentials, such as a user name and a password.
#>
function AddIterationToTeamWithBasicAuthentification{
	param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$JsonBody, 
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[Uri] $TeamUrl,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$Credential
	)

	process{
	    Write-Verbose "Beginn AddIterationToTeamWithBasicAuthentification"

		$query = "/_apis/work/teamsettings/iterations?api-version=v2.0-preview"
		$addIturl = $TeamUrl.AbsoluteUri + $query

		#Get no Error, if is fail
		Invoke-RestMethod -Method Post -ContentType "application/json" -Uri $addIturl -Credential $Credential -Body $jsonBody -ErrorVariable result -ErrorAction SilentlyContinue

	}
}

<#.AddIterationToTeamWithBasicAuthentificationHelp
.SYNOPSIS	
	A iteration relates to a team on a TFS or VSTS by the Personal Access Token. 
.DESCRIPTION
	The function sends a post request to TFS or VSTS. It uses for the authentification Username and corresponding Personal Access Token.
.EXAMPLE
    $content = @{ id = "8765" }
	$json = ConvertTo-Json -InputObject  $content
	$cred = Get-Credential -UserName "Domain\User" -Message: "TFS 2015 Login"

	AddIterationToTeamWithBasicAuthentification $json "https://example.visualstudio.com/MyFirstProject/MyFirstTeam" "UserName" "h2ixjlahgmrfb722yo23kzohh9f1evc2wf1bwhnwme9fn59dky3v"
.PARAMETER JsonBody
	The Json-String includes the id by the iteration add to a team
.PARAMETER TeamUrl
	The URI of Team Project inclusive the name of team  
.PARAMETER Username
	Login name of the VSTS or TFS account
.PARAMETER Token
	Personal Access Token, which is association with the username
#>
function AddIterationToTeamWithTokenAuthentification{
	param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$JsonBody, 
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[Uri] $TeamUrl,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Username,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Token
	)

	process{
	    Write-Verbose "Beginn AddIterationToTeamWithTokenAuthentification"

		$query = "/_apis/work/teamsettings/iterations?api-version=v2.0-preview"
		$addIturl = $TeamUrl.AbsoluteUri + $query
		$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $Username,$Token)))

		#Get no Error, if is fail
		Invoke-RestMethod -Method Post -ContentType "application/json" -Uri $addIturl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Body $jsonBody
	}
}

<#.AddIterationsToTeamListWithBasicAuthentificationHelp
.SYNOPSIS	
	For each iteration in the list relates to each team in the List. 
.DESCRIPTION
	For each mapping between iteration and team, the function creates the Data for the post request, which sends with the function AddIterationToTeamWithTokenAuthentification or AddIterationToTeamWithBasicAuthentification.
.EXAMPLE
    
.PARAMETER IterationList
	
.PARAMETER Teams
	  
.PARAMETER ProjectUrl
	The URI of the Team Project.

.PARAMETER Username
	Login name of the VSTS or TFS account

.PARAMETER Token
	Personal Access Token, which is association with the username

.PARAMETER Credential
	It is a set of security credentials, such as a user name and a password.

.PARAMETER AuthentificationType
	Depending on the AuthentificationType the script checks the requiered parameter and uses the corresponding the function to send the post request. Only the two value "Token" and "Basic" are allow. 
#>
function AddIterationsToTeamList{
	param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		$IterationList, 

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String[]]$Teams,

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()] 
		[Uri] $ProjectUrl,

		[Parameter(Mandatory=$false)]
		[string]$Username,

		[Parameter(Mandatory=$false)]
		[string]$Token,

		[Parameter(Mandatory=$false)]
		[PSCredential]$Credential,

		[Parameter(Mandatory=$true)]
		[ValidateSet ('Token','Basic')]
		[string]$AuthentificationType
	)

	process{
	    Write-Verbose "Beginn AddIterationsToTeamList"

		foreach ($it in $IterationList){
			$body = @{
				id = $it.identifier
			}

			$jsonBody = ConvertTo-Json -InputObject  $body

			foreach($t in $Teams){
				$teamUrl = $ProjectUrl.AbsoluteUri + "/" + $t.trim()

				if ($AuthentificationType -eq 'Token'){

					AddIterationToTeamWithTokenAuthentification $jsonBody $teamUrl $Username $Token
				}

				if ($AuthentificationType -eq 'Basic')
				{
					AddIterationToTeamWithBasicAuthentification $jsonBody $teamUrl $Credential
				}
			}
		}
	}
}






