<!---
 * Decodes a url-encoded string (a plus becomes a space).
 *
 * URLDecode() throws for a percent sign without two hexadecimal digits
 * after it. As in the original, such a sign is then kept as it is and
 * the rest is decoded.
--->
<cffunction name="parse_str_decode" returntype="string" output="no" hint="Decodes a url-encoded string, keeping a percent sign that is not followed by two hexadecimal digits">
	<cfargument name="string" type="string" required="yes">
	<cfset var buffer = "">
	<cfset var text = arguments.string>
	<cfset var position = Find("%", text)>
	<cfset var start = 1>

	<cfif position EQ 0>
		<cfreturn URLDecode(text)>
	</cfif>

	<cfset buffer = CreateObject("java", "java.lang.StringBuffer").init()>

	<cfloop condition="position GT 0">
		<cfset buffer.append(JavaCast("string", Mid(text, start, position - start + 1)))>
		<cfset start = position + 1>

		<!--- a percent sign that stands alone is written as %25 --->
		<cfif start + 1 GT Len(text) OR REFind("^[0-9A-Fa-f][0-9A-Fa-f]$", Mid(text, start, 2)) EQ 0>
			<cfset buffer.append(JavaCast("string", "25"))>
		</cfif>

		<cfset position = 0>
		<cfif start LTE Len(text)>
			<cfset position = Find("%", text, start)>
		</cfif>
	</cfloop>

	<cfif start LTE Len(text)>
		<cfset buffer.append(JavaCast("string", Mid(text, start, Len(text) - start + 1)))>
	</cfif>

	<cfreturn URLDecode(buffer.toString())>
</cffunction>

<!---
 * The top-level key a name has in the result of parse_str(). The name is
 * given decoded and left-trimmed.
 *
 * Only the part before the first bracket has its dots and spaces replaced.
 * An opening bracket without a closing one becomes an underscore, the
 * rest is kept. Shared with the cookie reader, so that both name a key
 * the same way.
--->
<cffunction name="parse_str_key" returntype="string" output="no" hint="Returns the top-level key of a decoded name">
	<cfargument name="name" type="string" required="yes">
	<cfset var lead = arguments.name>
	<cfset var position = Find("[", arguments.name)>

	<cfif position GT 0>
		<cfset lead = Left(arguments.name, position - 1)>
	</cfif>

	<cfset lead = Replace(Replace(lead, ".", "_", "all"), " ", "_", "all")>

	<cfif position GT 0 AND Find("]", arguments.name, position) EQ 0 AND lead NEQ "">
		<cfreturn lead & "_" & substr(arguments.name, position)>
	</cfif>

	<cfreturn lead>
</cffunction>

<!---
 * Parses a query string into an array with string keys (see array_()).
 *
 * Difference: the result is returned, as the original takes a second
 * argument to fill.
 *
 * The names are kept as they were sent, in their case. As in the
 * original, a dot or a space in the name before the first bracket
 * becomes an underscore, a[b]=1 makes a nested map, a[]=1 appends, and
 * a nested map whose keys are 0, 1, 2 ... is a list (an ArrayNew(1))
 * here. A name that repeats replaces the earlier value.
 *
 * As in the original, at most max_input_vars pairs are taken (the
 * others are dropped) and a name with more than max_input_nesting_level
 * pairs of brackets is dropped. They are read with ini_get(), and the
 * defaults of the original are 1000 and 64.
--->
<cffunction name="parse_str" returntype="any" output="no" hint="Parses a query string into an array with string keys">
	<cfargument name="string" type="string" required="yes">
	<cfset var result = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset var nested = ArrayNew(1)>
	<cfset var pairs = explode("&", arguments.string)>
	<cfset var pair = "">
	<cfset var name = "">
	<cfset var value = "">
	<cfset var keys = "">
	<cfset var rest = "">
	<cfset var container = "">
	<cfset var child = "">
	<cfset var entry = "">
	<cfset var list = "">
	<cfset var key = "">
	<cfset var nexts = CreateObject("java", "java.util.IdentityHashMap").init()>
	<cfset var number = "">
	<cfset var one = CreateObject("java", "java.math.BigInteger").valueOf(JavaCast("long", 1))>
	<cfset var maximum = CreateObject("java", "java.math.BigInteger").init(JavaCast("string", "9223372036854775807"))>
	<cfset var maxVars = 1000>
	<cfset var maxNesting = 64>
	<cfset var found = true>
	<cfset var count = 0>
	<cfset var position = 0>
	<cfset var i = 0>
	<cfset var j = 0>

	<!--- the defaults of max_input_vars and max_input_nesting_level --->
	<cfif Val(ini_get("max_input_vars")) GT 0>
		<cfset maxVars = Val(ini_get("max_input_vars"))>
	</cfif>
	<cfif Val(ini_get("max_input_nesting_level")) GT 0>
		<cfset maxNesting = Val(ini_get("max_input_nesting_level"))>
	</cfif>

	<cfloop from="1" to="#ArrayLen(pairs)#" index="i">
		<cfset pair = pairs[i]>

		<cfif pair NEQ "">
			<!--- the pairs after max_input_vars are dropped --->
			<cfset count = count + 1>
			<cfif count GT maxVars>
				<cfbreak>
			</cfif>

			<cfset position = Find("=", pair)>
			<cfif position GT 0>
				<cfset name = Left(pair, position - 1)>
				<cfset value = substr(pair, position)>
			<cfelse>
				<cfset name = pair>
				<cfset value = "">
			</cfif>

			<!--- the name ends at a NUL character, which is written %00 --->
			<cfset position = FindNoCase("%00", name)>
			<cfif position GT 0>
				<cfset name = Left(name, position - 1)>
			</cfif>

			<cfset name = parse_str_decode(name)>
			<cfset value = parse_str_decode(value)>

			<cfset name = LTrim(name)>
			<cfset keys = ArrayNew(1)>
			<cfset rest = "">
			<cfset position = Find("[", name)>
			<cfset ArrayAppend(keys, parse_str_key(name))>

			<cfif position GT 0 AND Find("]", name, position) GT 0>
				<cfset rest = substr(name, position - 1)>
			</cfif>

			<cfloop condition="Left(rest, 1) EQ '[' AND Find(']', rest) GT 0">
				<cfset position = Find("]", rest)>
				<cfset ArrayAppend(keys, Mid(rest, 2, position - 2))>
				<cfset rest = substr(rest, position)>
			</cfloop>

			<!--- a name with more than max_input_nesting_level pairs of brackets is dropped
			     (only the pair is dropped here; whether the original engine also removes an existing variable of that name is not known) --->
			<cfif keys[1] NEQ "" AND ArrayLen(keys) - 1 LTE maxNesting>
				<cfset container = result>

				<cfloop from="1" to="#ArrayLen(keys)#" index="j">
					<cfset key = keys[j]>

					<!--- an empty pair of brackets appends, with the next free number --->
					<cfif key EQ "" AND j GT 1>
						<cfset key = "0">
						<cfif nexts.containsKey(container)>
							<!--- past the largest integer the original refuses to append: the pair is dropped --->
							<cfif nexts.get(container).compareTo(maximum) GT 0>
								<cfbreak>
							</cfif>
							<cfset key = nexts.get(container).toString()>
						</cfif>
					</cfif>

					<!--- keep the next free number of the map (only a canonical decimal integer up to the largest integer is a number key;
					      after a negative key the next index is 0, as in the original before its 8.3 line) --->
					<cfif REFind("^(0|[1-9][0-9]{0,18})$", key) GT 0>
						<cfset number = CreateObject("java", "java.math.BigInteger").init(JavaCast("string", key))>
						<cfif number.compareTo(maximum) LTE 0 AND (NOT nexts.containsKey(container) OR number.add(one).compareTo(nexts.get(container)) GT 0)>
							<cfset nexts.put(container, number.add(one))>
						</cfif>
					</cfif>

					<cfif j EQ ArrayLen(keys)>
						<cfset container[key] = value>
					<cfelse>
						<cfif NOT StructKeyExists(container, key) OR NOT IsStruct(container[key])>
							<cfset child = CreateObject("java", "java.util.LinkedHashMap").init()>
							<cfset entry = StructNew()>
							<cfset entry.parent = container>
							<cfset entry.key = key>
							<cfset entry.node = child>
							<cfset ArrayAppend(nested, entry)>
							<cfset container[key] = child>
						</cfif>

						<cfset container = container[key]>
					</cfif>
				</cfloop>
			</cfif>
		</cfif>
	</cfloop>

	<!--- A map whose keys are 0, 1, 2 ... becomes a list. The children come first. --->
	<cfloop from="#ArrayLen(nested)#" to="1" index="i" step="-1">
		<cfset entry = nested[i]>
		<cfset count = StructCount(entry.node)>
		<cfset found = true>

		<cfloop from="0" to="#count - 1#" index="j">
			<cfif NOT StructKeyExists(entry.node, ToString(j))>
				<cfset found = false>
			</cfif>
		</cfloop>

		<cfset child = "">
		<cfif StructKeyExists(entry.parent, entry.key)>
			<cfset child = entry.parent[entry.key]>
		</cfif>

		<cfif found AND IsStruct(child) AND child.equals(entry.node)>
			<cfset list = ArrayNew(1)>

			<cfloop from="0" to="#count - 1#" index="j">
				<cfset ArrayAppend(list, entry.node[ToString(j)])>
			</cfloop>

			<cfset entry.parent[entry.key] = list>
		</cfif>
	</cfloop>

	<cfreturn result>
</cffunction>
