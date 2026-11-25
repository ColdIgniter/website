<!---
 * ColdIgniter Inflector Helpers
 *
 * A function here has no guard against a second definition (the original
 * checks function_exists): helper() keeps the first definition of a name.
 *
 * Difference: the original writes its rule tables into singular() and
 * plural(), so they are built at every call. Here they are built once, by
 * inflector_rules_() below (not in the original), and kept.
 *
 * Difference: the patterns of the rule tables, camelize(), underscore()
 * and decamelize() are the framework's own and cannot backtrack, so they
 * skip the regex guard (see regex_guard_()). humanize() builds its pattern
 * from the separator it is given, so it is guarded.
 *
 * Difference: the original calls strtolower(), str_replace() and lcfirst()
 * here. In this file they are LCase(), Replace() with "all" (exact, as
 * str_replace() is) and the same few lines written out, because that is
 * cheaper than a polyfill call. LCase() also lowercases letters outside
 * ASCII, which strtolower() and lcfirst() do not (since 8.2), so camelize(),
 * decamelize() and is_pluralizable() differ for such a letter.
--->

<!---
 * Not in the original. Returns the rule table of singular() or plural()
 * (the kind, "singular" or "plural"): a struct with three lists of the same
 * length, patterns, replacements and compiled (the java.util.regex.Pattern
 * of each pattern, immutable and so safe to share), in the order of the
 * original.
 *
 * Difference: a map keeps its order in the original (an array of
 * pattern => replacement). Here the order is the order of the two lists.
 *
 * The tables are built at the first call. In production they are kept in
 * the memory of the site (shared_().inflector in the application scope, one
 * map of tables per system folder) until the application ends, anywhere else in
 * request.ColdIgniter.inflector for the
 * request only, so a change of this file is seen on the next request.
 * They hold rules only, never a value of the configuration.
 *
 * A table is complete before it is stored, so it needs no lock: two
 * requests that build it at the same time store the same values.
 *
 * @param kind singular or plural
--->
<cffunction name="inflector_rules_" returntype="struct" output="no" hint="Returns the rule table of singular() or plural()">
	<cfargument name="kind" type="string" required="yes">
	<cfset var all = "">
	<cfset var kept = "">
	<cfset var rules = "">

	<cfif StructKeyExists(request, "ENVIRONMENT") AND request.ENVIRONMENT EQ "production">
		<!--- one map of tables per install, with the system folder as key --->
		<cfset all = shared_().inflector>

		<cfif NOT StructKeyExists(all, request.SYSTEMPATH)>
			<cfset all[request.SYSTEMPATH] = StructNew()>
		</cfif>

		<cfset kept = all[request.SYSTEMPATH]>
	<cfelseif StructKeyExists(request, "ColdIgniter")>
		<cfif NOT StructKeyExists(request.ColdIgniter, "inflector")>
			<cfset request.ColdIgniter.inflector = StructNew()>
		</cfif>

		<cfset kept = request.ColdIgniter.inflector>
	<cfelse>
		<!--- nowhere to keep them: built for this call only --->
		<cfset kept = StructNew()>
	</cfif>

	<cfif StructKeyExists(kept, arguments.kind)>
		<cfreturn kept[arguments.kind]>
	</cfif>

	<cfset rules = StructNew()>
	<cfset rules.patterns = ArrayNew(1)>
	<cfset rules.replacements = ArrayNew(1)>
	<cfset rules.compiled = ArrayNew(1)>

	<cfif arguments.kind EQ "singular">
		<!--- Arranged in order. --->
		<cfset inflector_rule_(rules, "/(matr)ices$/", "\1ix")>
		<cfset inflector_rule_(rules, "/(vert|ind)ices$/", "\1ex")>
		<cfset inflector_rule_(rules, "/^(ox)en/", "\1")>
		<cfset inflector_rule_(rules, "/(alias)es$/", "\1")>
		<cfset inflector_rule_(rules, "/([octop|vir])i$/", "\1us")>
		<cfset inflector_rule_(rules, "/(cris|ax|test)es$/", "\1is")>
		<cfset inflector_rule_(rules, "/(shoe)s$/", "\1")>
		<cfset inflector_rule_(rules, "/(o)es$/", "\1")>
		<cfset inflector_rule_(rules, "/(bus|campus)es$/", "\1")>
		<cfset inflector_rule_(rules, "/([m|l])ice$/", "\1ouse")>
		<cfset inflector_rule_(rules, "/(x|ch|ss|sh)es$/", "\1")>
		<cfset inflector_rule_(rules, "/(m)ovies$/", "\1\2ovie")>
		<cfset inflector_rule_(rules, "/(s)eries$/", "\1\2eries")>
		<cfset inflector_rule_(rules, "/([^aeiouy]|qu)ies$/", "\1y")>
		<cfset inflector_rule_(rules, "/([lr])ves$/", "\1f")>
		<cfset inflector_rule_(rules, "/(tive)s$/", "\1")>
		<cfset inflector_rule_(rules, "/(hive)s$/", "\1")>
		<cfset inflector_rule_(rules, "/([^f])ves$/", "\1fe")>
		<cfset inflector_rule_(rules, "/(^analy)ses$/", "\1sis")>
		<cfset inflector_rule_(rules, "/((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$/", "\1\2sis")>
		<cfset inflector_rule_(rules, "/([ti])a$/", "\1um")>
		<cfset inflector_rule_(rules, "/(p)eople$/", "\1\2erson")>
		<cfset inflector_rule_(rules, "/(m)en$/", "\1an")>
		<cfset inflector_rule_(rules, "/(s)tatuses$/", "\1\2tatus")>
		<cfset inflector_rule_(rules, "/(c)hildren$/", "\1\2hild")>
		<cfset inflector_rule_(rules, "/(n)ews$/", "\1\2ews")>
		<cfset inflector_rule_(rules, "/(quiz)zes$/", "\1")>
		<cfset inflector_rule_(rules, "/([^us])s$/", "\1")>
	<cfelse>
		<cfset inflector_rule_(rules, "/(quiz)$/", "\1zes")><!--- quizzes --->
		<cfset inflector_rule_(rules, "/^(ox)$/", "\1\2en")><!--- ox --->
		<cfset inflector_rule_(rules, "/([m|l])ouse$/", "\1ice")><!--- mouse, louse --->
		<cfset inflector_rule_(rules, "/(matr|vert|ind)ix|ex$/", "\1ices")><!--- matrix, vertex, index --->
		<cfset inflector_rule_(rules, "/(x|ch|ss|sh)$/", "\1es")><!--- search, switch, fix, box, process, address --->
		<cfset inflector_rule_(rules, "/([^aeiouy]|qu)y$/", "\1ies")><!--- query, ability, agency --->
		<cfset inflector_rule_(rules, "/(hive)$/", "\1s")><!--- archive, hive --->
		<cfset inflector_rule_(rules, "/(?:([^f])fe|([lr])f)$/", "\1\2ves")><!--- half, safe, wife --->
		<cfset inflector_rule_(rules, "/sis$/", "ses")><!--- basis, diagnosis --->
		<cfset inflector_rule_(rules, "/([ti])um$/", "\1a")><!--- datum, medium --->
		<cfset inflector_rule_(rules, "/(p)erson$/", "\1eople")><!--- person, salesperson --->
		<cfset inflector_rule_(rules, "/(m)an$/", "\1en")><!--- man, woman, spokesman --->
		<cfset inflector_rule_(rules, "/(c)hild$/", "\1hildren")><!--- child --->
		<cfset inflector_rule_(rules, "/(buffal|tomat)o$/", "\1\2oes")><!--- buffalo, tomato --->
		<cfset inflector_rule_(rules, "/(bu|campu)s$/", "\1\2ses")><!--- bus, campus --->
		<cfset inflector_rule_(rules, "/(alias|status|virus)$/", "\1es")><!--- alias --->
		<cfset inflector_rule_(rules, "/(octop)us$/", "\1i")><!--- octopus --->
		<cfset inflector_rule_(rules, "/(ax|cris|test)is$/", "\1es")><!--- axis, crisis --->
		<cfset inflector_rule_(rules, "/s$/", "s")><!--- no change (compatibility) --->
		<cfset inflector_rule_(rules, "/$/", "s")>
	</cfif>

	<cfset kept[arguments.kind] = rules>

	<cfreturn rules>
</cffunction>

<!---
 * Not in the original. Adds one rule to the end of a rule table.
--->
<cffunction name="inflector_rule_" returntype="void" output="no" hint="Adds one rule to a rule table">
	<cfargument name="rules" type="struct" required="yes">
	<cfargument name="pattern" type="string" required="yes">
	<cfargument name="replacement" type="string" required="yes">

	<cfset ArrayAppend(arguments.rules.patterns, arguments.pattern)>
	<cfset ArrayAppend(arguments.rules.replacements, arguments.replacement)>
	<cfset ArrayAppend(arguments.rules.compiled, preg_pattern(arguments.pattern))>
</cffunction>

<!---
 * Not in the original. Applies the first rule of a rule table that matches
 * to the string, as the loop in singular() and plural() does.
 *
 * Difference: one matcher per rule does the match and the replacement
 * (the original matches, then replaces). A reference in a replacement is
 * a backslash and one digit; a group that does not exist or did not take
 * part gives nothing, as in the original.
 *
 * @param kind   singular or plural
 * @param string The word
--->
<cffunction name="inflector_apply_" returntype="string" output="no" hint="Applies the first rule of a rule table that matches to the string">
	<cfargument name="kind" type="string" required="yes">
	<cfargument name="string" type="string" required="yes">
	<cfset var rules = inflector_rules_(arguments.kind)>
	<cfset var result = arguments.string>
	<cfset var matcher = "">
	<cfset var buffer = "">
	<cfset var template = "">
	<cfset var out = "">
	<cfset var character = "">
	<cfset var found = false>
	<cfset var position = 0>
	<cfset var group = 0>
	<cfset var i = 0>
	<cfset var j = 0>

	<cfloop from="1" to="#ArrayLen(rules.compiled)#" index="i">
		<cfset matcher = rules.compiled[i].matcher(JavaCast("string", result))>

		<cfif matcher.find()>
			<cfset template = rules.replacements[i]>
			<cfset buffer = CreateObject("java", "java.lang.StringBuffer").init()>
			<cfset position = 0>
			<cfset found = true>

			<cfloop condition="found">
				<cfset buffer.append(JavaCast("string", Mid(result, position + 1, matcher.start() - position)))>

				<!--- expand the references to the groups --->
				<cfset out = "">
				<cfset j = 1>
				<cfloop condition="j LTE Len(template)">
					<cfset character = Mid(template, j, 1)>

					<cfif Compare(character, "\") EQ 0 AND REFind("^[0-9]", Mid(template, j + 1, 1)) GT 0>
						<cfset group = Val(Mid(template, j + 1, 1))>
						<cfif group LTE matcher.groupCount() AND matcher.start(JavaCast("int", group)) GTE 0>
							<cfset out = out & matcher.group(JavaCast("int", group))>
						</cfif>
						<cfset j = j + 2>
					<cfelse>
						<cfset out = out & character>
						<cfset j = j + 1>
					</cfif>
				</cfloop>

				<cfset buffer.append(JavaCast("string", out))>
				<cfset position = matcher.end()>
				<cfset found = matcher.find()>
			</cfloop>

			<cfset buffer.append(JavaCast("string", Mid(result, position + 1, Len(result) - position)))>

			<cfreturn buffer.toString()>
		</cfif>
	</cfloop>

	<cfreturn result>
</cffunction>

<!---
 * Singular
 *
 * Takes a plural word and makes it singular
 *
 * @param string Input string
--->
<cffunction name="singular" returntype="string" output="no" hint="Takes a plural word and makes it singular">
	<cfargument name="string" type="string" required="yes">
	<cfset var result = arguments.string>

	<cfif NOT is_pluralizable(result)>
		<cfreturn result>
	</cfif>

	<!--- Arranged in order: the rules are in inflector_rules_(), the loop is in inflector_apply_(). --->
	<cfreturn inflector_apply_("singular", result)>
</cffunction>

<!---
 * Plural
 *
 * Takes a singular word and makes it plural
 *
 * @param string Input string
--->
<cffunction name="plural" returntype="string" output="no" hint="Takes a singular word and makes it plural">
	<cfargument name="string" type="string" required="yes">
	<cfset var result = arguments.string>

	<cfif NOT is_pluralizable(result)>
		<cfreturn result>
	</cfif>

	<cfreturn inflector_apply_("plural", result)>
</cffunction>

<!---
 * Counted
 *
 * Takes a number and a word to return the plural or not
 * E.g. 0 cats, 1 cat, 2 cats, ...
 *
 * @param count  Number of items
 * @param string Input string
--->
<cffunction name="counted" returntype="string" output="no" hint="Takes a number and a word to return the plural or not">
	<cfargument name="count" type="numeric" required="yes">
	<cfargument name="string" type="string" required="yes">
	<cfset var result = arguments.count & " ">

	<cfif arguments.count EQ 1>
		<cfreturn result & singular(arguments.string)>
	</cfif>

	<cfreturn result & plural(arguments.string)>
</cffunction>

<!---
 * Camelize
 *
 * Takes multiple words separated by spaces or
 * underscores and converts them to camel case.
 *
 * @param string Input string
--->
<cffunction name="camelize" returntype="string" output="no" hint="Takes multiple words separated by spaces or underscores and converts them to camel case">
	<cfargument name="string" type="string" required="yes">
	<cfset var result = Replace(ucwords(preg_replace("/[\s_]+/", " ", arguments.string, true)), " ", "", "all")>

	<!--- lcfirst --->
	<cfif Len(result) EQ 0>
		<cfreturn "">
	</cfif>

	<cfreturn LCase(Left(result, 1)) & Mid(result, 2, Len(result))>
</cffunction>

<!---
 * Pascalize
 *
 * Takes multiple words separated by spaces or
 * underscores and converts them to Pascal case,
 * which is camel case with an uppercase first letter.
 *
 * @param string Input string
--->
<cffunction name="pascalize" returntype="string" output="no" hint="Takes multiple words separated by spaces or underscores and converts them to Pascal case">
	<cfargument name="string" type="string" required="yes">

	<cfreturn ucfirst(camelize(arguments.string))>
</cffunction>

<!---
 * Underscore
 *
 * Takes multiple words separated by spaces and underscores them
 *
 * @param string Input string
--->
<cffunction name="underscore" returntype="string" output="no" hint="Takes multiple words separated by spaces and underscores them">
	<cfargument name="string" type="string" required="yes">
	<cfset var replacement = trim_(arguments.string)>

	<cfreturn preg_replace("/[\s]+/", "_", replacement, true)>
</cffunction>

<!---
 * Decamelize
 *
 * Takes multiple words separated by camel case and
 * underscores them.
 *
 * @param string Input string
--->
<cffunction name="decamelize" returntype="string" output="no" hint="Takes multiple words separated by camel case and underscores them">
	<cfargument name="string" type="string" required="yes">
	<cfset var patterns = ArrayNew(1)>

	<cfset ArrayAppend(patterns, "/([a-z\d])([A-Z])/")>
	<cfset ArrayAppend(patterns, "/([^_])([A-Z][a-z])/")>

	<cfreturn LCase(preg_replace(patterns, "$1_$2", trim_(arguments.string), true))>
</cffunction>

<!---
 * Humanize
 *
 * Takes multiple words separated by the separator,
 * camelizes and changes them to spaces
 *
 * @param string    Input string
 * @param separator Input separator
--->
<cffunction name="humanize" returntype="string" output="no" hint="Takes multiple words separated by the separator, camelizes and changes them to spaces">
	<cfargument name="string" type="string" required="yes">
	<cfargument name="separator" type="string" required="no" default="_">
	<cfset var replacement = trim_(arguments.string)>

	<cfreturn ucwords(preg_replace("/[" & arguments.separator & "]+/", " ", replacement))>
</cffunction>

<!---
 * Checks if the given word has a plural version.
 *
 * Difference: the original asks in_array() with a list of words made at
 * every call. Here the words are one text and ListFind() looks in it
 * (exact, as the strict flag of in_array() is). A word with a comma in it
 * is never one of them, and an empty word is not either.
 *
 * @param word Word to check
--->
<cffunction name="is_pluralizable" returntype="boolean" output="no" hint="Checks if the given word has a plural version">
	<cfargument name="word" type="string" required="yes">
	<cfset var uncountables = false>

	<cfif Len(arguments.word) GT 0>
		<cfset uncountables = ListFind("advice,bravery,butter,chaos,clarity,coal,courage,cowardice,curiosity,education,equipment,evidence,fish,fun,furniture,greed,help,homework,honesty,information,insurance,jewelry,knowledge,livestock,love,luck,marketing,meta,money,mud,news,patriotism,racism,rice,satisfaction,scenery,series,sexism,silence,species,spelling,sugar,water,weather,wisdom,work", LCase(arguments.word)) GT 0>
	</cfif>

	<cfreturn NOT uncountables>
</cffunction>

<!---
 * Replaces underscores with dashes in the string.
 *
 * @param string Input string
--->
<cffunction name="dasherize" returntype="string" output="no" hint="Replaces underscores with dashes in the string">
	<cfargument name="string" type="string" required="yes">

	<cfreturn Replace(arguments.string, "_", "-", "all")>
</cffunction>

<!---
 * Returns the suffix that should be added to a
 * number to denote the position in an ordered
 * sequence such as 1st, 2nd, 3rd, 4th.
 *
 * Difference: the suffixes are a list, not an array literal.
 *
 * @param integer The integer to determine the suffix
--->
<cffunction name="ordinal" returntype="string" output="no" hint="Returns the suffix that should be added to a number to denote the position in an ordered sequence">
	<cfargument name="integer" type="numeric" required="yes">
	<cfset var suffixes = "th,st,nd,rd,th,th,th,th,th,th">

	<cfif (arguments.integer MOD 100) GTE 11 AND (arguments.integer MOD 100) LTE 13>
		<cfreturn "th">
	</cfif>

	<cfreturn ListGetAt(suffixes, (arguments.integer MOD 10) + 1)>
</cffunction>

<!---
 * Turns a number into an ordinal string used
 * to denote the position in an ordered sequence
 * such as 1st, 2nd, 3rd, 4th.
 *
 * @param integer The integer to ordinalize
--->
<cffunction name="ordinalize" returntype="string" output="no" hint="Turns a number into an ordinal string used to denote the position in an ordered sequence">
	<cfargument name="integer" type="numeric" required="yes">

	<cfreturn arguments.integer & ordinal(arguments.integer)>
</cffunction>
