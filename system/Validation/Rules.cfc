<!---
 * Validation Rules.
 *
 * Not ported yet: is_not_unique, is_unique and prepareUniqueQuery, because
 * they need the database. A rule that is not a method here is "not found"
 * (the rule throws ValidationException.forRuleNotFound).
 *
 * Difference: there is no null. An empty string stands in for it, so a
 * rule that tells null from an empty string in the original takes the
 * "present" branch for an empty string here.
 *
 * Difference: the original types of the arguments are not declared.
 * A parameter that is missing is an empty string.
 *
 * Difference: a value that is not a simple value (a list or a map) is
 * turned into the text "Array" where the original casts it to a string,
 * and compared as it is where the original compares it with ===.
 *
 * Difference: the rule "equals" is the method equals_(), because a method
 * named equals clashes with the equals() of every Java object. The
 * Validation component maps the rule name to the method (ruleMethod).
 *
 * Difference: required_with[] and required_without[] with an empty
 * parameter take it as a field name, they do not throw.
 *
 * Difference: every comparison of two numbers goes through spaceship_(),
 * which reads a whole number of 19 digits as a double (see the polyfill).
--->
<cfcomponent output="no" hint="Validation Rules">

	<!---
	 * The value does not match another field in data.
	 *
	 * @param str   string|null
	 * @param field string
	 * @param data  Other field/value pairs
	--->
	<cffunction name="differs" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="field" type="string" required="yes">
		<cfargument name="data" type="any" required="yes">

		<cfset helper("array")>

		<cfif Find(".", arguments.field) GT 0>
			<cfreturn NOT identical_(arguments.str, dot_array_search(arguments.field, arguments.data))>
		</cfif>

		<cfif NOT array_key_exists(arguments.field, arguments.data)>
			<cfreturn false>
		</cfif>

		<cfreturn NOT identical_(arguments.str, arguments.data[arguments.field])>
	</cffunction>

	<!---
	 * Equals the static value provided.
	 *
	 * @param str string|null
	 * @param val string
	--->
	<cffunction name="equals_" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="val" type="string" required="yes">

		<cfset arguments.str = strval(arguments.str)>

		<cfreturn Compare(arguments.str, arguments.val) EQ 0>
	</cffunction>

	<!---
	 * Returns true if str is val characters long.
	 * val = "5" (one) | "5,8,12" (multiple values)
	 *
	 * @param str string|null
	 * @param val string
	--->
	<cffunction name="exact_length" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="val" type="string" required="yes">

		<cfset var parts = "">
		<cfset var tmp = "">
		<cfset var i = 0>

		<cfset arguments.str = strval(arguments.str)>

		<cfset parts = explode(",", arguments.val)>

		<cfloop from="1" to="#ArrayLen(parts)#" index="i">
			<cfset tmp = parts[i]>
			<cfif is_numeric(tmp)>
				<!--- (int) tmp: the fraction is cut off --->
				<cfif Fix(floatval(tmp)) EQ mb_strlen(arguments.str)>
					<cfreturn true>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn false>
	</cffunction>

	<!---
	 * Greater than
	 *
	 * @param str string|null
	 * @param min string
	--->
	<cffunction name="greater_than" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="min" type="string" required="yes">

		<cfset arguments.str = strval(arguments.str)>

		<cfif NOT is_numeric(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn spaceship_(arguments.str, arguments.min) GT 0>
	</cffunction>

	<!---
	 * Equal to or Greater than
	 *
	 * @param str string|null
	 * @param min string
	--->
	<cffunction name="greater_than_equal_to" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="min" type="string" required="yes">

		<cfset arguments.str = strval(arguments.str)>

		<cfif NOT is_numeric(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn spaceship_(arguments.str, arguments.min) GTE 0>
	</cffunction>

	<!---
	 * Checks the database to see if the given value exist.
	 * Can ignore records by field/value to filter (currently
	 * accept only one filter).
	 *
	 *    is_not_unique[dbGroup.table.field,where_field,where_value]
	 *    is_not_unique[table.field,where_field,where_value]
	 *    is_not_unique[menu.id,active,1]
	 *
	 * Not ported yet: is_not_unique, it needs the database.
	--->

	<!---
	 * Value should be within an array of values
	 *
	 * @param value string|null
	 * @param list  string
	--->
	<cffunction name="in_list" access="public" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="list" type="string" required="yes">

		<cfset var parts = "">
		<cfset var i = 0>

		<cfset arguments.value = strval(arguments.value)>

		<cfset parts = explode(",", arguments.list)>

		<cfloop from="1" to="#ArrayLen(parts)#" index="i">
			<cfset parts[i] = trim_(parts[i])>
		</cfloop>

		<cfreturn in_array(arguments.value, parts)>
	</cffunction>

	<!---
	 * Checks the database to see if the given value is unique. Can
	 * ignore a single record by field/value to make it useful during
	 * record updates.
	 *
	 * Example:
	 *    is_unique[dbGroup.table.field,ignore_field,ignore_value]
	 *    is_unique[table.field,ignore_field,ignore_value]
	 *    is_unique[users.email,id,5]
	 *
	 * Not ported yet: is_unique, it needs the database.
	--->

	<!---
	 * Prepares the database query for uniqueness checks.
	 *
	 * Not ported yet: prepareUniqueQuery, it needs the database.
	--->

	<!---
	 * Less than
	 *
	 * @param str string|null
	 * @param max string
	--->
	<cffunction name="less_than" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="max" type="string" required="yes">

		<cfset arguments.str = strval(arguments.str)>

		<cfif NOT is_numeric(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn spaceship_(arguments.str, arguments.max) LT 0>
	</cffunction>

	<!---
	 * Equal to or Less than
	 *
	 * @param str string|null
	 * @param max string
	--->
	<cffunction name="less_than_equal_to" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="max" type="string" required="yes">

		<cfset arguments.str = strval(arguments.str)>

		<cfif NOT is_numeric(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn spaceship_(arguments.str, arguments.max) LTE 0>
	</cffunction>

	<!---
	 * Matches the value of another field in data.
	 *
	 * Difference: the original tests isset(), which is false for a null
	 * value. There is no null here, so the key has to exist.
	 *
	 * @param str   string|null
	 * @param field string
	 * @param data  Other field/value pairs
	--->
	<cffunction name="matches" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="field" type="string" required="yes">
		<cfargument name="data" type="any" required="yes">

		<cfset helper("array")>

		<cfif Find(".", arguments.field) GT 0>
			<cfreturn identical_(arguments.str, dot_array_search(arguments.field, arguments.data))>
		</cfif>

		<cfif NOT array_key_exists(arguments.field, arguments.data)>
			<cfreturn false>
		</cfif>

		<cfreturn identical_(arguments.str, arguments.data[arguments.field])>
	</cffunction>

	<!---
	 * Returns true if str is val or fewer characters in length.
	 *
	 * @param str string|null
	 * @param val string
	--->
	<cffunction name="max_length" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="val" type="string" required="yes">

		<cfset arguments.str = strval(arguments.str)>

		<cfif NOT is_numeric(arguments.val)>
			<cfreturn false>
		</cfif>

		<cfreturn spaceship_(arguments.val, ToString(mb_strlen(arguments.str))) GTE 0>
	</cffunction>

	<!---
	 * Returns true if str is at least val length.
	 *
	 * @param str string|null
	 * @param val string
	--->
	<cffunction name="min_length" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="val" type="string" required="yes">

		<cfset arguments.str = strval(arguments.str)>

		<cfif NOT is_numeric(arguments.val)>
			<cfreturn false>
		</cfif>

		<cfreturn spaceship_(arguments.val, ToString(mb_strlen(arguments.str))) LTE 0>
	</cffunction>

	<!---
	 * Does not equal the static value provided.
	 *
	 * @param str string|null
	 * @param val string
	--->
	<cffunction name="not_equals" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="val" type="string" required="yes">

		<cfset arguments.str = strval(arguments.str)>

		<cfreturn Compare(arguments.str, arguments.val) NEQ 0>
	</cffunction>

	<!---
	 * Value should not be within an array of values.
	 *
	 * @param value string|null
	 * @param list  string
	--->
	<cffunction name="not_in_list" access="public" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="list" type="string" required="yes">

		<cfset arguments.value = strval(arguments.value)>

		<cfreturn NOT in_list(arguments.value, arguments.list)>
	</cffunction>

	<!---
	 * @param str mixed
	--->
	<cffunction name="required" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<!--- Difference: a null is an empty string, which is not present either. --->
		<cfif IsObject(arguments.str)>
			<cfreturn true>
		</cfif>

		<cfif is_array(arguments.str)>
			<cfif IsArray(arguments.str)>
				<cfreturn ArrayLen(arguments.str) NEQ 0>
			</cfif>

			<cfreturn StructCount(arguments.str) NEQ 0>
		</cfif>

		<cfreturn Len(trim_(strval(arguments.str))) NEQ 0>
	</cffunction>

	<!---
	 * The field is required when any of the other required fields are present
	 * in the data.
	 *
	 * Example (field is required when the password field is present):
	 *
	 *     required_with[password]
	 *
	 * @param str    string|null
	 * @param fields string|null List of fields that we should check if present
	 * @param data   Complete list of fields from the form
	--->
	<cffunction name="required_with" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">
		<cfargument name="fields" type="string" required="no" default="">
		<cfargument name="data" type="any" required="no" default="">

		<cfset var present = false>
		<cfset var requiredFields = ArrayNew(1)>
		<cfset var parts = "">
		<cfset var field = "">
		<cfset var found = false>
		<cfset var i = 0>

		<cfset helper("array")>

		<!--- Difference: an empty string is a parameter (required_with[]), not a null. --->
		<cfif isEmptyData(arguments.data)>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="You must supply the parameters: fields, data.">
		</cfif>

		<!---
		 * If the field is present we can safely assume that
		 * the field is here, no matter whether the corresponding
		 * search field is present or not.
		--->
		<cfset present = required(arguments.str)>

		<cfif present>
			<cfreturn true>
		</cfif>

		<!---
		 * Still here? Then we fail this test if
		 * any of the fields are present in data
		 * as fields is the list
		--->
		<cfset parts = explode(",", arguments.fields)>

		<cfloop from="1" to="#ArrayLen(parts)#" index="i">
			<cfset field = parts[i]>
			<cfset found = false>

			<cfif array_key_exists(field, arguments.data)>
				<cfif NOT isBlank(arguments.data[field])>
					<cfset found = true>
				</cfif>
			</cfif>

			<cfif NOT found AND Find(".", field) GT 0>
				<cfif NOT isBlank(dot_array_search(field, arguments.data))>
					<cfset found = true>
				</cfif>
			</cfif>

			<cfif found>
				<cfset ArrayAppend(requiredFields, field)>
			</cfif>
		</cfloop>

		<cfreturn ArrayLen(requiredFields) EQ 0>
	</cffunction>

	<!---
	 * The field is required when all the other fields are present
	 * in the data but not required.
	 *
	 * Example (field is required when the id or email field is missing):
	 *
	 *     required_without[id,email]
	 *
	 * @param str         string|null
	 * @param otherFields string|null The param fields of required_without[].
	 * @param data        array
	 * @param error       string|null
	 * @param field       string|null This rule param fields aren't present, this field is required.
	--->
	<cffunction name="required_without" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">
		<cfargument name="otherFields" type="string" required="no" default="">
		<cfargument name="data" type="any" required="no" default="">
		<cfargument name="error" type="string" required="no" default="">
		<cfargument name="field" type="string" required="no" default="">

		<cfset var present = false>
		<cfset var parts = "">
		<cfset var otherField = "">
		<cfset var fieldData = "">
		<cfset var fieldSplitArray = "">
		<cfset var fieldKey = "">
		<cfset var nowField = "">
		<cfset var nowFieldVaule = "">
		<cfset var i = 0>

		<cfset helper("array")>

		<!--- Difference: an empty string is a parameter (required_without[]), not a null. --->
		<cfif isEmptyData(arguments.data)>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="You must supply the parameters: otherFields, data.">
		</cfif>

		<!---
		 * If the field is present we can safely assume that
		 * the field is here, no matter whether the corresponding
		 * search field is present or not.
		--->
		<cfset present = required(arguments.str)>

		<cfif present>
			<cfreturn true>
		</cfif>

		<!---
		 * Still here? Then we fail this test if
		 * any of the fields are not present in data
		--->
		<cfset parts = explode(",", arguments.otherFields)>

		<cfloop from="1" to="#ArrayLen(parts)#" index="i">
			<cfset otherField = parts[i]>

			<cfif Find(".", otherField) EQ 0>
				<cfif NOT array_key_exists(otherField, arguments.data)>
					<cfreturn false>
				</cfif>

				<cfif isBlank(arguments.data[otherField])>
					<cfreturn false>
				</cfif>
			<cfelse>
				<cfif is_null(arguments.field)>
					<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="You must supply the parameters: field.">
				</cfif>

				<cfset fieldData = dot_array_search(otherField, arguments.data)>
				<cfset fieldSplitArray = explode(".", arguments.field)>

				<cfif ArrayLen(fieldSplitArray) GTE 2>
					<cfset fieldKey = fieldSplitArray[2]>
				<cfelse>
					<cfset fieldKey = "">
				</cfif>

				<cfif is_array(fieldData)>
					<cfif isBlank(itemOrBlank(fieldData, fieldKey))>
						<cfreturn false>
					</cfif>
				<cfelse>
					<cfset nowField = Replace(otherField, "*", fieldKey, "all")>
					<cfset nowFieldVaule = dot_array_search(nowField, arguments.data)>

					<cfif is_null(nowFieldVaule)>
						<cfreturn false>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn true>
	</cffunction>

	<!---
	 * The field exists in data.
	 *
	 * @param value mixed  The field value.
	 * @param param string|null  The rule's parameter.
	 * @param data  The data to be validated.
	 * @param error string|null
	 * @param field string|null  The field name.
	--->
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

	<!---
	 * Whether the value counts as blank for the required_with and
	 * required_without rules.
	 *
	 * The blank values are null, false, 0, 0.0, an empty string, "0" and an
	 * empty array. Any other string is not blank, also "0.0" and " ".
	 *
	 * @param value mixed
	--->
	<cffunction name="isBlank" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfif IsSimpleValue(arguments.value)>
			<cfreturn Compare(arguments.value, "") EQ 0 OR Compare(arguments.value, "0") EQ 0>
		</cfif>

		<cfif IsArray(arguments.value)>
			<cfreturn ArrayLen(arguments.value) EQ 0>
		</cfif>

		<cfif IsStruct(arguments.value)>
			<cfreturn StructCount(arguments.value) EQ 0>
		</cfif>

		<cfreturn false>
	</cffunction>

	<!---
	 * Stands in for "data === []": the data is an empty list or map (or an
	 * empty string, which is what a missing argument is).
	 *
	 * @param data mixed
	--->
	<cffunction name="isEmptyData" access="private" returntype="boolean" output="no">
		<cfargument name="data" type="any" required="yes">

		<cfif IsArray(arguments.data)>
			<cfreturn ArrayLen(arguments.data) EQ 0>
		</cfif>

		<cfif IsStruct(arguments.data)>
			<cfreturn StructCount(arguments.data) EQ 0>
		</cfif>

		<cfreturn true>
	</cffunction>

	<!---
	 * Stands in for "array[key] ?? null": the item of a list or a map, or
	 * an empty string when there is none.
	 *
	 * @param array mixed  A list or a map
	 * @param key   string
	--->
	<cffunction name="itemOrBlank" access="private" returntype="any" output="no">
		<cfargument name="array" type="any" required="yes">
		<cfargument name="key" type="string" required="yes">

		<cfif array_key_exists(arguments.key, arguments.array)>
			<cfif IsArray(arguments.array)>
				<cfreturn arguments.array[Val(arguments.key) + 1]>
			</cfif>

			<cfreturn arguments.array[arguments.key]>
		</cfif>

		<cfreturn "">
	</cffunction>

</cfcomponent>
