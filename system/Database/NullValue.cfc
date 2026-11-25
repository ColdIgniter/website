<!---
 * Stands in for null in a map of values.
 *
 * Difference: a null is an empty string in this port, and an empty string is
 * a string for where(), having(), set() and the data of an insert, so a
 * null that is a value in a map is written as new_("ColdIgniter\Database\NullValue").
 * escape() of the connection writes it as NULL, and where() and having()
 * write IS NULL for it, as the original does for null.
--->
<cfcomponent output="no" hint="Stands in for null in a map of values">

	<cffunction name="__construct" access="public" returntype="any" output="no">

		<cfreturn this>
	</cffunction>

	<cffunction name="__toString" access="public" returntype="string" output="no">

		<cfreturn "NULL">
	</cffunction>
</cfcomponent>
