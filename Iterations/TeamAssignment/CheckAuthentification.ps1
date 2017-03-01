function CheckAuthenficationVSTS{
	param(
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Username,

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Token
	)

	process{
		$returnValue = 0
		
		if ($Username.Trim() -eq "")
		{
			Write-Verbose 'Username must not be empty'
			$returnValue = 1
		}

		if ($Token.Trim() -eq "")
		{
			Write-Verbose 'Token must not be empty'
			$returnValue = 1
		}

		return $returnValue
	}
}

function CheckAuthenficationTFS{
	param(
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$Credential
	)

	process{
		$returnValue = 0

		if($Credential -eq $null)
		{
			Write-Verbose 'Please create a credential with Get-Credential'
			$returnValue = 1
		}

		return $returnValue
	}
}


