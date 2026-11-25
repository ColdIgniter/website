<!---
 * Strips tags from a string.
 *
 * Every "<" up to the next ">" is removed. The finer rules of the
 * original (allowed tags, comments, a lone "<") are not ported.
 *
 * Difference: the string is scanned by hand with Find(), because the
 * pattern <[^>]*> is quadratic on a long run of "<" with no ">".
--->
<cffunction name="strip_tags" returntype="string" output="no" hint="Strips tags from a string">
	<cfargument name="string" type="string" required="yes">
	<cfset var buffer = CreateObject("java", "java.lang.StringBuffer").init()>
	<cfset var position = 1>
	<cfset var open = 0>
	<cfset var close = 0>

	<cfloop condition="position LTE Len(arguments.string)">
		<cfset open = Find("<", arguments.string, position)>
		<cfif open EQ 0>
			<cfbreak>
		</cfif>

		<!--- no ">" after this one means no tag can follow --->
		<cfif open EQ Len(arguments.string)>
			<cfbreak>
		</cfif>

		<cfset close = Find(">", arguments.string, open + 1)>
		<cfif close EQ 0>
			<cfbreak>
		</cfif>

		<cfset buffer.append(JavaCast("string", Mid(arguments.string, position, open - position)))>
		<cfset position = close + 1>
	</cfloop>

	<cfset buffer.append(JavaCast("string", Mid(arguments.string, position, Len(arguments.string) - position + 1)))>

	<cfreturn buffer.toString()>
</cffunction>
