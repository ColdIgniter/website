<!---
 * Replaces all occurrences of the search string with the replacement
 * string, exactly (case-sensitive).
 *
 * The search is a string or a list (an array). The replacement is a
 * string, or a list that is read in step with the search list (a missing
 * item is an empty string). The subject has to be a string.
--->
<cffunction name="str_replace" returntype="string" output="no" hint="Replaces all occurrences of the search string with the replacement string">
	<cfargument name="search" type="any" required="yes">
	<cfargument name="replace" type="any" required="yes">
	<cfargument name="subject" type="string" required="yes">
	<cfset var result = arguments.subject>
	<cfset var needle = "">
	<cfset var replacement = "">
	<cfset var i = 0>

	<cfif NOT IsArray(arguments.search)>
		<cfif Len(arguments.search) EQ 0>
			<cfreturn result>
		</cfif>

		<cfreturn Replace(result, arguments.search, arguments.replace, "all")>
	</cfif>

	<cfloop from="1" to="#ArrayLen(arguments.search)#" index="i">
		<cfset needle = arguments.search[i]>
		<cfset replacement = "">

		<cfif IsArray(arguments.replace)>
			<cfif i LTE ArrayLen(arguments.replace)>
				<cfset replacement = arguments.replace[i]>
			</cfif>
		<cfelse>
			<cfset replacement = arguments.replace>
		</cfif>

		<cfif Len(needle) GT 0>
			<cfset result = Replace(result, needle, replacement, "all")>
		</cfif>
	</cfloop>

	<cfreturn result>
</cffunction>
