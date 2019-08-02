# Helper functions for Okta User Migration

function getUsersFromDB {
    Param (
        [string]$db,
        [string]$server
    )
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

# Get all Okta groups
# Params
# oktaBaseUri: Okta domain : string
# token: Okta API Key : string
Function getOktaGroups{
    Param (
        [string]$oktaBaseUri,
        [string]$token
    )
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
     $headers = @{"Accept"="application/json"; "Content-Type"="application/json"; "Authorization"="SSWS $token"}
    try{
        $oktaGroups = Invoke-RestMethod -Headers $headers -Method Get -Uri "$oktaBaseUri/groups";
        return $oktaGroups;
    } catch{
        Write-Error $_.Exception
        Break
    }
}

# Get Okta User by UserName. Return false if not found
# oktaBaseUri: Okta domain : string
# token: Okta API Key : string
# UserName: user email : string
Function getOktaUser{
    Param (
        [string]$oktaBaseUri,
        [string]$token,
        [string]$UserName
    )
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $headers = @{"Accept"="application/json"; "Content-Type"="application/json"; "Authorization"="SSWS ${token}"}
    try{
        $oktaUser = Invoke-RestMethod -Headers $headers -Method Get -Uri "$oktaBaseUri/users/$UserName"
        return $oktaUser;
    } catch{
        return 0;
    }
}

# Get Okta group mapping (Name = ID)
# Params
# oktaGroups: Array of okta groups
# groupNames:  Array ex. => @("oktaGroupName1","oktaGroupName2");
Function getOktaGroupIdsByNames{
    Param (
        [Object[]]$oktaGroups,
        [string[]]$groupNames
    )
    $groupIds = @();
    foreach($groupName in $groupNames){
        $groupId = foreach($group in $oktaGroups){
            if($groupName -eq $group.profile.name){
              $group.id
            }
        }
        $groupIds += $groupId
    }
    return $groupIds;
}

# Create an Okta User or adds them to a group if they already exist
Function addUsertoOktaGroups {
    Param (
        [string]$oktaBaseUri,
        [string]$token,
        [string]$userId,
        [string[]]$groupNames
    )
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $groupIds = @(getOktaGroupIdsByNames $oktaGroups $user.groupNames);
    $headers = @{"Accept"="application/json"; "Content-Type"="application/json"; "Authorization"="SSWS $token"}
    foreach ($groupId in $groupIds) {
        try {
            $response = Invoke-RestMethod -Headers $headers -Method Put -Uri "$oktaBaseUri/groups/$groupId/users/$userId"
        } catch{
            Write-Error $_.Exception
            Break
        }
    }
    return "Added to Groups $groupNames"
}

# Create Okta Users with the same group or adds them to the group if they already exist
Function createOktaUsers {
    Param (
        [string]$oktaBaseUri,
        [string]$token,
        [Object[]]$oktaGroups,
        [Object[]]$users,
        [string[]]$groupNames
    )
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $headers = @{"Accept"="application/json"; "Content-Type"="application/json"; "Authorization"="SSWS $token"}
    foreach ($u in $users) {
        $oktaUser = getOktaUser $oktaBaseUri $token $u.UserName;
        if(!$oktaUser){
            $body = @{}
            $body['profile'] = @{}
            $body.profile['firstName'] = $u.firstName
            $body.profile['lastName'] = $u.lastName
            $body.profile['email'] = $u.UserName
            $body.profile['login'] = $u.UserName
            $body.profile['displayName'] = $u.displayName
            $body['groupIds']= @(getOktaGroupIdsByNames $oktaGroups $groupNames)
                try {
                    $headers = @{"Accept"="application/json"; "Content-Type"="application/json"; "Authorization"="SSWS $token"}
                    $response = Invoke-RestMethod -Headers $headers -Method Post -Uri "$oktaBaseUri/users?activate=true" -Body (ConvertTo-Json $body -Depth 100)
                    "Response: "
                    ConvertTo-Json $response.profile -Depth 100
                } catch{
                    Write-Error $_.Exception
                    Break
                }
        } else {
            addUsertoOktaGroups $oktaBaseUri $token $oktaUser.id $groupNames
        }
    }
}

# Create an Okta User or adds the user to a group if they already exist
Function createOktaUser {
    Param (
        [string]$oktaBaseUri,
        [string]$token,
        [Object[]]$oktaGroups,
        [Object] $user
    )
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $oktaUser = getOktaUser $oktaBaseUri $token $user.UserName;
    if(!$oktaUser){
        $body = @{}
        $body['profile'] = @{}
        $body.profile['firstName'] = $user.firstName
        $body.profile['lastName'] = $user.lastName
        $body.profile['email'] = $user.UserName
        $body.profile['login'] = $user.UserName
        $body.profile['displayName'] = $user.displayName
        $body['groupIds']= @(getOktaGroupIdsByNames $oktaGroups $user.groupNames)
            try {
                $headers = @{"Accept"="application/json"; "Content-Type"="application/json"; "Authorization"="SSWS $token"}
                $response = Invoke-RestMethod -Headers $headers -Method Post -Uri "$oktaBaseUri/users?activate=true" -Body (ConvertTo-Json $body -Depth 100)
                "Response: "
                ConvertTo-Json $response.profile -Depth 100
            } catch{
                Write-Error $_.Exception
                Break
            }
    } else {
        addUsertoOktaGroups $oktaBaseUri $token $oktaUser.id $user.groupNames
    }
}

Export-ModuleMember -Function *















