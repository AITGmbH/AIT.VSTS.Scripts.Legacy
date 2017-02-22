$here = Split-Path -Parent $MyInvocation.MyCommand.Path
#get parent folder (Test = 4 chars)
$here = $here.Substring(0,$here.Length - 4)
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

#load script
. "$here\$sut"

Describe "Function GetStartRootNode" {
	It "Path is empty" {
	    $path = ""
		$actual= GetStartRootNode $path
		$actual | Should be ""
	}

	It "Path have only spaces" {
		$path = "      "
		$actual= GetStartRootNode $path
		$actual | Should be ""
	}

	It "Root is a number" {
		$path = "2017/Q1/January/KW 1 - KW 2/KW 1"
		$actual= GetStartRootNode $path
		$actual | Should be ([int]"2017")
	}

	It "Root has spaces" {
		$path = "Iteration Level 1/Iteration Level 1.2/Iteration Level 1.2.3/Iteration Level 1.2.3.4/"
		$actual= GetStartRootNode $path
		$actual | Should be "Iteration Level 1"
	}

	It "Root has not spaces" {
		$path = "extra-large-text-without-spaces/next-level-extra-large-text/next-level/no-end/ultimately-end"
		$actual= GetStartRootNode $path
		$actual | Should be "extra-large-text-without-spaces"
	}
}