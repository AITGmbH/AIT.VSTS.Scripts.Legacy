# Relate-VstsIteration
> This PowerShell script relates multiple iterations with teams in VSTS.

The script relates every exact level of iteration tree to a team. Each child of project iteration is a discrete iteration tree. This means that a project has any number of iteration.

# Table of Content

* [Install](#install)
    * [Run Script](#run-script)
    * [Run Unit Test](#run-unit-test)
* [Usage](#usage)
    * [Example 1: Relate all Weeks of 2017 to Team1](#example-1-relate-all-weeks-of-2017-to-team1)
    * [Example 2: Relate the root iteration to all teams](#example-2-relate-the-root-iteration-to-all-teams)
    * [Example 3: Relate level 5 to a team](#example-3-relate-level-5-to-a-team)
    * [Example 4: Relate Q1, Q2, Q3 and Q4 2017 to the team "Marketing"](#example-4-relate-q1-q2-q3-and-q4-2017-to-the-team-marketing)
* [API](#api)
    * [Syntax](#syntax)
    * [Parameter](#parameter)
        * [Username (required)](#username-required)
        * [Token (required)](#token-required)
        * [Projecturi (required)](#projecturi-required)
        * [TeamList (optional)](#teamlist-optional)
        * [StartOfIterationPath (optional)](#startofiterationpath-optional)

# Install
##  Run Script
1.  Download the script

2.  Open PowerShell

3.  Change directory to the location of the script

4.  Load the script

    ```powershell
      . .\Relate-VstsIteration.ps1 
    ```

5.  Run the script

    ```powershell
    Relate-VstsIteration -Username “user@example.com” -Projecturi “https://example.visualstudio.com/MyFirstProject” -Token “h2ixjlahgmrfb722yo23kzohh9f1evc2wf1bwhnwme9fn59dky3v”
    ```

##  Run Unit Test
1.  Install [Pester](https://github.com/pester/Pester)

2.  Download the script

3.  Open PowerShell

4.  Change directory to the location of the script

5.  Run the tests

    ```powershell
    Invoke-Pester -Script .\Test
    ```

# Usage
The script is suitable for Visual Studio Team Services, not for the local Team Foundation Server. The Login needs a Personal Access Token and corresponding Uri-Adresse ([How To: CreatePersonal AccessToken](https://www.visualstudio.com/en-us/docs/setup-admin/team-services/use-personal-access-tokens-to-authenticate)).

## Example 1: Relate all Weeks of 2017 to Team1

> This example demonstrates, how all weeks of a year are being related to the team "Team1". The year, month and weeks are iteration on the project "MyFirstProject". The difference between these iterations is the level.

Iterations for your project: 

![Figure 1: Result](_media/root_iteration.jpg)

Situation of iterations at the team "Team1"

![Figure 2: Empty iteration tree](_media/empty_iteration.jpg)

Calling script:

Both calls have the same result. It is only important to gives a level 4 iteration in the parameter "StartOfIterationPath". It is not important, which iteration item you specify on the parameter.  

```PowerShell
Relate-VstsIteration -Username "[Login name]" -Projecturi "https://[Subscription].visualstudio.com/[Project name]" -token "[Key]" -StartOfIterationPath "2017/Q2/April/KW 17"
```

```PowerShell
Relate-VstsIteration -Username "[Login name]" -Projecturi "https://[Subscription].visualstudio.com/[Project name]" -token "[Key]" -StartOfIterationPath "2017/Q1/January/KW 1"
```

When the scripts is finished, all of the weeks are mapped:

![Figure 3: Relate iteration tree](_media/relates_iteration.jpg)

## Example 2: Relate the root iteration to all teams

> This example demonstrates, how the iterations of the first level (root iterations) are being related to the team "Team1".   

General iteration tree of the project „GeneralProject"

![Figure 4: General iteration](_media/general_iteration_tree_root.jpg)

Calling script:

```PowerShell
Relate-VstsIteration -Username "[Login name]" -Projecturi "https://[Subscription].visualstudio.com/GeneralProject" -token "[Key]"
```

Result in all teams of the project:

![Figure 5: General Example Result](_media/general_example_2_result.jpg)

## Example 3: Relate level 5 to a team

> This example demonstrates, how the iterations in the fifth level are being related to the team "GeneralProject".

General iteration tree of the project „GeneralProject"

![Figure 6: General iteration](_media/general_iteration_tree_level5.jpg)

Calling script:

```PowerShell
Relate-VStsIteration -Username "[Login name]" -Projecturi "https://[Subdiscription].visualstudio.com/[Project name]" -Token "[Key]" -TeamList "Team1" -StartOfIterationPath "Iteration Level 1/Iteration Level 1.1/Iteration Level 1.1.3/Iteration Level 1.1.3.1/Iteration Level 1.1.3.1.5"
```

Result in "Team1" of the project:

![Figure 7: General Example 2 Result](_media/general_example_3_result.jpg)

## Example 4: Relate Q1, Q2, Q3 and Q4 2017 to the team "Marketing"

> This example demonstrates, how each quarter of the year 2017 is being related to the team "Marketing".

Iteration tree of the project „MyFirstProject"

![Figure 8: General iteration](_media/substantiated_iteration_tree.jpg)

Calling script:

```PowerShell
Relate-VStsIteration -Username "[Login]" -Token "[Key]" -Projecturi "https://[Subdiscription].visualstudio.com/[Project] -TeamList "Marketing" -StartOfIterationPath "2017/Q1"
```

Result:

![Figure 9: General Example 3 Result](_media/general_example_4_result.jpg)

# API
## Syntax

```PowerShell
Relate-VstsIteration [-Username] <String> [-Projecturi] <Uri> [-Token] <String> [[-TeamList] <String[]> [-StartOfIterationPath]<String>]
```

## Parameter 

### Username (required)
**Type:** String  
**Description:** Login name of the Visual Studio Team Services account.  
**Example:**
```PowerShell
"test.email@example.com"  
```

### Token (required)
**Type**: String  
**Description:** Personal Access Token, which is association with the username.  
**Example**: 
```PowerShell
"h2ixjlahgmrfb722yo23kzohh9f1evc2wf1bwhnwme9fn59dky3v"  
```

### Projecturi (required)
**Type:** Uri  
**Description:** The URI of the Team Project.  
**Example**: 
```PowerShell
"https://example.visualstudio.com/MyFirstProject"
```
```PowerShell
"https://sec.visualstudio.com/AppSec"
```

### TeamList (optional)
**Type:** String[]  
**Description:** List of Team names. If no value is provided, the script identifies all team names automatic.  
**Example:** 
```PowerShell
"Team1", "Team2", "Team3"
```
```PowerShell
"Marketing"
```
```PowerShell
"Marketing", "Development", "Production", "Testmanagment"
```

### StartOfIterationPath (optional)
**Type:** String  
**Description:** The level at the iteration tree which is assigned to the teams. If no value is provided, the script relates all root iteration to the teams. Warning: The project name must not be indicated to the path.  
**Example:** 
```PowerShell
"2017/Q1/January/KW 1"
```
```PowerShell
"Iteration Level 1/Iteration Level 1.2"
```
```PowerShell
"extra-large-text-without-spaces"
```
```PowerShell
"2017/Q1/January/KW 1 - KW 2/KW 1"
```
```PowerShell
"2017/Q4/November"
```
