<!---
 * Class FrameworkException
 *
 * A collection of exceptions thrown by the framework.
 *
 * Not ported yet: the messages come from the language files in the
 * original (Core.noHandlers); they are written out here until the
 * language service is ported. Every other method of the original is not
 * ported yet.
 *
 * An exception is not an object here. The method throws the exception
 * itself, with the type "ColdIgniter.Exceptions.FrameworkException":
 *
 *     <cfset static_("ColdIgniter\Exceptions\FrameworkException").forNoHandlers(class)>
 *
 * Difference: the original makes an exception of the class it is called
 * on ("static"), so a LogException has the type of its class. Here the
 * type is always the one of this class, and a class that needs its own
 * type (LogException) writes the method out again.
--->
<cfcomponent output="no" hint="A collection of exceptions thrown by the framework">

	<cffunction name="forNoHandlers" access="public" returntype="void" output="no">
		<cfargument name="class" type="string" required="yes">

		<cfthrow type="ColdIgniter.Exceptions.FrameworkException" errorcode="500" message="""#arguments.class#"" must provide at least one Handler.">
	</cffunction>

</cfcomponent>
