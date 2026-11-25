<!---
 * Security exceptions.
 *
 * forInvalidUTF8Chars and forInvalidControlChars write their English text
 * out, as the original does. The status of forInsecureCookie and
 * forInvalidSameSite is 400 here, where the original gives them none.
 *
 * An exception is not an object here. The methods throw the exception
 * themselves, with the type "ColdIgniter.Security.Exceptions.SecurityException":
 *
 *     <cfset static_("ColdIgniter\Security\Exceptions\SecurityException").forDisallowedAction()>
 *
 * The messages come from the language file Language/en/Security.cfm.
--->
<cfcomponent output="no" hint="Security exceptions">

	<!---
	 * HTTP status code
	--->
	<cfset this.code = 400>

	<!---
	 * Thrown when the CSRF token is missing or does not match. A 403, as
	 * the original, which has it as the code of the exception.
	--->
	<cffunction name="forDisallowedAction" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Security.Exceptions.SecurityException" errorcode="403" message="#lang('Security.disallowedAction')#">
	</cffunction>

	<!---
	 * Thrown when the SameSite value is not None, Lax, Strict or a blank string.
	--->
	<cffunction name="forInvalidSameSite" access="public" returntype="void" output="no">
		<cfargument name="samesite" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.samesite)>

		<cfthrow type="ColdIgniter.Security.Exceptions.SecurityException" errorcode="#this.code#" message="#lang('Security.invalidSameSite', parameters)#">
	</cffunction>

	<!---
	 * Thrown when the string is not valid UTF-8.
	--->
	<cffunction name="forInvalidUTF8Chars" access="public" returntype="void" output="no">
		<cfargument name="source" type="string" required="yes">
		<cfargument name="string" type="string" required="yes">

		<cfthrow type="ColdIgniter.Security.Exceptions.SecurityException" errorcode="#this.code#" message="Invalid UTF-8 characters in #arguments.source#: #arguments.string#">
	</cffunction>

	<!---
	 * Thrown when the string has control characters other than line breaks and tabs.
	--->
	<cffunction name="forInvalidControlChars" access="public" returntype="void" output="no">
		<cfargument name="source" type="string" required="yes">
		<cfargument name="string" type="string" required="yes">

		<cfthrow type="ColdIgniter.Security.Exceptions.SecurityException" errorcode="#this.code#" message="Invalid Control characters in #arguments.source#: #arguments.string#">
	</cffunction>

	<!---
	 * Throws if a secure cookie is dispatched when the current connection is not
	 * secure.
	--->
	<cffunction name="forInsecureCookie" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Security.Exceptions.SecurityException" errorcode="#this.code#" message="#lang('Security.insecureCookie')#">
	</cffunction>

</cfcomponent>
