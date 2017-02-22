$here = Split-Path -Parent $MyInvocation.MyCommand.Path
#get parent folder (Test = 4 chars)
$here = $here.Substring(0,$here.Length - 4)
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

#load script
. "$here\$sut"

Describe "Function GetNodeDepth" {
	Context "Exists Testdata"{
		It "Exists TestDepthFive.txt" {
			$actual= Test-Path ".\Test\Data\TestDepthOne.txt"
			$actual | Should be $true
		}

		It "Exists TestDepthFour.txt" {
			$actual= Test-Path ".\Test\Data\TestDepthOne.txt"
			$actual | Should be $true
		}

		It "Exists TestDepthThree.txt" {
			$actual= Test-Path ".\Test\Data\TestDepthThree.txt"
			$actual | Should be $true
		}

		It "Exists TestDepthTwo.txt" {
			$actual= Test-Path ".\Test\Data\TestDepthTwo.txt"
			$actual | Should be $true
		}

		It "Exists TestDepthOne.txt" {
			$actual= Test-Path ".\Test\Data\TestDepthOne.txt"
			$actual | Should be $true
		}
	}

	Context "GetNodeDepth"{
		It "Depth one"{
			ForEach( $File in Get-Content -Path ".\Test\Data\TestDepthOne.txt" ) { 
				getNodeDepth $File | Should be 1
			}
		}

		It "Depth two"{
			ForEach( $File in Get-Content -Path ".\Test\Data\TestDepthTwo.txt" ) { 
				getNodeDepth $File | Should be 1
			}
		}

		It "Depth three"{
			ForEach( $File in Get-Content -Path ".\Test\Data\TestDepthThree.txt" ) { 
				getNodeDepth $File | Should be 2
			}
		}

		It "Depth four"{
			ForEach( $File in Get-Content -Path ".\Test\Data\TestDepthFour.txt" ) { 
				getNodeDepth $File | Should be 3
			}
		}

		It "Depth five"{
			ForEach( $File in Get-Content -Path ".\Test\Data\TestDepthFive.txt" ) { 
				getNodeDepth $File | Should be 4
			}
		}
	}
}