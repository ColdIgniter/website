<!---
 * Checks if the class method exists.
 *
 * Difference: only public methods are seen from outside an object.
--->
<cffunction name="method_exists" returntype="boolean" output="no" hint="Checks if the class method exists">
	<cfargument name="object" type="any" required="yes">
	<cfargument name="method" type="string" required="yes">

	<cfreturn StructKeyExists(arguments.object, arguments.method) AND IsCustomFunction(arguments.object[arguments.method])>
</cffunction>
