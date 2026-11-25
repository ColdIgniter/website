<!---
 * Class Controller
 *
 * Not ported yet: forceHTTPS.
--->
<cfcomponent output="no" hint="Class Controller">

	<!---
	 * Helpers that will be automatically loaded on class instantiation.
	--->
	<cfset this.helpers = ArrayNew(1)>

	<!---
	 * Instance of the main Request object.
	 *
	 * Named with an underscore, because "request" is a scope.
	--->
	<cfset this.request_ = "">

	<!---
	 * Instance of the main response object.
	--->
	<cfset this.response = "">

	<!---
	 * Instance of logger to use.
	--->
	<cfset this.logger = "">

	<!---
	 * Should enforce HTTPS access for all methods in this controller.
	 *
	 * @var int Number of seconds to set HSTS header
	--->
	<cfset this.forceHTTPS = 0>

	<!---
	 * Once validation has been run, will hold the Validation instance.
	 *
	 * @var ValidationInterface|null
	--->
	<cfset this.validator = "">

	<!---
	 * Constructor.
	--->
	<cffunction name="initController" access="public" returntype="void" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="response" type="any" required="yes">
		<cfargument name="logger" type="any" required="yes">

		<cfset this.request_ = arguments.request_>
		<cfset this.response = arguments.response>
		<cfset this.logger = arguments.logger>

		<!--- Not ported yet: forceHTTPS --->

		<!--- Autoload helper files. --->
		<cfset helper(this.helpers)>
	</cffunction>

	<!---
	 * Provides a simple way to tie into the main ColdIgniter class and
	 * tell it how long to cache the current page for, if the
	 * PageCache filter is applied.
	 *
	 * @param time Seconds to cache the page for
	--->
	<cffunction name="cachePage" access="private" returntype="void" output="no">
		<cfargument name="time" type="numeric" required="yes">

		<cfset service("responsecache").setTtl(arguments.time)>
	</cffunction>

	<!---
	 * A shortcut to performing validation on Request data.
	 *
	 * @param rules    A map of rules, or the name of a group of the Validation config
	 * @param messages A map of custom error messages, or an empty string for none
	--->
	<cffunction name="validate" access="private" returntype="boolean" output="no">
		<cfargument name="rules" type="any" required="yes">
		<cfargument name="messages" type="any" required="no" default="">

		<cfset setValidator(arguments.rules, arguments.messages)>

		<cfset this.validator.withRequest(this.request_)>

		<cfreturn this.validator.run()>
	</cffunction>

	<!---
	 * A shortcut to performing validation on any input data.
	 *
	 * @param data     The data to validate (a map)
	 * @param rules    A map of rules, or the name of a group of the Validation config
	 * @param messages A map of custom error messages, or an empty string for none
	 * @param dbGroup  The database group to use, or an empty string (null)
	--->
	<cffunction name="validateData" access="private" returntype="boolean" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfargument name="rules" type="any" required="yes">
		<cfargument name="messages" type="any" required="no" default="">
		<cfargument name="dbGroup" type="any" required="no" default="">

		<cfset setValidator(arguments.rules, arguments.messages)>

		<cfreturn this.validator.run(arguments.data, "", arguments.dbGroup)>
	</cffunction>

	<!---
	 * Sets the validator and its rules.
	 *
	 * @param rules    A map of rules, or the name of a group of the Validation config
	 * @param messages A map of custom error messages, or an empty string for none
	--->
	<cffunction name="setValidator" access="private" returntype="void" output="no">
		<cfargument name="rules" type="any" required="yes">
		<cfargument name="messages" type="any" required="yes">

		<cfset var validation = "">
		<cfset var errorName = "">

		<cfset this.validator = service("validation")>

		<!--- If you replace the rules array with the name of the group --->
		<cfif IsSimpleValue(arguments.rules)>
			<cfset validation = config("Config\Validation")>

			<!---
			 If the rule wasn't found in the \Config\Validation, we
			 should throw an exception so the developer can find it.
			--->
			<cfif NOT StructKeyExists(validation, arguments.rules) OR is_null(validation[arguments.rules])>
				<cfset static_("ColdIgniter\Validation\Exceptions\ValidationException").forRuleNotFound(arguments.rules)>
			</cfif>

			<!--- If no error message is defined, use the error message in the Config\Validation file --->
			<cfif is_null(arguments.messages) OR (IsStruct(arguments.messages) AND StructIsEmpty(arguments.messages)) OR (IsArray(arguments.messages) AND ArrayLen(arguments.messages) EQ 0)>
				<cfset errorName = arguments.rules & "_errors">

				<cfif StructKeyExists(validation, errorName)>
					<cfset arguments.messages = validation[errorName]>
				</cfif>
			</cfif>

			<cfset arguments.rules = validation[arguments.rules]>
		</cfif>

		<cfset this.validator.setRules(arguments.rules, arguments.messages)>
	</cffunction>

</cfcomponent>
