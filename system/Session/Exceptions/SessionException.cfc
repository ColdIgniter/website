<!---
 * SessionException is thrown for invalid session settings.
 *
 * Not ported yet: the messages come from the language files in the
 * original (Session.*); they are written out here until the language
 * service is ported. forInvalidSavePathFormat() belongs to the Redis handler,
 * which is not ported yet.
 *
 * An exception is not an object here. The methods throw the exception
 * themselves, with the type "ColdIgniter.Session.Exceptions.SessionException":
 *
 *     <cfset static_("ColdIgniter\Session\Exceptions\SessionException").forEmptySavepath()>
--->
<cfcomponent output="no" parent="ColdIgniter\Exceptions\FrameworkException" hint="SessionException is thrown for invalid session settings">

	<cffunction name="forMissingDatabaseTable" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Session.Exceptions.SessionException" errorcode="500" message="Session: ""savePath"" must have the table name for the Database Session Handler to work.">
	</cffunction>

	<cffunction name="forInvalidSavePath" access="public" returntype="void" output="no">
		<cfargument name="path" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.Session.Exceptions.SessionException" errorcode="500" message="Session: Configured save path ""#arguments.path#"" is not a directory, does not exist or cannot be created.">
	</cffunction>

	<cffunction name="forWriteProtectedSavePath" access="public" returntype="void" output="no">
		<cfargument name="path" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.Session.Exceptions.SessionException" errorcode="500" message="Session: Configured save path ""#arguments.path#"" is not writable by the server process.">
	</cffunction>

	<cffunction name="forEmptySavepath" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Session.Exceptions.SessionException" errorcode="500" message="Session: No save path configured.">
	</cffunction>

	<cffunction name="forInvalidSavePathFormat" access="public" returntype="void" output="no">
		<cfargument name="path" type="string" required="yes">

		<cfthrow type="ColdIgniter.Session.Exceptions.SessionException" errorcode="500" message="Session: Invalid Redis save path format: ""#arguments.path#""">
	</cffunction>

	<!---
	 * @deprecated
	--->
	<cffunction name="forInvalidSameSiteSetting" access="public" returntype="void" output="no">
		<cfargument name="samesite" type="string" required="yes">

		<cfthrow type="ColdIgniter.Session.Exceptions.SessionException" errorcode="500" message="Session: The SameSite setting must be None, Lax, Strict, or a blank string. Given: ""#arguments.samesite#""">
	</cffunction>

</cfcomponent>
