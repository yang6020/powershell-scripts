### Script to generate an sql file for each stored procedure and function

**Details on scripts output**

- SQL files can be copy pasted directly and run.
- Overwrites procedures or creates stored procedures/functions folder if the created folder already exists
  - happens by deleting the folder with the new name recursively and creates a new one
- Changes CREATE PROCEDURE to ALTER PROCEDURE
  - This change is done by finding a string "CREATE PROCEDURE" and changes it to "ALTER PROCEDURE" this is replaced everywhere in the file
  - ^ warning if your procedure has a create procedure elsewhere

Folder structure

```
Existing folder
  └── Folder to create
      └── Stored Procedures
      └── Functions

```

**How to run**

- If you want to get prompted for details (prompt version)

```
.\Stored-Procedures-Functions-Import.ps1
```

- If you want it quick and easy (automated version)

```
.\Stored-Procedures-Functions-Import.ps1 target_folder new_folder server_name db_name
```

**Assumptions and Errors (Validation)**

- Target folder, new folder, server, and db are all required
  - When running the prompt version of the script, entering a null value (just pressing enter) will let the script prompt you again
- Script will exit and write and error if
  - Target folder that doesn't exist
  - Automated version of the script is run with incomplete fields
  - Server or database information is incorrect

**Extra Details** (for how the script gets procedures`)

Param \$type Legend:

- P -> SQL Stored Procedures
- TF -> SQL Table Valued Functions
- FN -> SQL Scalar Functions

More about types [here](https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-all-objects-transact-sql?view=sql-server-2017)
