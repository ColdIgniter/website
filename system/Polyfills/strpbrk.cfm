<!---
 * Searches a string for any of a set of characters. Returns the part of
 * the string from the first match to the end, or an empty string when
 * there is none. Difference: false is an empty string.
--->
<cffunction name="strpbrk" returntype="string" output="no" hint="Searches a string for any of a set of characters">
	<cfargument name="string" type="string" required="yes">
	<cfargument name="characters" type="string" required="yes">
	<cfset var i = 0>

	<cfloop from="1" to="#Len(arguments.string)#" index="i">
		<cfif Find(Mid(arguments.string, i, 1), arguments.characters) GT 0>
			<cfreturn Mid(arguments.string, i, Len(arguments.string) - i + 1)>
		</cfif>
	</cfloop>

	<cfreturn "">
</cffunction>
