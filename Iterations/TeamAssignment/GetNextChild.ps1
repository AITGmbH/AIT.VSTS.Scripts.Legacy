function GetNextChild
{
	param(
		[object[]]$list, 
		[int]$currentDepth,
		[int]$acceptDepth
	)

	process
	{
		$resultList = @()

		foreach($it in $list)
		{
			if(Get-Member -InputObject $it -Name children -MemberType Properties)
			{
			    $newDepth = $currentDepth + 1
				$resultList += GetNextChild $it.children $newDepth $acceptDepth
			}else{
			    if($currentDepth -eq $acceptDepth)
				{
					$resultList += $it
				}
			}
		}

		return $resultList
	}
}
