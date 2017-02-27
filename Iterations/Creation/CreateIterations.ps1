<#
	REQUIRED CHANGES IN ORDER TO ADAPT TO OWN PROJECT
    ------------------------------------------------- 
	Line 17:      libraryPathLocation
    Line 364/365: start/end date
    Line 367:     project
    Line 368:     collection
#>


########################################## LOADING .NET ASSEMBLIES ##########################################
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation");
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Client.dll");
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Common.dll");
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Server.ICommonSturctureService");

$libraryPathLocation = "C:\TFS\AIT.Tools\Tools\Scripts\ALM\Dlls\"

Add-Type -Path $libraryPathLocation"Microsoft.TeamFoundation.Client.dll"
Add-Type -Path $libraryPathLocation"Microsoft.TeamFoundation.Common.dll"


########################################## TFS HELPER-METHODS ##########################################

#Get the TFS Collection 
function Get-TfsCollection 
{
 Param(
       [string] $CollectionUrl
       )
    if ($CollectionUrl -ne "")
    {
        #if collection is passed then use it and select all projects
        $tfs = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($CollectionUrl)
    }
    else
    {
        #if no collection is specified, open project picker to select it via gui
        $picker = New-Object Microsoft.TeamFoundation.Client.TeamProjectPicker([Microsoft.TeamFoundation.Client.TeamProjectPickerMode]::NoProject, $false)
        $dialogResult = $picker.ShowDialog()
        if ($dialogResult -ne "OK")
        {
            #exit
        }
        $tfs = $picker.SelectedTeamProjectCollection
    }
    Return $tfs
}
    
#Get the Common structure service, that is responsible for the creation of iteration paths
function Get-TfsCommonStructureService 
{
 Param(
       [Microsoft.TeamFoundation.Client.TfsTeamProjectCollection] $TfsCollection
       )
       [Microsoft.TeamFoundation.Server.ICommonStructureService4]$service = $TfsCollection.GetService("Microsoft.TeamFoundation.Server.ICommonStructureService4");
       
    return [Microsoft.TeamFoundation.Server.ICommonStructureService4]$service;
}

#Get the project info for a given projectName
function GetProjectInfoFromProjectName
{
 Param(
       [string] $projectName,
       [Microsoft.TeamFoundation.Client.TfsTeamProjectCollection] $TfsCollection,
       $css
       )

    [Microsoft.Teamfoundation.Server.ProjectInfo]$returnProject;
	foreach ($projectInfo in $css.ListProjects())
    {
		if ($projectInfo.Name.Equals($projectName))
		{
			$returnProject = $projectInfo;
		}
	}

	if (!$returnProject)
	{
		throw new Exception("The Project does not exist on the server.");
	}

	Return $returnProject;
}

#Creates a new iteration
function CreateIteration
{
 Param(
        [Microsoft.TeamFoundation.Server.ICommonStructureService4]$css,
        $projectInfo,
        [string] $iterationName, 
        [DateTime] $startDate, 
        [DateTime] $endDate
       )
	$createdNode = CreateNode $css $projectInfo $iterationName;
    if ($createdNode)
	{         
		$css.SetIterationDates($createdNode.Uri, $startDate, $endDate);
		 $result = $true
	}
	else
	{
		Write-Host("Creating the Iteration failed.");
	}
            
	return $result;
}

#Creates a new iteration node
function CreateNode   
{
 Param(
        [Microsoft.TeamFoundation.Server.ICommonStructureService4]$css,
        $projectInfo,
        [string] $elementName
	   )        
       
	$rootNodePath =  [string]::Format("\{0}\{1}", $projectInfo, "Iteration");
    $pathRoot = $css.GetNodeFromPath($rootNodePath);
	if(!$pathRoot)
	{
		Write-Host ("Error while getting the root Node")
		exit;
	}
            
	<# The elementName could contain e.g. "A\B\C\D" which indicates a hierarchy of nodes
       we must ensure that each node in the hierarchy exists. If not we must create it.
	 #>

	#split the elementName into its parts
	$parts = $elementName.Split("\");

	#check each part if it exists
	foreach ($part in $parts)
	{
		if (HasChild $pathRoot $part $css)
		{
			# Pick the child node and use it as new pathRoot node
            $pathRoot = GetChild $pathRoot $part $css;
		}
		else
		{
			#1 The child node did not exist so we need to create it.
			#2 Once we hit this path first, every other part processed afterwards will also end up here.
			#3 The result of this method contains the uri to the created node.
			$createdNode = $css.CreateNode($part, $pathRoot.Uri);

			#Using the URI we can get the new created node
			$pathRoot = $css.GetNode($createdNode);
		}

        $result =  $pathRoot;
	}
	# If we did find all parts from the elementName we did not create any new node and 
	# therefore we will return false, otherwise we will return true.
	Write-Host($result.GetType());
    return   $result;
}

#Determins if the specified iteration node has a child node with the specified name 
function HasChild
{
  Param(
		$node,$childName,$css
       )

	try
    {
		$tmp = $css.GetNodeFromPath($node.Path + "\" + $childName);

		if ($tmp)
		{
			 return $true;
		}
	}
	catch [Exception] 
	{
		# just means that this path does not exist and we can continue.
	}
	return $false;
}

#Gets the specified child node for the given node
function GetChild
{
 Param(
	   $node, $childName, $css
	  )

	$path =  [string]::Format("{0}\{1}", $node.Path, $childName);
	$foundNode = $css.GetNodeFromPath($path);

	if ($foundNode -eq $null)
	{
		throw new NodeDoesNotExistException("The Node does not exist");     
	}
	else
	{
		return $foundNode;
	}         
}


########################################## ALL FUNCTIONS FOR THE DATE AND TIME ##########################################

# Simple function to retrieve the calendar week to a given or the current date.
function Get-IterationData 
{
 param(
	   $startDate, $endDate
	  )
 
	# get current culture object
	$Culture = [System.Globalization.CultureInfo]::CurrentCulture
  
	#the return array with all calendar week information
	$returnArray = @{};
	$returnArray = Get-Years $startDate $endDate $returnArray

	#get the day of the week from the startDate
	$day = $startDate.DayOfWeek;

	# retrieve calendar week from the startDate
	$startCw = $Culture.Calendar.GetWeekOfYear($startDate, $Culture.DateTimeFormat.CalendarWeekRule, 
	$Culture.DateTimeFormat.FirstDayOfWeek);
	
	#Loop over the dates and get the kalendarweeks
	$currentDate = $startDate
	do
	{
		#Determine how many days should be added to get the next calendarWeek
		$currentCw = $Culture.Calendar.GetWeekOfYear($currentDate, $Culture.DateTimeFormat.CalendarWeekRule, $Culture.DateTimeFormat.FirstDayOfWeek); 

		if ($currentDate.DayOfWeek -ne $Culture.DateTimeFormat.FirstDayOfWeek)
		{
			$DaysToAdd = 7 - ( [int]$currentDate.DayOfWeek - [int]$Culture.DateTimeFormat.FirstDayOfWeek);
		}
		else
		{
			$DaysToAdd = 7;
		}
            
		#Get the quarter of the current week and check if it is in the array
		$quarterNumber = Get-Quarters($currentDate);
		$quarterName = "Q"+$quarterNumber;
             
		if (!$returnArray[$currentDate.Year].ContainsKey($quarterName))
		{
			$iterationPathNameQuarter = [string]::Format("{0}\{1}",$currentDate.Year,$quarterName )
			switch ($quarterNumber) 
			{ 
				1 
				{
					$quarterStart = [datetime]([string]::Format("01.01.{0}",$currentDate.Year))
					$quarterEnd = [datetime]([string]::Format("03.31.{0}",$currentDate.Year))
				}
				2 
				{
					$quarterStart = [datetime]([string]::Format("04.01.{0}",$currentDate.Year))
					$quarterEnd = [datetime]([string]::Format("06.30.{0}",$currentDate.Year))
				}
				3 
				{
					$quarterStart = [datetime]([string]::Format("07.01.{0}",$currentDate.Year))
					$quarterEnd = [datetime]([string]::Format("09.30.{0}",$currentDate.Year))
				}
				4 
				{
					$quarterStart = [datetime]([string]::Format("10.01.{0}",$currentDate.Year))
					$quarterEnd = [datetime]([string]::Format("12.31.{0}",$currentDate.Year))
				}
			}
			$returnArray[$currentDate.Year][$quarterName] = @{};
			$returnArray[$currentDate.Year][$quarterName]["Start"] = $quarterStart;
			$returnArray[$currentDate.Year][$quarterName]["End"] = $quarterEnd;
			$returnArray[$currentDate.Year][$quarterName]["Iterationpath"] =  $iterationPathNameQuarter;
		}
	  
		#build the pair that identifies two calendar weeks
		$rest = $currentCw;
		$rest %= 2;

		if ($rest -eq 0)
		{
			$cwPair = [string]::Format("KW {0}-{1}",[int]($currentCw-1),$currentCw );
			$cwPairStart =  $currentDate.AddDays(-7);
			$cwPairEnd = ($currentDate.AddDays($DaysToAdd-1));
		}
		else
		{
			$cwPair = [string]::Format("KW {0}-{1}",$currentCw, [int]($currentCw+1));
			$cwPairStart = $currentDate.AddDays(-(7-$DaysToAdd));
			$cwPairEnd = ($currentDate.AddDays(7+$DaysToAdd-1));
		}

		if (!$returnArray[$currentDate.Year][$quarterName].ContainsKey($cwPair))
		{
			$iterationPathNameCwPair = [string]::Format("{0}\{1}\{2}",$currentDate.Year,$quarterName,$cwPair )

			$returnArray[$currentDate.Year][$quarterName][$cwPair] = @{};
			$returnArray[$currentDate.Year][$quarterName][$cwPair]["Start"] =$cwPairStart;
			$returnArray[$currentDate.Year][$quarterName][$cwPair]["End"] = $cwPairEnd;
			$returnArray[$currentDate.Year][$quarterName][$cwPair]["Iterationpath"] =  $iterationPathNameCwPair;
		}

		#Add the CW to the array
		if (!$returnArray[$currentDate.Year][$quarterName][$cwPair].ContainsKey($currentCw))
		{
			#build the path name
			$iterationPathName = [string]::Format("{0}\{1}\{2}\KW {3}",$currentDate.Year,$quarterName,$cwPair, $currentCw )

			$returnArray[$currentDate.Year][$quarterName][$cwPair][$currentCw] = @{};
			$returnArray[$currentDate.Year][$quarterName][$cwPair][$currentCw]["Start"] = $currentDate;
			$returnArray[$currentDate.Year][$quarterName][$cwPair][$currentCw]["End"] = ($currentDate.AddDays($DaysToAdd-1));
			$returnArray[$currentDate.Year][$quarterName][$cwPair][$currentCw]["Iterationpath"] = [String]$iterationPathName;     
		}

		$currentDate = $currentDate.AddDays($DaysToAdd);
	}
	 while ( $currentDate -le $endDate);
		return $returnArray;
} 

#Simple function to determine the years between the start and end date
function Get-Years
{
 param(
	   $StartDate, $EndDate, $array
	  )
       
	$startYear = [int]$StartDate.Year;
    $endYear = [int]$EndDate.Year;
	
    for ([int]$i = $startYear; $i -le $endYear; $i++)
	{
		if ($array -notcontains $i)
		{     
			##Add the year to the array
            $array[$i] =@{};
            $array[$i]["Start"] = [datetime]([string]::Format("01.01.{0}",$i));
            $array[$i]["End"]  = [datetime]([string]::Format("12.31.{0}",$i));
            $array[$i]["Iterationpath"] =$i;
        }
    }
    return $array;
}

#Determines the quarter of the specified date
function Get-Quarters
{
 param($date)

	$quarter = [Math]::ceiling(($date.Month)/3)
	return $quarter;
}


########################################## THE MAIN CONTENT ##########################################

#Create the objects for the iterations
#Set the start and end in American Format: mm-dd-yyyy
[datetime]$start = "12.31.2015"
[datetime]$end = "03.31.2016"

$projectName = "WordToTFS CMMI";
$tfsCollectionName = "https://goeller.visualstudio.com/DefaultCollection/";

$iterationArray = @{}

#Get the Year
$years = Get-Years $start $end $iterationArray

#Get the quarters
$iterationData = Get-IterationData $start $end

#Get the collection
$tfs =Get-TfsCollection $tfsCollectionName;

if (!$tfs)
{
    Write-Output("Connection to TFS failed with collection"+$tfsCollectionName)
    break;
}

Write-Output($tfs);

Write-Output("Connection to TFS established")

#Get the common structure service, that is responsible for the creation of the iterations
[Microsoft.TeamFoundation.Server.ICommonStructureService4]$css =  Get-TfsCommonStructureService $tfs
if (!$css)
{
    Write-Output("Structure Service cannot be obtained")
    break;
}
Write-Output($css);
Write-Output("Structure Service obtained")

#Get the project
$project = GetProjectInfoFromProjectName $projectName $tfs $css
if (!$project)
{
    Write-Output("Project: "+$projectName+" cannot be found ");
    break;
}
Write-Output("Project"+$project+"found and loaded");
Write-Output("ProjectName: "+[string]$projectName);

# Create the iterations paths for each calendar week
foreach ($it in $iterationData.GetEnumerator()) 
{
	#Add the years
	$resultCreation = CreateIteration $css $projectName $it.Value["Iterationpath"] $it.Value["Start"] $it.Value["End"]; 
	if ($resultCreation)
	{
		Write-Host("Created Iteration: "+ $it.Value["Iterationpath"]);
	}
	#Add the Quarters
	foreach ($quarter in $it.Value.GetEnumerator()) 
	{
		if (($quarter.Name -ne "Start") -and ($quarter.Name -ne "End")-and ($quarter.Name -ne "Iterationpath"))
		{
			$resultCreation = CreateIteration $css $projectName $quarter.Value["Iterationpath"] $quarter.Value["Start"] $quarter.Value["End"];
			if ($resultCreation)
			{
                    Write-Host("Created Iteration: "+ $quarter.Value["Iterationpath"]);
            } 
			#Add the Calendar Week Pairs
			foreach ($cwPair in $quarter.Value.GetEnumerator()) 
			{
				if (($cwPair.Name -ne "Start") -and ($cwPair.Name -ne "End")-and ($cwPair.Name -ne "Iterationpath"))
				{
					$resultCreation = CreateIteration $css $projectName $cwPair.Value["Iterationpath"] $cwPair.Value["Start"] $cwPair.Value["End"]; 
					if ($resultCreation)
					{
						Write-Host("Created Iteration: "+ $cwPair.Value["Iterationpath"]);
					}
					#Add the Calendar Weeks
					foreach ($cw in $cwPair.Value.GetEnumerator()) 
					{
						if (($cw.Name -ne "Start") -and ($cw.Name -ne "End")-and ($cw.Name -ne "Iterationpath"))
						{
							$resultCreation = CreateIteration $css  $projectName $cw.Value["Iterationpath"] $cw.Value["Start"] $cw.Value["End"]; 
							if ($resultCreation)
							{
								Write-Host("Created Iteration: "+ $cw.Value["Iterationpath"]);
							}
						}        
					}
				}
			}
		}
	}
}
