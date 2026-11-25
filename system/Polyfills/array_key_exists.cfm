<!---
 * Checks if the given key exists in an array: a map (see array_()) is
 * searched by its key, exactly (case-sensitive), a list by its position,
 * counted from zero as in the original.
--->
<cffunction name="array_key_exists" returntype="boolean" output="no" hint="Checks if the given key exists in an array">
	<cfargument name="key" type="string" required="yes">
	<cfargument name="array" type="any" required="yes">

	<cfif IsStruct(arguments.array)>
		<cfreturn StructKeyExists(arguments.array, arguments.key)>
	</cfif>

	<cfif IsArray(arguments.array) AND REFind("^(0|[1-9][0-9]*)$", arguments.key) GT 0>
		<cfreturn Val(arguments.key) LT ArrayLen(arguments.array)>
	</cfif>

	<cfreturn false>
</cffunction>
