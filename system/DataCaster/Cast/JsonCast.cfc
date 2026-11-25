<!---
 * Class JsonCast
 *
 * Handles converting a JSON text to and from a map or a list.
 *
 * Difference: there is no stdClass, so an object is a map (see array_()).
 * json_decode() gives numbers and the words true, false and null as text.
 * The type check of get() is isSimple_() (see BaseCast). The flag
 * JSON_UNESCAPED_UNICODE is not ported yet, so json_encode() of the
 * polyfills escapes what it escapes. The error of the reader is mapped to
 * the error name that CastException::forInvalidJsonFormat() takes.
--->
<cfcomponent output="no" extends="BaseCast" hint="Handles converting a JSON text to and from an array or an object">

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">
		<cfset var output = "">
		<cfset var error = "">

		<cfif NOT isSimple_(arguments.value)>
			<cfset invalidTypeValueError(arguments.value)>
		</cfif>

		<cftry>
			<cfset output = json_decode(arguments.value)>
			<cfcatch type="ColdIgniter.JsonException">
				<cfset error = jsonError_(cfcatch.message)>
			</cfcatch>
		</cftry>

		<cfif error NEQ "">
			<cfset static_("ColdIgniter\DataCaster\Exceptions\CastException").forInvalidJsonFormat(error)>
		</cfif>

		<cfreturn output>
	</cffunction>

	<cffunction name="set" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">
		<cfset var output = "">
		<cfset var error = "">

		<cftry>
			<cfset output = json_encode(arguments.value)>
			<cfcatch type="ColdIgniter.JsonException">
				<cfset error = jsonError_(cfcatch.message)>
			</cfcatch>
		</cftry>

		<cfif error NEQ "">
			<cfset static_("ColdIgniter\DataCaster\Exceptions\CastException").forInvalidJsonFormat(error)>
		</cfif>

		<cfreturn output>
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
