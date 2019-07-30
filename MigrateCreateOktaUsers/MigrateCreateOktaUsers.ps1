# -------------------------------------------------------------------------------------------------
# About this script
# -------------------------------------------------------------------------------------------------

# Adds Users to Okta and specific groups if provided
# Two ways to use this script
    # 1) Get User from DB and add them to Okta (and groups)
        # Assumptions
            # Database authentication is db_lighthouseauthentication. The example below will get users from phsa_ligthhouseauthentication (db name)
            # We are only hitting aworks300\lighthouse (server)
        # example = .\migrateOktaUsers.ps1 phsa groupId1,groupId2

    # 2) Manually add users by editing the object called $users below. A boiler plate example is provided below
        # example = .\migrateOktaUsers.ps1

# -------------------------------------------------------------------------------------------------
# Params for script usage 1
# -------------------------------------------------------------------------------------------------

Param (
    [string]$db,
    [string[]]$groupIds
)

# -------------------------------------------------------------------------------------------------
# SET ENV
# -------------------------------------------------------------------------------------------------

$script:db
$script:groupIds
$script:baseUri = ""
$script:token = ""
$script:headers = @{"Accept"="application/json"; "Content-Type"="application/json"; "Authorization"="SSWS ${token}"}
$script:server = "aworks300\lighthouse"

# Use and edit this if you want to add users manually
$users = @(
  @{
    'firstName'='Justin';
    'lastName'='Yang';
    'UserName'='justinvyang@gmail.com';
    'displayName'='Justin Yang';
    'groupIds' =  @("oktagroupId1","oktagroupId2")
  }
  @{
    'firstName'='BOB';
    'lastName'='Yang';
    'UserName'='justinvyang+1@gmail.com';
    'displayName'='BOB Yang';
    'groupIds' =  @()
  }
)

# -------------------------------------------------------------------------------------------------
# Helper Functions
# -------------------------------------------------------------------------------------------------

# Parses user data to an object Okta needs
Function setRequestBody{
    Param (
        [Object]$user
    )
    $body = @{}
    $body['profile'] = @{}
    $body.profile['firstName'] = $u.firstName
    $body.profile['lastName'] = $u.lastName
    $body.profile['email'] = $u.UserName
    $body.profile['login'] = $u.UserName
    $body.profile['displayName'] = $u.displayName
    $body['groupIds']= $u.groupIds
    return $body
}

# -------------------------------------------------------------------------------------------------
# Parent Functions
# -------------------------------------------------------------------------------------------------

function getUsersFromDB {
    $sql = "
        SELECT firstName,lastName,UserName
        FROM [dbo].[AspNetUsers]
    "
    try{
        return Invoke-Sqlcmd -ServerInstance $server -Database "${db}_lighthouseauthentication" -Query $sql;
    } catch{
            Write-Error $_.Exception
            Break
    }
}

Function createOktaUsers {
    Param (
        [Object[]]$users
    )
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    foreach ($u in $users) {
        $body = setRequestBody -user $u
        try{
            $response = Invoke-RestMethod -Headers $headers -Method Post -Uri $baseUri -Body (ConvertTo-Json $body -Depth 100);
            "Response: "
            ConvertTo-Json $response.profile -Depth 100
        } catch{
            Write-Error $_.Exception
            Break
        }
    }
    Write-Output $RespErr
}

# -------------------------------------------------------------------------------------------------
# Script
# -------------------------------------------------------------------------------------------------

if($db.length -gt 0){
    $userList = @();
    $DBUsers = getUsersFromDB;

    foreach ($u in $DBUsers) {
    $user =   @{
        'firstName'= $u.firstName;
        'lastName'= $u.lastName;
        'UserName'= $u.UserName;
        'displayName'= $u.UserName;
        'groupIds' =  @($groupIds)
    }
    $userList += $user
    }
    # For now, since we don't want to send random people emails, getting users from the DB will simply log it on the console.
    Write-Output $userList
} else {
    $userList = $users
    # Invite people from the users object above. Right now the default is set to me! Feel free to edit.
    createOktaUsers -users $userList
}


