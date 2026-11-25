<!---
 * Class DatetimeCast
 *
 * Handles converting a date and time text of the database to a Time and
 * back, with the date format of the connection.
 *
 * Difference: the type check of get() is isSimple_() (see BaseCast), and
 * the helper is checked as a BaseConnection by the short name of its
 * class (see instanceof_()).
--->
<cfcomponent output="no" extends="BaseCast" hint="Handles converting a date and time text to a Time and back">

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">
		<cfset var format = "">

		<cfif NOT isSimple_(arguments.value)>
			<cfset invalidTypeValueError(arguments.value)>
		</cfif>

		<cfif NOT instanceof_(arguments.helper, "BaseConnection")>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="The parameter $helper must be BaseConnection.">
		</cfif>

		<cfset format = getDateTimeFormat(arguments.params, arguments.helper)>

		<cfreturn static_("ColdIgniter\I18n\Time").createFromFormat(format, arguments.value)>
	</cffunction>

	<cffunction name="set" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">
		<cfset var format = "">

		<cfif NOT instanceof_(arguments.value, "Time")>
			<cfset invalidTypeValueError(arguments.value)>
		</cfif>

		<cfif NOT instanceof_(arguments.helper, "BaseConnection")>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="The parameter $helper must be BaseConnection.">
		</cfif>

		<cfset format = getDateTimeFormat(arguments.params, arguments.helper)>

		<cfreturn arguments.value.format(format)>
	</cffunction>

	<cffunction name="getDateTimeFormat" access="public" returntype="string" output="no">
		<cfargument name="params" type="any" required="yes">
		<cfargument name="db" type="any" required="yes">
		<cfset var param = "">

		<cfif IsArray(arguments.params) AND ArrayLen(arguments.params) GT 0>
			<cfset param = arguments.params[1]>
		</cfif>

		<cfif Compare(param, "") EQ 0>
			<cfreturn arguments.db.dateFormat["datetime"]>
		<cfelseif Compare(param, "ms") EQ 0>
			<cfreturn arguments.db.dateFormat["datetime-ms"]>
		<cfelseif Compare(param, "us") EQ 0>
			<cfreturn arguments.db.dateFormat["datetime-us"]>
		</cfif>

		<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Invalid parameter: #param#">
	</cffunction>
</cfcomponent>
