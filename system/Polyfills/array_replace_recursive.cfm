<!---
 * Replaces the values of the first array with the ones of the second,
 * going into nested arrays: array_replace_recursive(array, replacement).
 *
 * A map (see array_()) is replaced by key, a list by position. The
 * arguments are not changed; a nested value that is not touched is
 * shared with the argument it came from.
--->
<cffunction name="array_replace_recursive" returntype="any" output="no" hint="Replaces the values of the first array with the ones of the second, recursively">
	<cfargument name="array" type="any" required="yes">
	<cfargument name="replacement" type="any" required="yes">
	<cfset var result = "">
	<cfset var key = "">
	<cfset var i = 0>

	<cfif IsArray(arguments.array)>
		<cfset result = ArrayNew(1)>

		<cfloop from="1" to="#ArrayLen(arguments.array)#" index="i">
			<cfset ArrayAppend(result, arguments.array[i])>
		</cfloop>

		<cfloop from="1" to="#ArrayLen(arguments.replacement)#" index="i">
			<cfif i LTE ArrayLen(result) AND is_array(result[i]) AND is_array(arguments.replacement[i]) AND IsArray(result[i]) EQ IsArray(arguments.replacement[i])>
				<cfset result[i] = array_replace_recursive(result[i], arguments.replacement[i])>
			<cfelseif i LTE ArrayLen(result)>
				<cfset result[i] = arguments.replacement[i]>
			<cfelse>
				<cfset ArrayAppend(result, arguments.replacement[i])>
			</cfif>
		</cfloop>

		<cfreturn result>
	</cfif>

	<cfset result = CreateObject("java", "java.util.LinkedHashMap").init()>

	<cfloop collection="#arguments.array#" item="key">
		<cfset result[key] = arguments.array[key]>
	</cfloop>

	<cfloop collection="#arguments.replacement#" item="key">
		<cfif StructKeyExists(result, key) AND is_array(result[key]) AND is_array(arguments.replacement[key]) AND IsArray(result[key]) EQ IsArray(arguments.replacement[key])>
			<cfset result[key] = array_replace_recursive(result[key], arguments.replacement[key])>
		<cfelse>
			<cfset result[key] = arguments.replacement[key]>
		</cfif>
	</cfloop>

	<cfreturn result>
</cffunction>
