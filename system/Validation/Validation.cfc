<!---
 * Validator
 *
 * Not ported yet:
 *  - closures and callables as rules (a rule is a string, run by a rule set)
 *  - the JSON branch of withRequest (6.1 has no JSON parser), it throws
 *  - the rules of CreditCardRules, is_unique and is_not_unique
 *
 * Difference: there is no null. An empty string stands in for it (an empty
 * label, a missing parameter and a missing value). A rule string with
 * empty brackets, like "foo[]", still has a parameter.
 *
 * Difference: an array of the original is a list (ArrayNew) or a map (see
 * array_()). The rules, the errors and the data are maps, and the list of
 * rules of a field is a list.
 *
 * Difference: a rule is called with Evaluate(), after method_exists() found
 * it, because 6.1 cannot call a method by a name held in a variable.
 *
 * Difference: the value of an error message that is a list or a map is written
 * by a small JSON writer here (jsonEncode): every simple value is quoted.
--->
<cfcomponent output="no" extends="ValidationInterface" hint="Validator">

	<!---
	 * Files to load with validation functions.
	 *
	 * @var list<class-string>
	--->
	<cfset this.ruleSetFiles = "">

	<!---
	 * The loaded instances of our validation files.
	 *
	 * @var array<class-string, object>
	--->
	<cfset this.ruleSetInstances = ArrayNew(1)>

	<!---
	 * Stores the actual rules that should be run against data.
	 * ```
	 * [
	 *     field1 => [
	 *         'label' => label,
	 *         'rules' => [
	 *              rule1, rule2, ...
	 *          ],
	 *     ],
	 * ]
	 * ```
	 *
	 * A map of fields, each a map with label (an empty string for none) and
	 * rules (a list of strings).
	--->
	<cfset this.rules = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * The data that should be validated,
	 * where 'key' is the alias, with value.
	 *
	 * @var array<string, mixed>
	--->
	<cfset this.data = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * The data that was actually validated.
	 *
	 * @var array<string, mixed>
	--->
	<cfset this.validated = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Any generated errors during validation.
	 * 'key' is the alias, 'value' is the message.
	 *
	 * @var array<string, string>
	--->
	<cfset this.errors = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Stores custom error message to use
	 * during validation. Where 'key' is the alias.
	 *
	 * @var array<string, array<string, string>>
	--->
	<cfset this.customErrors = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Our configuration.
	 *
	 * @var object{ruleSets: list<class-string>}
	--->
	<cfset this.config = "">

	<!---
	 * The view renderer used to render validation messages.
	 *
	 * @var RendererInterface
	--->
	<cfset this.view = "">

	<!---
	 * Validation constructor.
	 *
	 * @param config object{ruleSets: list<class-string>}
	 * @param view   RendererInterface
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">
		<cfargument name="view" type="any" required="yes">

		<cfset this.ruleSetFiles = arguments.config.ruleSets>
		<cfset this.config = arguments.config>
		<cfset this.view = arguments.view>

		<cfset loadRuleSets()>

		<cfreturn this>
	</cffunction>

	<!---
	 * Runs the validation process, returning true/false determining whether
	 * or not validation was successful.
	 *
	 * @param data    The map of data to validate, an empty string (null) for the data that was set
	 * @param group   The predefined group of rules to apply, an empty string (null) for none
	 * @param dbGroup Reserved name for is_unique and is_not_unique, an empty string (null) for none
	--->
	<cffunction name="run" access="public" returntype="boolean" output="no">
		<cfargument name="data" type="any" required="no" default="">
		<cfargument name="group" type="any" required="no" default="">
		<cfargument name="dbGroup" type="any" required="no" default="">

		<cfset var copy = CreateObject("java", "java.util.LinkedHashMap").init()>
		<cfset var keys = "">
		<cfset var key = "">
		<cfset var fields = "">
		<cfset var field = "">
		<cfset var setup = "">
		<cfset var rules = "">
		<cfset var label = "">
		<cfset var flattenedArray = "">
		<cfset var pattern = "">
		<cfset var values = "">
		<cfset var paths = "">
		<cfset var dotFields = "">
		<cfset var dotField = "">
		<cfset var i = 0>
		<cfset var j = 0>

		<cfif is_null(arguments.data)>
			<cfset arguments.data = this.data>
		<cfelse>
			<!--- Store data to validate. --->
			<cfset this.data = arguments.data>
		</cfif>

		<!--- a copy, so that the data that was given does not get the DBGroup key --->
		<cfif IsArray(arguments.data)>
			<!--- a list has the keys 0, 1, 2 and so on --->
			<cfloop from="1" to="#ArrayLen(arguments.data)#" index="i">
				<cfset copy[ToString(i - 1)] = arguments.data[i]>
			</cfloop>
		<cfelse>
			<cfset keys = array_keys(arguments.data)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset copy[keys[i]] = arguments.data[keys[i]]>
			</cfloop>
		</cfif>

		<!--- `DBGroup` is a reserved name. For is_unique and is_not_unique --->
		<cfset copy["DBGroup"] = arguments.dbGroup>

		<cfset loadRuleGroup(arguments.group)>

		<!---
		 If no rules exist, we return false to ensure
		 the developer didn't forget to set the rules.
		--->
		<cfif StructCount(this.rules) EQ 0>
			<cfreturn false>
		</cfif>

		<!---
		 Replace any placeholders (e.g. {id}) in the rules with
		 the value found in data, if any.
		--->
		<cfset this.rules = fillPlaceholders(this.rules, copy)>

		<!--- Need this for searching arrays in validation. --->
		<cfset helper("array")>

		<!---
		 Run through each rule. If we have any field set for
		 this rule, then we need to run them through!
		--->
		<cfset fields = array_keys(this.rules)>

		<cfloop from="1" to="#ArrayLen(fields)#" index="i">
			<cfset field = fields[i]>
			<cfset setup = this.rules[field]>
			<cfset rules = setup["rules"]>

			<cfif Len(setup["label"]) GT 0>
				<cfset label = setup["label"]>
			<cfelse>
				<cfset label = field>
			</cfif>

			<cfif Find("*", field) GT 0>
				<cfset flattenedArray = array_flatten_with_dots(copy)>
				<cfset pattern = getRegex(field)>
				<cfset values = CreateObject("java", "java.util.LinkedHashMap").init()>
				<cfset keys = array_keys(flattenedArray)>

				<cfloop from="1" to="#ArrayLen(keys)#" index="j">
					<cfif JavaCast("string", keys[j]).matches(pattern)>
						<cfset values[keys[j]] = flattenedArray[keys[j]]>
					</cfif>
				</cfloop>

				<!---
				 Emit null for every leaf path that is structurally reachable
				 but whose key is absent from the data. This mirrors the
				 non-wildcard behaviour where a missing key is treated as null,
				 so that all rules behave consistently regardless of whether
				 the field uses a wildcard or not.
				--->
				<cfset paths = walkForAllPossiblePaths(explode(".", field), copy, "")>

				<cfloop from="1" to="#ArrayLen(paths)#" index="j">
					<cfset values[paths[j]] = "">
				</cfloop>

				<!--- if keys not found --->
				<cfif StructCount(values) EQ 0>
					<cfset values[field] = "">
				</cfif>
			<cfelse>
				<cfset values = dot_array_search(field, copy)>
			</cfif>

			<cfif IsArray(values) AND ArrayLen(values) EQ 0 OR IsStruct(values) AND StructCount(values) EQ 0>
				<!--- We'll process the values right away if an empty array --->
				<cfset processRules(field, label, values, rules, copy, field)>
			<cfelseif Find("*", field) GT 0>
				<!--- Process multiple fields --->
				<cfset dotFields = array_keys(values)>

				<cfloop from="1" to="#ArrayLen(dotFields)#" index="j">
					<cfset dotField = dotFields[j]>

					<cfset processRules(dotField, label, values[dotField], rules, copy, field)>
				</cfloop>
			<cfelse>
				<!--- Process single field --->
				<cfset processRules(field, label, values, rules, copy, field)>
			</cfif>
		</cfloop>

		<cfif StructCount(getErrors()) EQ 0>
			<!--- Store data that was actually validated. --->
			<cfset this.validated = static_("ColdIgniter\Validation\DotArrayFilter").run(array_keys(this.rules), this.data)>

			<cfreturn true>
		</cfif>

		<cfreturn false>
	</cffunction>

	<!---
	 * Returns regex pattern for key with dot array syntax.
	 *
	 * Difference: the pattern is for the Java engine, which anchors it
	 * when it is used with matches().
	--->
	<cffunction name="getRegex" access="private" returntype="string" output="no">
		<cfargument name="field" type="string" required="yes">

		<cfset var text = preg_quote(arguments.field)>

		<cfset text = Replace(text, "\.\*", "\.[^.]+", "all")>
		<cfset text = Replace(text, "\*\.", "[^.]+\.", "all")>

		<cfreturn text>
	</cffunction>

	<!---
	 * Runs the validation process, returning true or false
	 * determining whether or not validation was successful.
	 *
	 * @param value   Value to validate.
	 * @param rules   A string or a list of rules
	 * @param errors  A map of messages, or an empty string for none
	 * @param dbGroup The database group to use, or an empty string (null)
	 *
	 * @return True if valid, else false.
	--->
	<cffunction name="check" access="public" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="rules" type="any" required="yes">
		<cfargument name="errors" type="any" required="no" default="">
		<cfargument name="dbGroup" type="any" required="no" default="">

		<cfset reset()>

		<cfset setRule("check", "", arguments.rules, arguments.errors)>

		<cfreturn run(array_("check", arguments.value), "", arguments.dbGroup)>
	</cffunction>

	<!---
	 * Returns the data that was actually validated.
	--->
	<cffunction name="getValidated" access="public" returntype="any" output="no">
		<cfreturn this.validated>
	</cffunction>

	<!---
	 * Runs all of rules against field, until one fails, or
	 * all of them have been processed. If one fails, it adds
	 * the error to this.errors and moves on to the next,
	 * so that we can collect all of the first errors.
	 *
	 * @param field         The field (a dot path) to process
	 * @param label         The label, or an empty string (null)
	 * @param value         A simple value, a list or a map
	 * @param rules         A list of rules
	 * @param data          The map of data to validate, with `DBGroup`.
	 * @param originalField The original asterisk field name like "foo.*.bar".
	--->
	<cffunction name="processRules" access="private" returntype="boolean" output="no">
		<cfargument name="field" type="string" required="yes">
		<cfargument name="label" type="any" required="no" default="">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="rules" type="any" required="no" default="">
		<cfargument name="data" type="any" required="no" default="">
		<cfargument name="originalField" type="any" required="no" default="">

		<cfset var ruleList = "">
		<cfset var rule = "">
		<cfset var param = "">
		<cfset var hasParam = false>
		<cfset var matcher = "">
		<cfset var error = "">
		<cfset var found = false>
		<cfset var passed = false>
		<cfset var ruleSetInstance = "">
		<cfset var shown = "">
		<cfset var fieldForErrors = "">
		<cfset var i = 0>
		<cfset var j = 0>

		<cfif is_null(arguments.data)>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="You must supply the parameter: data.">
		</cfif>

		<cfset ruleList = processIfExist(arguments.field, arguments.rules, arguments.data)>

		<cfif IsSimpleValue(ruleList)>
			<cfreturn true>
		</cfif>

		<cfset ruleList = processPermitEmpty(arguments.value, ruleList, arguments.data)>

		<cfif IsSimpleValue(ruleList)>
			<cfreturn true>
		</cfif>

		<cfloop from="1" to="#ArrayLen(ruleList)#" index="i">
			<cfset rule = ruleList[i]>

			<!--- Not ported yet: closures and callables as rules --->
			<cfif NOT IsSimpleValue(rule)>
				<cfthrow type="ColdIgniter.Exceptions.LogicException" message="Not ported yet: a rule that is not a string.">
			</cfif>

			<cfset passed = false>
			<cfset param = "">
			<cfset hasParam = false>

			<!--- Difference: anchored at a line start, because the unanchored (.*?)\[(.*)\] is cubic on a long run of "[". The match is the same. --->
			<cfset matcher = CreateObject("java", "java.util.regex.Pattern").compile(JavaCast("string", "(?dm)^([^\[\n]*)\[(.*)\]")).matcher(JavaCast("string", rule))>

			<cfif matcher.find()>
				<cfset rule = matcher.group(JavaCast("int", 1))>
				<cfset param = matcher.group(JavaCast("int", 2))>
				<cfset hasParam = true>
			</cfif>

			<!--- Placeholder for custom errors from the rules. --->
			<cfset error = "">

			<cfset found = false>

			<!--- Check in our rulesets --->
			<cfloop from="1" to="#ArrayLen(this.ruleSetInstances)#" index="j">
				<cfset ruleSetInstance = this.ruleSetInstances[j]>

				<cfif NOT method_exists(ruleSetInstance, ruleMethod(rule))>
					<!--- the next rule set --->
				<cfelse>
					<cfset found = true>

					<cfif Compare(rule, "field_exists") EQ 0>
						<cfset passed = Evaluate("ruleSetInstance.#ruleMethod(rule)#(value, param, data, error, originalField)")>
					<cfelseif NOT hasParam>
						<cfset passed = Evaluate("ruleSetInstance.#ruleMethod(rule)#(value, error)")>
					<cfelse>
						<cfset passed = Evaluate("ruleSetInstance.#ruleMethod(rule)#(value, param, data, error, field)")>
					</cfif>

					<cfbreak>
				</cfif>
			</cfloop>

			<!---
			 If the rule wasn't found anywhere, we
			 should throw an exception so the developer can find it.
			--->
			<cfif NOT found>
				<cfset static_("ColdIgniter\Validation\Exceptions\ValidationException").forRuleNotFound(rule)>
			</cfif>

			<!--- Set the error message if we didn't survive. --->
			<cfif NOT passed>
				<!--- if the value is an array, convert it to as string representation --->
				<cfif IsArray(arguments.value) OR IsStruct(arguments.value)>
					<cfif isStringList(arguments.value)>
						<cfset shown = "[" & implode(", ", toList(arguments.value)) & "]">
					<cfelse>
						<cfset shown = jsonEncode(arguments.value)>
					</cfif>
				<cfelse>
					<cfset shown = arguments.value>
				</cfif>

				<cfif Compare(rule, "field_exists") EQ 0>
					<cfset fieldForErrors = arguments.originalField>
				<cfelse>
					<cfset fieldForErrors = arguments.field>
				</cfif>

				<cfif Len(error) GT 0>
					<cfset this.errors[fieldForErrors] = error>
				<cfelse>
					<cfset this.errors[fieldForErrors] = getErrorMessage(rule, arguments.field, arguments.label, param, shown, arguments.originalField)>
				</cfif>

				<cfreturn false>
			</cfif>
		</cfloop>

		<cfreturn true>
	</cffunction>

	<!---
	 * @param field The field (a dot path)
	 * @param rules A list of rules
	 * @param data  The map of data to validate, with `DBGroup`.
	 *
	 * @return The modified list of rules, or true if we return early
	--->
	<cffunction name="processIfExist" access="private" returntype="any" output="no">
		<cfargument name="field" type="string" required="yes">
		<cfargument name="rules" type="any" required="yes">
		<cfargument name="data" type="any" required="yes">

		<cfset var flattenedData = "">
		<cfset var ifExistField = arguments.field>
		<cfset var dataIsExisting = false>
		<cfset var pattern = "">
		<cfset var keys = "">
		<cfset var filtered = "">
		<cfset var i = 0>

		<cfif in_array("if_exist", arguments.rules)>
			<cfset flattenedData = array_flatten_with_dots(arguments.data)>

			<cfif Find(".*", arguments.field) GT 0>
				<!--- We'll change the dot notation into a pattern that can be used later --->
				<cfset ifExistField = Replace(preg_quote(arguments.field), "\.\*", "\.(?:[^\.]+)", "all")>
				<cfset pattern = CreateObject("java", "java.util.regex.Pattern").compile(JavaCast("string", ifExistField))>
				<cfset keys = array_keys(flattenedData)>

				<cfloop from="1" to="#ArrayLen(keys)#" index="i">
					<cfif pattern.matcher(JavaCast("string", keys[i])).find()>
						<cfset dataIsExisting = true>
						<cfbreak>
					</cfif>
				</cfloop>
			<cfelseif Find(".", arguments.field) GT 0>
				<cfset dataIsExisting = array_key_exists(ifExistField, flattenedData)>
			<cfelse>
				<cfset dataIsExisting = array_key_exists(ifExistField, arguments.data)>
			</cfif>

			<cfif NOT dataIsExisting>
				<!--- we return early if `if_exist` is not satisfied. we have nothing to do here. --->
				<cfreturn true>
			</cfif>

			<!--- Otherwise remove the if_exist rule and continue the process --->
			<cfreturn withoutRule(arguments.rules, "if_exist")>
		</cfif>

		<cfreturn arguments.rules>
	</cffunction>

	<!---
	 * @param value A simple value, a list or a map
	 * @param rules A list of rules
	 * @param data  The map of data to validate, with `DBGroup`.
	 *
	 * @return The modified list of rules, or true if we return early
	--->
	<cffunction name="processPermitEmpty" access="private" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="rules" type="any" required="yes">
		<cfargument name="data" type="any" required="yes">

		<cfset var blank = false>
		<cfset var passed = true>
		<cfset var rule = "">
		<cfset var param = "">
		<cfset var matcher = "">
		<cfset var ruleSetInstance = "">
		<cfset var i = 0>
		<cfset var j = 0>

		<cfif in_array("permit_empty", arguments.rules)>
			<cfif IsArray(arguments.value)>
				<cfset blank = (ArrayLen(arguments.value) EQ 0)>
			<cfelseif IsStruct(arguments.value)>
				<cfset blank = (StructCount(arguments.value) EQ 0)>
			<cfelse>
				<cfset blank = (Compare(trim_(arguments.value), "") EQ 0)>
			</cfif>

			<cfif NOT in_array("required", arguments.rules) AND blank>
				<cfset passed = true>

				<cfloop from="1" to="#ArrayLen(arguments.rules)#" index="i">
					<cfset rule = arguments.rules[i]>

					<cfif NOT IsSimpleValue(rule)>
						<!--- Not ported yet: closures and callables as rules --->
						<cfthrow type="ColdIgniter.Exceptions.LogicException" message="Not ported yet: a rule that is not a string.">
					</cfif>

					<!--- Difference: anchored at a line start, because the unanchored (.*?)\[(.*)\] is cubic on a long run of "[". The match is the same. --->
					<cfset matcher = CreateObject("java", "java.util.regex.Pattern").compile(JavaCast("string", "(?dm)^([^\[\n]*)\[(.*)\]")).matcher(JavaCast("string", rule))>

					<cfif matcher.find()>
						<cfset rule = matcher.group(JavaCast("int", 1))>
						<cfset param = matcher.group(JavaCast("int", 2))>

						<cfif in_array(rule, explode(",", "required_with,required_without"))>
							<!--- Check in our rulesets --->
							<cfloop from="1" to="#ArrayLen(this.ruleSetInstances)#" index="j">
								<cfset ruleSetInstance = this.ruleSetInstances[j]>

								<cfif method_exists(ruleSetInstance, ruleMethod(rule))>
									<cfif passed>
										<cfset passed = Evaluate("ruleSetInstance.#ruleMethod(rule)#(arguments.value, param, arguments.data)")>
									</cfif>

									<cfbreak>
								</cfif>
							</cfloop>
						</cfif>
					</cfif>
				</cfloop>

				<cfif passed>
					<cfreturn true>
				</cfif>
			</cfif>

			<cfreturn withoutRule(arguments.rules, "permit_empty")>
		</cfif>

		<cfreturn arguments.rules>
	</cffunction>

	<!---
	 * The name of the method of a rule.
	 *
	 * Difference: a method cannot be named "equals" (it is a method of every
	 * object), so the rule "equals" is the method "equals_".
	--->
	<cffunction name="ruleMethod" access="private" returntype="string" output="no">
		<cfargument name="rule" type="string" required="yes">

		<cfif Compare(arguments.rule, "equals") EQ 0>
			<cfreturn "equals_">
		</cfif>

		<cfreturn arguments.rule>
	</cffunction>

	<!---
	 * A copy of a list of rules without the rule of a name.
	 *
	 * @param rules A list of rules
	 * @param name  The rule to leave out
	--->
	<cffunction name="withoutRule" access="private" returntype="array" output="no">
		<cfargument name="rules" type="any" required="yes">
		<cfargument name="name" type="string" required="yes">

		<cfset var result = ArrayNew(1)>
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(arguments.rules)#" index="i">
			<cfif NOT IsSimpleValue(arguments.rules[i]) OR Compare(arguments.rules[i], arguments.name) NEQ 0>
				<cfset ArrayAppend(result, arguments.rules[i])>
			</cfif>
		</cfloop>

		<cfreturn result>
	</cffunction>

	<!---
	 * Is the array a string list `list<string>`?
	 *
	 * Difference: a map with the keys "0", "1" and so on in that order is a
	 * list too, as the array of the original is.
	 *
	 * @param array A list or a map
	--->
	<cffunction name="isStringList" access="private" returntype="boolean" output="no">
		<cfargument name="array" type="any" required="yes">

		<cfset var keys = "">
		<cfset var expectedKey = 0>
		<cfset var i = 0>

		<cfif IsArray(arguments.array)>
			<cfloop from="1" to="#ArrayLen(arguments.array)#" index="i">
				<cfif NOT IsSimpleValue(arguments.array[i])>
					<cfreturn false>
				</cfif>
			</cfloop>

			<cfreturn true>
		</cfif>

		<cfset keys = array_keys(arguments.array)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfif Compare(keys[i], expectedKey) NEQ 0>
				<cfreturn false>
			</cfif>

			<cfset expectedKey = expectedKey + 1>

			<cfif NOT IsSimpleValue(arguments.array[keys[i]])>
				<cfreturn false>
			</cfif>
		</cfloop>

		<cfreturn true>
	</cffunction>

	<!---
	 * The values of a list, or of a map in the order of its keys.
	 *
	 * @param array A list or a map
	--->
	<cffunction name="toList" access="private" returntype="array" output="no">
		<cfargument name="array" type="any" required="yes">

		<cfset var result = ArrayNew(1)>
		<cfset var keys = "">
		<cfset var i = 0>

		<cfif IsArray(arguments.array)>
			<cfreturn arguments.array>
		</cfif>

		<cfset keys = array_keys(arguments.array)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset ArrayAppend(result, arguments.array[keys[i]])>
		</cfloop>

		<cfreturn result>
	</cffunction>

	<!---
	 * A JSON text of a value, as json_encode() writes it.
	 *
	 * Difference: every simple value is a string, because a number and its
	 * text cannot be told apart. A character outside ASCII is written as
	 * \u and four hexadecimal digits, a slash is escaped.
	 *
	 * @param value A simple value, a list or a map
	--->
	<cffunction name="jsonEncode" access="private" returntype="string" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfset var result = "">
		<cfset var keys = "">
		<cfset var text = "">
		<cfset var char = "">
		<cfset var code = 0>
		<cfset var i = 0>

		<cfif IsArray(arguments.value)>
			<cfloop from="1" to="#ArrayLen(arguments.value)#" index="i">
				<cfif i GT 1>
					<cfset result = result & ",">
				</cfif>

				<cfset result = result & jsonEncode(arguments.value[i])>
			</cfloop>

			<cfreturn "[" & result & "]">
		</cfif>

		<cfif IsStruct(arguments.value)>
			<cfif StructCount(arguments.value) GT 0 AND isStringListKeys(arguments.value)>
				<cfreturn jsonEncode(toList(arguments.value))>
			</cfif>

			<cfset keys = array_keys(arguments.value)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfif i GT 1>
					<cfset result = result & ",">
				</cfif>

				<cfset result = result & jsonEncode(keys[i]) & ":" & jsonEncode(arguments.value[keys[i]])>
			</cfloop>

			<cfreturn "{" & result & "}">
		</cfif>

		<cfset text = arguments.value>

		<cfloop from="1" to="#Len(text)#" index="i">
			<cfset char = Mid(text, i, 1)>
			<cfset code = Asc(char)>

			<cfif Compare(char, """") EQ 0>
				<cfset result = result & "\""">
			<cfelseif Compare(char, "\") EQ 0>
				<cfset result = result & "\\">
			<cfelseif Compare(char, "/") EQ 0>
				<cfset result = result & "\/">
			<cfelseif code EQ 8>
				<cfset result = result & "\b">
			<cfelseif code EQ 9>
				<cfset result = result & "\t">
			<cfelseif code EQ 10>
				<cfset result = result & "\n">
			<cfelseif code EQ 12>
				<cfset result = result & "\f">
			<cfelseif code EQ 13>
				<cfset result = result & "\r">
			<cfelseif code LT 32 OR code GT 126>
				<cfset result = result & "\u" & RepeatString("0", 4 - Len(FormatBaseN(code, 16))) & LCase(FormatBaseN(code, 16))>
			<cfelse>
				<cfset result = result & char>
			</cfif>
		</cfloop>

		<cfreturn """" & result & """">
	</cffunction>

	<!---
	 * Whether the keys of a map are "0", "1" and so on, in that order.
	 *
	 * @param array A map
	--->
	<cffunction name="isStringListKeys" access="private" returntype="boolean" output="no">
		<cfargument name="array" type="any" required="yes">

		<cfset var keys = array_keys(arguments.array)>
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfif Compare(keys[i], i - 1) NEQ 0>
				<cfreturn false>
			</cfif>
		</cfloop>

		<cfreturn true>
	</cffunction>

	<!---
	 * Takes a Request object and grabs the input data to use from its
	 * array values.
	 *
	 * Not ported yet: a request with a JSON body (6.1 has no JSON parser).
	 * It throws, as the original does for a body that is not an array.
	 *
	 * @param request_ The request (IncomingRequest)
	--->
	<cffunction name="withRequest" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">

		<cfset var contentType = arguments.request_.getHeaderLine("Content-Type")>
		<cfset var input = "">

		<cfif Find("application/json", contentType) GT 0>
			<cfthrow type="ColdIgniter.HTTP.Exceptions.HTTPException" message="Provided JSON format is not supported.">
		</cfif>

		<cfif ListFindNoCase("PUT,PATCH,DELETE", arguments.request_.getMethod()) GT 0 AND Find("multipart/form-data", contentType) EQ 0>
			<cfset input = arguments.request_.getRawInput()>
		<cfelse>
			<cfset input = arguments.request_.getVar()>
		</cfif>

		<cfif is_null(input)>
			<cfset input = CreateObject("java", "java.util.LinkedHashMap").init()>
		</cfif>

		<cfset this.data = input>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets an individual rule and custom error messages for a single field.
	 *
	 * The custom error message should be just the messages that apply to
	 * this field, like so:
	 *
	 *    errors = array_("required", "You must have this field.")
	 *
	 * @param field  The field name
	 * @param label  The field label, or an empty string (null)
	 * @param rules  A string or a list of rules
	 * @param errors A map of messages, or an empty string for none
	--->
	<cffunction name="setRule" access="public" returntype="any" output="no">
		<cfargument name="field" type="any" required="yes">
		<cfargument name="label" type="any" required="yes">
		<cfargument name="rules" type="any" required="yes">
		<cfargument name="errors" type="any" required="no" default="">

		<cfset var ruleSet = array_("label", arguments.label, "rules", arguments.rules)>
		<cfset var merged = CreateObject("java", "java.util.LinkedHashMap").init()>
		<cfset var current = getRules()>
		<cfset var keys = array_keys(current)>
		<cfset var i = 0>

		<cfif NOT IsSimpleValue(arguments.rules) AND NOT IsArray(arguments.rules)>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="$rules must be of type string|array">
		</cfif>

		<cfif NOT is_null(arguments.errors)>
			<cfset ruleSet["errors"] = arguments.errors>
		</cfif>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset merged[keys[i]] = current[keys[i]]>
		</cfloop>

		<cfset merged[arguments.field] = ruleSet>

		<cfset setRules(merged, this.customErrors)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Stores the rules that should be used to validate the items.
	 *
	 * @param rules    A map of fields. A field is a string of rules, a list of
	 *                 rules, or a map with rules (a string or a list), label
	 *                 and errors.
	 * @param messages A map of custom messages, or an empty string for none
	--->
	<cffunction name="setRules" access="public" returntype="any" output="no">
		<cfargument name="rules" type="any" required="yes">
		<cfargument name="messages" type="any" required="no" default="">

		<cfset var newRules = CreateObject("java", "java.util.LinkedHashMap").init()>
		<cfset var errors = CreateObject("java", "java.util.LinkedHashMap").init()>
		<cfset var keys = "">
		<cfset var field = "">
		<cfset var rule = "">
		<cfset var ruleList = "">
		<cfset var label = "">
		<cfset var entry = "">
		<cfset var i = 0>

		<cfif NOT is_null(arguments.messages)>
			<cfset keys = array_keys(arguments.messages)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset errors[keys[i]] = arguments.messages[keys[i]]>
			</cfloop>
		</cfif>

		<cfset keys = array_keys(arguments.rules)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset field = keys[i]>
			<cfset rule = arguments.rules[field]>
			<cfset label = "">
			<cfset ruleList = "">

			<cfif IsStruct(rule)>
				<cfif StructKeyExists(rule, "errors")>
					<cfset errors[field] = rule["errors"]>
				</cfif>

				<cfif StructKeyExists(rule, "label") AND IsSimpleValue(rule["label"])>
					<cfset label = rule["label"]>
				</cfif>

				<!--- Difference: a map without rules has no rules --->
				<cfif StructKeyExists(rule, "rules")>
					<cfset ruleList = rule["rules"]>
				<cfelse>
					<cfset ruleList = ArrayNew(1)>
				</cfif>
			<cfelse>
				<!--- a string of rules, or a list of rules --->
				<cfset ruleList = rule>
			</cfif>

			<cfif IsSimpleValue(ruleList)>
				<cfset ruleList = splitRules(ruleList)>
			<cfelse>
				<cfset ruleList = withoutRule(ruleList, Chr(0))>
			</cfif>

			<cfset entry = array_("label", label, "rules", ruleList)>
			<cfset newRules[field] = entry>
		</cfloop>

		<cfset this.customErrors = errors>
		<cfset this.rules = newRules>

		<cfreturn this>
	</cffunction>

	<!---
	 * Returns the rules that have been set.
	--->
	<cffunction name="getRules" access="public" returntype="any" output="no">
		<cfreturn this.rules>
	</cffunction>

	<!---
	 * Checks to see if the rule for key field has been set or not.
	 *
	 * @param field The field name
	--->
	<cffunction name="hasRule" access="public" returntype="boolean" output="no">
		<cfargument name="field" type="any" required="yes">

		<cfreturn array_key_exists(arguments.field, this.rules)>
	</cffunction>

	<!---
	 * Get rule group.
	 *
	 * @param group Group.
	 *
	 * @return Rule group.
	 *
	 * @throws ValidationException If group not found.
	--->
	<cffunction name="getRuleGroup" access="public" returntype="any" output="no">
		<cfargument name="group" type="any" required="yes">

		<cfif NOT StructKeyExists(this.config, arguments.group) OR is_null(this.config[arguments.group])>
			<cfset static_("ColdIgniter\Validation\Exceptions\ValidationException").forGroupNotFound(arguments.group)>
		</cfif>

		<cfif NOT is_array(this.config[arguments.group])>
			<cfset static_("ColdIgniter\Validation\Exceptions\ValidationException").forGroupNotArray(arguments.group)>
		</cfif>

		<cfreturn this.config[arguments.group]>
	</cffunction>

	<!---
	 * Set rule group.
	 *
	 * @param group Group.
	 *
	 * @throws ValidationException If group not found.
	--->
	<cffunction name="setRuleGroup" access="public" returntype="void" output="no">
		<cfargument name="group" type="any" required="yes">

		<cfset var rules = getRuleGroup(arguments.group)>
		<cfset var errorName = arguments.group & "_errors">

		<cfset setRules(rules)>

		<cfif StructKeyExists(this.config, errorName) AND NOT is_null(this.config[errorName])>
			<cfset this.customErrors = this.config[errorName]>
		</cfif>
	</cffunction>

	<!---
	 * Returns the rendered HTML of the errors as defined in template.
	 *
	 * You can also use validation_list_errors() in Form helper.
	 *
	 * @param template The name of a template of the config
	--->
	<cffunction name="listErrors" access="public" returntype="string" output="no">
		<cfargument name="template" type="any" required="no" default="list">

		<cfif NOT array_key_exists(arguments.template, this.config.templates)>
			<cfset static_("ColdIgniter\Validation\Exceptions\ValidationException").forInvalidTemplate(arguments.template)>
		</cfif>

		<cfset this.view.setVar("errors", getErrors())>

		<cfreturn this.view.render(this.config.templates[arguments.template])>
	</cffunction>

	<!---
	 * Displays a single error in formatted HTML as defined in the template view.
	 *
	 * You can also use validation_show_error() in Form helper.
	 *
	 * @param field    The field name
	 * @param template The name of a template of the config
	--->
	<cffunction name="showError" access="public" returntype="string" output="no">
		<cfargument name="field" type="any" required="yes">
		<cfargument name="template" type="any" required="no" default="single">

		<cfif NOT array_key_exists(arguments.field, getErrors())>
			<cfreturn "">
		</cfif>

		<cfif NOT array_key_exists(arguments.template, this.config.templates)>
			<cfset static_("ColdIgniter\Validation\Exceptions\ValidationException").forInvalidTemplate(arguments.template)>
		</cfif>

		<cfset this.view.setVar("error", getError(arguments.field))>

		<cfreturn this.view.render(this.config.templates[arguments.template])>
	</cffunction>

	<!---
	 * Loads all of the rulesets classes that have been defined in the
	 * Config\Validation and stores them locally so we can use them.
	--->
	<cffunction name="loadRuleSets" access="private" returntype="any" output="no">
		<cfset var i = 0>

		<cfif NOT IsArray(this.ruleSetFiles) OR ArrayLen(this.ruleSetFiles) EQ 0>
			<cfset static_("ColdIgniter\Validation\Exceptions\ValidationException").forNoRuleSets()>
		</cfif>

		<cfloop from="1" to="#ArrayLen(this.ruleSetFiles)#" index="i">
			<cfset ArrayAppend(this.ruleSetInstances, new_(this.ruleSetFiles[i]))>
		</cfloop>

		<cfreturn "">
	</cffunction>

	<!---
	 * Loads a group of rules (see setRuleGroup), and the errors of the group.
	 *
	 * @param group The name of the group, or an empty string (null)
	 *
	 * @return An empty list for no group, otherwise a list of the rules and the custom errors
	--->
	<cffunction name="loadRuleGroup" access="public" returntype="any" output="no">
		<cfargument name="group" type="any" required="no" default="">

		<cfset var errorName = arguments.group & "_errors">
		<cfset var result = ArrayNew(1)>

		<cfif is_null(arguments.group)>
			<cfreturn result>
		</cfif>

		<cfif NOT StructKeyExists(this.config, arguments.group) OR is_null(this.config[arguments.group])>
			<cfset static_("ColdIgniter\Validation\Exceptions\ValidationException").forGroupNotFound(arguments.group)>
		</cfif>

		<cfif NOT is_array(this.config[arguments.group])>
			<cfset static_("ColdIgniter\Validation\Exceptions\ValidationException").forGroupNotArray(arguments.group)>
		</cfif>

		<cfset setRules(this.config[arguments.group])>

		<!---
		 If {group}_errors exists in the config file,
		 then override our custom errors with them.
		--->
		<cfif StructKeyExists(this.config, errorName) AND NOT is_null(this.config[errorName])>
			<cfset this.customErrors = this.config[errorName]>
		</cfif>

		<cfset ArrayAppend(result, this.rules)>
		<cfset ArrayAppend(result, this.customErrors)>

		<cfreturn result>
	</cffunction>

	<!---
	 * Replace any placeholders within the rules with the values that
	 * match the 'key' of any properties being set. For example, if
	 * we had the following data map:
	 *
	 * [ 'id' => 13 ]
	 *
	 * and the following rule:
	 *
	 *  'is_unique[users,email,id,{id}]'
	 *
	 * The value of {id} would be replaced with the actual id in the form data:
	 *
	 *  'is_unique[users,email,id,13]'
	 *
	 * @param rules The map of fields, each a map with label and rules
	 * @param data  The map of data, with `DBGroup`.
	 *
	 * @return The map of fields
	--->
	<cffunction name="fillPlaceholders" access="private" returntype="any" output="no">
		<cfargument name="rules" type="any" required="yes">
		<cfargument name="data" type="any" required="yes">

		<cfset var fields = array_keys(arguments.rules)>
		<cfset var setup = "">
		<cfset var ruleSet = "">
		<cfset var row = "">
		<cfset var placeholderFields = "">
		<cfset var field = "">
		<cfset var validator = "">
		<cfset var placeholderRules = "">
		<cfset var dbGroup = "">
		<cfset var i = 0>
		<cfset var j = 0>
		<cfset var k = 0>
		<cfset var m = 0>

		<cfloop from="1" to="#ArrayLen(fields)#" index="i">
			<cfset setup = arguments.rules[fields[i]]>
			<cfset ruleSet = setup["rules"]>

			<cfloop from="1" to="#ArrayLen(ruleSet)#" index="j">
				<cfset row = ruleSet[j]>

				<cfif IsSimpleValue(row)>
					<cfset placeholderFields = retrievePlaceholders(row, arguments.data)>

					<cfloop from="1" to="#ArrayLen(placeholderFields)#" index="k">
						<cfset field = placeholderFields[k]>

						<cfif NOT IsObject(validator)>
							<cfset validator = service("validation", "", false)>
						</cfif>

						<cfif array_key_exists(field, arguments.rules)>
							<cfset placeholderRules = arguments.rules[field]["rules"]>
						<cfelse>
							<cfset placeholderRules = "">
						</cfif>

						<!--- Check if the validation rule for the placeholder exists --->
						<cfif is_null(placeholderRules)>
							<cfthrow type="ColdIgniter.Exceptions.LogicException" message="No validation rules for the placeholder: ""#field#"". You must set the validation rules for the field. See <https://codeigniter4.github.io/userguide/libraries/validation.html##validation-placeholders>.">
						</cfif>

						<!--- Check if the rule does not have placeholders --->
						<cfloop from="1" to="#ArrayLen(placeholderRules)#" index="m">
							<cfif IsSimpleValue(placeholderRules[m]) AND ArrayLen(retrievePlaceholders(placeholderRules[m], arguments.data)) GT 0>
								<cfthrow type="ColdIgniter.Exceptions.LogicException" message="The placeholder field cannot use placeholder: #field#">
							</cfif>
						</cfloop>

						<!--- Validate the placeholder field --->
						<cfset dbGroup = "">

						<cfif array_key_exists("DBGroup", arguments.data)>
							<cfset dbGroup = arguments.data["DBGroup"]>
						</cfif>

						<!--- if fails, do nothing --->
						<cfif validator.check(arguments.data[field], placeholderRules, "", dbGroup)>
							<!--- Replace the placeholder in the current rule string --->
							<cfif Compare(Left(row, 12), "regex_match[") EQ 0>
								<cfset row = Replace(row, "{{" & field & "}}", strval(arguments.data[field]), "all")>
							<cfelse>
								<cfset row = Replace(row, "{" & field & "}", strval(arguments.data[field]), "all")>
							</cfif>

							<cfset ruleSet[j] = row>
						</cfif>
					</cfloop>
				</cfif>
			</cfloop>

			<!--- an assignment copies a list, so it is put back --->
			<cfset setup["rules"] = ruleSet>
		</cfloop>

		<cfreturn arguments.rules>
	</cffunction>

	<!---
	 * Retrieves valid placeholder fields.
	 *
	 * @param rule The rule string
	 * @param data The map of data
	 *
	 * @return A list of the names
	--->
	<cffunction name="retrievePlaceholders" access="private" returntype="array" output="no">
		<cfargument name="rule" type="string" required="yes">
		<cfargument name="data" type="any" required="yes">

		<cfset var result = ArrayNew(1)>
		<cfset var pattern = "(?d)\{(.+?)\}">
		<cfset var matcher = "">

		<cfif Compare(Left(arguments.rule, 12), "regex_match[") EQ 0>
			<!--- For regex_match rules, only look for double-bracket placeholders --->
			<cfset pattern = "(?d)\{\{((?:(?![{}]).)+?)\}\}">
		</cfif>

		<!--- For all other rules, use single-bracket placeholders --->
		<cfset matcher = CreateObject("java", "java.util.regex.Pattern").compile(JavaCast("string", pattern)).matcher(JavaCast("string", arguments.rule))>

		<cfloop condition="matcher.find()">
			<cfif array_key_exists(matcher.group(JavaCast("int", 1)), arguments.data)>
				<cfset ArrayAppend(result, matcher.group(JavaCast("int", 1)))>
			</cfif>
		</cfloop>

		<cfreturn result>
	</cffunction>

	<!---
	 * Checks to see if an error exists for the given field.
	 *
	 * @param field The field name
	--->
	<cffunction name="hasError" access="public" returntype="boolean" output="no">
		<cfargument name="field" type="any" required="yes">

		<cfset var pattern = getRegex(arguments.field)>
		<cfset var keys = array_keys(getErrors())>
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfif JavaCast("string", keys[i]).matches(pattern)>
				<cfreturn true>
			</cfif>
		</cfloop>

		<cfreturn false>
	</cffunction>

	<!---
	 * Returns the error(s) for a specified field (or empty string if not
	 * set).
	 *
	 * @param field The field name, or an empty string (null)
	--->
	<cffunction name="getError" access="public" returntype="string" output="no">
		<cfargument name="field" type="any" required="no" default="">

		<cfset var errors = getErrors()>
		<cfset var keys = array_keys(errors)>
		<cfset var pattern = "">
		<cfset var result = ArrayNew(1)>
		<cfset var first = "">
		<cfset var i = 0>

		<cfif is_null(arguments.field) AND StructCount(this.rules) EQ 1>
			<cfset first = array_keys(this.rules)>
			<cfset arguments.field = first[1]>
		</cfif>

		<cfset pattern = getRegex(arguments.field)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfif JavaCast("string", keys[i]).matches(pattern)>
				<cfset ArrayAppend(result, errors[keys[i]])>
			</cfif>
		</cfloop>

		<cfreturn implode(Chr(10), result)>
	</cffunction>

	<!---
	 * Returns the map of errors that were encountered during
	 * a run() call. The map should be in the following format:
	 *
	 *    [
	 *        'field1' => 'error message',
	 *        'field2' => 'error message',
	 *    ]
	 *
	 * @return array<string, string>
	--->
	<cffunction name="getErrors" access="public" returntype="any" output="no">
		<cfreturn this.errors>
	</cffunction>

	<!---
	 * Sets the error for a specific field. Used by custom validation methods.
	 *
	 * @param field The field name
	 * @param error The message
	--->
	<cffunction name="setError" access="public" returntype="any" output="no">
		<cfargument name="field" type="any" required="yes">
		<cfargument name="error" type="any" required="yes">

		<cfset this.errors[arguments.field] = arguments.error>

		<cfreturn this>
	</cffunction>

	<!---
	 * Attempts to find the appropriate error message
	 *
	 * @param rule          The rule name
	 * @param field         The field name
	 * @param label         The label, or an empty string (null)
	 * @param param         The parameter of the rule, or an empty string (null)
	 * @param value         The value that caused the validation to fail.
	 * @param originalField The original asterisk field name, or an empty string (null)
	--->
	<cffunction name="getErrorMessage" access="private" returntype="string" output="no">
		<cfargument name="rule" type="string" required="yes">
		<cfargument name="field" type="string" required="yes">
		<cfargument name="label" type="any" required="no" default="">
		<cfargument name="param" type="any" required="no" default="">
		<cfargument name="value" type="any" required="no" default="">
		<cfargument name="originalField" type="any" required="no" default="">

		<cfset var args = array_("field", arguments.field, "param", arguments.param, "value", arguments.value)>
		<cfset var custom = "">

		<cfif NOT is_null(arguments.label)>
			<cfset args["field"] = lang(arguments.label)>
		</cfif>

		<cfif array_key_exists(arguments.param, this.rules)>
			<cfif Len(this.rules[arguments.param]["label"]) GT 0>
				<cfset args["param"] = lang(this.rules[arguments.param]["label"])>
			</cfif>
		</cfif>

		<!--- Check if custom message has been defined by user --->
		<cfset custom = findCustomError(arguments.field, arguments.rule)>

		<cfif Len(custom) GT 0>
			<cfreturn lang(custom, args)>
		</cfif>

		<cfif NOT is_null(arguments.originalField)>
			<cfset custom = findCustomError(arguments.originalField, arguments.rule)>

			<cfif Len(custom) GT 0>
				<cfreturn lang(custom, args)>
			</cfif>
		</cfif>

		<!---
		 Try to grab a localized version of the message...
		 lang() will return the rule name back if not found,
		 so there will always be a string being returned.
		--->
		<cfreturn lang("Validation." & arguments.rule, args)>
	</cffunction>

	<!---
	 * The custom message of a field for a rule, or an empty string.
	 *
	 * @param field The field name
	 * @param rule  The rule name
	--->
	<cffunction name="findCustomError" access="private" returntype="string" output="no">
		<cfargument name="field" type="string" required="yes">
		<cfargument name="rule" type="string" required="yes">

		<cfset var found = "">

		<cfif array_key_exists(arguments.field, this.customErrors)>
			<cfif IsStruct(this.customErrors[arguments.field])>
				<cfif StructKeyExists(this.customErrors[arguments.field], arguments.rule)>
					<cfset found = this.customErrors[arguments.field][arguments.rule]>
				</cfif>
			</cfif>
		</cfif>

		<cfreturn found>
	</cffunction>

	<!---
	 * Split rules string by pipe operator.
	 *
	 * Difference: a bracket that is never closed ends the loop at the end of
	 * the string, where the original does not stop.
	 *
	 * @param rules The string of rules
	 *
	 * @return A list of rules
	--->
	<cffunction name="splitRules" access="private" returntype="array" output="no">
		<cfargument name="rules" type="string" required="yes">

		<cfset var string = arguments.rules>
		<cfset var result = ArrayNew(1)>
		<cfset var length = Len(arguments.rules)>
		<cfset var cursor = 0>
		<cfset var pos = 0>
		<cfset var next = 0>
		<cfset var rule = "">

		<cfif Find("|", arguments.rules) EQ 0>
			<cfset ArrayAppend(result, arguments.rules)>

			<cfreturn result>
		</cfif>

		<cfloop condition="cursor LT length">
			<cfset pos = Find("|", string, cursor + 1) - 1>

			<cfif pos LT 0>
				<!--- we're in the last rule --->
				<cfset pos = length>
			</cfif>

			<cfset rule = substr(string, cursor, pos - cursor)>

			<cfloop condition="countOf(rule, '[') - countOf(rule, '\[') NEQ countOf(rule, ']') - countOf(rule, '\]') AND pos LT length">
				<!---
				 the pipe is inside the brackets causing the closing bracket to
				 not be included. so, we adjust the rule to include that portion.
				--->
				<cfset next = 0>

				<cfif cursor + Len(rule) + 2 LTE length>
					<cfset next = Find("|", string, cursor + Len(rule) + 2)>
				</cfif>

				<cfif next EQ 0>
					<cfset pos = length>
				<cfelse>
					<cfset pos = next - 1>
				</cfif>

				<cfset rule = substr(string, cursor, pos - cursor)>
			</cfloop>

			<cfset ArrayAppend(result, rule)>

			<cfset cursor = cursor + Len(rule) + 1>
		</cfloop>

		<cfreturn array_unique(result)>
	</cffunction>

	<!---
	 * Counts the places of a text in another (substr_count).
	 *
	 * @param text The text to look in
	 * @param part The text to count
	--->
	<cffunction name="countOf" access="private" returntype="numeric" output="no">
		<cfargument name="text" type="string" required="yes">
		<cfargument name="part" type="string" required="yes">

		<cfreturn (Len(arguments.text) - Len(Replace(arguments.text, arguments.part, "", "all"))) / Len(arguments.part)>
	</cffunction>

	<!---
	 * Entry point: allocates a single accumulator and delegates to the
	 * recursive collector.
	 *
	 * @param segments A list of strings
	 * @param current  The data (a list or a map)
	 * @param prefix   The path so far
	 *
	 * @return A list of strings
	--->
	<cffunction name="walkForAllPossiblePaths" access="private" returntype="array" output="no">
		<cfargument name="segments" type="array" required="yes">
		<cfargument name="current" type="any" required="yes">
		<cfargument name="prefix" type="string" required="yes">

		<cfset var result = ArrayNew(1)>

		<cfset collectMissingPaths(arguments.segments, 0, ArrayLen(arguments.segments), arguments.current, arguments.prefix, result)>

		<cfreturn result>
	</cffunction>

	<!---
	 * Recursively walks the data structure, expanding wildcard segments over
	 * all array keys, and appends to result (a list, which is shared). Only
	 * concrete leaf paths where the key is genuinely absent are recorded -
	 * intermediate missing segments are silently skipped so `*` never appears
	 * in a result.
	 *
	 * @param segments     A list of strings
	 * @param index        The segment to look at, from zero
	 * @param segmentCount The number of segments
	 * @param current      The data at this point (a list or a map)
	 * @param prefix       The path so far
	 * @param result       A list of strings
	--->
	<cffunction name="collectMissingPaths" access="private" returntype="any" output="no">
		<cfargument name="segments" type="array" required="yes">
		<cfargument name="index" type="numeric" required="yes">
		<cfargument name="segmentCount" type="numeric" required="yes">
		<cfargument name="current" type="any" required="yes">
		<cfargument name="prefix" type="string" required="yes">
		<cfargument name="result" type="array" required="yes">

		<cfset var segment = "">
		<cfset var nextIndex = arguments.index + 1>
		<cfset var keys = "">
		<cfset var key = "">
		<cfset var value = "">
		<cfset var keyPrefix = "">
		<cfset var newPrefix = "">
		<cfset var next = "">
		<cfset var i = 0>

		<cfif arguments.index GTE arguments.segmentCount>
			<!--- Successfully navigated every segment - the path exists in the data. --->
			<cfreturn "">
		</cfif>

		<cfset segment = arguments.segments[arguments.index + 1]>

		<cfif Compare(segment, "*") EQ 0>
			<cfif NOT is_array(arguments.current)>
				<cfreturn "">
			</cfif>

			<cfif IsArray(arguments.current)>
				<cfset keys = ArrayNew(1)>

				<cfloop from="1" to="#ArrayLen(arguments.current)#" index="i">
					<cfset ArrayAppend(keys, i - 1)>
				</cfloop>
			<cfelse>
				<cfset keys = array_keys(arguments.current)>
			</cfif>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset key = keys[i]>

				<cfif IsArray(arguments.current)>
					<cfset value = arguments.current[i]>
				<cfelse>
					<cfset value = arguments.current[key]>
				</cfif>

				<cfif Len(arguments.prefix) GT 0>
					<cfset keyPrefix = arguments.prefix & "." & key>
				<cfelse>
					<cfset keyPrefix = key>
				</cfif>

				<!---
				 Non-array elements with remaining segments are a structural
				 mismatch (e.g. the DBGroup sentinel, scalar siblings) - skip.
				--->
				<cfif is_array(value) OR nextIndex GTE arguments.segmentCount>
					<cfset collectMissingPaths(arguments.segments, nextIndex, arguments.segmentCount, value, keyPrefix, arguments.result)>
				</cfif>
			</cfloop>

			<cfreturn "">
		</cfif>

		<cfif Len(arguments.prefix) GT 0>
			<cfset newPrefix = arguments.prefix & "." & segment>
		<cfelse>
			<cfset newPrefix = segment>
		</cfif>

		<cfif NOT is_array(arguments.current)>
			<cfset next = false>
		<cfelse>
			<cfset next = array_key_exists(segment, arguments.current)>
		</cfif>

		<cfif NOT next>
			<!---
			 Only record a missing path for the leaf key. When an intermediate
			 segment is absent there is nothing to validate in that branch,
			 so skip it to avoid false-positive errors.
			--->
			<cfif nextIndex EQ arguments.segmentCount>
				<cfset ArrayAppend(arguments.result, newPrefix)>
			</cfif>

			<cfreturn "">
		</cfif>

		<cfif IsArray(arguments.current)>
			<cfset value = arguments.current[Val(segment) + 1]>
		<cfelse>
			<cfset value = arguments.current[segment]>
		</cfif>

		<cfset collectMissingPaths(arguments.segments, nextIndex, arguments.segmentCount, value, newPrefix, arguments.result)>

		<cfreturn "">
	</cffunction>

	<!---
	 * Resets the class to a blank slate. Should be called whenever
	 * you need to process more than one array.
	--->
	<cffunction name="reset" access="public" returntype="any" output="no">
		<cfset this.data = CreateObject("java", "java.util.LinkedHashMap").init()>
		<cfset this.validated = CreateObject("java", "java.util.LinkedHashMap").init()>
		<cfset this.rules = CreateObject("java", "java.util.LinkedHashMap").init()>
		<cfset this.errors = CreateObject("java", "java.util.LinkedHashMap").init()>
		<cfset this.customErrors = CreateObject("java", "java.util.LinkedHashMap").init()>

		<cfreturn this>
	</cffunction>

</cfcomponent>
