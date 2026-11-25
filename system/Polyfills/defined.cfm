<!---
 * Checks whether a constant with the given name exists.
--->
<cffunction name="defined" returntype="boolean" output="no" hint="Checks whether a constant with the given name exists">
	<cfargument name="constant_name" type="string" required="yes">

	<cfreturn StructKeyExists(request, arguments.constant_name)>
</cffunction>
