<!---
 * Returns part of a string.
 *
 * The offset starts at 0. Without a length, the rest of the string is
 * returned. A negative offset counts from the end of the string. A
 * negative length is not supported.
--->
<cffunction name="substr" returntype="string" output="no" hint="Returns part of a string">
	<cfargument name="string" type="string" required="yes">
	<cfargument name="offset" type="numeric" required="yes">
	<cfargument name="length" type="numeric" required="no" default="-1">
	<cfset var start = arguments.offset>
	<cfset var rest = 0>

	<cfif start LT 0>
		<cfset start = Len(arguments.string) + start>
		<cfif start LT 0>
			<cfset start = 0>
		</cfif>
	</cfif>

	<cfset rest = Len(arguments.string) - start>

	<cfif rest LTE 0>
		<cfreturn "">
	</cfif>

	<cfif arguments.length GTE 0 AND arguments.length LT rest>
		<cfset rest = arguments.length>
	</cfif>

	<cfif rest EQ 0>
		<cfreturn "">
	</cfif>

	<cfreturn Mid(arguments.string, start + 1, rest)>
</cffunction>
