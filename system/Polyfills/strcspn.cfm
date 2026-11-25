<!---
 * Finds the length of the initial segment of a string that has none of
 * the characters of a mask: strcspn(string, characters, offset).
 *
 * The offset starts at 0 and the segment is searched from there. The
 * search is one pass over the string with a pattern that is one
 * character class (every character of the mask written as \xHH), so
 * it cannot backtrack. Only characters up to code 255 can be in the mask.
--->
<cffunction name="strcspn" returntype="numeric" output="no" hint="Finds the length of the initial segment that has none of the mask characters">
	<cfargument name="string" type="string" required="yes">
	<cfargument name="characters" type="string" required="yes">
	<cfargument name="offset" type="numeric" required="no" default="0">
	<cfset var class = "">
	<cfset var matcher = "">
	<cfset var i = 0>

	<cfif arguments.offset GTE Len(arguments.string)>
		<cfreturn 0>
	</cfif>

	<cfif Len(arguments.characters) EQ 0>
		<cfreturn Len(arguments.string) - arguments.offset>
	</cfif>

	<cfloop from="1" to="#Len(arguments.characters)#" index="i">
		<cfset class = class & "\x" & Right("0" & FormatBaseN(Asc(Mid(arguments.characters, i, 1)), 16), 2)>
	</cfloop>

	<cfset matcher = CreateObject("java", "java.util.regex.Pattern").compile("[" & class & "]").matcher(arguments.string)>

	<cfif matcher.find(JavaCast("int", arguments.offset))>
		<cfreturn matcher.start() - arguments.offset>
	</cfif>

	<cfreturn Len(arguments.string) - arguments.offset>
</cffunction>
