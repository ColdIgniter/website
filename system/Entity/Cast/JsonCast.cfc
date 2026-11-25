<!---
 * Class JsonCast
 *
 * Handles converting a JSON text to and from a map or a list.
 *
 * Difference: there is no stdClass, so an object is a map (see array_()),
 * and the 'array' parameter only changes what a value that is not JSON
 * gives (an empty list instead of an empty map). A null (an empty string)
 * stays an empty string. json_decode() gives numbers and the words true,
 * false and null as text.
 *
 * Difference: the flag JSON_UNESCAPED_UNICODE is not ported yet, so
 * json_encode() of the polyfills escapes what it escapes (see there).
 * The error of the reader is mapped to the error name that
 * CastException::forInvalidJsonFormat() takes.
--->
<cfcomponent output="no" extends="BaseCast" hint="Handles converting a JSON text to and from an array or an object">

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">
		<cfset var associative = IsArray(arguments.params) AND in_array("array", arguments.params)>
		<cfset var tmp = "">
		<cfset var error = "">

		<cfif is_null(arguments.value)>
			<cfreturn "">
		</cfif>

		<cfif associative>
			<cfset tmp = ArrayNew(1)>
		<cfelse>
			<cfset tmp = array_()>
		</cfif>

		<cfif IsSimpleValue(arguments.value) AND ((Len(arguments.value) GT 1 AND ListFind("[,{,""", Left(arguments.value, 1)) GT 0) OR is_numeric(arguments.value))>
			<cftry>
				<cfset tmp = json_decode(arguments.value)>
				<cfcatch type="ColdIgniter.JsonException">
					<cfset error = jsonError_(cfcatch.message)>
				</cfcatch>
			</cftry>

			<cfif error NEQ "">
				<cfset static_("ColdIgniter\Entity\Exceptions\CastException").forInvalidJsonFormat(error)>
			</cfif>
		</cfif>

		<cfreturn tmp>
	</cffunction>

	<cffunction name="set" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">
		<cfset var result = "">
		<cfset var error = "">

		<cftry>
			<cfset result = json_encode(arguments.value)>
			<cfcatch type="ColdIgniter.JsonException">
				<cfset error = jsonError_(cfcatch.message)>
			</cfcatch>
		</cftry>

		<cfif error NEQ "">
			<cfset static_("ColdIgniter\Entity\Exceptions\CastException").forInvalidJsonFormat(error)>
		</cfif>

		<cfreturn result>
	</cffunction>

	<!---
	 * Gives the name of the error of a message of the JSON reader. Not in
	 * the original.
	--->
	<cffunction name="jsonError_" access="private" returntype="string" output="no">
		<cfargument name="message" type="string" required="yes">

		<cfif Compare(arguments.message, "Maximum stack depth exceeded") EQ 0>
			<cfreturn "depth">
		<cfelseif Find("Control character", arguments.message) GT 0>
			<cfreturn "ctrl_char">
		<cfelseif Compare(arguments.message, "Syntax error") EQ 0>
			<cfreturn "syntax">
		</cfif>

		<cfreturn "unknown">
	</cffunction>
</cfcomponent>
