<!---
 * Strict Rules.
 *
 * Not ported yet: is_not_unique and is_unique (they need the database).
 *
 * Difference: there is no type of a value, so a number and its text are the
 * same. A rule that wants a string gives false for a list or a map, and
 * passes the other values on. differs and matches compare the text of the two
 * values with Compare(), so 1 and "1" are the same, and "a" and "A" differ.
 *
 * Difference: this component cannot extend or reach the one in the folder
 * above, so it creates it and calls it, as the original does.
--->
<cfcomponent output="no" hint="Strict Rules">

	<!--- the non strict rules --->
	<cfset this.nonStrictRules = "">

	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfset this.nonStrictRules = new_("ColdIgniter\Validation\Rules")>

		<cfreturn this>
	</cffunction>

	<cffunction name="differs" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="otherField" type="string" required="yes">
		<cfargument name="data" type="any" required="yes">
		<cfargument name="error" type="string" required="no" default="">
		<cfargument name="field" type="string" required="no" default="">

		<cfset helper("array")>

		<cfif Find(".", arguments.otherField) GT 0>
			<cfreturn NOT identical_(arguments.str, dot_array_search(arguments.otherField, arguments.data))>
		</cfif>

		<cfif NOT array_key_exists(arguments.otherField, arguments.data)>
			<cfreturn false>
		</cfif>

		<cfif Find(".", arguments.field) GT 0>
			<cfif NOT static_("ColdIgniter\Helpers\Array\ArrayHelper").dotKeyExists(arguments.field, arguments.data)>
				<cfreturn false>
			</cfif>
		<cfelseif NOT array_key_exists(arguments.field, arguments.data)>
			<cfreturn false>
		</cfif>

		<cfreturn NOT identical_(arguments.str, arguments.data[arguments.otherField])>
	</cffunction>

	<cffunction name="equals_" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="val" type="string" required="yes">

		<cfreturn this.nonStrictRules.equals_(arguments.str, arguments.val)>
	</cffunction>

	<cffunction name="exact_length" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="val" type="string" required="yes">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictRules.exact_length(arguments.str, arguments.val)>
	</cffunction>

	<cffunction name="greater_than" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="min" type="string" required="yes">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictRules.greater_than(arguments.str, arguments.min)>
	</cffunction>

	<cffunction name="greater_than_equal_to" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="min" type="string" required="yes">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictRules.greater_than_equal_to(arguments.str, arguments.min)>
	</cffunction>

	<!--- Not ported yet: is_not_unique --->

	<cffunction name="in_list" access="public" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="list" type="string" required="yes">

		<cfif NOT IsSimpleValue(arguments.value)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictRules.in_list(arguments.value, arguments.list)>
	</cffunction>

	<!--- Not ported yet: is_unique --->

	<cffunction name="less_than" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="max" type="string" required="yes">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictRules.less_than(arguments.str, arguments.max)>
	</cffunction>

	<cffunction name="less_than_equal_to" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="max" type="string" required="yes">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictRules.less_than_equal_to(arguments.str, arguments.max)>
	</cffunction>

	<cffunction name="matches" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="otherField" type="string" required="yes">
		<cfargument name="data" type="any" required="yes">
		<cfargument name="error" type="string" required="no" default="">
		<cfargument name="field" type="string" required="no" default="">

		<cfset helper("array")>

		<cfif Find(".", arguments.otherField) GT 0>
			<cfreturn identical_(arguments.str, dot_array_search(arguments.otherField, arguments.data))>
		</cfif>

		<cfif NOT array_key_exists(arguments.otherField, arguments.data)>
			<cfreturn false>
		</cfif>

		<cfif Find(".", arguments.field) GT 0>
			<cfif NOT static_("ColdIgniter\Helpers\Array\ArrayHelper").dotKeyExists(arguments.field, arguments.data)>
				<cfreturn false>
			</cfif>
		<cfelseif NOT array_key_exists(arguments.field, arguments.data)>
			<cfreturn false>
		</cfif>

		<cfreturn identical_(arguments.str, arguments.data[arguments.otherField])>
	</cffunction>

	<cffunction name="max_length" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="val" type="string" required="yes">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictRules.max_length(arguments.str, arguments.val)>
	</cffunction>

	<cffunction name="min_length" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="val" type="string" required="yes">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictRules.min_length(arguments.str, arguments.val)>
	</cffunction>

	<cffunction name="not_equals" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="val" type="string" required="yes">

		<cfreturn this.nonStrictRules.not_equals(arguments.str, arguments.val)>
	</cffunction>

	<cffunction name="not_in_list" access="public" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="list" type="string" required="yes">

		<!--- Difference: there is no null, an empty string is not in the list --->
		<cfif NOT IsSimpleValue(arguments.value)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictRules.not_in_list(arguments.value, arguments.list)>
	</cffunction>

	<cffunction name="required" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfreturn this.nonStrictRules.required(arguments.str)>
	</cffunction>

	<cffunction name="required_with" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">
		<cfargument name="fields" type="string" required="no" default="">
		<cfargument name="data" type="any" required="no" default="">

		<cfreturn this.nonStrictRules.required_with(arguments.str, arguments.fields, arguments.data)>
	</cffunction>

	<cffunction name="required_without" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">
		<cfargument name="otherFields" type="string" required="no" default="">
		<cfargument name="data" type="any" required="no" default="">
		<cfargument name="error" type="string" required="no" default="">
		<cfargument name="field" type="string" required="no" default="">

		<cfreturn this.nonStrictRules.required_without(arguments.str, arguments.otherFields, arguments.data, arguments.error, arguments.field)>
	</cffunction>

	<cffunction name="field_exists" access="public" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="no" default="">
		<cfargument name="param" type="string" required="no" default="">
		<cfargument name="data" type="any" required="no" default="">
		<cfargument name="error" type="string" required="no" default="">
		<cfargument name="field" type="string" required="no" default="">

		<cfif Find(".", arguments.field) GT 0>
			<cfreturn static_("ColdIgniter\Helpers\Array\ArrayHelper").dotKeyExists(arguments.field, arguments.data)>
		</cfif>

		<cfreturn array_key_exists(arguments.field, arguments.data)>
	</cffunction>

</cfcomponent>
