<!---
 * Custom exception for API-related errors.
 *
 * An exception is not an object here. The methods throw the exception
 * themselves, with the type "ColdIgniter.API.ApiException":
 *
 *     <cfset static_("ColdIgniter\API\ApiException").forInvalidFields(field)>
 *
 * The messages come from the language file Language/en/Api.cfm.
 *
 * Difference: the original extends FrameworkException, so a catch of
 * that type finds it; here the type is its own.
--->
<cfcomponent output="no" hint="Custom exception for API-related errors">

	<!---
	 * Thrown when the fields requested in a URL are not valid.
	--->
	<cffunction name="forInvalidFields" access="public" returntype="void" output="no">
		<cfargument name="field" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.field)>

		<cfthrow type="ColdIgniter.API.ApiException" errorcode="500" message="#lang('Api.invalidFields', parameters)#">
	</cffunction>

	<!---
	 * Thrown when the includes requested in a URL are not valid.
	--->
	<cffunction name="forInvalidIncludes" access="public" returntype="void" output="no">
		<cfargument name="include" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.include)>

		<cfthrow type="ColdIgniter.API.ApiException" errorcode="500" message="#lang('Api.invalidIncludes', parameters)#">
	</cffunction>

	<!---
	 * Thrown when an include is requested, but the method to handle it
	 * does not exist on the model.
	--->
	<cffunction name="forMissingInclude" access="public" returntype="void" output="no">
		<cfargument name="include" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.include)>

		<cfthrow type="ColdIgniter.API.ApiException" errorcode="500" message="#lang('Api.missingInclude', parameters)#">
	</cffunction>

	<!---
	 * Thrown when a transformer class cannot be found.
	--->
	<cffunction name="forTransformerNotFound" access="public" returntype="void" output="no">
		<cfargument name="transformerClass" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.transformerClass)>

		<cfthrow type="ColdIgniter.API.ApiException" errorcode="500" message="#lang('Api.transformerNotFound', parameters)#">
	</cffunction>

	<!---
	 * Thrown when a transformer class does not implement TransformerInterface.
	--->
	<cffunction name="forInvalidTransformer" access="public" returntype="void" output="no">
		<cfargument name="transformerClass" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.transformerClass)>

		<cfthrow type="ColdIgniter.API.ApiException" errorcode="500" message="#lang('Api.invalidTransformer', parameters)#">
	</cffunction>

</cfcomponent>
