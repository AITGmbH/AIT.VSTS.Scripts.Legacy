function GetNodeDepth
{
	param(
		[String] $startNodePath
	)

	process
	{
		if ($startNodePath -eq "")
		{
			return 1
		}

		if($startNodePath.Contains("/"))
		{
			$resultDepth = $startNodePath.Split("/").Length
			#Project level will be omitted in the tree (depth is relative to the root).
			$resultDepth = $resultDepth - 1
			return  $resultDepth
		}else{
			return 1
		}
	}
}
