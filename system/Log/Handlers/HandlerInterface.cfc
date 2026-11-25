<!---
 * Expected behavior for a Log handler
 *
 * There are no interfaces on 6.1, so this is a base component. A handler
 * extends it (BaseHandler does), and it has to define the three methods.
 * The methods here only throw.
--->
<cfcomponent output="no" hint="Expected behavior for a Log handler">

	<!---
	 * Handles logging the message.
	 * If the handler returns false, then execution of handlers
	 * will stop. Any handlers that have not run, yet, will not
	 * be run.
	 *
	 * @param level   string
	 * @param message string
	--->
	<cffunction name="handle" access="public" returntype="boolean" output="no">
		<cfargument name="level" type="string" required="yes">
		<cfargument name="message" type="string" required="yes">

		<cfthrow type="ColdIgniter.Log.Exceptions.LogException" message="The handler does not define handle().">
	</cffunction>

	<!---
	 * Checks whether the Handler will handle logging items of this
	 * log Level.
	--->
	<cffunction name="canHandle" access="public" returntype="boolean" output="no">
		<cfargument name="level" type="string" required="yes">

		<cfthrow type="ColdIgniter.Log.Exceptions.LogException" message="The handler does not define canHandle().">
	</cffunction>

	<!---
	 * Sets the preferred date format to use when logging.
	 *
	 * @return The handler
	--->
	<cffunction name="setDateFormat" access="public" returntype="any" output="no">
		<cfargument name="format" type="string" required="yes">

		<cfthrow type="ColdIgniter.Log.Exceptions.LogException" message="The handler does not define setDateFormat().">
	</cffunction>

</cfcomponent>
