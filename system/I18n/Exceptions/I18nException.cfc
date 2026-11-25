<!---
 * I18n exceptions.
 *
 * An exception is not an object here. The methods throw the exception
 * themselves, with the type "ColdIgniter.I18n.Exceptions.I18nException":
 *
 *     <cfset static_("ColdIgniter\I18n\Exceptions\I18nException").forInvalidFormat(format)>
 *
 * The messages come from the language file Language/en/Time.cfm.
 *
 * Not ported yet: DebugTraceableTrait.
--->
<cfcomponent output="no" hint="I18n exceptions">

	<cffunction name="forInvalidFormat" access="public" returntype="void" output="no">
		<cfargument name="format" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.format)>

		<cfthrow type="ColdIgniter.I18n.Exceptions.I18nException" errorcode="500" message="#lang('Time.invalidFormat', parameters)#">
	</cffunction>

	<cffunction name="forInvalidMonth" access="public" returntype="void" output="no">
		<cfargument name="month" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.month)>

		<cfthrow type="ColdIgniter.I18n.Exceptions.I18nException" errorcode="500" message="#lang('Time.invalidMonth', parameters)#">
	</cffunction>

	<cffunction name="forInvalidDay" access="public" returntype="void" output="no">
		<cfargument name="day" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.day)>

		<cfthrow type="ColdIgniter.I18n.Exceptions.I18nException" errorcode="500" message="#lang('Time.invalidDay', parameters)#">
	</cffunction>

	<cffunction name="forInvalidOverDay" access="public" returntype="void" output="no">
		<cfargument name="lastDay" type="string" required="yes">
		<cfargument name="day" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.lastDay)>
		<cfset ArrayAppend(parameters, arguments.day)>

		<cfthrow type="ColdIgniter.I18n.Exceptions.I18nException" errorcode="500" message="#lang('Time.invalidOverDay', parameters)#">
	</cffunction>

	<cffunction name="forInvalidHour" access="public" returntype="void" output="no">
		<cfargument name="hour" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.hour)>

		<cfthrow type="ColdIgniter.I18n.Exceptions.I18nException" errorcode="500" message="#lang('Time.invalidHours', parameters)#">
	</cffunction>

	<cffunction name="forInvalidMinutes" access="public" returntype="void" output="no">
		<cfargument name="minutes" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.minutes)>

		<cfthrow type="ColdIgniter.I18n.Exceptions.I18nException" errorcode="500" message="#lang('Time.invalidMinutes', parameters)#">
	</cffunction>

	<cffunction name="forInvalidSeconds" access="public" returntype="void" output="no">
		<cfargument name="seconds" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.seconds)>

		<cfthrow type="ColdIgniter.I18n.Exceptions.I18nException" errorcode="500" message="#lang('Time.invalidSeconds', parameters)#">
	</cffunction>

</cfcomponent>
