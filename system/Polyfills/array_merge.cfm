<!---
 * Merges one or more arrays: array_merge(array, array, ...).
 *
 * Arrays with string keys (see array_()) are merged by key, and a
 * later value replaces an earlier one. Lists are appended one after
 * the other. The arguments are not changed.
--->
<cffunction name="array_merge" returntype="any" output="no" hint="Merges one or more arrays">
	<cfset var result = "">
	<cfset var key = "">
	<cfset var i = 0>
	<cfset var j = 0>

	<cfif ArrayLen(arguments) GT 0 AND IsArray(arguments[1])>
		<cfset result = ArrayNew(1)>

		<cfloop from="1" to="#ArrayLen(arguments)#" index="i">
			<cfloop from="1" to="#ArrayLen(arguments[i])#" index="j">
				<cfset ArrayAppend(result, arguments[i][j])>
			</cfloop>
		</cfloop>

		<cfreturn result>
	</cfif>

	<cfset result = CreateObject("java", "java.util.LinkedHashMap").init()>

	<cfloop from="1" to="#ArrayLen(arguments)#" index="i">
		<cfloop collection="#arguments[i]#" item="key">
			<cfset result[key] = arguments[i][key]>
		</cfloop>
	</cfloop>

	<cfreturn result>
</cffunction>
