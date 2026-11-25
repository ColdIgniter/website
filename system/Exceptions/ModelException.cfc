<!---
 * Model exceptions.
 *
 * An exception is not an object here. The methods throw the exception
 * themselves, with the type "ColdIgniter.Exceptions.ModelException":
 *
 *     <cfset static_("ColdIgniter\Exceptions\ModelException").forNoPrimaryKey(class)>
 *
 * The messages come from the language file Language/en/Database.cfm.
 *
 * Difference: the original extends FrameworkException, so a catch of
 * that type finds it; here the type is its own.
--->
<cfcomponent output="no" hint="Model exceptions">

	<cffunction name="forNoPrimaryKey" access="public" returntype="void" output="no">
		<cfargument name="modelName" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.modelName)>
		<cfthrow type="ColdIgniter.Exceptions.ModelException" message="#lang('Database.noPrimaryKey', parameters)#">
	</cffunction>

	<cffunction name="forNoDateFormat" access="public" returntype="void" output="no">
		<cfargument name="modelName" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.modelName)>
		<cfthrow type="ColdIgniter.Exceptions.ModelException" message="#lang('Database.noDateFormat', parameters)#">
	</cffunction>

	<cffunction name="forMethodNotAvailable" access="public" returntype="void" output="no">
		<cfargument name="modelName" type="string" required="yes">
		<cfargument name="methodName" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.modelName)>
		<cfset ArrayAppend(parameters, arguments.methodName)>
		<cfthrow type="ColdIgniter.Exceptions.ModelException" message="#lang('Database.methodNotAvailable', parameters)#">
	</cffunction>

</cfcomponent>
