<!---
 * ColdIgniter Number Helpers
 *
 * Difference: the original formats with the intl extension (ICU
 * NumberFormatter). Here java.text.NumberFormat and java.text.DecimalFormat
 * of Java 1.4.2 do it, with a java.util.Locale. Their locale data is older
 * than ICU, so the output can differ for a locale other than "en_US":
 * the currency symbol (a code such as "GBP" in a locale that does not use
 * it), the decimal and grouping separators and the no-break space of some
 * locales, the pattern of a negative currency amount ("($1,234)" where
 * ICU prints "-$1,234"), and a locale Java does not know (it falls back to
 * the root locale). The unit names come from lang() as in the original.
 *
 * Not ported yet: NumberFormatter errors (intl_is_failure). Java throws an
 * exception for a bad currency code or locale; format_number() turns it
 * into a BadFunctionCallException (the class is not ported, so the type
 * "ColdIgniter.Exceptions.BadFunctionCallException" is thrown).
 *
 * Difference: Java 1.4.2 does not know every ISO 4217 code (it has no
 * "RSD", for one), so number_to_currency() with such a code throws that
 * BadFunctionCallException, where ICU formats it.
 *
 * A function here has no guard against a second definition (the original
 * checks function_exists): helper() keeps the first definition of a name.
 *
 * Where the original takes null for locale or options, the argument is
 * left out or is an empty string, because null and an empty string cannot
 * be told apart. Options are a map (see array_()).
--->

<!---
 * Formats a numbers as bytes, based on size, and adds the appropriate suffix
 *
 * @param num       Will be cast as int
 * @param precision
 * @param locale    [optional] An empty string (null) for the default locale
 *
 * @return false for a number that is not numeric, or the formatted string
--->
<cffunction name="number_to_size" returntype="any" output="no" hint="Formats a numbers as bytes, based on size, and adds the appropriate suffix">
	<cfargument name="num" type="any" required="yes">
	<cfargument name="precision" type="numeric" required="no" default="1">
	<cfargument name="locale" type="string" required="no" default="">
	<cfset var generalLocale = arguments.locale>
	<cfset var underscorePos = 0>
	<cfset var unit = "">

	<!--- Strip any formatting & ensure numeric input --->
	<!--- Difference: a non-numeric value is tested, where the original catches the warning (ErrorException). --->
	<!--- Only a leading-numeric string ("12abc") gives false there; a wholly non-numeric one ("abc") throws a TypeError, and here it gives false as well. --->
	<cfset arguments.num = str_replace(",", "", arguments.num & "")>
	<cfif NOT is_numeric(arguments.num)>
		<cfreturn false>
	</cfif>
	<cfset arguments.num = floatval(arguments.num)>

	<!--- ignore sub part --->
	<cfif arguments.locale NEQ "">
		<cfset underscorePos = strpos(arguments.locale, "_")>
		<cfif underscorePos GT 0>
			<cfset generalLocale = substr(arguments.locale, 0, underscorePos)>
		</cfif>
	</cfif>

	<cfif arguments.num GTE 1000000000000>
		<cfset arguments.num = round_(arguments.num / 1099511627776, arguments.precision)>
		<cfset unit = lang("Number.terabyteAbbr", "", generalLocale)>
	<cfelseif arguments.num GTE 1000000000>
		<cfset arguments.num = round_(arguments.num / 1073741824, arguments.precision)>
		<cfset unit = lang("Number.gigabyteAbbr", "", generalLocale)>
	<cfelseif arguments.num GTE 1000000>
		<cfset arguments.num = round_(arguments.num / 1048576, arguments.precision)>
		<cfset unit = lang("Number.megabyteAbbr", "", generalLocale)>
	<cfelseif arguments.num GTE 1000>
		<cfset arguments.num = round_(arguments.num / 1024, arguments.precision)>
		<cfset unit = lang("Number.kilobyteAbbr", "", generalLocale)>
	<cfelse>
		<cfset unit = lang("Number.bytes", "", generalLocale)>
	</cfif>

	<cfreturn format_number(arguments.num, arguments.precision, arguments.locale, array_("after", " " & unit))>
</cffunction>

<!---
 * Converts numbers to a more readable representation
 * when dealing with very large numbers (in the thousands or above),
 * up to the quadrillions, because you won't often deal with numbers
 * larger than that.
 *
 * It uses the "short form" numbering system as this is most commonly
 * used within most English-speaking countries today.
 *
 * @see https://simple.wikipedia.org/wiki/Names_for_large_numbers
 *
 * @param num       Will be cast as int
 * @param precision [optional] The optional number of decimal digits to round to.
 * @param locale    [optional] An empty string (null) for the default locale
 *
 * @return false for a number that is not numeric, or the formatted string
--->
<cffunction name="number_to_amount" returntype="any" output="no" hint="Converts numbers to a more readable representation when dealing with very large numbers">
	<cfargument name="num" type="any" required="yes">
	<cfargument name="precision" type="numeric" required="no" default="0">
	<cfargument name="locale" type="string" required="no" default="">
	<cfset var suffix = "">
	<cfset var generalLocale = arguments.locale>
	<cfset var underscorePos = 0>

	<!--- Strip any formatting & ensure numeric input --->
	<!--- Difference: a non-numeric value is tested, where the original catches the warning (ErrorException). --->
	<!--- Only a leading-numeric string ("12abc") gives false there; a wholly non-numeric one ("abc") throws a TypeError, and here it gives false as well. --->
	<cfset arguments.num = str_replace(",", "", arguments.num & "")>
	<cfif NOT is_numeric(arguments.num)>
		<cfreturn false>
	</cfif>
	<cfset arguments.num = floatval(arguments.num)>

	<!--- ignore sub part --->
	<cfif arguments.locale NEQ "">
		<cfset underscorePos = strpos(arguments.locale, "_")>
		<cfif underscorePos GT 0>
			<cfset generalLocale = substr(arguments.locale, 0, underscorePos)>
		</cfif>
	</cfif>

	<cfif arguments.num GTE 1000000000000000>
		<cfset suffix = lang("Number.quadrillion", "", generalLocale)>
		<cfset arguments.num = round_(arguments.num / 1000000000000000, arguments.precision)>
	<cfelseif arguments.num GTE 1000000000000>
		<cfset suffix = lang("Number.trillion", "", generalLocale)>
		<cfset arguments.num = round_(arguments.num / 1000000000000, arguments.precision)>
	<cfelseif arguments.num GTE 1000000000>
		<cfset suffix = lang("Number.billion", "", generalLocale)>
		<cfset arguments.num = round_(arguments.num / 1000000000, arguments.precision)>
	<cfelseif arguments.num GTE 1000000>
		<cfset suffix = lang("Number.million", "", generalLocale)>
		<cfset arguments.num = round_(arguments.num / 1000000, arguments.precision)>
	<cfelseif arguments.num GTE 1000>
		<cfset suffix = lang("Number.thousand", "", generalLocale)>
		<cfset arguments.num = round_(arguments.num / 1000, arguments.precision)>
	</cfif>

	<cfreturn format_number(arguments.num, arguments.precision, arguments.locale, array_("after", suffix))>
</cffunction>

<!---
 * Formats a number as a currency in the locale.
 *
 * @param num      The amount
 * @param currency The ISO 4217 code, e.g. "USD"
 * @param locale   An empty string (null) for the default locale
 * @param fraction The number of fraction digits
--->
<cffunction name="number_to_currency" returntype="string" output="no" hint="Formats a number as a currency in the locale">
	<cfargument name="num" type="numeric" required="yes">
	<cfargument name="currency" type="string" required="yes">
	<cfargument name="locale" type="string" required="no" default="">
	<cfargument name="fraction" type="numeric" required="no" default="0">

	<!--- Difference: NumberFormatter::CURRENCY is its value, 2. --->
	<cfreturn format_number(arguments.num, 1, arguments.locale, array_("type", 2, "currency", arguments.currency, "fraction", arguments.fraction))>
</cffunction>

<!---
 * A general purpose, locale-aware, number_format method.
 * Used by all of the functions of the number_helper.
 *
 * @param num
 * @param precision
 * @param locale    An empty string (null) for the default locale of the request
 * @param options   A map (see array_()) of before, after, type, currency and fraction
--->
<cffunction name="format_number" returntype="string" output="no" hint="A general purpose, locale-aware, number_format method">
	<cfargument name="num" type="numeric" required="yes">
	<cfargument name="precision" type="numeric" required="no" default="1">
	<cfargument name="locale" type="string" required="no" default="">
	<cfargument name="options" type="any" required="no" default="">
	<cfset var options_ = arguments.options>
	<cfset var parts = ArrayNew(1)>
	<cfset var javaLocale = "">
	<cfset var type = 1>
	<cfset var formatter = "">
	<cfset var pattern = "">
	<cfset var output = "">
	<cfset var handles = number_handles_()>
	<cfset var reason = "">
	<cfset var found = 0>
	<cfset var rest = "">

	<!--- If locale is not passed, get from the default locale that is set from our config file --->
	<!--- or set by HTTP content negotiation. --->
	<cfif arguments.locale EQ "">
		<cfset arguments.locale = service("request").getLocale_()>
	</cfif>

	<cfif NOT IsStruct(options_)>
		<cfset options_ = array_()>
	</cfif>

	<!--- Type can be any of the NumberFormatter options, but provide a default. --->
	<!--- Difference: only DECIMAL (1) and CURRENCY (2) exist, as the plain numbers. --->
	<cfif StructKeyExists(options_, "type")>
		<cfset type = Fix(Val(options_["type"]))>
	</cfif>

	<!--- Difference: a Java locale is made from "en_US" or "en-US"; ICU keywords ("@") are not read. --->
	<!--- A Locale is immutable, so one made for a name is kept (at most 100 names) and used again. --->
	<cfif handles.locales.containsKey(JavaCast("string", arguments.locale))>
		<cfset javaLocale = handles.locales.get(JavaCast("string", arguments.locale))>
	<cfelse>
		<cfset parts = ListToArray(Replace(arguments.locale, "-", "_", "all"), "_")>
		<cfif ArrayLen(parts) GTE 3>
			<cfset javaLocale = CreateObject("java", "java.util.Locale").init(parts[1], parts[2], parts[3])>
		<cfelseif ArrayLen(parts) EQ 2>
			<cfset javaLocale = CreateObject("java", "java.util.Locale").init(parts[1], parts[2])>
		<cfelseif ArrayLen(parts) EQ 1>
			<cfset javaLocale = CreateObject("java", "java.util.Locale").init(parts[1])>
		<cfelse>
			<cfset javaLocale = CreateObject("java", "java.util.Locale").init("")>
		</cfif>

		<cfif handles.locales.size() LT 100>
			<cfset handles.locales.put(JavaCast("string", arguments.locale), javaLocale)>
		</cfif>
	</cfif>

	<cftry>
		<cfif type EQ 2>
			<cfset formatter = handles.numberFormat.getCurrencyInstance(javaLocale)>
		<cfelse>
			<cfset formatter = handles.numberFormat.getInstance(javaLocale)>
		</cfif>

		<!--- Try to format it per the locale --->
		<cfif type EQ 2>
			<!--- Difference: FRACTION_DIGITS sets the minimum and the maximum, as two calls. --->
			<cfset formatter.setMinimumFractionDigits(JavaCast("int", Fix(Val(options_["fraction"]))))>
			<cfset formatter.setMaximumFractionDigits(JavaCast("int", Fix(Val(options_["fraction"]))))>
			<cfset formatter.setCurrency(handles.currency.getInstance(JavaCast("string", options_["currency"])))>
			<cfset output = format_number_java_(handles, formatter, arguments.num)>
		<cfelse>
			<!--- In order to specify a precision, we'll have to modify --->
			<!--- the pattern used by NumberFormatter. --->
			<!--- Difference: a number sign is written ## in a string here, so the pattern is ##,####0. --->
			<cfset pattern = "##,####0." & RepeatString("##", arguments.precision)>

			<cfset formatter.applyPattern(JavaCast("string", pattern))>
			<cfset output = format_number_java_(handles, formatter, arguments.num)>
		</cfif>

		<cfcatch type="java.lang.Exception">
			<!--- Difference: a call through reflection fails with an InvocationTargetException that has no message, so the message of its cause is used. --->
			<cfset reason = cfcatch.message>
			<cfif reason EQ "">
				<cfset found = Find("Caused by: ", cfcatch.stackTrace)>
				<cfif found GT 0>
					<cfset rest = Mid(cfcatch.stackTrace, found + 11, Len(cfcatch.stackTrace))>
					<cfif Find(Chr(10), rest) GT 0>
						<cfset rest = Left(rest, Find(Chr(10), rest) - 1)>
					</cfif>
					<cfset reason = Trim(rest)>
				</cfif>
			</cfif>
			<cfif reason EQ "">
				<cfset reason = cfcatch.type>
			</cfif>
			<cfthrow type="ColdIgniter.Exceptions.BadFunctionCallException" message="#reason#">
		</cfcatch>
	</cftry>

	<!--- This might lead a trailing period if precision == 0 --->
	<cfset output = trim_(output, ". ")>

	<!--- Add on any before/after text. --->
	<cfif StructKeyExists(options_, "before") AND IsSimpleValue(options_["before"])>
		<cfset output = options_["before"] & output>
	</cfif>

	<cfif StructKeyExists(options_, "after") AND IsSimpleValue(options_["after"])>
		<cfset output = output & options_["after"]>
	</cfif>

	<cfreturn output>
</cffunction>

<!---
 * Returns the Java objects that the formatting needs and that can be kept:
 * the format(double) Method, the class handles for the static calls, the
 * reflection helpers and a table of Locale objects by name.
 *
 * Difference: not in the original. Looking these up takes about a
 * millisecond, so they are kept in the memory of the site in production
 * (shared_().number in the application scope, one entry per system folder), anywhere else
 * in request.ColdIgniter.number for the request only, and made for the
 * call when there is no request.ColdIgniter. They hold no value of the
 * configuration. A Method, a Class and a Locale are immutable, and the
 * table of locales is a synchronized java.util.Hashtable. A
 * NumberFormat is not thread-safe and is never kept.
 *
 * The entry is complete before it is stored with one assignment, so it
 * needs no lock: two requests that build it at the same time store equal
 * values.
--->
<cffunction name="number_handles_" returntype="struct" output="no" hint="Returns the Java objects that the number formatting keeps">
	<cfset var kept = "">
	<cfset var handles = "">

	<cfif StructKeyExists(request, "ENVIRONMENT") AND request.ENVIRONMENT EQ "production" AND StructKeyExists(request, "SYSTEMPATH")>
		<cfset kept = shared_().number>

		<cfif NOT StructKeyExists(kept, request.SYSTEMPATH)>
			<!--- complete before it is stored: two requests that build it store equal values --->
			<cfset handles = number_handles_make_()>
			<cfset kept[request.SYSTEMPATH] = handles>
		</cfif>

		<cfreturn kept[request.SYSTEMPATH]>
	</cfif>

	<cfif StructKeyExists(request, "ColdIgniter")>
		<cfif NOT StructKeyExists(request.ColdIgniter, "number")>
			<cfset request.ColdIgniter.number = number_handles_make_()>
		</cfif>

		<cfreturn request.ColdIgniter.number>
	</cfif>

	<!--- nowhere to keep them: made for this call only --->
	<cfreturn number_handles_make_()>
</cffunction>

<!---
 * Makes the entry of number_handles_().
--->
<cffunction name="number_handles_make_" returntype="struct" output="no" hint="Makes the Java objects that the number formatting keeps">
	<cfset var handles = StructNew()>
	<cfset var classClass = CreateObject("java", "java.lang.Class")>
	<cfset var types = "">

	<cfset handles.reflectArray = CreateObject("java", "java.lang.reflect.Array")>
	<cfset handles.objectClass = classClass.forName("java.lang.Object")>
	<cfset handles.numberFormat = CreateObject("java", "java.text.NumberFormat")>
	<cfset handles.currency = CreateObject("java", "java.util.Currency")>
	<cfset handles.locales = CreateObject("java", "java.util.Hashtable").init()>

	<cfset types = handles.reflectArray.newInstance(classClass.forName("java.lang.Class"), JavaCast("int", 1))>
	<cfset handles.reflectArray.set(types, JavaCast("int", 0), CreateObject("java", "java.lang.Double").TYPE)>
	<cfset handles.format = classClass.forName("java.text.NumberFormat").getMethod("format", types)>

	<cfreturn handles>
</cffunction>

<!---
 * Calls format(double) of a java.text.NumberFormat.
 *
 * Difference: not in the original. The method format is overloaded
 * (double, long, Object and the forms with a StringBuffer) and the server
 * does not choose one for a number, so the method for a double, kept by
 * number_handles_(), is invoked.
 *
 * @param handles   See number_handles_()
 * @param formatter A java.text.NumberFormat
 * @param num
--->
<cffunction name="format_number_java_" returntype="string" output="no" hint="Calls format(double) of a java.text.NumberFormat">
	<cfargument name="handles" type="struct" required="yes">
	<cfargument name="formatter" type="any" required="yes">
	<cfargument name="num" type="numeric" required="yes">
	<cfset var values = arguments.handles.reflectArray.newInstance(arguments.handles.objectClass, JavaCast("int", 1))>

	<cfset arguments.handles.reflectArray.set(values, JavaCast("int", 0), CreateObject("java", "java.lang.Double").init(JavaCast("double", arguments.num)))>

	<cfreturn arguments.handles.format.invoke(arguments.formatter, values) & "">
</cffunction>

<!---
 * Convert a number to a roman numeral.
 *
 * Difference: a number outside 1 to 3999 gives an empty string (null).
 * The map of numerals is built on each call (no static variable), as two
 * lists in the same order.
 *
 * @param num it will convert to int
--->
<cffunction name="number_to_roman" returntype="string" output="no" hint="Convert a number to a roman numeral">
	<cfargument name="num" type="any" required="yes">
	<cfset var romans = ListToArray("M,CM,D,CD,C,XC,L,XL,X,IX,V,IV,I")>
	<cfset var arabics = ListToArray("1000,900,500,400,100,90,50,40,10,9,5,4,1")>
	<cfset var result = "">
	<cfset var repeat = 0>
	<cfset var i = 0>

	<!--- Difference: a numeric value is read in full, any other string by Val() for its numeric prefix. --->
	<cfif is_numeric(arguments.num)>
		<cfset arguments.num = Fix(floatval(arguments.num))>
	<cfelse>
		<cfset arguments.num = Fix(Val(arguments.num))>
	</cfif>

	<cfif arguments.num LT 1 OR arguments.num GT 3999>
		<cfreturn "">
	</cfif>

	<cfloop from="1" to="#ArrayLen(romans)#" index="i">
		<cfset repeat = Fix(arguments.num / arabics[i])>
		<cfset result = result & RepeatString(romans[i], repeat)>
		<cfset arguments.num = arguments.num MOD arabics[i]>
	</cfloop>

	<cfreturn result>
</cffunction>
