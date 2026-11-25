<!---
 * Class DatetimeCast
 *
 * Handles converting a value to a Time.
 *
 * Difference: a Time stays as it is; a TimeLegacy (the nearest to a
 * DateTimeInterface here) is converted with createFromInstance(). A number
 * is a timestamp in the timezone of the application, as the original uses
 * the default timezone.
--->
<cfcomponent output="no" extends="BaseCast" hint="Handles converting a value to a Time">

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">
		<cfset var time = static_("ColdIgniter\I18n\Time")>

		<cfif IsObject(arguments.value)>
			<cfif instanceof_(arguments.value, "TimeLegacy")>
				<cfreturn time.createFromInstance(arguments.value)>
			</cfif>

			<!--- a Time, or an object that is neither --->
			<cfreturn arguments.value>
		</cfif>

		<cfif is_numeric(arguments.value)>
			<cfreturn time.createFromTimestamp(Fix(arguments.value), "")>
		</cfif>

		<cfif IsSimpleValue(arguments.value) AND NOT is_null(arguments.value)>
			<cfreturn time.parse(arguments.value)>
		</cfif>

		<cfreturn arguments.value>
	</cffunction>
</cfcomponent>
