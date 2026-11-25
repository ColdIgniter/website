<!---
 * Class Parser
 *
 * This class represents a simple template parser.
 *
 * Template: { key } and {! key !} (raw), pairs {key} ... {/key} for a list of
 * maps, conditionals { if cond } { elseif cond } { else } { endif }, and
 * comments {# ... #}.
 *
 * Difference: the original uses regular expressions, here the template is
 * scanned with plain string functions, and a condition is read by a small
 * evaluator (never by Evaluate()): an operand is $name, a quoted string, a
 * number, true, false or [] (an empty list), the operators are ==, !=, ===
 * and !==, or an operand alone is true when it is not "", "0", "false" or
 * an empty list or map. A condition inside a pair is read with the data of the
 * whole template, not of the row.
 *
 * {noparse} ... {/noparse} is kept as it is, and the tags that open and close
 * the original's code are written as entities. A value of a pair that is a
 * map is a list of rows, each value that is a map is a row, and any other
 * value is skipped (the original would read it as a row of one item).
 *
 * Not ported yet: the plugins ({+ name +}), the filters ({ key | filter }),
 * the cache options, the decorators, the file locator, renderString,
 * setDelimiters, and the data of a single row inside a conditional of a pair.
--->
<cfcomponent output="no" extends="View" hint="Class Parser">

	<!---
	 * Constructor
	 *
	 * @param config
	 * @param viewPath
	 * @param loader
	 * @param debug
	 * @param logger
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">
		<cfargument name="viewPath" type="string" required="no" default="">
		<cfargument name="loader" type="any" required="no" default="">
		<cfargument name="debug" type="any" required="no" default="">
		<cfargument name="logger" type="any" required="no" default="">

		<cfset super.__construct(arguments.config, arguments.viewPath, arguments.loader, arguments.debug, arguments.logger)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Parses a template file with the data that was set.
	 *
	 * @param view     File name of the template source
	 * @param options  Reserved for 3rd-party uses
	 * @param saveData If true, will save data for use with any other calls,
	 *                 if false, will clean the data after displaying the view,
	 *                 if not given, use the config setting.
	--->
	<cffunction name="render" access="public" returntype="string" output="no">
		<cfargument name="view" type="string" required="yes">
		<cfargument name="options" type="any" required="no" default="">
		<cfargument name="saveData" type="any" required="no" default="">
		<cfset var start = microtime(true)>
		<cfset var file = "">
		<cfset var template = "">
		<cfset var output = "">

		<cfif is_null(arguments.saveData)>
			<cfset arguments.saveData = this.saveData>
		</cfif>

		<!--- A view without an extension is a template file of this kind. --->
		<cfif Find(".", ListLast(arguments.view, "\/")) EQ 0>
			<cfset arguments.view = arguments.view & ".cfm">
		</cfif>

		<cfset file = this.viewPath & arguments.view>

		<cfif NOT is_file(file)>
			<cfthrow type="ColdIgniter.View.Exceptions.ViewException" message="Invalid file: ""#arguments.view#""">
		</cfif>

		<cfset template = file_get_contents(file)>

		<!--- Make our view data available to the template. --->
		<cfset prepareTemplateData(arguments.saveData)>

		<cfset output = parse(template, this.tempData)>

		<cfset logPerformance(start, microtime(true), arguments.view)>

		<cfset this.tempData = "">

		<cfreturn output>
	</cffunction>

	<!---
	 * Parses a template string with the given data: the comments, the
	 * conditionals, the pairs, then the single values.
	 *
	 * @param template The template
	 * @param data     A map
	--->
	<cffunction name="parse" access="public" returntype="string" output="no">
		<cfargument name="template" type="string" required="yes">
		<cfargument name="data" type="any" required="yes">
		<cfset var output = stripComments(arguments.template)>
		<cfset var blocks = StructNew()>
		<cfset var it = "">
		<cfset var hash = "">

		<!--- the opening and closing tags of the original's code are neutralized after the comments are gone --->
		<cfset output = Replace(output, "<" & "?", "&lt;?", "all")>
		<cfset output = Replace(output, "?" & ">", "?&gt;", "all")>

		<cfset output = extractNoparse(output, blocks)>
		<cfset output = parseConditionals(output, arguments.data)>
		<cfset output = parsePair(output, arguments.data)>
		<cfset output = parseSingle(output, arguments.data)>

		<!--- put the noparse contents back, they are never parsed --->
		<cfset it = blocks.keySet().iterator()>
		<cfloop condition="it.hasNext()">
			<cfset hash = it.next()>
			<cfset output = Replace(output, "noparse_" & hash, blocks.get(hash), "all")>
		</cfloop>

		<cfreturn output>
	</cffunction>

	<!---
	 * Extracts the {noparse} ... {/noparse} blocks, leaving "noparse_" and the
	 * hash of the contents in their place.
	 *
	 * @param template The template
	 * @param blocks   A map that receives hash => contents
	--->
	<cffunction name="extractNoparse" access="private" returntype="string" output="no">
		<cfargument name="template" type="string" required="yes">
		<cfargument name="blocks" type="any" required="yes">
		<cfset var output = "">
		<cfset var pos = 1>
		<cfset var open = "">
		<cfset var close = "">
		<cfset var start = 0>
		<cfset var hash = "">
		<cfset var contents = "">

		<cfloop condition="true">
			<cfset open = REFind("\{[[:space:]]*noparse[[:space:]]*\}", arguments.template, pos, true)>
			<cfif open.pos[1] EQ 0>
				<cfbreak>
			</cfif>

			<cfset start = open.pos[1] + open.len[1]>
			<cfset close = REFind("\{[[:space:]]*/noparse[[:space:]]*\}", arguments.template, start, true)>
			<cfif close.pos[1] EQ 0>
				<cfbreak>
			</cfif>

			<cfset contents = Mid(arguments.template, start, close.pos[1] - start)>
			<cfset hash = Hash(contents)>
			<cfset arguments.blocks.put(hash, contents)>
			<cfset output = output & Mid(arguments.template, pos, open.pos[1] - pos) & "noparse_" & hash>
			<cfset pos = close.pos[1] + close.len[1]>
		</cfloop>

		<cfreturn output & Mid(arguments.template, pos, Len(arguments.template) - pos + 1)>
	</cffunction>

	<!---
	 * Removes {# ... #}.
	--->
	<cffunction name="stripComments" access="private" returntype="string" output="no">
		<cfargument name="template" type="string" required="yes">
		<cfset var output = "">
		<cfset var pos = 1>
		<cfset var open = 0>
		<cfset var close = 0>

		<cfloop condition="true">
			<cfset open = Find("{##", arguments.template, pos)>
			<cfif open EQ 0>
				<cfbreak>
			</cfif>

			<cfset close = Find("##}", arguments.template, open + 2)>
			<cfif close EQ 0>
				<cfbreak>
			</cfif>

			<cfset output = output & Mid(arguments.template, pos, open - pos)>
			<cfset pos = close + 2>
		</cfloop>

		<cfreturn output & Mid(arguments.template, pos, Len(arguments.template) - pos + 1)>
	</cffunction>

	<!---
	 * Replaces the single values: { key } is escaped, {! key !} is raw.
	 * A key that is not in the data, or that holds a list or a map, stays as it is.
	--->
	<cffunction name="parseSingle" access="private" returntype="string" output="no">
		<cfargument name="template" type="string" required="yes">
		<cfargument name="data" type="any" required="yes">
		<cfset var output = "">
		<cfset var pos = 1>
		<cfset var open = 0>
		<cfset var close = 0>
		<cfset var inner = "">
		<cfset var key = "">
		<cfset var raw = false>
		<cfset var value = "">
		<cfset var scan = 0>

		<cfloop condition="true">
			<cfset open = Find("{", arguments.template, pos)>
			<cfif open EQ 0>
				<cfbreak>
			</cfif>

			<cfset close = Find("}", arguments.template, open)>
			<cfif close EQ 0>
				<cfbreak>
			</cfif>

			<!--- an opening brace inside: only the last one before the closing brace can start a tag --->
			<cfset scan = close - 1>
			<cfloop condition="scan GT open AND Compare(Mid(arguments.template, scan, 1), '{') NEQ 0">
				<cfset scan = scan - 1>
			</cfloop>
			<cfset open = scan>

			<cfset inner = Trim(Mid(arguments.template, open + 1, close - open - 1))>
			<cfset raw = false>
			<cfset key = inner>

			<cfif Len(inner) GTE 2 AND Left(inner, 1) EQ "!" AND Right(inner, 1) EQ "!">
				<cfset raw = true>
				<cfset key = Trim(Mid(inner, 2, Len(inner) - 2))>
			</cfif>

			<cfif Compare(key, "") NEQ 0 AND array_key_exists(key, arguments.data) AND IsSimpleValue(arguments.data[key])>
				<cfset value = arguments.data[key]>
				<cfif raw>
					<cfset output = output & Mid(arguments.template, pos, open - pos) & value>
				<cfelse>
					<cfset output = output & Mid(arguments.template, pos, open - pos) & esc(value)>
				</cfif>
				<cfset pos = close + 1>
			<cfelse>
				<cfset output = output & Mid(arguments.template, pos, close - pos + 1)>
				<cfset pos = close + 1>
			</cfif>
		</cfloop>

		<cfreturn output & Mid(arguments.template, pos, Len(arguments.template) - pos + 1)>
	</cffunction>

	<!---
	 * Replaces each {key} ... {/key} where the data has a list of maps (or
	 * a map of maps) for the key, once for each row, with the row as data.
	--->
	<cffunction name="parsePair" access="private" returntype="string" output="no">
		<cfargument name="template" type="string" required="yes">
		<cfargument name="data" type="any" required="yes">
		<cfset var output = arguments.template>
		<cfset var it = arguments.data.keySet().iterator()>
		<cfset var key = "">
		<cfset var value = "">
		<cfset var rows = "">
		<cfset var row = "">
		<cfset var pos = 0>
		<cfset var open = 0>
		<cfset var close = 0>
		<cfset var openTag = "">
		<cfset var closeTag = "">
		<cfset var body = "">
		<cfset var replaced = "">
		<cfset var result = "">
		<cfset var i = 0>

		<cfloop condition="it.hasNext()">
			<cfset key = it.next()>
			<cfset value = arguments.data.get(key)>

			<cfif IsArray(value) OR IsStruct(value)>
				<cfset openTag = "{" & key & "}">
				<cfset closeTag = "{/" & key & "}">
				<cfset result = "">
				<cfset pos = 1>

				<cfloop condition="true">
					<cfset open = Find(openTag, output, pos)>
					<cfif open EQ 0>
						<cfbreak>
					</cfif>

					<cfset close = Find(closeTag, output, open + Len(openTag))>
					<cfif close EQ 0>
						<cfbreak>
					</cfif>

					<cfset body = Mid(output, open + Len(openTag), close - open - Len(openTag))>
					<cfset replaced = "">

					<cfif IsStruct(value)>
						<!--- a map is a list of rows: each of its values that is a map --->
						<cfset rows = value.values().iterator()>
						<cfloop condition="rows.hasNext()">
							<cfset row = rows.next()>
							<cfif IsStruct(row)>
								<cfset replaced = replaced & parse(body, row)>
							</cfif>
						</cfloop>
					<cfelse>
						<cfloop from="1" to="#ArrayLen(value)#" index="i">
							<cfif IsStruct(value[i])>
								<cfset replaced = replaced & parse(body, value[i])>
							</cfif>
						</cfloop>
					</cfif>

					<cfset result = result & Mid(output, pos, open - pos) & replaced>
					<cfset pos = close + Len(closeTag)>
				</cfloop>

				<cfset output = result & Mid(output, pos, Len(output) - pos + 1)>
			</cfif>
		</cfloop>

		<cfreturn output>
	</cffunction>

	<!---
	 * Handles { if cond } ... { elseif cond } ... { else } ... { endif },
	 * also nested ones. The first branch whose condition is true is kept.
	--->
	<cffunction name="parseConditionals" access="private" returntype="string" output="no">
		<cfargument name="template" type="string" required="yes">
		<cfargument name="data" type="any" required="yes">
		<cfset var pattern = "\{[ ]*(if|elseif|else|endif)[ }]">
		<cfset var output = "">
		<cfset var pos = 1>
		<cfset var match = "">
		<cfset var inner = "">
		<cfset var scan = 0>
		<cfset var tagEnd = 0>
		<cfset var depth = 0>
		<cfset var keyword = "">
		<cfset var ifStart = 0>
		<cfset var branchStart = 0>
		<cfset var branchCondition = "">
		<cfset var branchIsElse = false>
		<cfset var chosen = false>
		<cfset var chosenBody = "">
		<cfset var closed = false>
		<cfset var next = "">
		<cfset var stop = false>

		<cfloop condition="NOT stop">
			<cfset match = REFind(pattern, arguments.template, pos, true)>

			<cfif match.pos[1] EQ 0>
				<cfset output = output & Mid(arguments.template, pos, Len(arguments.template) - pos + 1)>
				<cfset stop = true>
			<cfelse>
				<cfset keyword = Mid(arguments.template, match.pos[2], match.len[2])>
				<cfset ifStart = match.pos[1]>
				<cfset tagEnd = Find("}", arguments.template, ifStart)>

				<cfif tagEnd EQ 0>
					<cfset output = output & Mid(arguments.template, pos, Len(arguments.template) - pos + 1)>
					<cfset stop = true>
				<cfelseif Compare(keyword, "if") NEQ 0>
					<!--- an else or an endif without an if stays as it is --->
					<cfset output = output & Mid(arguments.template, pos, tagEnd - pos + 1)>
					<cfset pos = tagEnd + 1>
				<cfelse>
					<cfset output = output & Mid(arguments.template, pos, ifStart - pos)>

					<cfset inner = Trim(Mid(arguments.template, ifStart + 1, tagEnd - ifStart - 1))>
					<cfset branchCondition = "">
					<cfif Len(inner) GT 2>
						<cfset branchCondition = Trim(Mid(inner, 3, Len(inner) - 2))>
					</cfif>
					<cfset branchIsElse = false>
					<cfset branchStart = tagEnd + 1>
					<cfset depth = 1>
					<cfset chosen = false>
					<cfset chosenBody = "">
					<cfset closed = false>
					<cfset scan = tagEnd + 1>

					<cfloop condition="NOT closed">
						<cfset next = REFind(pattern, arguments.template, scan, true)>

						<cfif next.pos[1] EQ 0>
							<!--- there is no endif: the rest stays as it is --->
							<cfset output = output & Mid(arguments.template, ifStart, Len(arguments.template) - ifStart + 1)>
							<cfset pos = Len(arguments.template) + 1>
							<cfset closed = true>
							<cfset stop = true>
						<cfelse>
							<cfset keyword = Mid(arguments.template, next.pos[2], next.len[2])>
							<cfset tagEnd = Find("}", arguments.template, next.pos[1])>

							<cfif tagEnd EQ 0>
								<cfset output = output & Mid(arguments.template, ifStart, Len(arguments.template) - ifStart + 1)>
								<cfset pos = Len(arguments.template) + 1>
								<cfset closed = true>
								<cfset stop = true>
							<cfelse>
								<cfif Compare(keyword, "if") EQ 0>
									<cfset depth = depth + 1>
								<cfelseif Compare(keyword, "endif") EQ 0>
									<cfset depth = depth - 1>
								</cfif>

								<cfif (depth EQ 1 AND Compare(keyword, "if") NEQ 0 AND Compare(keyword, "endif") NEQ 0) OR depth EQ 0>
									<!--- the branch that ends here --->
									<cfif NOT chosen>
										<cfif branchIsElse>
											<cfset chosen = true>
										<cfelse>
											<cfset chosen = checkCondition(branchCondition, arguments.data)>
										</cfif>

										<cfif chosen>
											<cfset chosenBody = Mid(arguments.template, branchStart, next.pos[1] - branchStart)>
										</cfif>
									</cfif>

									<cfif depth EQ 0>
										<cfset closed = true>
										<cfset pos = tagEnd + 1>
									<cfelse>
										<cfset branchIsElse = Compare(keyword, "else") EQ 0>
										<cfset inner = Trim(Mid(arguments.template, next.pos[1] + 1, tagEnd - next.pos[1] - 1))>
										<cfset branchCondition = "">
										<cfif Len(inner) GT 6>
											<cfset branchCondition = Trim(Mid(inner, 7, Len(inner) - 6))>
										</cfif>
										<cfset branchStart = tagEnd + 1>
									</cfif>
								</cfif>

								<cfset scan = tagEnd + 1>
							</cfif>
						</cfif>
					</cfloop>

					<cfif chosen>
						<cfset output = output & parseConditionals(chosenBody, arguments.data)>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn output>
	</cffunction>

	<!---
	 * Reads a condition (see the head of this file).
	--->
	<cffunction name="checkCondition" access="private" returntype="boolean" output="no">
		<cfargument name="condition" type="string" required="yes">
		<cfargument name="data" type="any" required="yes">
		<cfset var expression = Trim(arguments.condition)>
		<cfset var parts = REFind("^(.*?)(===|!==|==|!=)(.*)$", expression, 1, true)>
		<cfset var leftValue = "">
		<cfset var rightValue = "">
		<cfset var operator = "">
		<cfset var isSame = false>

		<cfif parts.pos[1] EQ 0>
			<cfreturn isTruthy(operand(expression, arguments.data))>
		</cfif>

		<cfset leftValue = operand(Trim(Mid(expression, parts.pos[2], parts.len[2])), arguments.data)>
		<cfset operator = Mid(expression, parts.pos[3], parts.len[3])>
		<cfset rightValue = operand(Trim(Mid(expression, parts.pos[4], parts.len[4])), arguments.data)>

		<cfset isSame = looselyEqual(leftValue, rightValue)>

		<cfif Left(operator, 1) EQ "!">
			<cfreturn NOT isSame>
		</cfif>

		<cfreturn isSame>
	</cffunction>

	<!---
	 * The value of an operand of a condition: $name, a quoted string, a
	 * number, true, false or [].
	--->
	<cffunction name="operand" access="private" returntype="any" output="no">
		<cfargument name="text" type="string" required="yes">
		<cfargument name="data" type="any" required="yes">
		<cfset var name = "">

		<cfif Compare(arguments.text, "[]") EQ 0>
			<cfreturn ArrayNew(1)>
		</cfif>

		<cfif Left(arguments.text, 1) EQ "$">
			<cfset name = Mid(arguments.text, 2, Len(arguments.text) - 1)>
			<cfif array_key_exists(name, arguments.data)>
				<cfreturn arguments.data[name]>
			</cfif>

			<cfreturn "">
		</cfif>

		<cfif Len(arguments.text) GTE 2 AND ((Left(arguments.text, 1) EQ "'" AND Right(arguments.text, 1) EQ "'") OR (Left(arguments.text, 1) EQ """" AND Right(arguments.text, 1) EQ """"))>
			<cfreturn Mid(arguments.text, 2, Len(arguments.text) - 2)>
		</cfif>

		<!--- a number, true or false stays as the text it is --->
		<cfreturn arguments.text>
	</cffunction>

	<cffunction name="isTruthy" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfset var text = "">

		<cfif IsArray(arguments.value)>
			<cfreturn ArrayLen(arguments.value) GT 0>
		</cfif>

		<cfif IsStruct(arguments.value)>
			<cfreturn arguments.value.size() GT 0>
		</cfif>

		<cfset text = LCase(Trim(arguments.value & ""))>

		<cfreturn Compare(text, "") NEQ 0 AND Compare(text, "0") NEQ 0 AND Compare(text, "false") NEQ 0>
	</cffunction>

	<cffunction name="looselyEqual" access="private" returntype="boolean" output="no">
		<cfargument name="leftValue" type="any" required="yes">
		<cfargument name="rightValue" type="any" required="yes">

		<!--- a list or a map is the same as [] (or an empty value) when it is empty --->
		<cfif NOT IsSimpleValue(arguments.leftValue) OR NOT IsSimpleValue(arguments.rightValue)>
			<cfreturn NOT isTruthy(arguments.leftValue) AND NOT isTruthy(arguments.rightValue)>
		</cfif>

		<cfif IsNumeric(arguments.leftValue) AND IsNumeric(arguments.rightValue)>
			<cfreturn arguments.leftValue EQ arguments.rightValue>
		</cfif>

		<cfreturn Compare(arguments.leftValue & "", arguments.rightValue & "") EQ 0>
	</cffunction>

</cfcomponent>
