<!---
 * Honeypot exceptions.
 *
 * An exception is not an object here. The methods throw the exception
 * themselves, with the type "ColdIgniter.Honeypot.Exceptions.HoneypotException"
 * and the HTTP status as the error code:
 *
 *     <cfset static_("ColdIgniter\Honeypot\Exceptions\HoneypotException").isBot()>
 *
 * The messages come from the language file Language/en/Honeypot.cfm.
 *
 * Difference: the original extends ConfigException, so a catch of that
 * type finds it; here the type is its own.
 *
 * Not ported yet: forNoHiddenValue (deprecated, never used).
--->
<cfcomponent output="no" hint="Honeypot exceptions">

	<!---
	 * Thrown when the template value of config is empty.
	--->
	<cffunction name="forNoTemplate" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Honeypot.Exceptions.HoneypotException" errorcode="500" message="#lang('Honeypot.noTemplate')#">
	</cffunction>

	<!---
	 * Thrown when the name value of config is empty.
	--->
	<cffunction name="forNoNameField" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Honeypot.Exceptions.HoneypotException" errorcode="500" message="#lang('Honeypot.noNameField')#">
	</cffunction>

	<!---
	 * Thrown when there are no data in the request of honeypot field.
	--->
	<cffunction name="isBot" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Honeypot.Exceptions.HoneypotException" errorcode="403" message="#lang('Honeypot.theClientIsABot')#">
	</cffunction>

</cfcomponent>
