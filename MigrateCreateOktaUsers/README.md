# Creating a User in Okta (and sending an email)

## HTTP

POST: https://dev-732994.okta.com/api/v1/users?activate=true

Headers:
| Key | Value |
| ------------- |:-------------:|
| Authorization | SSWS {API-KEY} |
| Content-Type | application/json |

Body:

```
{
   "profile":{
	"login":"justinvyang@gmail.com",
	"email":"justinvyang@gmail.com",
	"displayName":"JUSTIN",
	"firstName":"Justin",
	"lastName":"Yang"
   },
   groupIds:["groupId1,groupId2"]
}
```

---

## LH1.0 User db schema

- id
- UserName (email)
- FirstName
- LastName
- etc

# About the Script
Adds Users to Okta and specific groups if provided. If user already exists, add them to the group instead.

- Main script - oktaMigrationScript

- Okta functions - oktauserMigration

Two ways to use this script:

1. Get User from LOCAL DB and add them to Okta (and groups)

   - Assumptions:

     - Database authentication is db_lighthouseauthentication. The example below will get users from phsa_ligthhouseauthentication (db name)
     - We are only hitting aworks300\lighthouse (server) aka no credentials to query users

   - Example `.\oktaMigrationScript.ps1 phsa groupName1,groupName2` - Note: This way adds them all to the same groups

2. Manually add users by editing the object called \$users below. A boiler plate example is provided below
   - Example `.\oktaMigrationScript.ps1`
