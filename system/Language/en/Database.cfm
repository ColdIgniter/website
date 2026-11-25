<!---
 * Database language settings
 *
 * A language file is included by the Language component, and has to
 * set the variable "lines" to a map (see array_()); that stands in for
 * the "return [...]" of the original. The keys keep their order.
--->
<cfset lines = array_()>

<cfset lines["invalidEvent"] = """{0}"" is not a valid Model Event callback.">
<cfset lines["invalidArgument"] = "You must provide a valid ""{0}"".">
<cfset lines["invalidAllowedFields"] = "Allowed fields must be specified for model: ""{0}""">
<cfset lines["emptyDataset"] = "There is no data to {0}.">
<cfset lines["emptyPrimaryKey"] = "There is no primary key defined when trying to make {0}.">
<cfset lines["failGetFieldData"] = "Failed to get field data from database.">
<cfset lines["failGetIndexData"] = "Failed to get index data from database.">
<cfset lines["failGetForeignKeyData"] = "Failed to get foreign key data from database.">
<cfset lines["parseStringFail"] = "Parsing key string failed.">
<cfset lines["featureUnavailable"] = "This feature is not available for the database you are using.">
<cfset lines["tableNotFound"] = "Table ""{0}"" was not found in the current database.">
<cfset lines["noPrimaryKey"] = """{0}"" model class does not specify a Primary Key.">
<cfset lines["noDateFormat"] = """{0}"" model class does not have a valid dateFormat.">
<cfset lines["fieldNotExists"] = "Field ""{0}"" not found.">
<cfset lines["forEmptyInputGiven"] = "Empty statement is given for the field ""{0}""">
<cfset lines["forFindColumnHaveMultipleColumns"] = "Only single column allowed in Column name.">
<cfset lines["methodNotAvailable"] = "You cannot use ""{1}"" in ""{0}"". This is a method of the Query Builder Class.">
