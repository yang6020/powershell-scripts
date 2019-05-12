# Script to generate an sql file for each stored procedure and function

# Folder structure
# Existing folder 
#   └── Folder to create
#       └── Stored Procedures
#       └── Functions

# Param $type Legend:
# - P  -> SQL Stored Procedures
# - TF -> SQL Table Valued Functions
# - FN -> SQL Scalar Functions
# More about types https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-all-objects-transact-sql?view=sql-server-2017

# -------------------------------------------------------------------------------------------------
# CLI params + Script variables
# -------------------------------------------------------------------------------------------------

Param (
    [string]$targetFolder,
    [string]$createdFolder,
    [string]$server,
    [string]$db
)
$script:path
$script:server
$script:db

# -------------------------------------------------------------------------------------------------
# Child helper functions
# -------------------------------------------------------------------------------------------------

# Function to prompt user depending on which data we want
Function promptUser{
        Param(
        [string]$data
    )
    $question = switch ([string]$data){
        'server' {
            "Input SERVER you are getting the procedures from:"
        }
        'db' {
            "Input DATABASE you are getting the procedures from:"
        }
        'targetFolder'{
            "Input which folder you want to import stored procedures and functions: "
        }
        'createdFolder'{
            "Name the folder you are creating: "
        }
    }
    $answer = Read-Host $question
    while(!$answer){
        $answer = Read-Host $question
    }
    return $answer
}

# Function to get server, db, or path
# Path works differntly. First, we get the target folder, then the name of the folder to be created. Finally, we put them together for the path.
# These are required so while loops are in place
Function getData {
    Param(
        [string]$data,
        [string]$createdFolder,
        [string]$targetFolder
    )
    if(!$targetFolder -and !$createdFolder){
        if($data -eq 'path'){
            $targetFolder = promptUser -data 'targetFolder'
            if (!(Test-Path ".\$targetFolder")) {
                Write-Error "Suitcase or folder does not exist"
            Break
            }
            $createdFolder = promptUser -data 'createdFolder'
            $path = ".\$targetFolder\$createdFolder"
            return $path
        }
        return promptUser -data $data
    }
    $path = ".\$targetFolder\$createdFolder"
    return $path
}

# Function to get procedure names based on the 'type'
Function getProcedureNames {
    Param (
        [string]$type
    )
    $sql = "
        GO
        SELECT
            name
        FROM
            sys.all_objects
        WHERE
            ([type] = '$type' )
            AND [is_ms_shipped] = 0
        ORDER BY
            name
        GO
    "
    try{
        Invoke-Sqlcmd -ServerInstance $server -Database $db -Query $sql
    } catch{
        Write-Error $_.Exception
        Break
    }
}

# Function to create empty sql file, extract data from procedure using name, push data to empty sql file in the respective folder
Function loopProcedures {
    Param (
        $ProcedureNames,
        [string]$savePath
    )

    foreach ($name in $ProcedureNames) {
        New-Item -Name "$name.sql" -ItemType "file" -Path $savePath
        $sql = "
            EXEC sp_helptext '$name'
        "
        $query = Invoke-Sqlcmd -ServerInstance $server -Database $db -Query $sql -verbose
        try{
            # Remove blank lines and replace CREATE PROCEDURE with ALTER PROCEDURE
            $procedureData = $query.text -match '\S'|  % {$_.replace("CREATE PROCEDURE","ALTER PROCEDURE")} | Out-File -filePath "$savePath/$name.sql" -NoNewLine
        } catch{
            throw "Error inserting procedure in $savePath/$name.sql error is ($_.Exception)"
        }
    }
}

# Main function calling the other helper functions - this gets the names, loops over them, and saves to sql files based on the inputted typwe
Function saveProcedures {
    Param (
        [string]$type
    )
    $savePath = switch ([string]$type) {
        'P' {
            "$path\StoredProcedures\"
        }
        'TF' {
            "$path\Functions\Table-valued-functions\"
        }
        'FN' {
            "$path\Functions\Scalar-valued-functions\"
        }
    }
    try{
    New-Item -ItemType directory -Path $savePath -ea stop
    } catch {
        Remove-Item -Path $savePath -recurse
        New-Item -ItemType directory -Path $savePath -ea stop
    }
    $procedureQuery = getProcedureNames -type $type
    $procedureNames = $procedureQuery.name
    loopProcedures -ProcedureNames $procedureNames -savePath $savePath
}

# -------------------------------------------------------------------------------------------------
# Parent Functions
# -------------------------------------------------------------------------------------------------

# Set params and all data required. If no variable was passed (manual), getData prompts to ask for data. Else, sets the variables as the params
Function setData{
    Param (
        $targetFolder,
        $createdFolder,
        $server,
        $db
    )
     if(!$targetFolder){
        $script:path = getData -data "path"
        $script:server = getData -data "server"
        $script:db  = getData -data "db"
     } else {
        $script:path = getData -data "path" -targetFolder $targetFolder -createdFolder $createdFolder
        $script:server = $server
        $script:db  = $db
     }
}

# Call saveProcedures for Stored Procedures, Table-Valued-Functions, and Scalar-Valued-Functions + log data
Function saveAll {
    saveProcedures -type 'P'
    saveProcedures -type 'TF'
    saveProcedures -type 'FN'
}

# -------------------------------------------------------------------------------------------------
# Script
# -------------------------------------------------------------------------------------------------

# if no variables are inputted, assume a manual script
if(!$targetFolder){
    setData
    $start = GET-DATE
    saveAll
    $timetaken = $(GET-DATE) - $start
    ""
    Write-Output "It took $($timetaken.TotalSeconds) seconds to run this script. Have a good one!"
    Break
}
# makes sure if variables are inputted, they're complete
if(!$db) {
    throw "Missing required fields please input variables in this order: targetFolderersion, codeVersion, server, db"
} else {
    setData -targetFolder $targetFolder -createdFolder $createdFolder -server $server -db $db
    $start = GET-DATE
    saveAll
    $timetaken = $(GET-DATE) - $start
    ""
    Write-Output "It took $($timetaken.TotalSeconds) seconds to run this script. Have a good one!"
}