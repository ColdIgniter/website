<!---
 * Class LogException
 *
 * Not ported yet: the messages come from the language files in the
 * original (Log.invalidLogLevel and Log.invalidMessageType); they are
 * written out here until the language service is ported.
 *
 * An exception is not an object here. The methods throw the exception
 * themselves, with the type "ColdIgniter.Log.Exceptions.LogException":
 *
 *     <cfset static_("ColdIgniter\Log\Exceptions\LogException").forInvalidLogLevel(level)>
 *
 * Difference: forNoHandlers() is inherited in the original, which makes an
 * exception of the class it is called on ("static"). Here it is written
 * out again, so that it throws the type of this class.
--->
<cfcomponent output="no" parent="ColdIgniter\Exceptions\FrameworkException" hint="Log exceptions">

	<cffunction name="forNoHandlers" access="public" returntype="void" output="no">
		<cfargument name="class" type="string" required="yes">

		<cfthrow type="ColdIgniter.Log.Exceptions.LogException" errorcode="500" message="""#arguments.class#"" must provide at least one Handler.">
	</cffunction>

	<cffunction name="forInvalidLogLevel" access="public" returntype="void" output="no">
		<cfargument name="level" type="string" required="yes">

		<cfthrow type="ColdIgniter.Log.Exceptions.LogException" errorcode="500" message="""#arguments.level#"" is an invalid log level.">
	</cffunction>

	<cffunction name="forInvalidMessageType" access="public" returntype="void" output="no">
		<cfargument name="messageType" type="string" required="yes">

		<cfthrow type="ColdIgniter.Log.Exceptions.LogException" errorcode="500" message="The given message type ""#arguments.messageType#"" is not supported.">
	</cffunction>

</cfcomponent>
