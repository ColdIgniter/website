<!---
 * Expected behavior of a validator
 *
 * There are no interfaces on 6.1, so this is a base component. A validator
 * extends it (Validation does), and it has to define the methods.
 * The methods here only throw.
 *
 * Difference: the original types are not declared (an array of the original
 * is a list or a map here, and null is an empty string).
--->
<cfcomponent output="no" hint="Expected behavior of a validator">

	<!---
	 * Runs the validation process, returning true/false determining whether
	 * validation was successful or not.
	 *
	 * @param data    The array of data to validate.
	 * @param group   The predefined group of rules to apply.
	 * @param dbGroup The database group to use.
	--->
	<cffunction name="run" access="public" returntype="boolean" output="no">
		<cfargument name="data" type="any" required="no" default="">
		<cfargument name="group" type="any" required="no" default="">
		<cfargument name="dbGroup" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" message="The validator does not define run().">
	</cffunction>

	<!---
	 * Check; runs the validation process, returning true or false
	 * determining whether or not validation was successful.
	 *
	 * @param value   Value to validate.
	 * @param rules   A list of rules or a string
	 * @param errors  A map of messages
	 * @param dbGroup The database group to use.
	 *
	 * @return True if valid, else false.
	--->
	<cffunction name="check" access="public" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="rules" type="any" required="yes">
		<cfargument name="errors" type="any" required="no" default="">
		<cfargument name="dbGroup" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" message="The validator does not define check().">
	</cffunction>

	<!---
	 * Takes a Request object and grabs the input data to use from its
	 * array values.
	--->
	<cffunction name="withRequest" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">

		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" message="The validator does not define withRequest().">
	</cffunction>

	<!---
	 * Sets an individual rule and custom error messages for a single field.
	 *
	 * The custom error message should be just the messages that apply to
	 * this field, like so:
	 *
	 *     rule1 => message, rule2 => message
	 *
	 * @return this
	--->
	<cffunction name="setRule" access="public" returntype="any" output="no">
		<cfargument name="field" type="any" required="yes">
		<cfargument name="label" type="any" required="yes">
		<cfargument name="rules" type="any" required="yes">
		<cfargument name="errors" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" message="The validator does not define setRule().">
	</cffunction>

	<!---
	 * Stores the rules that should be used to validate the items.
	--->
	<cffunction name="setRules" access="public" returntype="any" output="no">
		<cfargument name="rules" type="any" required="yes">
		<cfargument name="messages" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" message="The validator does not define setRules().">
	</cffunction>

	<!---
	 * Returns all of the rules currently defined.
	--->
	<cffunction name="getRules" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" message="The validator does not define getRules().">
	</cffunction>

	<!---
	 * Checks to see if the rule for key field has been set or not.
	--->
	<cffunction name="hasRule" access="public" returntype="boolean" output="no">
		<cfargument name="field" type="any" required="yes">

		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" message="The validator does not define hasRule().">
	</cffunction>

	<!---
	 * Get rule group.
	 *
	 * @param group Group.
	 *
	 * @return Rule group.
	--->
	<cffunction name="getRuleGroup" access="public" returntype="any" output="no">
		<cfargument name="group" type="any" required="yes">

		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" message="The validator does not define getRuleGroup().">
	</cffunction>

	<!---
	 * Set rule group.
	 *
	 * @param group Group.
	--->
	<cffunction name="setRuleGroup" access="public" returntype="void" output="no">
		<cfargument name="group" type="any" required="yes">

		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" message="The validator does not define setRuleGroup().">
	</cffunction>

	<!---
	 * Returns the error for a specified field (or empty string if not set).
	--->
	<cffunction name="getError" access="public" returntype="string" output="no">
		<cfargument name="field" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" message="The validator does not define getError().">
	</cffunction>

	<!---
	 * Returns the map of errors that were encountered during
	 * a run() call. The map is in the following format:
	 *
	 *     field1 => error message, field2 => error message
	 *
	 * @return A map of field name to message
	--->
	<cffunction name="getErrors" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" message="The validator does not define getErrors().">
	</cffunction>

	<!---
	 * Sets the error for a specific field. Used by custom validation methods.
	--->
	<cffunction name="setError" access="public" returntype="any" output="no">
		<cfargument name="alias" type="any" required="yes">
		<cfargument name="error" type="any" required="yes">

		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" message="The validator does not define setError().">
	</cffunction>

	<!---
	 * Resets the class to a blank slate. Should be called whenever
	 * you need to process more than one array.
	--->
	<cffunction name="reset" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" message="The validator does not define reset().">
	</cffunction>

	<!---
	 * Loads custom rule groups (if set) into the current rules.
	 *
	 * Rules can be pre-defined in Config\Validation and can
	 * be any name, but must all still be an array of the
	 * same format used with setRules(). Additionally, check
	 * for {group}_errors for an array of custom error messages.
	--->
	<cffunction name="loadRuleGroup" access="public" returntype="any" output="no">
		<cfargument name="group" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" message="The validator does not define loadRuleGroup().">
	</cffunction>

	<!---
	 * Checks to see if an error exists for the given field.
	--->
	<cffunction name="hasError" access="public" returntype="boolean" output="no">
		<cfargument name="field" type="any" required="yes">

		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" message="The validator does not define hasError().">
	</cffunction>

	<!---
	 * Returns the rendered HTML of the errors as defined in template.
	--->
	<cffunction name="listErrors" access="public" returntype="string" output="no">
		<cfargument name="template" type="any" required="no" default="list">

		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" message="The validator does not define listErrors().">
	</cffunction>

	<!---
	 * Displays a single error in formatted HTML as defined in the template view.
	--->
	<cffunction name="showError" access="public" returntype="string" output="no">
		<cfargument name="field" type="any" required="yes">
		<cfargument name="template" type="any" required="no" default="single">

		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" message="The validator does not define showError().">
	</cffunction>

	<!---
	 * Returns the actual validated data.
	--->
	<cffunction name="getValidated" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Validation.Exceptions.ValidationException" message="The validator does not define getValidated().">
	</cffunction>

</cfcomponent>
