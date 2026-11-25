<!---
 * Finds whether a variable is an array.
 *
 * An array of the original is a list or a map, so both a CFML array and a struct
 * (also an array_() map) count.
--->
<cffunction name="is_array" returntype="boolean" output="no" hint="Finds whether a variable is an array (a list or a map)">
	<cfargument name="value" type="any" required="yes">

	<cfreturn IsArray(arguments.value) OR IsStruct(arguments.value)>
</cffunction>
