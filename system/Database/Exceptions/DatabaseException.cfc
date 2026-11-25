<!---
 * Database exception.
 *
 * An exception is not an object here. Code that throws the original
 * "new DatabaseException(message)" writes, instead:
 *
 *     <cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" errorcode="#code#" message="#message#">
 *
 * getExitCode() is kept as a method of this component, for the code
 * that handles the exception to call.
--->
<cfcomponent output="no" hint="Database exception">

	<cffunction name="getExitCode" access="public" returntype="numeric" output="no">

		<cfreturn request.EXIT_DATABASE>
	</cffunction>

</cfcomponent>
