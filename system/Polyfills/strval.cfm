<!---
 * Gets the string value of a variable, as a cast to string does.
 *
 * An array or a map becomes "Array", as in the original.
--->
<cffunction name="strval" returntype="string" output="no" hint="Gets the string value of a variable">
	<cfargument name="value" type="any" required="yes">

	<cfif IsSimpleValue(arguments.value)>
		<cfreturn arguments.value>
	</cfif>

	<cfreturn "Array">
</cffunction>
