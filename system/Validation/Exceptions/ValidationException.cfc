<!---
 * An exception is not an object here. The methods throw the exception
 * themselves, with the type "ColdIgniter.Validation.Exceptions.ValidationException":
 *
 *     <cfset static_("ColdIgniter\Validation\Exceptions\ValidationException").forRuleNotFound(rule)>
 *
 * stands in for "throw ValidationException::forRuleNotFound(rule)".
 *
 * Difference: the original extends FrameworkException, and this one does
 * not, because a method cannot make an exception of another class here.
 * The type and the code (500) are the same.
--->
<cfcomponent output="no" hint="Validation exceptions">

	<!---
	 * Throws when the validation rule is not found.
	--->
	<cffunction name="forRuleNotFound" access="public" returntype="void" output="no">
		<cfargument name="rule" type="string" required="no" default="">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.rule)>
		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" errorcode="500" message="#lang('Validation.ruleNotFound', parameters)#">
	</cffunction>

	<!---
	 * Throws when the group value of config is not set.
	--->
	<cffunction name="forGroupNotFound" access="public" returntype="void" output="no">
		<cfargument name="group" type="string" required="no" default="">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.group)>
		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" errorcode="500" message="#lang('Validation.groupNotFound', parameters)#">
	</cffunction>

	<!---
	 * Throws when the group value of config is not array type.
	--->
	<cffunction name="forGroupNotArray" access="public" returntype="void" output="no">
		<cfargument name="group" type="string" required="no" default="">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.group)>
		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" errorcode="500" message="#lang('Validation.groupNotArray', parameters)#">
	</cffunction>

	<!---
	 * Throws when the template of config is invalid.
	--->
	<cffunction name="forInvalidTemplate" access="public" returntype="void" output="no">
		<cfargument name="template" type="string" required="no" default="">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.template)>
		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" errorcode="500" message="#lang('Validation.invalidTemplate', parameters)#">
	</cffunction>

	<!---
	 * Throws when there is no any rule set.
	--->
	<cffunction name="forNoRuleSets" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" errorcode="500" message="#lang('Validation.noRuleSets')#">
	</cffunction>

</cfcomponent>
