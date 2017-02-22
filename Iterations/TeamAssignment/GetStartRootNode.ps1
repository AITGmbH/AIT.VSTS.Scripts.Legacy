function GetStartRootNode{
	param(
		[String] $startNodePath
	)

	process{
		if ($startNodePath -eq "")
		{
			return ""
		}

		if($startNodePath.Contains("/"))
		{
			$inhalt = $startNodePath.Split("/")
			return $inhalt[0]
		}else{
			return ""
		}
	}
}
