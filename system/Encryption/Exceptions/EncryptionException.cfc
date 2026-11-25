<!---
 * Encryption exceptions.
 *
 * An exception is not an object here. The methods throw the exception
 * themselves, with the type "ColdIgniter.Encryption.Exceptions.EncryptionException":
 *
 *     <cfset static_("ColdIgniter\Encryption\Exceptions\EncryptionException").forNeedsStarterKey()>
 *
 * The messages come from the language file Language/en/Encryption.cfm. A
 * message never holds a key.
 *
 * Not ported yet: DebugTraceableTrait.
--->
<cfcomponent output="no" hint="Encryption exceptions">

	<!---
	 * Thrown when no driver is requested.
	--->
	<cffunction name="forNoDriverRequested" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Encryption.Exceptions.EncryptionException" errorcode="500" message="#lang('Encryption.noDriverRequested')#">
	</cffunction>

	<!---
	 * Thrown when the handler of the driver is not available.
	--->
	<cffunction name="forNoHandlerAvailable" access="public" returntype="void" output="no">
		<cfargument name="handler" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.handler)>

		<cfthrow type="ColdIgniter.Encryption.Exceptions.EncryptionException" errorcode="500" message="#lang('Encryption.noHandlerAvailable', parameters)#">
	</cffunction>

	<!---
	 * Thrown when the driver is not known.
	 *
	 * @param driver The driver, or an empty string (null)
	--->
	<cffunction name="forUnKnownHandler" access="public" returntype="void" output="no">
		<cfargument name="driver" type="string" required="no" default="">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.driver)>

		<cfthrow type="ColdIgniter.Encryption.Exceptions.EncryptionException" errorcode="500" message="#lang('Encryption.unKnownHandler', parameters)#">
	</cffunction>

	<!---
	 * Thrown when there is no key.
	--->
	<cffunction name="forNeedsStarterKey" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Encryption.Exceptions.EncryptionException" errorcode="500" message="#lang('Encryption.starterKeyNeeded')#">
	</cffunction>

	<!---
	 * Thrown when the data does not authenticate.
	--->
	<cffunction name="forAuthenticationFailed" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Encryption.Exceptions.EncryptionException" errorcode="500" message="#lang('Encryption.authenticationFailed')#">
	</cffunction>

	<!---
	 * Thrown when the data cannot be encrypted.
	--->
	<cffunction name="forEncryptionFailed" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Encryption.Exceptions.EncryptionException" errorcode="500" message="#lang('Encryption.encryptionFailed')#">
	</cffunction>

	<!---
	 * Difference: not in the original. Thrown when the cipher needs a key
	 * of more than 128 bits and the JVM has not the unlimited-strength
	 * policy files.
	--->
	<cffunction name="forUnlimitedStrengthNeeded" access="public" returntype="void" output="no">
		<cfargument name="cipher" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.cipher)>

		<cfthrow type="ColdIgniter.Encryption.Exceptions.EncryptionException" errorcode="500" message="#lang('Encryption.unlimitedStrengthNeeded', parameters)#">
	</cffunction>

</cfcomponent>
