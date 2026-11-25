<!---
 * Class TimestampCast
 *
 * Handles converting a date text to a timestamp.
 *
 * Difference: there is no strtotime(), so the text is read by Time::parse()
 * and the timestamp is taken from it; any text it can not read throws the
 * exception for an invalid timestamp.
--->
<cfcomponent output="no" extends="BaseCast" hint="Handles converting a date text to a timestamp">

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">
		<cfset var result = "">
		<cfset var failed = false>

		<cftry>
			<cfset result = static_("ColdIgniter\I18n\Time").parse(arguments.value).getTimestamp()>
			<cfcatch type="any">
				<cfset failed = true>
			</cfcatch>
		</cftry>

		<cfif failed>
			<cfset static_("ColdIgniter\Entity\Exceptions\CastException").forInvalidTimestamp()>
		</cfif>

		<cfreturn result>
	</cffunction>
</cfcomponent>
