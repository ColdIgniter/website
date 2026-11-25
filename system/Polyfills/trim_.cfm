<!---
 * Strips characters from the start and the end of a string.
 *
 * Named with an underscore, because a CFML function has the name of the original.
 *
 * Not ported yet: the NUL character in the default list of characters,
 * because Chr(0) is an empty string on the server.
--->
<cffunction name="trim_" returntype="string" output="no" hint="Strips characters from the start and the end of a string">
	<cfargument name="string" type="string" required="yes">
	<cfargument name="characters" type="string" required="no" default="#Chr(32) & Chr(9) & Chr(10) & Chr(13) & Chr(11)#">

	<cfreturn rtrim_(ltrim_(arguments.string, arguments.characters), arguments.characters)>
</cffunction>
