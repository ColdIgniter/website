<!---
 * Class Negotiate
 *
 * Provides methods to negotiate with the HTTP headers to determine the best
 * type match between what the application supports and what the requesting
 * server wants.
 *
 * @see http://tools.ietf.org/html/rfc7231#section-5.3
 *
 * Difference: the header is split with the Java String.split(), and the
 * supported values are parsed once for a whole match, where the original
 * parses them again for every comparison; the result is the same. A header
 * value is an entry, a struct of the keys value, q (a number) and params (a
 * struct), where the names of the parameters are compared ignoring case, as
 * the keys of a struct are. A value is looked up for exclusion only when
 * the header has a quality of zero, as nothing else can exclude it.
 *
 * Difference: a parameter with an empty name (as in "text/html; =x") is
 * skipped, where the original keeps it under the empty key, which a struct
 * does not take. A header of three or more values with the same quality is
 * sorted by a comparator in the original that returns 0 when the first value
 * has fewer asterisks, so its order depends on the input order; here the
 * order is the one its comments intend: fewer asterisks first, then more
 * parameters, then the order of the header.
--->
<cfcomponent output="no" hint="Content negotiation with the HTTP headers">

	<!---
	 * Request
	--->
	<cfset this.request = "">

	<!---
	 * Constructor
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="request" type="any" required="no" default="">

		<cfif NOT is_null(arguments.request)>
			<cfset this.request = arguments.request>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Stores the request instance to grab the headers from.
	 *
	 * @return this
	--->
	<cffunction name="setRequest" access="public" returntype="any" output="no">
		<cfargument name="request" type="any" required="yes">

		<cfset this.request = arguments.request>

		<cfreturn this>
	</cffunction>

	<!---
	 * Determines the best content-type to use based on the $supported
	 * types the application says it supports, and the types requested
	 * by the client.
	 *
	 * If no match is found, the first, highest-ranking client requested
	 * type is returned.
	 *
	 * @param supported   array of strings
	 * @param strictMatch If TRUE, will return an empty string when no match found.
	 *                    If FALSE, will return the first supported element.
	--->
	<cffunction name="media" access="public" returntype="string" output="no">
		<cfargument name="supported" type="array" required="yes">
		<cfargument name="strictMatch" type="boolean" required="no" default="false">

		<cfreturn getBestMatch(arguments.supported, this.request.getHeaderLine("accept"), true, arguments.strictMatch)>
	</cffunction>

	<!---
	 * Determines the best charset to use based on the $supported
	 * types the application says it supports, and the types requested
	 * by the client.
	 *
	 * If no match is found, the first, highest-ranking client requested
	 * type is returned.
	 *
	 * @param supported array of strings
	--->
	<cffunction name="charset" access="public" returntype="string" output="no">
		<cfargument name="supported" type="array" required="yes">
		<cfset var best = getBestMatch(arguments.supported, this.request.getHeaderLine("accept-charset"), false, true)>

		<!--- If no charset is shown as a match, ignore the directive
		      as allowed by the RFC, and tell it a default value. --->
		<cfif best EQ "">
			<cfreturn "utf-8">
		</cfif>

		<cfreturn best>
	</cffunction>

	<!---
	 * Determines the best encoding type to use based on the $supported
	 * types the application says it supports, and the types requested
	 * by the client.
	 *
	 * If no match is found, the first, highest-ranking client requested
	 * type is returned.
	 *
	 * @param supported array of strings
	--->
	<cffunction name="encoding" access="public" returntype="string" output="no">
		<cfargument name="supported" type="any" required="no" default="">
		<cfset var list = ArrayNew(1)>
		<cfset var i = 0>

		<!--- the argument can be the caller's own array or list, and a java.util.List is
		      shared by reference, so the values are copied before "identity" is appended --->
		<cfif NOT is_null(arguments.supported)>
			<cfloop from="1" to="#ArrayLen(arguments.supported)#" index="i">
				<cfset ArrayAppend(list, arguments.supported[i])>
			</cfloop>
		</cfif>

		<cfset ArrayAppend(list, "identity")>

		<cfreturn getBestMatch(list, this.request.getHeaderLine("accept-encoding"))>
	</cffunction>

	<!---
	 * Determines the best language to use based on the $supported
	 * types the application says it supports, and the types requested
	 * by the client.
	 *
	 * If strict locale negotiation is disabled and no match is found, the first, highest-ranking client requested
	 * type is returned.
	 *
	 * @param supported array of strings
	--->
	<cffunction name="language" access="public" returntype="string" output="no">
		<cfargument name="supported" type="array" required="yes">

		<cfif config("Config\Feature").strictLocaleNegotiation>
			<cfreturn getBestLocaleMatch(arguments.supported, this.request.getHeaderLine("accept-language"))>
		</cfif>

		<cfreturn getBestMatch(arguments.supported, this.request.getHeaderLine("accept-language"), false, false, true)>
	</cffunction>

	<!---
	 * --------------------------------------------------------------------
	 * Utility Methods
	 * --------------------------------------------------------------------
	--->

	<!---
	 * Does the grunt work of comparing any of the app-supported values
	 * against a given Accept* header string.
	 *
	 * Portions of this code base on Aura.Accept library.
	 *
	 * @param supported    App-supported values, an array of strings
	 * @param header       header string
	 * @param enforceTypes If TRUE, will compare media types and sub-types.
	 * @param strictMatch  If TRUE, will return empty string on no match.
	 *                     If FALSE, will return the first supported element.
	 * @param matchLocales If TRUE, will match locale sub-types to a broad type (fr-FR = fr)
	 *
	 * @return Best match
	--->
	<cffunction name="getBestMatch" access="public" returntype="string" output="no">
		<cfargument name="supported" type="array" required="yes">
		<cfargument name="header" type="any" required="no" default="">
		<cfargument name="enforceTypes" type="boolean" required="no" default="false">
		<cfargument name="strictMatch" type="boolean" required="no" default="false">
		<cfargument name="matchLocales" type="boolean" required="no" default="false">
		<cfset var acceptable = "">
		<cfset var parsed = ArrayNew(1)>
		<cfset var accept = "">
		<cfset var hasZero = false>
		<cfset var i = 0>
		<cfset var j = 0>

		<cfif ArrayLen(arguments.supported) EQ 0>
			<cfthrow type="ColdIgniter.HTTP.Exceptions.HTTPException" message="You must provide an array of supported values to all Negotiations.">
		</cfif>

		<cfif arguments.header EQ "">
			<cfif arguments.strictMatch>
				<cfreturn "">
			</cfif>

			<cfreturn arguments.supported[1]>
		</cfif>

		<cfset acceptable = parseHeader(arguments.header)>

		<cfloop from="1" to="#ArrayLen(acceptable)#" index="i">
			<cfif acceptable[i].q EQ 0>
				<cfset hasZero = true>
			</cfif>
		</cfloop>

		<cfloop from="1" to="#ArrayLen(acceptable)#" index="i">
			<cfset accept = acceptable[i]>

			<!--- if acceptable quality is zero, skip it. --->
			<cfif accept.q NEQ 0>
				<!--- a wildcard that nothing excludes takes the first supported value --->
				<cfif NOT hasZero AND (accept.value EQ "*" OR accept.value EQ "*/*")>
					<cfreturn arguments.supported[1]>
				</cfif>

				<!--- the supported values are parsed when they are first compared --->
				<cfif ArrayLen(parsed) EQ 0>
					<cfloop from="1" to="#ArrayLen(arguments.supported)#" index="j">
						<cfset ArrayAppend(parsed, parseSupported(arguments.supported[j]))>
					</cfloop>
				</cfif>

				<cfif accept.value EQ "*" OR accept.value EQ "*/*">
					<!--- if acceptable value is "anything", return the first available
					      that the header does not exclude --->
					<cfloop from="1" to="#ArrayLen(parsed)#" index="j">
						<cfif NOT hasZero OR NOT isExcluded(acceptable, parsed[j], arguments.enforceTypes, arguments.matchLocales)>
							<cfreturn arguments.supported[j]>
						</cfif>
					</cfloop>
				<cfelse>
					<!--- If an acceptable value is supported, return it, unless the header
					      excludes it with a more specific value, such as "text/html;q=0"
					      for "text/*" --->
					<cfloop from="1" to="#ArrayLen(parsed)#" index="j">
						<cfif matchParsed(accept, parsed[j], arguments.enforceTypes, arguments.matchLocales)
							AND (NOT hasZero OR NOT isExcluded(acceptable, parsed[j], arguments.enforceTypes, arguments.matchLocales))>
							<cfreturn arguments.supported[j]>
						</cfif>
					</cfloop>
				</cfif>
			</cfif>
		</cfloop>

		<!--- No matches? Return the first supported element. --->
		<cfif arguments.strictMatch>
			<cfreturn "">
		</cfif>

		<cfreturn arguments.supported[1]>
	</cffunction>

	<!---
	 * Try to find the best matching locale. It supports strict locale comparison.
	 *
	 * If Config\App::$supportedLocales have "en-US" and "en-GB" locales, they can be recognized
	 * as two different locales. This method checks first for the strict match, then fallback
	 * to the most general locale (in this case "en") ISO 639-1 and finally to the locale variant
	 * "en-*" (ISO 639-1 plus "wildcard" for ISO 3166-1 alpha-2).
	 *
	 * If nothing from above is matched, then it returns the first option from the $supportedLocales array.
	 *
	 * @param supportedLocales App-supported values, an array of strings
	 * @param header           Compatible 'Accept-Language' header string
	--->
	<cffunction name="getBestLocaleMatch" access="public" returntype="string" output="no">
		<cfargument name="supportedLocales" type="array" required="yes">
		<cfargument name="header" type="any" required="no" default="">
		<cfset var acceptable = "">
		<cfset var parsed = ArrayNew(1)>
		<cfset var fallbackLocales = ArrayNew(1)>
		<cfset var accept = "">
		<cfset var fallbackLocale = "">
		<cfset var hasZero = false>
		<cfset var i = 0>
		<cfset var j = 0>
		<cfset var k = 0>

		<cfif ArrayLen(arguments.supportedLocales) EQ 0>
			<cfthrow type="ColdIgniter.HTTP.Exceptions.HTTPException" message="You must provide an array of supported values to all Negotiations.">
		</cfif>

		<cfif arguments.header EQ "">
			<cfreturn arguments.supportedLocales[1]>
		</cfif>

		<cfset acceptable = parseHeader(arguments.header)>

		<cfloop from="1" to="#ArrayLen(acceptable)#" index="i">
			<cfif acceptable[i].q EQ 0>
				<cfset hasZero = true>
			</cfif>
		</cfloop>

		<!--- the supported values are only compared by specificity when a value can be excluded --->
		<cfif hasZero>
			<cfloop from="1" to="#ArrayLen(arguments.supportedLocales)#" index="j">
				<cfset ArrayAppend(parsed, parseSupported(arguments.supportedLocales[j]))>
			</cfloop>
		</cfif>

		<cfloop from="1" to="#ArrayLen(acceptable)#" index="i">
			<cfset accept = acceptable[i]>

			<!--- if acceptable quality is zero, skip it. --->
			<cfif accept.q NEQ 0>
				<cfif accept.value EQ "*" AND NOT hasZero>
					<cfreturn arguments.supportedLocales[1]>
				<cfelseif accept.value EQ "*">
					<!--- if acceptable value is "anything", return the first available
					      that the header does not exclude --->
					<cfloop from="1" to="#ArrayLen(parsed)#" index="j">
						<cfif NOT isExcluded(acceptable, parsed[j], false, true)>
							<cfreturn arguments.supportedLocales[j]>
						</cfif>
					</cfloop>
				<cfelse>
					<!--- look for exact match --->
					<cfloop from="1" to="#ArrayLen(arguments.supportedLocales)#" index="j">
						<cfif Compare(arguments.supportedLocales[j], accept.value) EQ 0>
							<cfreturn accept.value>
						</cfif>
					</cfloop>

					<!--- set a fallback locale --->
					<cfset ArrayAppend(fallbackLocales, ListFirst(accept.value, "-"))>
				</cfif>
			</cfif>
		</cfloop>

		<cfloop from="1" to="#ArrayLen(fallbackLocales)#" index="k">
			<cfset fallbackLocale = fallbackLocales[k]>

			<!--- look for exact match --->
			<cfloop from="1" to="#ArrayLen(arguments.supportedLocales)#" index="j">
				<cfif Compare(arguments.supportedLocales[j], fallbackLocale) EQ 0
					AND (NOT hasZero OR NOT isExcluded(acceptable, parsed[j], false, true))>
					<cfreturn fallbackLocale>
				</cfif>
			</cfloop>

			<!--- look for regional locale match --->
			<cfloop from="1" to="#ArrayLen(arguments.supportedLocales)#" index="j">
				<cfif str_starts_with(arguments.supportedLocales[j], fallbackLocale & "-")
					AND (NOT hasZero OR NOT isExcluded(acceptable, parsed[j], false, true))>
					<cfreturn arguments.supportedLocales[j]>
				</cfif>
			</cfloop>
		</cfloop>

		<cfreturn arguments.supportedLocales[1]>
	</cffunction>

	<!---
	 * Parses a supported value into its entry. A value without a comma or a
	 * semicolon has nothing to parse, which is the common case.
	 *
	 * @return The entry of the highest ranking value
	--->
	<cffunction name="parseSupported" access="private" returntype="any" output="no">
		<cfargument name="supported" type="string" required="yes">
		<cfset var entry = "">
		<cfset var entries = "">

		<cfif Find(",", arguments.supported) EQ 0 AND Find(";", arguments.supported) EQ 0>
			<cfset entry = StructNew()>
			<cfset entry.value = Trim(arguments.supported)>
			<cfset entry.q = 1>
			<cfset entry.params = StructNew()>

			<cfreturn entry>
		</cfif>

		<cfset entries = parseHeader(arguments.supported)>

		<cfreturn entries[1]>
	</cffunction>

	<!---
	 * The part of a string before a position, which may be the first character.
	--->
	<cffunction name="before" access="private" returntype="string" output="no">
		<cfargument name="string" type="string" required="yes">
		<cfargument name="position" type="numeric" required="yes">

		<cfif arguments.position LTE 1>
			<cfreturn "">
		</cfif>

		<cfreturn Left(arguments.string, arguments.position - 1)>
	</cffunction>

	<!---
	 * Checks whether the header excludes a supported value, that is, whether
	 * the most specific value in the header that matches it has q=0.
	 *
	 * @param acceptable   The entries of the header
	 * @param supported    The entry of the supported value
	 * @param enforceTypes If TRUE, the values are media types.
	 * @param matchLocales If TRUE, the values are language tags.
	--->
	<cffunction name="isExcluded" access="private" returntype="boolean" output="no">
		<cfargument name="acceptable" type="array" required="yes">
		<cfargument name="supported" type="struct" required="yes">
		<cfargument name="enforceTypes" type="boolean" required="yes">
		<cfargument name="matchLocales" type="boolean" required="yes">
		<cfset var specificity = -1>
		<cfset var excluded = false>
		<cfset var acceptSpecificity = 0>
		<cfset var i = 0>

		<!--- The header is sorted by quality, so of two equally specific values,
		      the one with the higher quality is used. --->
		<cfloop from="1" to="#ArrayLen(arguments.acceptable)#" index="i">
			<cfset acceptSpecificity = getMatchSpecificity(arguments.acceptable[i], arguments.supported, arguments.enforceTypes, arguments.matchLocales)>

			<cfif acceptSpecificity GT specificity>
				<cfset specificity = acceptSpecificity>
				<cfset excluded = arguments.acceptable[i].q EQ 0>
			</cfif>
		</cfloop>

		<cfreturn excluded>
	</cffunction>

	<!---
	 * Returns how specifically a header value matches a supported value, or -1
	 * if it does not match it. A wildcard is the least specific.
	 *
	 * A media range matches the media types of its type and subtype that have
	 * its parameters. "text/html" is more specific than "text/*", which is more
	 * specific than a full wildcard, and a range is more specific than one of
	 * the same kind with fewer parameters, so "text/html;level=1" is more
	 * specific than "text/html", and "text/*;charset=utf-8" than "text/*"
	 * (RFC 9110, Section 12.5.1). Types, subtypes, parameter names and charset
	 * values are compared ignoring case (RFC 9110, Section 8.3).
	 * A language range matches the tags that equal it or start with it followed
	 * by "-", ignoring case, and is more specific with more subtags
	 * (RFC 4647, Section 3.3.1). Other values must be equal, ignoring case.
	 *
	 * @param accept    The entry of the header value
	 * @param supported The entry of the supported value
	--->
	<cffunction name="getMatchSpecificity" access="private" returntype="numeric" output="no">
		<cfargument name="accept" type="struct" required="yes">
		<cfargument name="supported" type="struct" required="yes">
		<cfargument name="enforceTypes" type="boolean" required="yes">
		<cfargument name="matchLocales" type="boolean" required="yes">
		<cfset var range = "">
		<cfset var aType = "">
		<cfset var aSubType = "">
		<cfset var sRange = "">
		<cfset var sType = "">
		<cfset var sSubType = "">
		<cfset var level = 0>
		<cfset var label = "">
		<cfset var aTag = "">
		<cfset var sTag = "">
		<cfset var position = 0>

		<cfif arguments.enforceTypes>
			<cfset range = LCase(arguments.accept.value)>
			<cfset position = Find("/", range)>
			<cfif position GT 0>
				<cfset aType = before(range, position)>
				<cfset aSubType = Mid(range, position + 1, Len(range))>
			<cfelse>
				<cfset aType = range>
			</cfif>

			<cfset sRange = LCase(arguments.supported.value)>
			<cfset position = Find("/", sRange)>
			<cfif position GT 0>
				<cfset sType = before(sRange, position)>
				<cfset sSubType = Mid(sRange, position + 1, Len(sRange))>
			<cfelse>
				<cfset sType = sRange>
			</cfif>

			<cfif range EQ "*" OR range EQ "*/*">
				<cfset level = 0>
			<cfelseif Compare(aType, sType) EQ 0 AND Compare(aSubType, "*") EQ 0>
				<cfset level = 1>
			<cfelseif Compare(aType, sType) EQ 0 AND Compare(aSubType, sSubType) EQ 0>
				<cfset level = 2>
			<cfelse>
				<cfreturn -1>
			</cfif>

			<cfloop collection="#arguments.accept.params#" item="label">
				<cfif NOT StructKeyExists(arguments.supported.params, label)>
					<cfreturn -1>
				</cfif>

				<cfif label EQ "charset">
					<cfif CompareNoCase(arguments.accept.params[label], arguments.supported.params[label]) NEQ 0>
						<cfreturn -1>
					</cfif>
				<cfelseif Compare(arguments.accept.params[label], arguments.supported.params[label]) NEQ 0>
					<cfreturn -1>
				</cfif>
			</cfloop>

			<!--- A range has at most as many parameters as the value it matches,
			      so it is more specific than any range of a lower level. --->
			<cfreturn level * (StructCount(arguments.supported.params) + 1) + StructCount(arguments.accept.params)>
		</cfif>

		<cfif arguments.accept.value EQ "*" OR arguments.accept.value EQ "*/*">
			<cfreturn 0>
		</cfif>

		<cfif arguments.matchLocales>
			<cfset aTag = LCase(arguments.accept.value)>
			<cfset sTag = LCase(arguments.supported.value)>

			<cfif Compare(aTag, sTag) NEQ 0 AND NOT str_starts_with(sTag, aTag & "-")>
				<cfreturn -1>
			</cfif>

			<cfreturn Len(aTag) - Len(Replace(aTag, "-", "", "all")) + 1>
		</cfif>

		<cfif CompareNoCase(arguments.accept.value, arguments.supported.value) EQ 0>
			<cfreturn 1>
		</cfif>

		<cfreturn -1>
	</cffunction>

	<!---
	 * Parses an Accept* header into it's multiple values.
	 *
	 * This is based on code from Aura.Accept library.
	 *
	 * @return An array of entries, each a struct of the keys value, q (a number) and params (a struct)
	--->
	<cffunction name="parseHeader" access="public" returntype="array" output="no">
		<cfargument name="header" type="string" required="yes">
		<cfset var results = ArrayNew(1)>
		<cfset var acceptable = JavaCast("string", arguments.header).split(",", JavaCast("int", -1))>
		<cfset var n = ArrayLen(acceptable)>
		<cfset var pairs = "">
		<cfset var entry = "">
		<cfset var pair = "">
		<cfset var name = "">
		<cfset var rest = "">
		<cfset var quote = "">
		<cfset var item = "">
		<cfset var better = false>
		<cfset var i = 0>
		<cfset var j = 0>
		<cfset var position = 0>
		<cfset var itemAst = 0>
		<cfset var prevAst = 0>

		<cfloop from="1" to="#n#" index="i">
			<cfset pairs = acceptable[i].split(";", JavaCast("int", -1))>

			<cfset entry = StructNew()>
			<cfset entry.value = Trim(pairs[1])>
			<cfset entry.q = 1>
			<cfset entry.params = StructNew()>

			<cfloop from="2" to="#ArrayLen(pairs)#" index="j">
				<cfset pair = pairs[j]>

				<!--- name=value, where the value may be in quotes, and the name has at least one character --->
				<cfset position = 0>
				<cfif Len(pair) GT 1>
					<cfset position = Find("=", pair, 2)>
				</cfif>

				<cfif position GT 0>
					<cfset name = Trim(Left(pair, position - 1))>
					<cfset rest = Mid(pair, position + 1, Len(pair))>

					<cfif Len(rest) GT 0>
						<cfset quote = Left(rest, 1)>

						<cfif quote EQ """" OR quote EQ "'">
							<cfset rest = Mid(rest, 2, Len(rest))>
							<cfif Len(rest) GT 0 AND Right(rest, 1) EQ quote>
								<cfset rest = Left(rest, Len(rest) - 1)>
							</cfif>
						</cfif>
					</cfif>

					<cfif Compare(name, "q") EQ 0>
						<cfset entry.q = Val(Trim(rest))>
					<cfelseif Len(name) GT 0>
						<cfset entry.params[name] = Trim(rest)>
					</cfif>
				</cfif>
			</cfloop>

			<cfset ArrayAppend(results, entry)>
		</cfloop>

		<!--- Sort to get the highest results first, a stable insertion sort: a value
		      moves up past the ones before it only if it is better than them. --->
		<cfloop from="2" to="#n#" index="i">
			<cfset item = results[i]>
			<cfset j = i - 1>

			<cfloop condition="j GTE 1">
				<cfif item.q NEQ results[j].q>
					<cfset better = item.q GT results[j].q>
				<cfelse>
					<!--- '*/*' has lower precedence than 'text/*',
					      and 'text/*' has lower priority than 'text/plain' --->
					<cfset itemAst = Len(item.value) - Len(Replace(item.value, "*", "", "all"))>
					<cfset prevAst = Len(results[j].value) - Len(Replace(results[j].value, "*", "", "all"))>

					<cfif itemAst NEQ prevAst>
						<cfset better = itemAst LT prevAst>
					<cfelse>
						<!--- If the counts are the same, but one element
						      has more params than another, it has higher precedence. --->
						<cfset better = StructCount(item.params) GT StructCount(results[j].params)>
					</cfif>
				</cfif>

				<cfif NOT better>
					<cfbreak>
				</cfif>

				<cfset results[j + 1] = results[j]>
				<cfset j = j - 1>
			</cfloop>

			<cfset results[j + 1] = item>
		</cfloop>

		<cfreturn results>
	</cffunction>

	<!---
	 * Match-maker
	 *
	 * @param acceptable The entry of the header value
	 * @param supported  The supported value, a string
	--->
	<cffunction name="match" access="public" returntype="boolean" output="no">
		<cfargument name="acceptable" type="struct" required="yes">
		<cfargument name="supported" type="string" required="yes">
		<cfargument name="enforceTypes" type="boolean" required="no" default="false">
		<cfargument name="matchLocales" type="boolean" required="no" default="false">

		<cfreturn matchParsed(arguments.acceptable, parseSupported(arguments.supported), arguments.enforceTypes, arguments.matchLocales)>
	</cffunction>

	<!---
	 * The match-maker, for a supported value that is parsed already.
	--->
	<cffunction name="matchParsed" access="private" returntype="boolean" output="no">
		<cfargument name="acceptable" type="struct" required="yes">
		<cfargument name="supported" type="struct" required="yes">
		<cfargument name="enforceTypes" type="boolean" required="yes">
		<cfargument name="matchLocales" type="boolean" required="yes">

		<!--- Is it an exact match? --->
		<cfif Compare(arguments.acceptable.value, arguments.supported.value) EQ 0>
			<cfreturn matchParameters(arguments.acceptable, arguments.supported)>
		</cfif>

		<!--- Do we need to compare types/sub-types? Only used
		      by negotiateMedia(). --->
		<cfif arguments.enforceTypes>
			<cfreturn matchTypes(arguments.acceptable, arguments.supported)>
		</cfif>

		<!--- Do we need to match locales against broader locales? --->
		<cfif arguments.matchLocales>
			<cfreturn this.matchLocales(arguments.acceptable, arguments.supported)>
		</cfif>

		<cfreturn false>
	</cffunction>

	<!---
	 * Checks two Accept values with matching 'values' to see if their
	 * 'params' are the same.
	 *
	 * @param acceptable The entry of the header value
	 * @param supported  The entry of the supported value
	--->
	<cffunction name="matchParameters" access="public" returntype="boolean" output="no">
		<cfargument name="acceptable" type="struct" required="yes">
		<cfargument name="supported" type="struct" required="yes">
		<cfset var label = "">

		<cfif StructCount(arguments.acceptable.params) NEQ StructCount(arguments.supported.params)>
			<cfreturn false>
		</cfif>

		<cfloop collection="#arguments.supported.params#" item="label">
			<cfif NOT StructKeyExists(arguments.acceptable.params, label)
				OR Compare(arguments.acceptable.params[label], arguments.supported.params[label]) NEQ 0>
				<cfreturn false>
			</cfif>
		</cfloop>

		<cfreturn true>
	</cffunction>

	<!---
	 * Compares the types/subtypes of an acceptable Media type and
	 * the supported string.
	 *
	 * @param acceptable The entry of the header value
	 * @param supported  The entry of the supported value
	--->
	<cffunction name="matchTypes" access="public" returntype="boolean" output="no">
		<cfargument name="acceptable" type="struct" required="yes">
		<cfargument name="supported" type="struct" required="yes">
		<cfset var aValue = arguments.acceptable.value>
		<cfset var sValue = arguments.supported.value>
		<cfset var aPos = Find("/", aValue)>
		<cfset var sPos = Find("/", sValue)>
		<cfset var aSubType = "">
		<cfset var sSubType = "">
		<cfset var position = 0>

		<!--- A value without a subtype, such as a malformed "json", is not a media type. --->
		<cfif aPos EQ 0 OR sPos EQ 0>
			<cfreturn false>
		</cfif>

		<!--- If the types don't match, we're done. --->
		<cfif Compare(before(aValue, aPos), before(sValue, sPos)) NEQ 0>
			<cfreturn false>
		</cfif>

		<!--- The subtype is up to the next slash, if there is one. --->
		<cfset aSubType = Mid(aValue, aPos + 1, Len(aValue))>
		<cfset position = Find("/", aSubType)>
		<cfif position GT 0>
			<cfset aSubType = before(aSubType, position)>
		</cfif>

		<!--- If there's an asterisk, we're cool --->
		<cfif Compare(aSubType, "*") EQ 0>
			<cfreturn true>
		</cfif>

		<cfset sSubType = Mid(sValue, sPos + 1, Len(sValue))>
		<cfset position = Find("/", sSubType)>
		<cfif position GT 0>
			<cfset sSubType = before(sSubType, position)>
		</cfif>

		<!--- Otherwise, subtypes must match also. --->
		<cfreturn Compare(aSubType, sSubType) EQ 0>
	</cffunction>

	<!---
	 * Will match locales against their broader pairs, so that fr-FR would
	 * match a supported localed of fr
	 *
	 * @param acceptable The entry of the header value
	 * @param supported  The entry of the supported value
	--->
	<cffunction name="matchLocales" access="public" returntype="boolean" output="no">
		<cfargument name="acceptable" type="struct" required="yes">
		<cfargument name="supported" type="struct" required="yes">
		<cfset var aBroad = arguments.acceptable.value>
		<cfset var sBroad = arguments.supported.value>
		<cfset var position = Find("-", aBroad)>

		<cfif position GT 1>
			<cfset aBroad = Left(aBroad, position - 1)>
		</cfif>

		<cfset position = Find("-", sBroad)>
		<cfif position GT 1>
			<cfset sBroad = Left(sBroad, position - 1)>
		</cfif>

		<cfreturn CompareNoCase(aBroad, sBroad) EQ 0>
	</cffunction>
</cfcomponent>
