<!---
 * Class TimestampCast
 *
 * Handles converting a timestamp to a Time and back.
 *
 * Difference: the type check of get() is isSimple_() (see BaseCast), and
 * the timezone is the one of the application (an empty timezone), as the
 * original uses the default timezone.
--->
<cfcomponent output="no" extends="BaseCast" hint="Handles converting a timestamp to a Time and back">

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfif NOT isSimple_(arguments.value)>
			<cfset invalidTypeValueError(arguments.value)>
		</cfif>

		<cfreturn static_("ColdIgniter\I18n\Time").createFromTimestamp(intval(arguments.value), "")>
	</cffunction>

	<cffunction name="set" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfif NOT instanceof_(arguments.value, "Time")>
			<cfset invalidTypeValueError(arguments.value)>
		</cfif>

		<cfreturn arguments.value.getTimestamp()>
	</cffunction>
</cfcomponent>
