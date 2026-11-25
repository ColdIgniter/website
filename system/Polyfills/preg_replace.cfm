<!---
 * Performs a regular expression search and replace. The pattern and the
 * replacement are strings, or lists that are read in step (a missing
 * replacement is an empty string). The replacement refers to a group as
 * \1, $1 or ${1}. See preg_pattern() for the form of a pattern.
 *
 * Difference: the number of replacements is not returned.
 *
 * Difference: a subject longer than the limit is refused (see
 * regex_guard_()), unless unguarded is true. Only the framework passes
 * unguarded, for a pattern of its own that cannot backtrack.
--->
<cffunction name="preg_replace" returntype="string" output="no" hint="Performs a regular expression search and replace">
	<cfargument name="pattern" type="any" required="yes">
	<cfargument name="replacement" type="any" required="yes">
	<cfargument name="subject" type="string" required="yes">
	<cfargument name="unguarded" type="boolean" required="no" default="false">
	<cfset var result = arguments.subject>
	<cfset var patterns = ArrayNew(1)>
	<cfset var template = "">
	<cfset var matcher = "">
	<cfset var buffer = "">
	<cfset var out = "">
	<cfset var position = 0>
	<cfset var character = "">
	<cfset var digits = "">
	<cfset var group = 0>
	<cfset var i = 0>
	<cfset var j = 0>

	<cfif IsArray(arguments.pattern)>
		<cfset patterns = arguments.pattern>
	<cfelse>
		<cfset ArrayAppend(patterns, arguments.pattern)>
	</cfif>

	<cfloop from="1" to="#ArrayLen(patterns)#" index="i">
		<cfset template = "">
		<cfif IsArray(arguments.replacement)>
			<cfif i LTE ArrayLen(arguments.replacement)>
				<cfset template = arguments.replacement[i]>
			</cfif>
		<cfelse>
			<cfset template = arguments.replacement>
		</cfif>

		<cfif NOT arguments.unguarded>
			<cfset regex_guard_(result)>
		</cfif>

		<cfset matcher = preg_pattern(patterns[i]).matcher(JavaCast("string", result))>
		<cfset buffer = CreateObject("java", "java.lang.StringBuffer").init()>
		<cfset position = 0>

		<cfloop condition="matcher.find()">
			<cfset buffer.append(JavaCast("string", Mid(result, position + 1, matcher.start() - position)))>

			<!--- expand the references to the groups --->
			<cfset out = "">
			<cfset j = 1>
			<cfloop condition="j LTE Len(template)">
				<cfset character = Mid(template, j, 1)>
				<cfset digits = "">

				<cfif Compare(character, "\") EQ 0 OR Compare(character, "$") EQ 0>
					<cfif Compare(character, "$") EQ 0 AND REFind("^\{[0-9]{1,2}\}", Mid(template, j + 1, 4)) GT 0>
						<cfset digits = REReplace(Mid(template, j + 1, 4), "^\{([0-9]{1,2})\}.*$", "\1")>
						<cfset j = j + Len(digits) + 3>
					<cfelseif REFind("^[0-9]", Mid(template, j + 1, 1)) GT 0>
						<cfset digits = Mid(template, j + 1, 1)>
						<cfif REFind("^[0-9]", Mid(template, j + 2, 1)) GT 0>
							<cfset digits = digits & Mid(template, j + 2, 1)>
						</cfif>
						<cfset j = j + Len(digits) + 1>
					</cfif>
				</cfif>

				<cfif Len(digits) GT 0>
					<cfset group = Val(digits)>
					<cfif group LTE matcher.groupCount() AND matcher.start(JavaCast("int", group)) GTE 0>
						<cfset out = out & matcher.group(JavaCast("int", group))>
					</cfif>
				<cfelse>
					<cfset out = out & character>
					<cfset j = j + 1>
				</cfif>
			</cfloop>

			<cfset buffer.append(JavaCast("string", out))>
			<cfset position = matcher.end()>
		</cfloop>

		<cfset buffer.append(JavaCast("string", Mid(result, position + 1, Len(result) - position)))>
		<cfset result = buffer.toString()>
	</cfloop>

	<cfreturn result>
</cffunction>
