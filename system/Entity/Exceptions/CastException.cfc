<!---
 * CastException is thrown for invalid cast initialization and management.
 *
 * An exception is not an object here. The methods throw the exception
 * themselves, with the type "ColdIgniter.Entity.Exceptions.CastException":
 *
 *     <cfset static_("ColdIgniter\Entity\Exceptions\CastException").forInvalidMethod(method)>
 *
 * The messages come from the language file Language/en/Cast.cfm.
 *
 * Difference: the original makes an exception of the class it is called on
 * ("static"); the type is always the one of this class, also for the
 * exceptions of DataCaster. The original implements HasExitCodeInterface,
 * so getExitCode() is kept as a method.
 *
 * Difference: forInvalidEnumValue() takes the value as text.
 *
 * Not ported yet: the enum casts (there are no enums), so the enum methods
 * are written out and nothing calls them.
--->
<cfcomponent output="no" parent="ColdIgniter\Exceptions\FrameworkException" hint="CastException is thrown for invalid cast initialization and management">

	<cffunction name="getExitCode" access="public" returntype="numeric" output="no">

		<cfreturn request.EXIT_CONFIG>
	</cffunction>

	<!---
	 * Thrown when the cast class does not extends BaseCast.
	--->
	<cffunction name="forInvalidInterface" access="public" returntype="void" output="no">
		<cfargument name="class" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.class)>

		<cfthrow type="ColdIgniter.Entity.Exceptions.CastException" errorcode="500" message="#lang('Cast.baseCastMissing', parameters)#">
	</cffunction>

	<!---
	 * Thrown when the Json format is invalid.
	 *
	 * Difference: the error is the name of the error, not the code of json_last_error():
	 * "depth", "state_mismatch", "ctrl_char", "syntax" or "utf8"; any other name gives
	 * the unknown error. The reader of json_decode() has no codes.
	--->
	<cffunction name="forInvalidJsonFormat" access="public" returntype="void" output="no">
		<cfargument name="error" type="string" required="yes">
		<cfset var key = "jsonErrorUnknown">

		<cfif Compare(arguments.error, "depth") EQ 0>
			<cfset key = "jsonErrorDepth">
		<cfelseif Compare(arguments.error, "state_mismatch") EQ 0>
			<cfset key = "jsonErrorStateMismatch">
		<cfelseif Compare(arguments.error, "ctrl_char") EQ 0>
			<cfset key = "jsonErrorCtrlChar">
		<cfelseif Compare(arguments.error, "syntax") EQ 0>
			<cfset key = "jsonErrorSyntax">
		<cfelseif Compare(arguments.error, "utf8") EQ 0>
			<cfset key = "jsonErrorUtf8">
		</cfif>

		<cfthrow type="ColdIgniter.Entity.Exceptions.CastException" errorcode="500" message="#lang('Cast.' & key)#">
	</cffunction>

	<!---
	 * Thrown when the cast method is not `get` or `set`.
	--->
	<cffunction name="forInvalidMethod" access="public" returntype="void" output="no">
		<cfargument name="method" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.method)>

		<cfthrow type="ColdIgniter.Entity.Exceptions.CastException" errorcode="500" message="#lang('Cast.invalidCastMethod', parameters)#">
	</cffunction>

	<!---
	 * Thrown when the casting timestamp is not correct timestamp.
	--->
	<cffunction name="forInvalidTimestamp" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Entity.Exceptions.CastException" errorcode="500" message="#lang('Cast.invalidTimestamp')#">
	</cffunction>

	<!---
	 * Thrown when the enum class is not specified in cast parameters.
	--->
	<cffunction name="forMissingEnumClass" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Entity.Exceptions.CastException" errorcode="500" message="#lang('Cast.enumMissingClass')#">
	</cffunction>

	<!---
	 * Thrown when the specified class is not an enum.
	--->
	<cffunction name="forNotEnum" access="public" returntype="void" output="no">
		<cfargument name="class" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.class)>

		<cfthrow type="ColdIgniter.Entity.Exceptions.CastException" errorcode="500" message="#lang('Cast.enumNotEnum', parameters)#">
	</cffunction>

	<!---
	 * Thrown when an invalid value is provided for an enum.
	--->
	<cffunction name="forInvalidEnumValue" access="public" returntype="void" output="no">
		<cfargument name="enumClass" type="string" required="yes">
		<cfargument name="value" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.enumClass)>
		<cfset ArrayAppend(parameters, arguments.value)>

		<cfthrow type="ColdIgniter.Entity.Exceptions.CastException" errorcode="500" message="#lang('Cast.enumInvalidValue', parameters)#">
	</cffunction>

	<!---
	 * Thrown when an invalid case name is provided for a unit enum.
	--->
	<cffunction name="forInvalidEnumCaseName" access="public" returntype="void" output="no">
		<cfargument name="enumClass" type="string" required="yes">
		<cfargument name="caseName" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.caseName)>
		<cfset ArrayAppend(parameters, arguments.enumClass)>

		<cfthrow type="ColdIgniter.Entity.Exceptions.CastException" errorcode="500" message="#lang('Cast.enumInvalidCaseName', parameters)#">
	</cffunction>

	<!---
	 * Thrown when an enum instance of wrong type is provided.
	--->
	<cffunction name="forInvalidEnumType" access="public" returntype="void" output="no">
		<cfargument name="expectedClass" type="string" required="yes">
		<cfargument name="actualClass" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.actualClass)>
		<cfset ArrayAppend(parameters, arguments.expectedClass)>

		<cfthrow type="ColdIgniter.Entity.Exceptions.CastException" errorcode="500" message="#lang('Cast.enumInvalidType', parameters)#">
	</cffunction>

</cfcomponent>
