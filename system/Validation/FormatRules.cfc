<!---
 * Format validation Rules.
 *
 * Not ported yet:
 *  - valid_json, because 6.1 has no JSON parser. A rule that is not a method
 *    here is "not found" (the rule throws ValidationException.forRuleNotFound).
 *  - the idn_to_ascii step of valid_email, and the binary addresses (inet_ntop)
 *    of valid_ip.
 *  - valid_date without a format (strtotime), and the tokens e, T, z, x, X
 *    and p of a format. They throw an InvalidArgumentException/LogicException.
 *
 * Difference: there is no null. An empty string stands in for it, so a rule
 * that tells null from an empty string in the original takes the "present"
 * branch for an empty string here: alpha_space("") is false (true for null),
 * valid_base64("") is true (false for null), string("") is true (false for null).
 *
 * Difference: there is no type of a value. A number and its text are the
 * same, so string(5) is true (false for an int in the original). A value that
 * is a list or a map is turned into the text "Array", as the original
 * does where it casts to a string.
 *
 * Difference: the regular expressions are run by the Java engine (see the
 * reference), and the letter classes are written out as ASCII ranges.
--->
<cfcomponent output="no" hint="Format validation Rules">

	<!---
	 * Alpha
	 *
	 * @param str string|null
	--->
	<cffunction name="alpha" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfset arguments.str = strval(arguments.str)>

		<cfreturn JavaCast("string", arguments.str).matches("[A-Za-z]+")>
	</cffunction>

	<!---
	 * Alpha with spaces.
	 *
	 * @param value string|null Value.
	 *
	 * @return True if alpha with spaces, else false.
	--->
	<cffunction name="alpha_space" access="public" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="no" default="">

		<!--- Difference: a null is true in the original, an empty string is false here --->
		<cfset arguments.value = strval(arguments.value)>

		<cfreturn JavaCast("string", arguments.value).matches("[A-Za-z ]+")>
	</cffunction>

	<!---
	 * Alphanumeric with underscores and dashes
	 *
	 * @param str string|null
	--->
	<cffunction name="alpha_dash" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfset arguments.str = strval(arguments.str)>

		<cfreturn JavaCast("string", arguments.str).matches("[A-Za-z0-9_-]+")>
	</cffunction>

	<!---
	 * Alphanumeric, spaces, and a limited set of punctuation characters.
	 * Accepted punctuation characters are: ~ tilde, ! exclamation,
	 * # number, $ dollar, % percent, & ampersand, * asterisk, - dash,
	 * _ underscore, + plus, = equals, | vertical bar, : colon, . period
	 * ~ ! # $ % & * - _ + = | : .
	 *
	 * @param str string|null
	 *
	 * @return boolean
	--->
	<cffunction name="alpha_numeric_punct" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfset arguments.str = strval(arguments.str)>

		<cfreturn JavaCast("string", arguments.str).matches("[A-Za-z0-9 ~!##$%&*\-_+=|:.]+")>
	</cffunction>

	<!---
	 * Alphanumeric
	 *
	 * @param str string|null
	--->
	<cffunction name="alpha_numeric" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfset arguments.str = strval(arguments.str)>

		<cfreturn JavaCast("string", arguments.str).matches("[A-Za-z0-9]+")>
	</cffunction>

	<!---
	 * Alphanumeric w/ spaces
	 *
	 * @param str string|null
	--->
	<cffunction name="alpha_numeric_space" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfset arguments.str = strval(arguments.str)>

		<cfreturn JavaCast("string", arguments.str).matches("[A-Za-z0-9 ]+")>
	</cffunction>

	<!---
	 * Any type of string
	 *
	 * Note: we specifically do NOT type hint str here so that
	 * it doesn't convert numbers into strings.
	 *
	 * Difference: a number and its text cannot be told apart, so a simple
	 * value is a string. A list or a map is not.
	 *
	 * @param str string|null
	--->
	<cffunction name="string" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfreturn IsSimpleValue(arguments.str)>
	</cffunction>

	<!---
	 * Decimal number
	 *
	 * @param str string|null
	--->
	<cffunction name="decimal" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfset arguments.str = strval(arguments.str)>

		<!--- Difference: no optional part before the digits, because [0-9]*\.?[0-9]+ is quadratic on a long run of digits. The same strings match. --->
		<cfreturn JavaCast("string", arguments.str).matches("[-+]?(?:[0-9]+(?:\.[0-9]+)?|\.[0-9]+)")>
	</cffunction>

	<!---
	 * String of hexidecimal characters
	 *
	 * @param str string|null
	--->
	<cffunction name="hex" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfset arguments.str = strval(arguments.str)>

		<cfreturn JavaCast("string", arguments.str).matches("[0-9A-Fa-f]+")>
	</cffunction>

	<!---
	 * Integer
	 *
	 * @param str string|null
	--->
	<cffunction name="integer" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfset arguments.str = strval(arguments.str)>

		<cfreturn JavaCast("string", arguments.str).matches("[\-+]?[0-9]+")>
	</cffunction>

	<!---
	 * Is a Natural number  (0,1,2,3, etc.)
	 *
	 * @param str string|null
	--->
	<cffunction name="is_natural" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfset arguments.str = strval(arguments.str)>

		<cfreturn JavaCast("string", arguments.str).matches("[0-9]+")>
	</cffunction>

	<!---
	 * Is a Natural number, but not a zero  (1,2,3, etc.)
	 *
	 * @param str string|null
	--->
	<cffunction name="is_natural_no_zero" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfset arguments.str = strval(arguments.str)>

		<cfif Compare(arguments.str, "0") EQ 0>
			<cfreturn false>
		</cfif>

		<cfreturn JavaCast("string", arguments.str).matches("[0-9]+")>
	</cffunction>

	<!---
	 * Numeric
	 *
	 * @param str string|null
	--->
	<cffunction name="numeric" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfset arguments.str = strval(arguments.str)>

		<!--- Difference: no optional part before the digits, because [0-9]*\.?[0-9]+ is quadratic on a long run of digits. The same strings match. --->
		<cfreturn JavaCast("string", arguments.str).matches("[\-+]?(?:[0-9]+(?:\.[0-9]+)?|\.[0-9]+)")>
	</cffunction>

	<!---
	 * Compares value against a regular expression pattern.
	 *
	 * Difference: the pattern is read by the Java engine. The delimiters
	 * and the modifiers i, m, s, x and u are read as in the original, and
	 * the POSIX classes ([:alpha:] and the others) are translated. A pattern
	 * that Java cannot compile is not a match (the original gives false for an
	 * error too). The other modifiers throw (not ported yet), and so do
	 * the features that only the original has (named groups with ?P, \h, \R,
	 * \x{...}), which fail to compile and are not a match.
	 *
	 * Difference: with the modifier x the Java engine also ignores a space
	 * inside a character class, and the original keeps it there ("/[ ]/x"
	 * matches a space in the original and nothing here).
	 *
	 * Difference: the Java engine has no limit on backtracking. A pattern
	 * that the original gives up on (and so does not match) can keep the
	 * request busy here; the pattern is written by the developer, never by
	 * the client.
	 *
	 * @param str string|null
	 * @param pattern string
	--->
	<cffunction name="regex_match" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">
		<cfargument name="pattern" type="string" required="yes">

		<cfset var text = "">
		<cfset var delimiter = "/">
		<cfset var position = 2>
		<cfset var length = 0>
		<cfset var found = 0>
		<cfset var body = "">
		<cfset var modifiers = "">
		<cfset var prefix = "(?d)">
		<cfset var modifier = "">
		<cfset var matcher = "">
		<cfset var i = 0>

		<cfset arguments.str = strval(arguments.str)>

		<cfif Compare(Left(arguments.pattern, 1), "/") NEQ 0>
			<cfset arguments.pattern = "/" & arguments.pattern & "/">
		</cfif>

		<cfset length = Len(arguments.pattern)>

		<!--- find the ending delimiter: a backslash escapes the next character --->
		<cfloop condition="position LTE length AND found EQ 0">
			<cfset text = Mid(arguments.pattern, position, 1)>

			<cfif Compare(text, "\") EQ 0>
				<cfset position = position + 2>
			<cfelseif Compare(text, delimiter) EQ 0>
				<cfset found = position>
			<cfelse>
				<cfset position = position + 1>
			</cfif>
		</cfloop>

		<!--- no ending delimiter --->
		<cfif found EQ 0>
			<cfreturn false>
		</cfif>

		<cfset body = Mid(arguments.pattern, 2, found - 2)>
		<cfset modifiers = Mid(arguments.pattern, found + 1, length - found)>

		<cfloop from="1" to="#Len(modifiers)#" index="i">
			<cfset modifier = Mid(modifiers, i, 1)>

			<cfif Compare(modifier, "i") EQ 0 OR Compare(modifier, "m") EQ 0 OR Compare(modifier, "s") EQ 0 OR Compare(modifier, "x") EQ 0>
				<cfset prefix = prefix & "(?" & modifier & ")">
			<cfelseif Compare(modifier, "u") EQ 0 OR Compare(modifier, " ") EQ 0 OR Compare(modifier, Chr(10)) EQ 0 OR Compare(modifier, Chr(13)) EQ 0>
				<!--- u changes nothing here: a string is made of characters --->
			<cfelseif Find(modifier, "ADSUXJ") GT 0>
				<cfthrow type="ColdIgniter.Exceptions.LogicException" message="Not ported yet: the regex_match modifier #modifier#.">
			<cfelse>
				<!--- unknown modifier --->
				<cfreturn false>
			</cfif>
		</cfloop>

		<cfset body = Replace(body, "[:alpha:]", "a-zA-Z", "all")>
		<cfset body = Replace(body, "[:alnum:]", "a-zA-Z0-9", "all")>
		<cfset body = Replace(body, "[:digit:]", "0-9", "all")>
		<cfset body = Replace(body, "[:lower:]", "a-z", "all")>
		<cfset body = Replace(body, "[:upper:]", "A-Z", "all")>
		<cfset body = Replace(body, "[:xdigit:]", "0-9A-Fa-f", "all")>
		<cfset body = Replace(body, "[:word:]", "A-Za-z0-9_", "all")>
		<cfset body = Replace(body, "[:blank:]", " \t", "all")>
		<cfset body = Replace(body, "[:space:]", " \t\n\r\f\x0B", "all")>
		<cfset body = Replace(body, "[:punct:]", "!-/:-@\[-`{-~", "all")>
		<cfset body = Replace(body, "[:cntrl:]", "\x00-\x1F\x7F", "all")>
		<cfset body = Replace(body, "[:print:]", "\x20-\x7E", "all")>
		<cfset body = Replace(body, "[:graph:]", "\x21-\x7E", "all")>

		<cftry>
			<!--- a subject that is too long throws and is caught below, so the rule fails --->
			<cfset regex_guard_(arguments.str)>
			<cfset matcher = CreateObject("java", "java.util.regex.Pattern").compile(JavaCast("string", prefix & body)).matcher(JavaCast("string", arguments.str))>

			<cfreturn matcher.find()>

			<cfcatch type="any">
				<cfreturn false>
			</cfcatch>
		</cftry>
	</cffunction>

	<!---
	 * Validates that the string is a valid timezone as per the
	 * timezone_identifiers_list function.
	 *
	 * Difference: the list is made from the zones that the Java runtime of
	 * 6.1 knows (Java 1.4, so an old copy of the time zone data), the
	 * same groups as the original (Africa, America, Antarctica, Arctic,
	 * Asia, Atlantic, Australia, Europe, Indian, Pacific and UTC). A
	 * zone that was added after that data is not in the list, and a zone that
	 * was removed since is.
	 *
	 * @param str string|null
	--->
	<cffunction name="timezone" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfset var identifiers = CreateObject("java", "java.util.Arrays").asList(CreateObject("java", "java.util.TimeZone").getAvailableIDs())>
		<cfset var groups = "Africa/,America/,Antarctica/,Arctic/,Asia/,Atlantic/,Australia/,Europe/,Indian/,Pacific/">
		<cfset var i = 0>

		<cfset arguments.str = strval(arguments.str)>

		<cfif Compare(arguments.str, "UTC") EQ 0>
			<cfreturn true>
		</cfif>

		<cfif NOT identifiers.contains(JavaCast("string", arguments.str))>
			<cfreturn false>
		</cfif>

		<cfloop list="#groups#" index="i">
			<cfif Compare(Left(arguments.str, Len(i)), i) EQ 0>
				<cfreturn true>
			</cfif>
		</cfloop>

		<cfreturn false>
	</cffunction>

	<!---
	 * Valid Base64
	 *
	 * Tests a string for characters outside of the Base64 alphabet
	 * as defined by RFC 2045 http://www.faqs.org/rfcs/rfc2045
	 *
	 * The text has to be what the encoder writes: the whole alphabet and the
	 * padding of the original, and nothing else, also no white space. The
	 * unused bits at the end have to be zero.
	 *
	 * Difference: a null is false in the original, an empty string is true here.
	 *
	 * @param str string|null
	--->
	<cffunction name="valid_base64" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfset var alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/">
		<cfset var length = 0>
		<cfset var last = 0>

		<cfset arguments.str = strval(arguments.str)>
		<cfset length = Len(arguments.str)>

		<cfif length EQ 0>
			<cfreturn true>
		</cfif>

		<cfif length MOD 4 NEQ 0>
			<cfreturn false>
		</cfif>

		<cfif NOT JavaCast("string", arguments.str).matches("[A-Za-z0-9+/]*={0,2}")>
			<cfreturn false>
		</cfif>

		<cfif Compare(Right(arguments.str, 2), "==") EQ 0>
			<cfset last = Find(Mid(arguments.str, length - 2, 1), alphabet) - 1>

			<cfreturn BitAnd(last, 15) EQ 0>
		</cfif>

		<cfif Compare(Right(arguments.str, 1), "=") EQ 0>
			<cfset last = Find(Mid(arguments.str, length - 1, 1), alphabet) - 1>

			<cfreturn BitAnd(last, 3) EQ 0>
		</cfif>

		<cfreturn true>
	</cffunction>

	<!---
	 * Valid JSON
	 *
	 * Not ported yet: valid_json, 6.1 has no JSON parser.
	--->

	<!---
	 * Checks for a correctly formatted email address
	 *
	 * Not ported yet: the idn_to_ascii step (internationalized domain names).
	 *
	 * @param str string|null
	--->
	<cffunction name="valid_email" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfset arguments.str = strval(arguments.str)>

		<cfreturn filter_var(arguments.str, "email")>
	</cffunction>

	<!---
	 * Validate a comma-separated list of email addresses.
	 *
	 * Example:
	 *     valid_emails[one@example.com,two@example.com]
	 *
	 * @param str string|null
	--->
	<cffunction name="valid_emails" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfset var parts = "">
		<cfset var email = "">
		<cfset var i = 0>

		<cfset arguments.str = strval(arguments.str)>

		<cfset parts = explode(",", arguments.str)>

		<cfloop from="1" to="#ArrayLen(parts)#" index="i">
			<cfset email = trim_(parts[i])>

			<cfif Compare(email, "") EQ 0>
				<cfreturn false>
			</cfif>

			<cfif valid_email(email) EQ false>
				<cfreturn false>
			</cfif>
		</cfloop>

		<cfreturn true>
	</cffunction>

	<!---
	 * Validate an IP address (human readable format or binary string - inet_pton)
	 *
	 * Not ported yet: the binary string (inet_ntop). A text with a character
	 * that cannot be printed is not an address.
	 *
	 * @param ip string|null
	 * @param which string|null IP protocol: 'ipv4' or 'ipv6'
	--->
	<cffunction name="valid_ip" access="public" returntype="boolean" output="no">
		<cfargument name="ip" type="any" required="no" default="">
		<cfargument name="which" type="string" required="no" default="">

		<cfset var option = "">

		<cfset arguments.ip = strval(arguments.ip)>

		<cfif Compare(arguments.ip, "") EQ 0>
			<cfreturn false>
		</cfif>

		<cfif Compare(LCase(arguments.which), "ipv4") EQ 0>
			<cfset option = "ipv4">
		<cfelseif Compare(LCase(arguments.which), "ipv6") EQ 0>
			<cfset option = "ipv6">
		</cfif>

		<cfreturn filter_var(arguments.ip, "ip", option)>
	</cffunction>

	<!---
	 * Checks a string to ensure it is (loosely) a URL.
	 *
	 * Warning: this rule will pass basic strings like
	 * "banana"; use valid_url_strict for a stricter rule.
	 *
	 * @param str string|null
	--->
	<cffunction name="valid_url" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfset var matcher = "">
		<cfset var scheme = "">

		<cfset arguments.str = strval(arguments.str)>

		<cfif Compare(arguments.str, "") EQ 0>
			<cfreturn false>
		</cfif>

		<!--- the dot of the original does not match a line feed only --->
		<cfset matcher = CreateObject("java", "java.util.regex.Pattern").compile(JavaCast("string", "(?:([^:]*):)?//([^\n]+)")).matcher(JavaCast("string", arguments.str))>

		<cfif matcher.matches()>
			<cfif matcher.start(JavaCast("int", 1)) GTE 0>
				<cfset scheme = matcher.group(JavaCast("int", 1))>
			</cfif>

			<cfif Compare(scheme, "http") NEQ 0 AND Compare(scheme, "https") NEQ 0>
				<cfreturn false>
			</cfif>

			<cfset arguments.str = matcher.group(JavaCast("int", 2))>
		</cfif>

		<cfset arguments.str = "http://" & arguments.str>

		<cfreturn filter_var(arguments.str, "url")>
	</cffunction>

	<!---
	 * Checks a URL to ensure it's formed correctly.
	 *
	 * Difference: an empty list of schemes ("valid_url_strict[]") cannot be
	 * told apart from no list, so it means "http,https" here. In the
	 * original it allows no scheme at all and no URL passes.
	 *
	 * @param str string|null
	 * @param validSchemes string|null comma separated list of allowed schemes
	--->
	<cffunction name="valid_url_strict" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">
		<cfargument name="validSchemes" type="string" required="no" default="">

		<cfset var parts = "">
		<cfset var scheme = "">
		<cfset var schemes = "">

		<cfset arguments.str = strval(arguments.str)>

		<cfif Compare(arguments.str, "") EQ 0 OR Compare(arguments.str, "0") EQ 0>
			<cfreturn false>
		</cfif>

		<!--- the parser gives no scheme when it refuses the text --->
		<cfset parts = filter_url_parse_(arguments.str)>

		<cfif parts["valid"] AND StructKeyExists(parts, "scheme")>
			<cfset scheme = LCase(parts["scheme"])>
		</cfif>

		<cfif is_null(arguments.validSchemes)>
			<cfset arguments.validSchemes = "http,https">
		</cfif>

		<cfset schemes = explode(",", LCase(arguments.validSchemes))>

		<cfif NOT in_array(scheme, schemes)>
			<cfreturn false>
		</cfif>

		<cfreturn filter_var(arguments.str, "url")>
	</cffunction>

	<!---
	 * Checks for a valid date and matches a given date format
	 *
	 * Not ported yet: a date without a format (strtotime). It throws.
	 *
	 * Difference: the format is read by the code below, which keeps the rules
	 * of the original for d j D l S F M m n Y y a A g h G H i s u v U O P and
	 * for ? * ! | + and a backslash. The tokens e T z x X p throw (not ported
	 * yet). A day name or a month name is looked up in the English names only.
	 * A zone (O, P) is a sign and hours with minutes, not a name.
	 *
	 * @param str string|null
	 * @param format string|null
	--->
	<cffunction name="valid_date" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">
		<cfargument name="format" type="string" required="no" default="">

		<cfset arguments.str = strval(arguments.str)>

		<cfif Compare(arguments.str, "") EQ 0>
			<cfreturn false>
		</cfif>

		<cfif Compare(arguments.format, "") EQ 0>
			<!--- Not ported yet: strtotime --->
			<cfthrow type="ColdIgniter.Exceptions.LogicException" message="Not ported yet: valid_date without a format (strtotime).">
		</cfif>

		<!---
		 * DateTime::createFromFormat() and DateTime::getLastErrors(): the date
		 * is valid when it has no error and no warning.
		--->
		<cfreturn parseFromFormat(arguments.format, arguments.str)>
	</cffunction>

	<!---
	 * Reads a text with a date format, as DateTime::createFromFormat() does,
	 * and tells whether it found no error and no warning.
	 *
	 * @param format string
	 * @param str    string
	--->
	<cffunction name="parseFromFormat" access="private" returntype="boolean" output="no">
		<cfargument name="format" type="string" required="yes">
		<cfargument name="str" type="string" required="yes">

		<cfset var unset = -1>
		<cfset var year = -1>
		<cfset var month = -1>
		<cfset var day = -1>
		<cfset var hour = -1>
		<cfset var minute = -1>
		<cfset var second = -1>
		<cfset var micro = -1>
		<cfset var haveTime = false>
		<cfset var pos = 1>
		<cfset var fpos = 1>
		<cfset var strLength = Len(arguments.str)>
		<cfset var formatLength = Len(arguments.format)>
		<cfset var token = "">
		<cfset var count = 0>
		<cfset var word = "">
		<cfset var index = 0>
		<cfset var meridian = "">
		<cfset var adjust = 0>
		<cfset var zoneLength = 0>
		<cfset var months = "january,february,march,april,may,june,july,august,september,october,november,december">
		<cfset var monthShort = "jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec">
		<cfset var days = "sunday,monday,tuesday,wednesday,thursday,friday,saturday,sun,mon,tue,wed,thu,fri,sat,tues,wednes,thur,thurs">
		<cfset var maxDay = 0>
		<cfset var stopChars = " " & Chr(9) & ".,:;/-0123456789">
		<!--- Difference: the narrow no-break space (U+202F) is left out, a character is one byte here --->
		<cfset var spaceChars = " " & Chr(9) & Chr(160)>

		<!--- the original reads while there is text and format left --->
		<cfloop condition="fpos LTE formatLength AND pos LTE strLength">
			<cfset token = Mid(arguments.format, fpos, 1)>

			<cfif Find(token, "djmnyYgGhHisuv") GT 0>
				<!--- numbers: the digits that are there, up to a limit --->
				<cfif Find(token, "djmnyg") GT 0 OR Compare(token, "h") EQ 0 OR Compare(token, "G") EQ 0 OR Compare(token, "H") EQ 0 OR Compare(token, "i") EQ 0 OR Compare(token, "s") EQ 0>
					<cfset adjust = 2>
				<cfelseif Compare(token, "Y") EQ 0>
					<cfset adjust = 4>
				<cfelseif Compare(token, "u") EQ 0>
					<cfset adjust = 6>
				<cfelse>
					<cfset adjust = 3>
				</cfif>

				<cfset count = readDigits(arguments.str, pos, adjust)>

				<!--- a number is not found, or the minute and the second need two digits --->
				<cfif count EQ 0 OR ((Compare(token, "i") EQ 0 OR Compare(token, "s") EQ 0) AND count NEQ 2)>
					<cfreturn false>
				</cfif>

				<cfset index = Val(Mid(arguments.str, pos, count))>
				<cfset pos = pos + count>

				<cfif Compare(token, "d") EQ 0 OR Compare(token, "j") EQ 0>
					<cfset day = index>
				<cfelseif Compare(token, "m") EQ 0 OR Compare(token, "n") EQ 0>
					<cfset month = index>
				<cfelseif Compare(token, "y") EQ 0>
					<!--- two digit year: 70 to 99 is 19xx, and 00 to 69 is 20xx --->
					<cfif index LT 70>
						<cfset year = index + 2000>
					<cfelse>
						<cfset year = index + 1900>
					</cfif>
				<cfelseif Compare(token, "Y") EQ 0>
					<cfset year = index>
				<cfelseif Compare(token, "g") EQ 0 OR Compare(token, "h") EQ 0>
					<!--- the hour cannot be higher than 12 --->
					<cfif index GT 12>
						<cfreturn false>
					</cfif>

					<cfset hour = index>
					<cfset haveTime = true>
				<cfelseif Compare(token, "G") EQ 0 OR Compare(token, "H") EQ 0>
					<cfset hour = index>
					<cfset haveTime = true>
				<cfelseif Compare(token, "i") EQ 0>
					<cfset minute = index>
					<cfset haveTime = true>
				<cfelseif Compare(token, "s") EQ 0>
					<cfset second = index>
					<cfset haveTime = true>
				<cfelse>
					<cfset micro = index>
				</cfif>
			<cfelseif Compare(token, "S") EQ 0>
				<!--- the English suffix of a day: st, nd, rd and th, in any case --->
				<cfif ListFindNoCase("nd,rd,st,th", Mid(arguments.str, pos, 2)) GT 0>
					<cfset pos = pos + 2>
				</cfif>
			<cfelseif Compare(token, "a") EQ 0 OR Compare(token, "A") EQ 0>
				<!--- a meridian can only come after an hour --->
				<cfif hour EQ unset>
					<cfreturn false>
				</cfif>

				<cfset meridian = LCase(Mid(arguments.str, pos, 1))>

				<cfif Compare(meridian, "a") NEQ 0 AND Compare(meridian, "p") NEQ 0>
					<cfreturn false>
				</cfif>

				<cfset pos = pos + 1>

				<cfif Compare(Mid(arguments.str, pos, 1), ".") EQ 0>
					<cfset pos = pos + 1>
				</cfif>

				<cfif Compare(LCase(Mid(arguments.str, pos, 1)), "m") NEQ 0>
					<cfreturn false>
				</cfif>

				<cfset pos = pos + 1>

				<cfif Compare(Mid(arguments.str, pos, 1), ".") EQ 0>
					<cfset pos = pos + 1>
				</cfif>

				<cfif Compare(meridian, "a") EQ 0>
					<cfif hour EQ 12>
						<cfset hour = 0>
					</cfif>
				<cfelseif hour NEQ 12>
					<cfset hour = hour + 12>
				</cfif>

				<cfset haveTime = true>
			<cfelseif Compare(token, "D") EQ 0 OR Compare(token, "l") EQ 0>
				<!--- Difference: only the letters are read as the day name, and only the English names and short names are known. The original reads up to a separator, so a name directly followed by digits fails there but passes here; it also accepts relative words such as week. Not checked against the original on this machine --->
				<cfset word = readWord(arguments.str, pos)>

				<cfif ListFindNoCase(days, word) EQ 0>
					<cfreturn false>
				</cfif>

				<cfset pos = pos + Len(word)>
			<cfelseif Compare(token, "F") EQ 0 OR Compare(token, "M") EQ 0>
				<!--- Difference: only the letters are read as the month name, and only the English names, the three letter names and sept are known. The original also skips a leading space, tab, dash, dot or slash and accepts the roman numerals i to xii; this port does not. Not checked against the original on this machine --->
				<cfset word = readWord(arguments.str, pos)>
				<cfset index = ListFindNoCase(months, word)>

				<cfif index EQ 0 AND Len(word) EQ 3>
					<cfset index = ListFindNoCase(monthShort, word)>
				</cfif>

				<cfif index EQ 0 AND CompareNoCase(word, "sept") EQ 0>
					<cfset index = 9>
				</cfif>

				<cfif index EQ 0>
					<cfreturn false>
				</cfif>

				<cfset month = index>
				<cfset pos = pos + Len(word)>
			<cfelseif Compare(token, "U") EQ 0>
				<!--- a Unix timestamp, with a minus sign or not --->
				<cfif Compare(Mid(arguments.str, pos, 1), "-") EQ 0>
					<cfset pos = pos + 1>
				</cfif>

				<cfset count = readDigits(arguments.str, pos, 24)>

				<cfif count EQ 0>
					<cfreturn false>
				</cfif>

				<cfset pos = pos + count>
			<cfelseif Compare(token, "O") EQ 0 OR Compare(token, "P") EQ 0>
				<cfset zoneLength = readZone(arguments.str, pos)>

				<cfif zoneLength EQ 0>
					<cfreturn false>
				</cfif>

				<cfset pos = pos + zoneLength>
			<cfelseif Find(token, "eTzxXp") GT 0>
				<!--- Not ported yet: the zone names, the day of the year, the signed year --->
				<cfthrow type="ColdIgniter.Exceptions.LogicException" message="Not ported yet: the date format token #token#.">
			<cfelseif Compare(token, "?") EQ 0>
				<!--- any one character --->
				<cfset pos = pos + 1>
			<cfelseif Compare(token, "*") EQ 0>
				<!--- random characters until the next separator or digit --->
				<cfloop condition="pos LTE strLength AND Find(Mid(arguments.str, pos, 1), stopChars) EQ 0">
					<cfset pos = pos + 1>
				</cfloop>
			<cfelseif Compare(token, "!") EQ 0>
				<!--- reset all fields to the Unix epoch --->
				<cfset year = 1970>
				<cfset month = 1>
				<cfset day = 1>
				<cfset hour = 0>
				<cfset minute = 0>
				<cfset second = 0>
				<cfset micro = 0>
			<cfelseif Compare(token, "|") EQ 0>
				<!--- reset the fields that are not set to the Unix epoch --->
				<cfif year EQ unset><cfset year = 1970></cfif>
				<cfif month EQ unset><cfset month = 1></cfif>
				<cfif day EQ unset><cfset day = 1></cfif>
				<cfif hour EQ unset><cfset hour = 0></cfif>
				<cfif minute EQ unset><cfset minute = 0></cfif>
				<cfif second EQ unset><cfset second = 0></cfif>
				<cfif micro EQ unset><cfset micro = 0></cfif>
			<cfelseif Compare(token, "+") EQ 0>
				<!--- the original only allows trailing text and keeps reading the format; text that is left is a warning, and a warning is not valid (see the check after the loop), so there is nothing to do here --->
			<cfelseif Compare(token, "\") EQ 0>
				<!--- the next character of the format has to be in the text --->
				<cfset fpos = fpos + 1>

				<cfif fpos GT formatLength>
					<cfreturn false>
				</cfif>

				<cfif Compare(Mid(arguments.format, fpos, 1), Mid(arguments.str, pos, 1)) NEQ 0>
					<cfreturn false>
				</cfif>

				<cfset pos = pos + 1>
			<cfelseif Compare(token, " ") EQ 0>
				<!--- zero or more spaces, tabs and no-break spaces --->
				<cfloop condition="pos LTE strLength AND Find(Mid(arguments.str, pos, 1), spaceChars) GT 0">
					<cfset pos = pos + 1>
				</cfloop>
			<cfelse>
				<!--- a separator or any other character has to be the same in the text --->
				<cfif Compare(token, Mid(arguments.str, pos, 1)) NEQ 0>
					<cfreturn false>
				</cfif>

				<cfset pos = pos + 1>
			</cfif>

			<cfset fpos = fpos + 1>
		</cfloop>

		<!--- trailing data --->
		<cfif pos LTE strLength>
			<cfreturn false>
		</cfif>

		<!--- format characters that are left: only ! | and + may be missing --->
		<cfloop condition="fpos LTE formatLength">
			<cfset token = Mid(arguments.format, fpos, 1)>

			<cfif Compare(token, "!") EQ 0>
				<cfset year = 1970>
				<cfset month = 1>
				<cfset day = 1>
				<cfset hour = 0>
				<cfset minute = 0>
				<cfset second = 0>
				<cfset micro = 0>
			<cfelseif Compare(token, "|") EQ 0>
				<cfif year EQ unset><cfset year = 1970></cfif>
				<cfif month EQ unset><cfset month = 1></cfif>
				<cfif day EQ unset><cfset day = 1></cfif>
				<cfif hour EQ unset><cfset hour = 0></cfif>
				<cfif minute EQ unset><cfset minute = 0></cfif>
				<cfif second EQ unset><cfset second = 0></cfif>
				<cfif micro EQ unset><cfset micro = 0></cfif>
			<cfelseif Compare(token, "+") NEQ 0>
				<!--- not enough data to satisfy the format --->
				<cfreturn false>
			</cfif>

			<cfset fpos = fpos + 1>
		</cfloop>

		<!--- the time fields that are not set count as zero when one of them is --->
		<cfif hour NEQ unset OR minute NEQ unset OR second NEQ unset OR micro NEQ unset>
			<cfif hour EQ unset><cfset hour = 0></cfif>
			<cfif minute EQ unset><cfset minute = 0></cfif>
			<cfif second EQ unset><cfset second = 0></cfif>
		</cfif>

		<!--- the parsed time has to be a valid time --->
		<cfif haveTime>
			<cfif hour LT 0 OR hour GT 23 OR minute LT 0 OR minute GT 59 OR second LT 0 OR second GT 59>
				<cfreturn false>
			</cfif>
		</cfif>

		<!--- the parsed date has to be a valid date, when there are a year, a month and a day --->
		<cfif year NEQ unset AND month NEQ unset AND day NEQ unset>
			<cfif month LT 1 OR month GT 12 OR day LT 1>
				<cfreturn false>
			</cfif>

			<cfset maxDay = ListGetAt("31,28,31,30,31,30,31,31,30,31,30,31", month)>

			<cfif month EQ 2 AND ((year MOD 4 EQ 0 AND year MOD 100 NEQ 0) OR year MOD 400 EQ 0)>
				<cfset maxDay = 29>
			</cfif>

			<cfif day GT maxDay>
				<cfreturn false>
			</cfif>
		</cfif>

		<cfreturn true>
	</cffunction>

	<!---
	 * Counts the digits at a position of a text, up to a limit.
	 *
	 * @param str   string
	 * @param pos   numeric
	 * @param limit numeric
	--->
	<cffunction name="readDigits" access="private" returntype="numeric" output="no">
		<cfargument name="str" type="string" required="yes">
		<cfargument name="pos" type="numeric" required="yes">
		<cfargument name="limit" type="numeric" required="yes">

		<cfset var count = 0>

		<cfloop condition="count LT arguments.limit AND arguments.pos + count LTE Len(arguments.str) AND REFind('[0-9]', Mid(arguments.str, arguments.pos + count, 1)) GT 0">
			<cfset count = count + 1>
		</cfloop>

		<cfreturn count>
	</cffunction>

	<!---
	 * Reads the letters at a position of a text.
	 *
	 * @param str string
	 * @param pos numeric
	--->
	<cffunction name="readWord" access="private" returntype="string" output="no">
		<cfargument name="str" type="string" required="yes">
		<cfargument name="pos" type="numeric" required="yes">

		<cfset var word = "">

		<cfloop condition="arguments.pos + Len(word) LTE Len(arguments.str) AND REFind('[A-Za-z]', Mid(arguments.str, arguments.pos + Len(word), 1)) GT 0">
			<cfset word = word & Mid(arguments.str, arguments.pos + Len(word), 1)>
		</cfloop>

		<cfreturn word>
	</cffunction>

	<!---
	 * Reads a zone offset at a position of a text: a sign, and the hours, with
	 * the minutes or not (+01, +0100 or +01:00). Gives the length, or zero.
	 *
	 * @param str string
	 * @param pos numeric
	--->
	<cffunction name="readZone" access="private" returntype="numeric" output="no">
		<cfargument name="str" type="string" required="yes">
		<cfargument name="pos" type="numeric" required="yes">

		<cfset var rest = Mid(arguments.str, arguments.pos, Len(arguments.str) - arguments.pos + 1)>
		<cfset var matcher = CreateObject("java", "java.util.regex.Pattern").compile(JavaCast("string", "^[+-]([0-9]{2}:[0-9]{2}|[0-9]{4}|[0-9]{1,2})")).matcher(JavaCast("string", rest))>

		<cfif matcher.find()>
			<cfreturn matcher.end()>
		</cfif>

		<cfreturn 0>
	</cffunction>

</cfcomponent>
