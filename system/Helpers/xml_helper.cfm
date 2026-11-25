<!---
 * ColdIgniter XML Helpers
 *
 * A function here has no guard against a second definition (the original
 * checks function_exists): helper() keeps the first definition of a name.
--->

<!---
 * Convert Reserved XML characters to Entities
 *
 * Difference: the original lists are arrays written as literals; here they
 * are built with ArrayAppend, and a # in a string is written ##.
 *
 * Difference: the patterns are the framework's own and cannot backtrack, so
 * preg_replace() is called unguarded (no limit on the length of the text).
 *
 * @param str
 * @param protectAll
--->
<cffunction name="xml_convert" returntype="string" output="no" hint="Convert Reserved XML characters to Entities">
	<cfargument name="str" type="string" required="yes">
	<cfargument name="protectAll" type="boolean" required="no" default="false">
	<cfset var temp = "__TEMP_AMPERSANDS__">
	<cfset var str_ = arguments.str>
	<cfset var original = ArrayNew(1)>
	<cfset var replacement = ArrayNew(1)>

	<!--- Replace entities to temporary markers so that --->
	<!--- ampersands won't get messed up --->
	<cfset str_ = preg_replace("/&##(\d+);/", temp & "\1;", str_, true)>

	<cfif arguments.protectAll>
		<cfset str_ = preg_replace("/&(\w+);/", temp & "\1;", str_, true)>
	</cfif>

	<cfset ArrayAppend(original, "&")>
	<cfset ArrayAppend(original, "<")>
	<cfset ArrayAppend(original, ">")>
	<cfset ArrayAppend(original, """")>
	<cfset ArrayAppend(original, "'")>
	<cfset ArrayAppend(original, "-")>

	<cfset ArrayAppend(replacement, "&amp;")>
	<cfset ArrayAppend(replacement, "&lt;")>
	<cfset ArrayAppend(replacement, "&gt;")>
	<cfset ArrayAppend(replacement, "&quot;")>
	<cfset ArrayAppend(replacement, "&apos;")>
	<cfset ArrayAppend(replacement, "&##45;")>

	<cfset str_ = str_replace(original, replacement, str_)>

	<!--- Decode the temp markers back to entities --->
	<cfset str_ = preg_replace("/" & temp & "(\d+);/", "&##\1;", str_, true)>

	<cfif arguments.protectAll>
		<cfreturn preg_replace("/" & temp & "(\w+);/", "&\1;", str_, true)>
	</cfif>

	<cfreturn str_>
</cffunction>
