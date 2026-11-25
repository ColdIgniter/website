<!---
 * Makes the first character of each word in a string upper case.
 *
 * Only a space, a tab, a carriage return, a line feed, a form feed and a
 * vertical tab start a word, as in the original.
--->
<cffunction name="ucwords" returntype="string" output="no" hint="Makes the first character of each word upper case">
	<cfargument name="string" type="string" required="yes">
	<cfset var result = "">
	<cfset var ch = "">
	<cfset var atStart = true>
	<cfset var i = 0>

	<cfloop from="1" to="#Len(arguments.string)#" index="i">
		<cfset ch = Mid(arguments.string, i, 1)>

		<cfif atStart>
			<cfset result = result & UCase(ch)>
		<cfelse>
			<cfset result = result & ch>
		</cfif>

		<cfset atStart = ListFind("32,9,13,10,12,11", Asc(ch)) GT 0>
	</cfloop>

	<cfreturn result>
</cffunction>
