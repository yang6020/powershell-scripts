# -------------------------------------------------------------------------------------------------
# ABOUT
# -------------------------------------------------------------------------------------------------

# Adds Users to Okta and specific groups if provided
# Two ways to use this script
    # 1) Get User from LOCAL DB and add them to Okta (and groups)
        # Assumptions
            # Database authentication is db_lighthouseauthentication. The example below will get users from phsa_ligthhouseauthentication (db name)
            # We are only hitting aworks300\lighthouse (server) aka no credentials to query users
        # Note: This way adds them all to the same groups
        # example = .\oktaMigrationScript.ps1 phsa groupName1,groupName2

    # 2) Manually add users by editing the object called $users below. A boiler plate example is provided below
        # example = .\oktaMigrationScript.ps1

# Params for script usage 1
Param (
    [string]$db,
    [string[]]$groupNames
)

$oktaBaseUri = "";
$token = "";
$server = "aworks300\lighthouse"

# Params for script usage 2
$users = @(
  @{
    'firstName'='Justin';
    'lastName'='Yang';
    'UserName'='justinvyang@gmail.com';
    'displayName'='Justin Yang';
    'groupNames' =  @("APP_LH2","APP_LH1");
  }
#   @{
#     'firstName'='Okta';
#     'lastName'='okta';
#     'UserName'='okta@analysisworks.com';
#     'displayName'='Test Okta';
#     'groupNames' =  @("APP_LH1");
#   }
)

Import-Module -Name C:\Users\jyang\desktop\oktaMigration\oktaUserMigration.psm1 -Force

# -------------------------------------------------------------------------------------------------
# Script
# -------------------------------------------------------------------------------------------------

# Get Okta Groups
$oktaGroups = getOktaGroups $oktaBaseUri $token;

# IF DB MIGRATION
if($db.length -gt 0){
    $script:users = getUsersFromDB $db $server;
    # createOktaUsers $oktaBaseUri $token $oktaGroups $users $groupNames
    Write-Output $users
} else {
    foreach($u in $users){
        createOktaUser $oktaBaseUri $token $oktaGroups $u;
    }
    #   createOktaUsers $oktaBaseUri $token $oktaGroups $users $groupNames
 }



