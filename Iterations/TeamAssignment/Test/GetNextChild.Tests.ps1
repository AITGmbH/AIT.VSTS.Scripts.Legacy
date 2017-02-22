$here = Split-Path -Parent $MyInvocation.MyCommand.Path
#get parent folder (Test = 4 chars)
$here = $here.Substring(0,$here.Length - 4)
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

#load script
. "$here\$sut"

Describe "GetNextChild"{
	it "No / empty parameter"{
		$list = @()
		GetNextChild -list $list -currentDepth 1 -acceptDepth 1
	}

	it "Wrong parameter"{
		$list = @("test","test")
		$actual = GetNextChild -list $list -currentDepth 1 -acceptDepth 1

		$actual[0] | Should be "test"
		$actual[1] | Should be "test"
		$actual.count | Should be 2
	}

	it "Get week iteration"{
		$list = Get-Content -Path ".\Test\Data\TestTreeWeekIteration.json" | ConvertFrom-Json
		$actual = GetNextChild -list $list.children -currentDepth 1  -acceptDepth 2
		$actualJson = ConvertTo-Json -InputObject $actual[0]

		$expect = @{
		 "id" = 24
		 "identifier" = "55117794-4a95-438f-ad5c-26be82b0aaf6"
		 "name" = "KW1"
		 "structureType" = "iteration"
		 "hasChildren" = "false"
		 "url" = "https://example.com/ddd10814-3263-49a8-94c3-f5d2e0a66097/_apis/wit/classificationNodes/Iterations/2017/q1/KW1"
		}

		$expectJson = ConvertTo-Json -InputObject $expect

		$actual | Should not BeNullOrEmpty

		$actualJson.id | Should be $expectJson.id
		$actualJson.identifier | Should be $expectJson.identifier
		$actualJson.name | Should be $expectJson.name
		$actualJson.structureType | Should be $expectJson.structureType
		$actualJson.hasChildren | Should be $expectJson.hasChildren
		$actualJson.url | Should be $expectJson.url

		$actual.count  | Should be 13
	}

	it "Get year iteration"{
		$list = Get-Content -Path ".\Test\Data\TestTreeYearIteration.json" | ConvertFrom-Json
		$actual = GetNextChild -list $list.children -currentDepth 1 -acceptDepth 1
		$actualJson = ConvertTo-Json -InputObject $actual[0]

		$expect = @{
		 "id" = 4
		 "identifier" = "82c47187-0f3f-4046-a032-dd627492161d"
		 "name" = "2015"
		 "structureType" = "iteration"
		 "hasChildren" = "true"
		 "url" = "https://example.com/ddd10814-3263-49a8-94c3-f5d2e0a66097/_apis/wit/classificationNodes/Iterations/Iteration%202"
		}

		$expectJson = ConvertTo-Json -InputObject $expect

		$actual | Should not BeNullOrEmpty

		$actualJson.id | Should be $expectJson.id
		$actualJson.identifier | Should be $expectJson.identifier
		$actualJson.name | Should be $expectJson.name
		$actualJson.structureType | Should be $expectJson.structureType
		$actualJson.hasChildren | Should be $expectJson.hasChildren
		$actualJson.url | Should be $expectJson.url
		
		$actual.count  | Should be 4
	}

	it "Get root iteration"{
		$list = Get-Content -Path ".\Test\Data\TestTreeRootIteration.json" | ConvertFrom-Json
		$actual = GetNextChild -list $list.children -currentDepth 1 -acceptDepth 1
		$actualJson = ConvertTo-Json -InputObject $actual[2]

		$expect = @{
		 "id" = 603
		 "identifier" = "3ebd8212-c8bf-4d38-9f08-c5710ce69bb3"
		 "name" = "Iteration 3"
		 "structureType" = "iteration"
		 "hasChildren" = "true"
		 "url" = "https://example.visualstudio.com/59827ca2-1e8a-4510-9a23-3923fe0b8540/_apis/wit/classificationNodes/Iterations/Iteration%203"
		}

		$expectJson = ConvertTo-Json -InputObject $expect

		$actual | Should not BeNullOrEmpty

		$actualJson.id | Should be $expectJson.id
		$actualJson.identifier | Should be $expectJson.identifier
		$actualJson.name | Should be $expectJson.name
		$actualJson.structureType | Should be $expectJson.structureType
		$actualJson.hasChildren | Should be $expectJson.hasChildren
		$actualJson.url | Should be $expectJson.url

		$actual | Should not BeNullOrEmpty
		$actual.count  | Should be 3
	}

	it "Get Level four iteration"{
		$list = Get-Content -Path ".\Test\Data\TestTree5LevelIteration.json" | ConvertFrom-Json
		$actual = GetNextChild -list $list.children -currentDepth 1 -acceptDepth 3
		$actualJson = ConvertTo-Json -InputObject $actual[0]

		$expect = @{
		 "id" = 428
		 "identifier" = "055e02a2-fed5-4c66-96ee-482e94054529"
		 "name" = "KW 1"
		 "structureType" = "iteration"
		 "hasChildren" = "false"
		 "attributes" = @{
			"startDate" = "2017-01-02T00:00:00Z"
            "finishDate" = "2017-01-06T00:00:00Z"
         }
		 "url" = "https://example.visualstudio.com/ddd10814-3263-49a8-94c3-f5d2e0a66097/_apis/wit/classificationNodes/Iterations/2017/Q1/January/KW%201"
		}

		$expectJson = ConvertTo-Json -InputObject $expect

		$actual | Should not BeNullOrEmpty

		$actualJson.id | Should be $expectJson.id
		$actualJson.identifier | Should be $expectJson.identifier
		$actualJson.name | Should be $expectJson.name
		$actualJson.structureType | Should be $expectJson.structureType
		$actualJson.hasChildren | Should be $expectJson.hasChildren
		$actualJson.url | Should be $expectJson.url

		$actual | Should not BeNullOrEmpty
		$actual.count  | Should be 17
	}

	
}