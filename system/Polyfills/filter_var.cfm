<!---
 * Filters a value: filter_var(value, filter, flags).
 *
 * There are two forms. With the name of a filter ("email", "ip" or "url")
 * it validates, with a number (a constant like request.FILTER_VALIDATE_INT)
 * it filters and gives back the filtered value, as the original does.
 *
 * The form with a name: the filters are "email", "ip" and "url", for
 * FILTER_VALIDATE_EMAIL, FILTER_VALIDATE_IP and FILTER_VALIDATE_URL. The
 * flags of "ip" are "ipv4" or "ipv6" (or nothing, for both). The functions
 * that follow it in this file (the names that start with filter_) belong
 * to it.
 *
 * Difference: the form with a name returns true when the value passes and
 * false when it does not. The original returns the filtered value, and the
 * callers here only compare it with false.
 *
 * Difference: the original checks bytes, and this checks characters. A
 * character above 127 is never part of an address, a host or a URL, so the
 * result is the same.
 *
 * The email check is the regular expression of the original (the one by
 * Michael Rushton), run by the Java engine. A text of more than 320
 * characters is refused first, as the original does.
 *
 * Difference: the Java engine has no limit on backtracking, so the parts of
 * that expression that can be read in many ways are written in a form that
 * can be read in one way only and accepts the same texts. The labels of the
 * domain are "(label.)+" (the original has "((label.){1,126}){1,}" and an
 * optional "xn--" that the label accepts anyway), and the two length checks
 * at its start are done by filter_email_length_ and not by a lookahead.
 *
 * The URL check keeps only the parts of the URL parser of the original that
 * the check needs: scheme, user, password, host and port.
 *
 * The form with a number is filter_value_().
--->
<cffunction name="filter_var" returntype="any" output="no" hint="Filters a value with the filter of a name or of a constant">
	<cfargument name="value" type="any" required="yes">
	<cfargument name="filter" type="any" required="yes">
	<cfargument name="flags" type="any" required="no" default="">
	<cfset var parts = "">
	<cfset var host = "">
	<cfset var scheme = "">
	<cfset var mode = "">

	<cfif IsNumeric(arguments.filter)>
		<cfreturn filter_value_(arguments.value, arguments.filter, arguments.flags)>
	</cfif>

	<cfif Compare(arguments.filter, "email") EQ 0>
		<cfreturn filter_email_(arguments.value)>
	</cfif>

	<cfif Compare(arguments.filter, "ip") EQ 0>
		<cfif Find(":", arguments.value) GT 0>
			<cfset mode = "ipv6">
		<cfelseif Find(".", arguments.value) GT 0>
			<cfset mode = "ipv4">
		<cfelse>
			<cfreturn false>
		</cfif>

		<cfif Len(arguments.flags) GT 0 AND Compare(arguments.flags, mode) NEQ 0>
			<cfreturn false>
		</cfif>

		<cfif Compare(mode, "ipv6") EQ 0>
			<cfreturn filter_ipv6_(arguments.value)>
		</cfif>

		<cfreturn filter_ipv4_(arguments.value)>
	</cfif>

	<cfif Compare(arguments.filter, "url") EQ 0>
		<!--- only the characters of a URL may be in it (the original removes the others and compares the length) --->
		<cfif NOT JavaCast("string", arguments.value).matches("[A-Za-z0-9$_.+!*'(),{}|\\^~\[\]`<>##%"";/?:@&=-]*")>
			<cfreturn false>
		</cfif>

		<cfset parts = filter_url_parse_(arguments.value)>

		<cfif NOT parts["valid"]>
			<cfreturn false>
		</cfif>

		<cfif StructKeyExists(parts, "scheme")>
			<cfset scheme = parts["scheme"]>
		</cfif>

		<cfif Len(scheme) GT 0 AND (CompareNoCase(scheme, "http") EQ 0 OR CompareNoCase(scheme, "https") EQ 0)>
			<cfif NOT StructKeyExists(parts, "host")>
				<cfreturn false>
			</cfif>

			<cfset host = parts["host"]>

			<!--- an IPv6 enclosed by square brackets is a valid hostname --->
			<cfif Compare(Left(host, 1), "[") EQ 0 AND Compare(Right(host, 1), "]") EQ 0 AND Len(host) GTE 2>
				<cfif filter_ipv6_(Mid(host, 2, Len(host) - 2))>
					<cfreturn true>
				</cfif>
			</cfif>

			<cfif NOT filter_domain_(host)>
				<cfreturn false>
			</cfif>
		</cfif>

		<cfif NOT StructKeyExists(parts, "scheme")>
			<cfreturn false>
		</cfif>

		<!--- some schemes allow the host to be empty --->
		<cfif NOT StructKeyExists(parts, "host") AND Compare(scheme, "mailto") NEQ 0 AND Compare(scheme, "news") NEQ 0 AND Compare(scheme, "file") NEQ 0>
			<cfreturn false>
		</cfif>

		<cfif StructKeyExists(parts, "user")>
			<cfif NOT filter_userinfo_(parts["user"])>
				<cfreturn false>
			</cfif>
		</cfif>

		<cfif StructKeyExists(parts, "pass")>
			<cfif NOT filter_userinfo_(parts["pass"])>
				<cfreturn false>
			</cfif>
		</cfif>

		<cfreturn true>
	</cfif>

	<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Not ported yet: the filter #arguments.filter#.">
</cffunction>

<!---
 * Filters a value with the filter of a constant and gives back the
 * filtered value, or false when the value does not pass (an empty string,
 * which is the null of this port, with FILTER_NULL_ON_FAILURE).
 *
 * The flags are a number (the sum of the flags) or a map with the keys
 * "flags" and "options". The options are a map: "min_range", "max_range"
 * (FILTER_VALIDATE_INT, FILTER_VALIDATE_FLOAT), "regexp"
 * (FILTER_VALIDATE_REGEXP), "decimal" and "thousand"
 * (FILTER_VALIDATE_FLOAT), and "default" for all filters.
 *
 * The filters are FILTER_VALIDATE_INT, _BOOLEAN, _FLOAT, _REGEXP, _URL, _EMAIL
 * and _IP, FILTER_UNSAFE_RAW (FILTER_DEFAULT), FILTER_SANITIZE_ENCODED,
 * _SPECIAL_CHARS, _FULL_SPECIAL_CHARS, _EMAIL, _URL, _NUMBER_INT,
 * _NUMBER_FLOAT and _ADD_SLASHES. A value that is an array is filtered at
 * each of its items when FILTER_REQUIRE_ARRAY or FILTER_FORCE_ARRAY is set,
 * and does not pass otherwise.
 *
 * Not ported yet: FILTER_VALIDATE_DOMAIN, _MAC, FILTER_SANITIZE_STRING (it
 * is deprecated), FILTER_CALLBACK, and the flags FILTER_FLAG_ALLOW_HEX,
 * _ALLOW_OCTAL, _ENCODE_LOW, _ENCODE_HIGH, _ENCODE_AMP, _EMPTY_STRING_NULL,
 * _PATH_REQUIRED, _QUERY_REQUIRED, _HOSTNAME and _EMAIL_UNICODE.
 *
 * Difference: null is an empty string here, so a failure with
 * FILTER_NULL_ON_FAILURE gives an empty string.
 *
 * Difference: a number is a double here. FILTER_VALIDATE_INT gives the digits
 * as text, so all 64 bits are kept, but "min_range" and "max_range" compare
 * as doubles, so a limit above 2^53 is not exact. A float is a double.
 *
 * Difference: the original strips and encodes bytes. Here FILTER_FLAG_STRIP_HIGH
 * counts characters, not bytes: one character above 127 is removed once,
 * where the original removes each of its bytes. The URL encoding is made of
 * the UTF-8 bytes of it, as the original gives for UTF-8 text.
 *
 * Difference: FILTER_SANITIZE_FULL_SPECIAL_CHARS is htmlspecialchars with
 * quotes. The original is htmlentities-like and does not encode twice, so
 * here a text that is encoded already (&amp;) is encoded again (&amp;amp;),
 * and a character above 127 stays as it is instead of becoming an entity.
 *
 * The ranges of FILTER_FLAG_NO_RES_RANGE, _NO_PRIV_RANGE and _GLOBAL_RANGE are
 * the tables of the original (RFC 6890), see filter_ip_range_.
 *
 * @param leaf true for an item of an array: the flags about arrays are not read
--->
<cffunction name="filter_value_" returntype="any" output="no" hint="Filters a value with the filter of a constant">
	<cfargument name="value" type="any" required="yes">
	<cfargument name="filter" type="any" required="yes">
	<cfargument name="flags" type="any" required="no" default="">
	<cfargument name="leaf" type="boolean" required="no" default="false">
	<cfset var bits = 0>
	<cfset var options = "">
	<cfset var hasDefault = false>
	<cfset var failed = false>
	<cfset var falsy = false>
	<cfset var kind = 516>
	<cfset var text = "">
	<cfset var jt = "">
	<cfset var result = "">
	<cfset var digits = "">
	<cfset var big = "">
	<cfset var dec = ".">
	<cfset var sep = ",'.">
	<cfset var sepClass = "">
	<cfset var pattern = "">
	<cfset var mode = "">
	<cfset var wrapped = "">

	<cfif IsStruct(arguments.flags)>
		<cfif StructKeyExists(arguments.flags, "flags")>
			<cfset bits = Int(Val(arguments.flags["flags"]))>
		</cfif>

		<cfif StructKeyExists(arguments.flags, "options")>
			<cfset options = arguments.flags["options"]>
			<cfset hasDefault = IsStruct(options) AND StructKeyExists(options, "default")>
		</cfif>
	<cfelseif IsNumeric(arguments.flags)>
		<cfset bits = Int(arguments.flags)>
	</cfif>

	<!--- an empty filter is null here, and the original takes FILTER_UNSAFE_RAW then; a name is a TypeError there --->
	<cfif IsNumeric(arguments.filter)>
		<cfset kind = Int(arguments.filter)>
	<cfelseif Len(arguments.filter) GT 0>
		<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="filter_var(): Argument ##2 ($filter) must be of type ?int, string given">
	</cfif>

	<!--- a failure about the array flags gives false at once: the option "default" and FILTER_FORCE_ARRAY do not apply --->
	<cfif NOT arguments.leaf>
		<cfif NOT IsSimpleValue(arguments.value)>
			<!--- an array needs FILTER_REQUIRE_ARRAY or FILTER_FORCE_ARRAY --->
			<cfif BitAnd(bits, 83886080) EQ 0>
				<cfif BitAnd(bits, 134217728) NEQ 0>
					<cfreturn "">
				</cfif>

				<cfreturn false>
			<cfelse>
				<cfreturn filter_walk_(arguments.value, arguments.filter, arguments.flags, true)>
			</cfif>
		<cfelseif BitAnd(bits, 16777216) NEQ 0>
			<cfif BitAnd(bits, 134217728) NEQ 0>
				<cfreturn "">
			</cfif>

			<cfreturn false>
		</cfif>
	</cfif>

	<cfif NOT failed>
		<cfset text = arguments.value>

		<!--- a boolean is "1" or "" (a string like "yes" is not one, and its class tells) --->
		<cfif IsBoolean(text) AND NOT IsNumeric(text)>
			<cfif Compare(text.getClass().getName(), "java.lang.Boolean") EQ 0>
				<cfif text>
					<cfset text = "1">
				<cfelse>
					<cfset text = "">
				</cfif>
			</cfif>
		</cfif>

		<cfset text = text & "">

		<cfswitch expression="#kind#">
			<!--- FILTER_UNSAFE_RAW, FILTER_DEFAULT --->
			<cfcase value="516">
				<cfset result = text>

				<cfif BitAnd(bits, 524) NEQ 0>
					<cfset result = filter_strip_(text, bits)>
				</cfif>
			</cfcase>

			<!--- FILTER_VALIDATE_INT --->
			<cfcase value="257">
				<cfset jt = JavaCast("string", text).replaceAll("^[ \t\r\x0B\n]+|[ \t\r\x0B\n]+$", "")>

				<!--- no leading zero, and a sign is allowed: "-0" and "+0" pass, "007" does not --->
				<cfif jt.matches("[+-]?(0|[1-9][0-9]*)")>
					<cfset digits = jt.replaceFirst("^[+-]", "")>
					<cfset big = digits>

					<cfif Compare(Left(jt, 1), "-") EQ 0>
						<cfset big = "-" & digits>
					</cfif>

					<!--- up to 18 digits always fit in a 64-bit integer --->
					<cfif Len(digits) GT 18>
						<cftry>
							<cfset CreateObject("java", "java.lang.Long").parseLong(JavaCast("string", big))>
							<cfcatch type="any">
								<cfset failed = true>
							</cfcatch>
						</cftry>
					</cfif>

					<cfif NOT failed>
						<!--- the digits as text keep all 64 bits, a number would round --->
						<cfset result = digits>

						<cfif Compare(Left(jt, 1), "-") EQ 0 AND Compare(digits, "0") NEQ 0>
							<cfset result = "-" & digits>
						</cfif>

						<cfif IsStruct(options)>
							<cfif StructKeyExists(options, "min_range") AND result LT options["min_range"]>
								<cfset failed = true>
							</cfif>

							<cfif StructKeyExists(options, "max_range") AND result GT options["max_range"]>
								<cfset failed = true>
							</cfif>
						</cfif>
					</cfif>
				<cfelse>
					<cfset failed = true>
				</cfif>
			</cfcase>

			<!--- FILTER_VALIDATE_BOOLEAN --->
			<cfcase value="258">
				<cfset jt = LCase(JavaCast("string", text).replaceAll("^[ \t\r\x0B\n]+|[ \t\r\x0B\n]+$", ""))>

				<cfif Len(jt) EQ 0 OR ListFind("0,false,off,no", jt) GT 0>
					<!--- an empty text is false, also with FILTER_NULL_ON_FAILURE --->
					<cfset result = false>
					<cfset falsy = true>
				<cfelseif ListFind("1,true,on,yes", jt) GT 0>
					<cfset result = true>
				<cfelse>
					<cfset failed = true>
				</cfif>
			</cfcase>

			<!--- FILTER_VALIDATE_FLOAT --->
			<cfcase value="259">
				<cfset jt = JavaCast("string", text).replaceAll("^[ \t\r\x0B\n]+|[ \t\r\x0B\n]+$", "")>

				<cfif IsStruct(options)>
					<cfif StructKeyExists(options, "decimal")>
						<cfset dec = options["decimal"] & "">

						<cfif Len(dec) NEQ 1>
							<cfset failed = true>
						</cfif>
					</cfif>

					<cfif StructKeyExists(options, "thousand") AND Len(options["thousand"]) GT 0>
						<cfset sep = options["thousand"] & "">
					</cfif>
				</cfif>

				<cfif NOT failed>
					<cfset sepClass = filter_quote_(Replace(sep, dec, "", "all"))>
					<cfset dec = filter_quote_(dec)>

					<!--- the groups of thousands: 1 to 3 digits, then groups of 3 --->
					<cfif BitAnd(bits, 8192) NEQ 0 AND Len(sepClass) GT 0>
						<cfset pattern = "[+-]?([0-9]+|[0-9]{1,3}([" & sepClass & "][0-9]{3})+)?(" & dec & "[0-9]*)?([eE][+-]?[0-9]*)?">
					<cfelse>
						<cfset pattern = "[+-]?[0-9]*(" & dec & "[0-9]*)?([eE][+-]?[0-9]*)?">
						<cfset sepClass = "">
					</cfif>

					<cfif jt.matches(pattern)>
						<cfset digits = jt>

						<cfif Len(sepClass) GT 0>
							<cfset digits = digits.replaceAll("[" & sepClass & "]", "")>
						</cfif>

						<cfif Compare(dec, "\.") NEQ 0>
								<cfset digits = Replace(digits, Right(dec, 1), ".", "all")>
						</cfif>

						<cfif JavaCast("string", digits).matches("[+-]?([0-9]+(\.[0-9]*)?|\.[0-9]+)([eE][+-]?[0-9]+)?")>
							<cfset result = floatval(digits)>

							<!--- an overflow, or a number that is too small and is 0 now --->
							<cfif REFindNoCase("INF", result & "") GT 0>
								<cfset failed = true>
							<cfelseif result EQ 0 AND Len(digits) GT 1 AND REFind("[1-9]", digits) GT 0>
								<cfset failed = true>
							</cfif>

							<cfif NOT failed AND IsStruct(options)>
								<cfif StructKeyExists(options, "min_range") AND result LT options["min_range"]>
									<cfset failed = true>
								</cfif>

								<cfif StructKeyExists(options, "max_range") AND result GT options["max_range"]>
									<cfset failed = true>
								</cfif>
							</cfif>
						<cfelse>
							<cfset failed = true>
						</cfif>
					<cfelse>
						<cfset failed = true>
					</cfif>
				</cfif>
			</cfcase>

			<!--- FILTER_VALIDATE_REGEXP --->
			<cfcase value="272">
				<cfif NOT IsStruct(options) OR NOT StructKeyExists(options, "regexp")>
					<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="filter_var(): 'regexp' option missing">
				</cfif>

				<cfif preg_match(options["regexp"], text) EQ 1>
					<cfset result = text>
				<cfelse>
					<cfset failed = true>
				</cfif>
			</cfcase>

			<!--- FILTER_VALIDATE_URL --->
			<cfcase value="273">
				<cfif filter_var(text, "url")>
					<cfset result = text>
				<cfelse>
					<cfset failed = true>
				</cfif>
			</cfcase>

			<!--- FILTER_VALIDATE_EMAIL --->
			<cfcase value="274">
				<cfif filter_var(text, "email")>
					<cfset result = text>
				<cfelse>
					<cfset failed = true>
				</cfif>
			</cfcase>

			<!--- FILTER_VALIDATE_IP: FILTER_FLAG_IPV4 is 1048576, FILTER_FLAG_IPV6 is 2097152 --->
			<cfcase value="275">
				<cfif BitAnd(bits, 1048576) NEQ 0 AND BitAnd(bits, 2097152) EQ 0>
					<cfset mode = "ipv4">
				<cfelseif BitAnd(bits, 2097152) NEQ 0 AND BitAnd(bits, 1048576) EQ 0>
					<cfset mode = "ipv6">
				</cfif>

				<cfif filter_var(text, "ip", mode) AND filter_ip_range_(text, bits)>
					<cfset result = text>
				<cfelse>
					<cfset failed = true>
				</cfif>
			</cfcase>

			<!--- FILTER_SANITIZE_ENCODED: everything but letters, digits and - . _ is %XX --->
			<cfcase value="514">
				<cfset result = Replace(rawurlencode(filter_strip_(text, bits)), "~", "%7E", "all")>
			</cfcase>

			<!--- FILTER_SANITIZE_SPECIAL_CHARS --->
			<cfcase value="515">
				<cfset result = filter_strip_(text, bits)>
				<cfset result = Replace(result, "&", "&##38;", "all")>
				<cfset result = Replace(result, "'", "&##39;", "all")>
				<cfset result = Replace(result, """", "&##34;", "all")>
				<cfset result = Replace(result, "<", "&##60;", "all")>
				<cfset result = Replace(result, ">", "&##62;", "all")>
				<cfset result = filter_encode_low_(result)>
			</cfcase>

			<!--- FILTER_SANITIZE_EMAIL --->
			<cfcase value="517">
				<cfset result = JavaCast("string", text).replaceAll("[^A-Za-z0-9!##$%&'*+=?^_`{|}~@.\[\]\-]", "")>
			</cfcase>

			<!--- FILTER_SANITIZE_URL --->
			<cfcase value="518">
				<cfset result = JavaCast("string", text).replaceAll("[^A-Za-z0-9$\-_.+!*'(),{}|\\^~\[\]`<>##%"";/?:@&=]", "")>
			</cfcase>

			<!--- FILTER_SANITIZE_NUMBER_INT --->
			<cfcase value="519">
				<cfset result = JavaCast("string", text).replaceAll("[^0-9+\-]", "")>
			</cfcase>

			<!--- FILTER_SANITIZE_NUMBER_FLOAT: FILTER_FLAG_ALLOW_FRACTION 4096, _THOUSAND 8192, _SCIENTIFIC 16384 --->
			<cfcase value="520">
				<cfset pattern = "0-9+\-">

				<cfif BitAnd(bits, 4096) NEQ 0>
					<cfset pattern = pattern & ".">
				</cfif>

				<cfif BitAnd(bits, 8192) NEQ 0>
					<cfset pattern = pattern & ",">
				</cfif>

				<cfif BitAnd(bits, 16384) NEQ 0>
					<cfset pattern = pattern & "eE">
				</cfif>

				<cfset result = JavaCast("string", text).replaceAll("[^" & pattern & "]", "")>
			</cfcase>

			<!--- FILTER_SANITIZE_FULL_SPECIAL_CHARS: FILTER_FLAG_NO_ENCODE_QUOTES is 128 --->
			<cfcase value="522">
				<cfset result = Replace(text, "&", "&amp;", "all")>

				<cfif BitAnd(bits, 128) EQ 0>
					<cfset result = Replace(result, """", "&quot;", "all")>
					<cfset result = Replace(result, "'", "&##039;", "all")>
				</cfif>

				<cfset result = Replace(result, "<", "&lt;", "all")>
				<cfset result = Replace(result, ">", "&gt;", "all")>
			</cfcase>

			<!--- FILTER_SANITIZE_ADD_SLASHES --->
			<cfcase value="523">
				<cfset result = Replace(text, "\", "\\", "all")>
				<cfset result = Replace(result, "'", "\'", "all")>
				<cfset result = Replace(result, """", "\""", "all")>
				<!--- Difference: a NUL byte is not turned into the two characters \0, as Chr(0) is an empty text here --->
			</cfcase>

			<cfdefaultcase>
				<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Not ported yet: the filter #kind#.">
			</cfdefaultcase>
		</cfswitch>
	</cfif>

	<!--- 134217728 is FILTER_NULL_ON_FAILURE; the option "default" replaces a failure (and a false result without it) --->
	<cfif failed>
		<cfif hasDefault>
			<cfset result = options["default"]>
		<cfelseif BitAnd(bits, 134217728) NEQ 0>
			<cfset result = "">
		<cfelse>
			<cfset result = false>
		</cfif>
	<cfelseif falsy AND hasDefault AND BitAnd(bits, 134217728) EQ 0>
		<cfset result = options["default"]>
	</cfif>

	<!--- FILTER_FORCE_ARRAY --->
	<cfif NOT arguments.leaf AND BitAnd(bits, 67108864) NEQ 0>
		<cfset wrapped = ArrayNew(1)>
		<cfset ArrayAppend(wrapped, result)>
		<cfset result = wrapped>
	</cfif>

	<cfreturn result>
</cffunction>

<!---
 * Filters every leaf of a nested value and gives back a copy (the values
 * of the request are kept as they are). It is array_walk_recursive() with
 * filter_var() on each leaf. A map keeps its keys and their order.
 *
 * @param leaf Passed to filter_value_()
--->
<cffunction name="filter_walk_" returntype="any" output="no" hint="Filters every leaf of a nested value">
	<cfargument name="value" type="any" required="yes">
	<cfargument name="filter" type="any" required="yes">
	<cfargument name="flags" type="any" required="no" default="">
	<cfargument name="leaf" type="boolean" required="no" default="false">
	<cfset var result = "">
	<cfset var item = "">
	<cfset var key = "">
	<cfset var i = 0>

	<cfif IsArray(arguments.value)>
		<cfset result = ArrayNew(1)>

		<cfloop from="1" to="#ArrayLen(arguments.value)#" index="i">
			<cfset item = arguments.value[i]>

			<cfif IsSimpleValue(item)>
				<cfset ArrayAppend(result, filter_value_(item, arguments.filter, arguments.flags, arguments.leaf))>
			<cfelseif IsArray(item) OR IsStruct(item)>
				<cfset ArrayAppend(result, filter_walk_(item, arguments.filter, arguments.flags, arguments.leaf))>
			<cfelse>
				<cfset ArrayAppend(result, item)>
			</cfif>
		</cfloop>

		<cfreturn result>
	</cfif>

	<cfset result = CreateObject("java", "java.util.LinkedHashMap").init()>

	<cfloop collection="#arguments.value#" item="key">
		<cfset item = arguments.value[key]>

		<cfif IsSimpleValue(item)>
			<cfset result[key] = filter_value_(item, arguments.filter, arguments.flags, arguments.leaf)>
		<cfelseif IsArray(item) OR IsStruct(item)>
			<cfset result[key] = filter_walk_(item, arguments.filter, arguments.flags, arguments.leaf)>
		<cfelse>
			<cfset result[key] = item>
		</cfif>
	</cfloop>

	<cfreturn result>
</cffunction>

<!---
 * Writes every character but a letter or digit with a backslash, so that a
 * text is literal inside a regular expression.
--->
<cffunction name="filter_quote_" returntype="string" output="no" hint="Writes every character but a letter or digit with a backslash, for a regular expression">
	<cfargument name="value" type="string" required="yes">

	<cfreturn JavaCast("string", arguments.value).replaceAll("([^A-Za-z0-9])", "\\$1")>
</cffunction>

<!---
 * Removes the characters that FILTER_FLAG_STRIP_LOW (4, below 32),
 * FILTER_FLAG_STRIP_HIGH (8, above 127) and FILTER_FLAG_STRIP_BACKTICK
 * (512) name.
--->
<cffunction name="filter_strip_" returntype="string" output="no" hint="Removes the characters that the strip flags name">
	<cfargument name="value" type="string" required="yes">
	<cfargument name="bits" type="numeric" required="yes">
	<cfset var chars = "">

	<cfif BitAnd(arguments.bits, 524) EQ 0>
		<cfreturn arguments.value>
	</cfif>

	<cfif BitAnd(arguments.bits, 4) NEQ 0>
		<cfset chars = chars & "\x00-\x1F">
	</cfif>

	<cfif BitAnd(arguments.bits, 8) NEQ 0>
		<cfset chars = chars & "\u0080-\uFFFF">
	</cfif>

	<cfif BitAnd(arguments.bits, 512) NEQ 0>
		<cfset chars = chars & "`">
	</cfif>

	<cfreturn JavaCast("string", arguments.value).replaceAll("[" & chars & "]", "")>
</cffunction>

<!---
 * Writes the characters below 32 as a numeric entity (&#10;).
--->
<cffunction name="filter_encode_low_" returntype="string" output="no" hint="Writes the control characters as numeric entities">
	<cfargument name="value" type="string" required="yes">
	<cfset var matcher = CreateObject("java", "java.util.regex.Pattern").compile("[\x00-\x1F]").matcher(JavaCast("string", arguments.value))>
	<cfset var buffer = "">

	<cfif NOT matcher.find()>
		<cfreturn arguments.value>
	</cfif>

	<cfset matcher.reset()>
	<cfset buffer = CreateObject("java", "java.lang.StringBuffer").init()>

	<cfloop condition="matcher.find()">
		<cfset matcher.appendReplacement(buffer, "&##" & Asc(matcher.group()) & ";")>
	</cfloop>

	<cfset matcher.appendTail(buffer)>

	<cfreturn buffer.toString()>
</cffunction>

<!---
 * Checks the ranges that FILTER_FLAG_NO_RES_RANGE (4194304),
 * FILTER_FLAG_NO_PRIV_RANGE (8388608) and FILTER_FLAG_GLOBAL_RANGE
 * (268435456) name. The address is valid already. The tables are those of
 * ipv4_get_status_flags and ipv6_get_status_flags (RFC 6890), in the same
 * order: the first block that holds the address gives its flags, and an
 * address in no block passes every flag, also FILTER_FLAG_GLOBAL_RANGE.
 *
 * @return true when the address is not refused
--->
<cffunction name="filter_ip_range_" returntype="boolean" output="no" hint="Checks the reserved, private and global ranges of an IP address">
	<cfargument name="value" type="string" required="yes">
	<cfargument name="bits" type="numeric" required="yes">
	<cfset var ip = "">
	<cfset var isGlobal = false>
	<cfset var isReserved = false>
	<cfset var isPrivate = false>
	<cfset var special = true>

	<cfif BitAnd(arguments.bits, 281018368) EQ 0>
		<cfreturn true>
	</cfif>

	<cfif Find(":", arguments.value) EQ 0>
		<cfset ip = ArrayNew(1)>
		<cfset ArrayAppend(ip, Val(ListGetAt(arguments.value, 1, ".")))>
		<cfset ArrayAppend(ip, Val(ListGetAt(arguments.value, 2, ".")))>
		<cfset ArrayAppend(ip, Val(ListGetAt(arguments.value, 3, ".")))>
		<cfset ArrayAppend(ip, Val(ListGetAt(arguments.value, 4, ".")))>

		<!--- the numbers are the index 0 to 3 of the original, plus one --->
		<cfif ip[1] EQ 0>
			<!--- RFC 0791 - This network --->
			<cfset isReserved = true>
		<cfelseif ip[1] EQ 10>
			<!--- RFC 1918 - Private Use --->
			<cfset isPrivate = true>
		<cfelseif ip[1] EQ 100 AND ip[2] GTE 64 AND ip[2] LTE 127>
			<!--- RFC 6598 - Shared Address Space --->
		<cfelseif ip[1] EQ 127>
			<!--- RFC 1122 - Loopback --->
			<cfset isReserved = true>
		<cfelseif ip[1] EQ 169 AND ip[2] EQ 254>
			<!--- RFC 3927 - Link Local --->
			<cfset isReserved = true>
		<cfelseif ip[1] EQ 172 AND ip[2] GTE 16 AND ip[2] LTE 31>
			<!--- RFC 1918 - Private Use --->
			<cfset isPrivate = true>
		<cfelseif ip[1] EQ 192 AND ip[2] EQ 0 AND ip[3] EQ 0>
			<!--- RFC 6890 - IETF Protocol Assignments --->
		<cfelseif ip[1] EQ 192 AND ip[2] EQ 0 AND ip[3] EQ 2>
			<!--- RFC 5737 - Documentation --->
		<cfelseif ip[1] EQ 192 AND ip[2] EQ 88 AND ip[3] EQ 99>
			<!--- RFC 3068 - 6to4 Relay Anycast --->
			<cfset isGlobal = true>
		<cfelseif ip[1] EQ 192 AND ip[2] EQ 168>
			<!--- RFC 1918 - Private Use --->
			<cfset isPrivate = true>
		<cfelseif ip[1] EQ 198 AND ip[2] GTE 18 AND ip[2] LTE 19>
			<!--- RFC 2544 - Benchmarking --->
		<cfelseif ip[1] EQ 198 AND ip[2] EQ 51 AND ip[3] EQ 100>
			<!--- RFC 5737 - Documentation --->
		<cfelseif ip[1] EQ 203 AND ip[2] EQ 0 AND ip[3] EQ 113>
			<!--- RFC 5737 - Documentation --->
		<cfelseif ip[1] GTE 240>
			<!--- RFC 1122 - Reserved, and RFC 0919 - Limited Broadcast --->
			<cfset isReserved = true>
		<cfelse>
			<cfset special = false>
		</cfif>
	<cfelse>
		<cfset ip = filter_ipv6_groups_(arguments.value)>

		<cfif ip[1] EQ 0 AND ip[2] EQ 0 AND ip[3] EQ 0 AND ip[4] EQ 0 AND ip[5] EQ 0 AND ip[6] EQ 0 AND ip[7] EQ 0 AND ip[8] EQ 0>
			<!--- RFC 4291 - Unspecified Address --->
			<cfset isReserved = true>
		<cfelseif ip[1] EQ 0 AND ip[2] EQ 0 AND ip[3] EQ 0 AND ip[4] EQ 0 AND ip[5] EQ 0 AND ip[6] EQ 0 AND ip[7] EQ 0 AND ip[8] EQ 1>
			<!--- RFC 4291 - Loopback Address --->
			<cfset isReserved = true>
		<cfelseif ip[1] EQ 100 AND ip[2] EQ 65435>
			<!--- RFC 6052 - IPv4-IPv6 Translation (64:ff9b) --->
			<cfset isGlobal = true>
		<cfelseif ip[1] EQ 0 AND ip[2] EQ 0 AND ip[3] EQ 0 AND ip[4] EQ 0 AND ip[5] EQ 0 AND ip[6] EQ 65535>
			<!--- RFC 4291 - IPv4-mapped Address --->
			<cfset isReserved = true>
		<cfelseif ip[1] EQ 256 AND ip[2] EQ 0 AND ip[3] EQ 0 AND ip[4] EQ 0>
			<!--- RFC 6666 - Discard-Only Address Block (0100::) --->
		<cfelseif ip[1] EQ 8193 AND ip[2] EQ 0>
			<!--- RFC 4380 - TEREDO --->
		<cfelseif ip[1] EQ 8193 AND ip[2] LTE 511>
			<!--- RFC 2928 - IETF Protocol Assignments --->
		<cfelseif ip[1] EQ 8193 AND ip[2] EQ 2 AND ip[3] EQ 0>
			<!--- RFC 5180 - Benchmarking --->
		<cfelseif ip[1] EQ 8193 AND ip[2] EQ 3512>
			<!--- RFC 3849 - Documentation (2001:db8) --->
		<cfelseif ip[1] EQ 8193 AND ip[2] GTE 16 AND ip[2] LTE 31>
			<!--- RFC 4843 - ORCHID --->
		<cfelseif ip[1] EQ 8194>
			<!--- RFC 3056 - 6to4 --->
		<cfelseif ip[1] GTE 64512 AND ip[1] LTE 65023>
			<!--- RFC 4193 - Unique-Local --->
			<cfset isPrivate = true>
		<cfelseif ip[1] GTE 65152 AND ip[1] LTE 65215>
			<!--- RFC 4291 - Linked-Scoped Unicast --->
			<cfset isReserved = true>
		<cfelse>
			<cfset special = false>
		</cfif>
	</cfif>

	<!--- an address in no special block is not tested against the flags --->
	<cfif NOT special>
		<cfreturn true>
	</cfif>

	<cfif BitAnd(arguments.bits, 268435456) NEQ 0 AND NOT isGlobal>
		<cfreturn false>
	</cfif>

	<cfif BitAnd(arguments.bits, 8388608) NEQ 0 AND isPrivate>
		<cfreturn false>
	</cfif>

	<cfif BitAnd(arguments.bits, 4194304) NEQ 0 AND isReserved>
		<cfreturn false>
	</cfif>

	<cfreturn true>
</cffunction>

<!---
 * Gives the eight 16-bit groups of a valid IPv6 address as numbers, with the
 * "::" filled with zeros and an IPv4 tail as the last two groups.
--->
<cffunction name="filter_ipv6_groups_" returntype="any" output="no" hint="Splits an IPv6 address into eight numbers">
	<cfargument name="value" type="string" required="yes">
	<cfset var text = JavaCast("string", arguments.value).toLowerCase()>
	<cfset var groups = ArrayNew(1)>
	<cfset var leftPart = ArrayNew(1)>
	<cfset var rightPart = ArrayNew(1)>
	<cfset var head = "">
	<cfset var tail = "">
	<cfset var pos = 0>
	<cfset var i = 0>

	<!--- an IPv4 tail is two groups --->
	<cfif Find(".", text) GT 0>
		<cfset tail = ListLast(text, ":")>
		<cfset text = JavaCast("string", text).substring(JavaCast("int", 0), JavaCast("int", Len(text) - Len(tail))) & FormatBaseN(ListGetAt(tail, 1, ".") * 256 + ListGetAt(tail, 2, "."), 16) & ":" & FormatBaseN(ListGetAt(tail, 3, ".") * 256 + ListGetAt(tail, 4, "."), 16)>
	</cfif>

	<cfset pos = Find("::", text)>

	<cfif pos GT 0>
		<!--- substring takes a length of 0, where Left and Mid do not --->
		<cfset head = JavaCast("string", text).substring(JavaCast("int", 0), JavaCast("int", pos - 1))>
		<cfset tail = JavaCast("string", text).substring(JavaCast("int", pos + 1))>
		<cfset leftPart = ListToArray(head, ":")>
		<cfset rightPart = ListToArray(tail, ":")>

		<cfloop from="1" to="#ArrayLen(leftPart)#" index="i">
			<cfset ArrayAppend(groups, InputBaseN(leftPart[i], 16))>
		</cfloop>

		<cfloop from="1" to="#8 - ArrayLen(leftPart) - ArrayLen(rightPart)#" index="i">
			<cfset ArrayAppend(groups, 0)>
		</cfloop>

		<cfloop from="1" to="#ArrayLen(rightPart)#" index="i">
			<cfset ArrayAppend(groups, InputBaseN(rightPart[i], 16))>
		</cfloop>
	<cfelse>
		<cfset leftPart = ListToArray(text, ":")>

		<cfloop from="1" to="#ArrayLen(leftPart)#" index="i">
			<cfset ArrayAppend(groups, InputBaseN(leftPart[i], 16))>
		</cfloop>
	</cfif>

	<cfreturn groups>
</cffunction>

<!---
 * Checks an email address (FILTER_VALIDATE_EMAIL).
--->
<cffunction name="filter_email_" returntype="boolean" output="no" hint="Checks an email address">
	<cfargument name="value" type="string" required="yes">
	<cfset var atom = "[\x21\x23-\x27\x2A\x2B\x2D\x2F-\x39\x3D\x3F\x5E-\x7E]+">
	<cfset var quoted = "\x22(?:[\x01-\x08\x0B\x0C\x0E-\x1F\x21\x23-\x5B\x5D-\x7F]|\x5C[\x00-\x7F])*\x22">
	<cfset var word = "(?:" & atom & ")|(?:" & quoted & ")">
	<cfset var byte = "(?:25[0-5])|(?:2[0-4][0-9])|(?:1[0-9]{2})|(?:[1-9]?[0-9])">
	<cfset var h = "[a-f0-9]{1,4}">
	<cfset var domain = "(?:(?!.*[^.]{64,})(?:[a-z0-9]+(?:-+[a-z0-9]+)*\.)+(?:(?:[a-z][a-z0-9]*)|(?:(?:xn--)[a-z0-9]+))(?:-+[a-z0-9]+)*)">
	<cfset var ipv4 = "(?:" & byte & ")(?:\.(?:" & byte & ")){3}">
	<cfset var ipv6full = "IPv6:(?:(?:" & h & "(?::" & h & "){7})|(?:(?!(?:.*[a-f0-9][:\]]){7,})(?:" & h & "(?::" & h & "){0,5})?::(?:" & h & "(?::" & h & "){0,5})?))">
	<cfset var ipv6v4 = "(?:IPv6:(?:(?:" & h & "(?::" & h & "){5}:)|(?:(?!(?:.*[a-f0-9]:){5,})(?:" & h & "(?::" & h & "){0,3})?::(?:" & h & "(?::" & h & "){0,3}:)?)))?" & ipv4>
	<cfset var literal = "(?:\[(?:(?:" & ipv6full & ")|(?:" & ipv6v4 & "))\])">
	<cfset var regex = "(?i)(?:" & word & ")(?:\.(?:" & word & "))*@(?:" & domain & "|" & literal & ")">

	<cfif Len(arguments.value) GT 320>
		<cfreturn false>
	</cfif>

	<cfif NOT filter_email_length_(arguments.value)>
		<cfreturn false>
	</cfif>

	<cfreturn JavaCast("string", arguments.value).matches(regex)>
</cffunction>

<!---
 * The two length checks at the start of the expression of the original:
 * the text must not start with 255 units, nor with 65 units and then an at
 * sign. A unit is a character that is not a quote or a backslash, or a
 * backslash and the character after it (up to 126), with one optional quote
 * before it and one after it.
 *
 * @return false when the text is too long
--->
<cffunction name="filter_email_length_" returntype="boolean" output="no" hint="The length checks of an email address">
	<cfargument name="value" type="string" required="yes">
	<cfset var length = Len(arguments.value)>
	<cfset var position = 1>
	<cfset var units = 0>
	<cfset var quotes = 0>
	<cfset var text = "">

	<cfloop condition="position LTE length">
		<cfset text = Mid(arguments.value, position, 1)>

		<cfif Compare(text, Chr(34)) EQ 0>
			<cfset quotes = quotes + 1>

			<!--- one quote before the first unit, two between two units --->
			<cfif units EQ 0 AND quotes GT 1 OR quotes GT 2>
				<cfreturn true>
			</cfif>

			<cfset position = position + 1>
		<cfelse>
			<cfif Compare(text, "@") EQ 0 AND units GTE 65 AND quotes LTE 1>
				<cfreturn false>
			</cfif>

			<cfif Compare(text, "\") EQ 0>
				<cfif position EQ length OR Asc(Mid(arguments.value, position + 1, 1)) GT 126>
					<cfreturn true>
				</cfif>

				<cfset position = position + 2>
			<cfelse>
				<cfset position = position + 1>
			</cfif>

			<cfset units = units + 1>
			<cfset quotes = 0>

			<cfif units GTE 255>
				<cfreturn false>
			</cfif>
		</cfif>
	</cfloop>

	<cfreturn true>
</cffunction>

<!---
 * Checks a dotted IPv4 address: four numbers up to 255, no leading zero.
--->
<cffunction name="filter_ipv4_" returntype="boolean" output="no" hint="Checks a dotted IPv4 address">
	<cfargument name="value" type="string" required="yes">
	<cfset var length = Len(arguments.value)>
	<cfset var position = 1>
	<cfset var count = 0>
	<cfset var number = 0>
	<cfset var digits = 0>
	<cfset var leadingZero = false>

	<cfloop condition="position LTE length">
		<cfif NOT filter_isdigit_(Mid(arguments.value, position, 1))>
			<cfreturn false>
		</cfif>

		<cfset leadingZero = Compare(Mid(arguments.value, position, 1), "0") EQ 0>
		<cfset digits = 1>
		<cfset number = Val(Mid(arguments.value, position, 1))>
		<cfset position = position + 1>

		<cfloop condition="position LTE length AND filter_isdigit_(Mid(arguments.value, position, 1))">
			<cfset number = number * 10 + Val(Mid(arguments.value, position, 1))>
			<cfset position = position + 1>
			<cfset digits = digits + 1>

			<cfif number GT 255 OR digits GT 3>
				<cfreturn false>
			</cfif>
		</cfloop>

		<!--- a leading 0 introduces octal numbers, which are not supported --->
		<cfif leadingZero AND (number NEQ 0 OR digits GT 1)>
			<cfreturn false>
		</cfif>

		<cfset count = count + 1>

		<cfif count EQ 4>
			<cfreturn position GT length>
		</cfif>

		<cfif position GT length>
			<cfreturn false>
		</cfif>

		<cfif Compare(Mid(arguments.value, position, 1), ".") NEQ 0>
			<cfreturn false>
		</cfif>

		<cfset position = position + 1>
	</cfloop>

	<cfreturn false>
</cffunction>

<!---
 * Checks an IPv6 address, also with an IPv4 address at the end.
--->
<cffunction name="filter_ipv6_" returntype="boolean" output="no" hint="Checks an IPv6 address">
	<cfargument name="value" type="string" required="yes">
	<cfset var length = Len(arguments.value)>
	<cfset var position = 1>
	<cfset var ipv4 = 0>
	<cfset var blocks = 0>
	<cfset var compressed = -1>
	<cfset var count = 0>

	<cfif Find(":", arguments.value) EQ 0>
		<cfreturn false>
	</cfif>

	<!--- check for bundled IPv4 --->
	<cfset ipv4 = Find(".", arguments.value)>

	<cfif ipv4 GT 0>
		<cfloop condition="ipv4 GT 1 AND Compare(Mid(arguments.value, ipv4 - 1, 1), ':') NEQ 0">
			<cfset ipv4 = ipv4 - 1>
		</cfloop>

		<cfif NOT filter_ipv4_(Mid(arguments.value, ipv4, length - ipv4 + 1))>
			<cfreturn false>
		</cfif>

		<!--- the length without the IPv4 address --->
		<cfset length = ipv4 - 1>

		<cfif length LT 2>
			<cfreturn false>
		</cfif>

		<cfif Compare(Mid(arguments.value, ipv4 - 2, 1), ":") NEQ 0>
			<!--- do not include the : before the IPv4 address unless it is a :: --->
			<cfset length = length - 1>
		</cfif>

		<cfset blocks = 2>
	</cfif>

	<cfloop condition="position LTE length">
		<cfif Compare(Mid(arguments.value, position, 1), ":") EQ 0>
			<cfset position = position + 1>

			<cfif position GT length>
				<!--- cannot end in : without a previous : --->
				<cfreturn false>
			</cfif>

			<cfif Compare(Mid(arguments.value, position, 1), ":") EQ 0>
				<cfif compressed GTE 0>
					<!--- cannot have multiple :: --->
					<cfreturn false>
				</cfif>

				<!--- :: means 1 or more 16-bit 0 blocks --->
				<cfset compressed = blocks>
				<cfset blocks = blocks + 1>
				<cfset position = position + 1>

				<cfif position GT length>
					<cfreturn blocks LTE 8>
				</cfif>
			<cfelseif position - 1 EQ 1>
				<!--- do not allow a leading : without another : following --->
				<cfreturn false>
			</cfif>
		</cfif>

		<!--- check for valid hex --->
		<cfset count = 0>

		<cfloop condition="position LTE length AND filter_isxdigit_(Mid(arguments.value, position, 1))">
			<cfset count = count + 1>
			<cfset position = position + 1>
		</cfloop>

		<cfif count LT 1 OR count GT 4>
			<cfreturn false>
		</cfif>

		<cfset blocks = blocks + 1>

		<cfif blocks GT 8>
			<cfreturn false>
		</cfif>
	</cfloop>

	<cfreturn (compressed GTE 0 AND blocks LTE 8) OR blocks EQ 8>
</cffunction>

<!---
 * Checks a host name: letters, digits and dashes, in labels of up to 63
 * characters, that start and end with a letter or a digit.
--->
<cffunction name="filter_domain_" returntype="boolean" output="no" hint="Checks a host name">
	<cfargument name="value" type="string" required="yes">
	<cfset var length = Len(arguments.value)>
	<cfset var position = 1>
	<cfset var counter = 1>
	<cfset var character = "">

	<!--- ignore a trailing dot --->
	<cfif length GT 0>
		<cfif Compare(Mid(arguments.value, length, 1), ".") EQ 0>
			<cfset length = length - 1>
		</cfif>
	</cfif>

	<!--- the total length cannot exceed 253 characters, the final dot not included --->
	<cfif length GT 253>
		<cfreturn false>
	</cfif>

	<!--- the first character must be alphanumeric --->
	<cfif NOT filter_isalnum_(Mid(arguments.value, 1, 1))>
		<cfreturn false>
	</cfif>

	<cfloop condition="position LTE length">
		<cfset character = Mid(arguments.value, position, 1)>

		<cfif Compare(character, ".") EQ 0>
			<!--- the first and the last character of a label must be alphanumeric --->
			<cfif NOT filter_isalnum_(Mid(arguments.value, position - 1, 1)) OR NOT filter_isalnum_(Mid(arguments.value, position + 1, 1))>
				<cfreturn false>
			</cfif>

			<cfset counter = 0>
		<cfelseif counter GT 63 OR (Compare(character, "-") NEQ 0 AND NOT filter_isalnum_(character))>
			<cfreturn false>
		</cfif>

		<cfset position = position + 1>
		<cfset counter = counter + 1>
	</cfloop>

	<!--- the last character of the final label must be alphanumeric --->
	<cfif length LT 1>
		<cfreturn false>
	</cfif>

	<cfreturn filter_isalnum_(Mid(arguments.value, length, 1))>
</cffunction>

<!---
 * Checks the user or the password of a URL: letters, digits, "-._~!$&'()*+,;=:"
 * and "%" followed by a digit and a hexadecimal digit.
--->
<cffunction name="filter_userinfo_" returntype="boolean" output="no" hint="Checks the user or the password of a URL">
	<cfargument name="value" type="string" required="yes">
	<cfset var length = Len(arguments.value)>
	<cfset var position = 1>
	<cfset var character = "">

	<cfloop condition="position LTE length">
		<cfset character = Mid(arguments.value, position, 1)>

		<cfif filter_isalnum_(character) OR Find(character, "-._~!$&'()*+,;=:") GT 0>
			<cfset position = position + 1>
		<cfelseif Compare(character, "%") EQ 0 AND position LTE length - 2>
			<cfif filter_isdigit_(Mid(arguments.value, position + 1, 1)) AND filter_isxdigit_(Mid(arguments.value, position + 2, 1))>
				<cfset position = position + 3>
			<cfelse>
				<cfreturn false>
			</cfif>
		<cfelse>
			<cfreturn false>
		</cfif>
	</cfloop>

	<cfreturn true>
</cffunction>

<!---
 * Splits a URL like the URL parser of the original: scheme, user, pass, host
 * and port. The result is a map with the key "valid" (false when the parser
 * refuses the text) and the parts that are in the text. The path, the query
 * and the fragment are not read.
--->
<cffunction name="filter_url_parse_" returntype="any" output="no" hint="Splits a URL into its parts">
	<cfargument name="value" type="string" required="yes">
	<cfset var result = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset var text = arguments.value>
	<cfset var ue = Len(arguments.value) + 1>
	<cfset var s = 1>
	<cfset var e = Find(":", arguments.value)>
	<cfset var p = 0>
	<cfset var pp = 0>
	<cfset var q = 0>
	<cfset var state = "">
	<cfset var bad = false>
	<cfset var port = 0>
	<cfset var scheme = "">
	<cfset var portText = "">

	<cfset result["valid"] = true>

	<cfif e GT 0 AND e NEQ s>
		<!--- validate the scheme: 1*[ lowalpha | digit | "+" | "-" | "." ] --->
		<cfloop from="#s#" to="#e - 1#" index="p">
			<cfif NOT filter_isalnum_(Mid(text, p, 1)) AND Find(Mid(text, p, 1), "+.-") EQ 0>
				<cfset bad = true>
				<cfbreak>
			</cfif>
		</cfloop>

		<cfif bad>
			<cfif e + 1 LT ue AND e LT filter_cspn_(text, s, "?##")>
				<cfset state = "port">
			<cfelseif s + 1 LT ue AND Compare(Mid(text, s, 2), "//") EQ 0>
				<cfset s = s + 2>
				<cfset e = 0>
				<cfset state = "host">
			<cfelse>
				<cfset state = "path">
			</cfif>
		<cfelse>
			<cfif e + 1 EQ ue>
				<!--- only the scheme is available --->
				<cfset result["scheme"] = Mid(text, s, e - s)>
				<cfreturn result>
			</cfif>

			<!--- some schemes, like mailto:, may not have any / after them --->
			<cfif Compare(Mid(text, e + 1, 1), "/") NEQ 0>
				<!--- check if the data is a port, to read a.com:80 --->
				<cfset p = e + 1>

				<cfloop condition="p LT ue AND filter_isdigit_(Mid(text, p, 1))">
					<cfset p = p + 1>
				</cfloop>

				<cfif (p EQ ue OR Compare(Mid(text, p, 1), "/") EQ 0) AND p - e LT 7>
					<cfset state = "port">
				<cfelse>
					<cfset result["scheme"] = Mid(text, s, e - s)>
					<cfset s = e + 1>
					<cfset state = "path">
				</cfif>
			<cfelse>
				<cfset scheme = Mid(text, s, e - s)>
				<cfset result["scheme"] = scheme>

				<cfif e + 2 LT ue AND Compare(Mid(text, e + 2, 1), "/") EQ 0>
					<cfset s = e + 3>
					<cfset state = "host">

					<cfif CompareNoCase(scheme, "file") EQ 0>
						<cfif e + 3 LT ue AND Compare(Mid(text, e + 3, 1), "/") EQ 0>
							<!--- support windows drive letters, as in file:///c:/somedir/file.txt --->
							<cfif e + 5 LT ue AND Compare(Mid(text, e + 5, 1), ":") EQ 0>
								<cfset s = e + 4>
							</cfif>

							<cfset state = "path">
						</cfif>
					</cfif>
				<cfelse>
					<cfset s = e + 1>
					<cfset state = "path">
				</cfif>
			</cfif>
		</cfif>
	<cfelseif e GT 0>
		<!--- no scheme, it starts with a colon: look for a port --->
		<cfset state = "port">
	<cfelseif s + 1 LT ue AND Compare(Mid(text, s, 2), "//") EQ 0>
		<cfset s = s + 2>
		<cfset state = "host">
	<cfelse>
		<cfset state = "path">
	</cfif>

	<cfif Compare(state, "port") EQ 0>
		<cfset p = e + 1>
		<cfset pp = p>

		<cfloop condition="pp LT ue AND pp - p LT 6 AND filter_isdigit_(Mid(text, pp, 1))">
			<cfset pp = pp + 1>
		</cfloop>

		<cfif pp - p GT 0 AND pp - p LT 6 AND (pp EQ ue OR Compare(Mid(text, pp, 1), "/") EQ 0)>
			<cfset port = Val(Mid(text, p, pp - p))>

			<cfif port GT 65535>
				<cfset result["valid"] = false>
				<cfreturn result>
			</cfif>

			<cfset result["port"] = port>

			<cfif s + 1 LT ue AND Compare(Mid(text, s, 2), "//") EQ 0>
				<cfset s = s + 2>
			</cfif>

			<cfset state = "host">
		<cfelseif p EQ pp AND pp EQ ue>
			<cfset result["valid"] = false>
			<cfreturn result>
		<cfelseif s + 1 LT ue AND Compare(Mid(text, s, 2), "//") EQ 0>
			<cfset s = s + 2>
			<cfset state = "host">
		<cfelse>
			<cfset state = "path">
		</cfif>
	</cfif>

	<cfif Compare(state, "host") NEQ 0>
		<cfreturn result>
	</cfif>

	<cfset e = filter_cspn_(text, s, "/?##")>

	<!--- check for a login and a password --->
	<cfset p = 0>

	<cfloop from="#e - 1#" to="#s#" index="q" step="-1">
		<cfif Compare(Mid(text, q, 1), "@") EQ 0>
			<cfset p = q>
			<cfbreak>
		</cfif>
	</cfloop>

	<cfif p GT 0>
		<cfset pp = 0>

		<cfloop from="#s#" to="#p - 1#" index="q">
			<cfif Compare(Mid(text, q, 1), ":") EQ 0>
				<cfset pp = q>
				<cfbreak>
			</cfif>
		</cfloop>

		<cfif pp GT 0>
			<cfset result["user"] = Mid(text, s, pp - s)>
			<cfset result["pass"] = Mid(text, pp + 1, p - pp - 1)>
		<cfelse>
			<cfset result["user"] = Mid(text, s, p - s)>
		</cfif>

		<cfset s = p + 1>
	</cfif>

	<!--- check for a port --->
	<cfset p = 0>

	<cfif s LT ue AND Compare(Mid(text, s, 1), "[") EQ 0 AND Compare(Mid(text, e - 1, 1), "]") EQ 0>
		<!--- an IPv6 address inside brackets: no port scan --->
		<cfset p = 0>
	<cfelse>
		<cfloop from="#e - 1#" to="#s#" index="q" step="-1">
			<cfif Compare(Mid(text, q, 1), ":") EQ 0>
				<cfset p = q>
				<cfbreak>
			</cfif>
		</cfloop>
	</cfif>

	<cfif p GT 0>
		<cfif NOT StructKeyExists(result, "port") OR result["port"] EQ 0>
			<cfif e - (p + 1) GT 5>
				<!--- a port cannot be longer than 5 characters --->
				<cfset result["valid"] = false>
				<cfreturn result>
			<cfelseif e - (p + 1) GT 0>
				<cfset portText = Mid(text, p + 1, e - p - 1)>

				<!--- the number at the start of the text, like the C function strtol --->
				<cfif NOT JavaCast("string", portText).matches("[ \t\n\x0B\f\r]*[+-]?[0-9]+.*")>
					<cfset result["valid"] = false>
					<cfreturn result>
				</cfif>

				<cfset port = Val(JavaCast("string", portText).replaceFirst("^[ \t\n\r\f\x0B]*", ""))>

				<cfif port LT 0 OR port GT 65535>
					<cfset result["valid"] = false>
					<cfreturn result>
				</cfif>

				<cfset result["port"] = port>
			</cfif>
		</cfif>
	<cfelse>
		<cfset p = e>
	</cfif>

	<!--- check if there is a valid host, if not the text is not a URL --->
	<cfif p - s LT 1>
		<cfset result["valid"] = false>
		<cfreturn result>
	</cfif>

	<cfset result["host"] = Mid(text, s, p - s)>

	<cfreturn result>
</cffunction>

<!---
 * Finds the first of the characters in the text, from a position. It gives
 * the position after the text when there is none.
--->
<cffunction name="filter_cspn_" returntype="numeric" output="no" hint="Finds the first of some characters in a text">
	<cfargument name="value" type="string" required="yes">
	<cfargument name="start" type="numeric" required="yes">
	<cfargument name="characters" type="string" required="yes">
	<cfset var position = arguments.start>
	<cfset var length = Len(arguments.value)>

	<cfloop condition="position LTE length">
		<cfif Find(Mid(arguments.value, position, 1), arguments.characters) GT 0>
			<cfreturn position>
		</cfif>

		<cfset position = position + 1>
	</cfloop>

	<cfreturn length + 1>
</cffunction>

<cffunction name="filter_isalnum_" returntype="boolean" output="no" hint="Checks for one letter or digit of ASCII">
	<cfargument name="character" type="string" required="yes">
	<cfreturn Len(arguments.character) EQ 1 AND REFind("[A-Za-z0-9]", arguments.character) GT 0>
</cffunction>

<cffunction name="filter_isdigit_" returntype="boolean" output="no" hint="Checks for one digit of ASCII">
	<cfargument name="character" type="string" required="yes">
	<cfreturn Len(arguments.character) EQ 1 AND REFind("[0-9]", arguments.character) GT 0>
</cffunction>

<cffunction name="filter_isxdigit_" returntype="boolean" output="no" hint="Checks for one hexadecimal digit of ASCII">
	<cfargument name="character" type="string" required="yes">
	<cfreturn Len(arguments.character) EQ 1 AND REFind("[0-9A-Fa-f]", arguments.character) GT 0>
</cffunction>
