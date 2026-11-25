<!---
 * Time Trait
 *
 * Provides the shared functionality of Time and TimeLegacy.
 *
 * A trait is a file of properties and functions that the component
 * includes where the original says "use TimeTrait".
 *
 * Difference: there is no DateTimeImmutable, DateTimeZone, IntlCalendar or
 * IntlDateFormatter in this engine, so the instant is kept in a Java
 * GregorianCalendar (this.cal) with the microseconds apart (this.micro), and
 * the timezone is a Java TimeZone. Time is immutable: the setters, add and
 * sub give a new object (TimeLegacy changes itself in the few places where
 * DateTime does).
 *
 * Difference: the functions that are static in the original (now, parse,
 * today, ...) are called on static_("ColdIgniter\I18n\Time"). now is named
 * now_, equals is named equals_, because Now and Equals clash with a built-in
 * function and a Java method. The magic methods are called by name:
 * __get("year"), __isset("year"), __toString().
 *
 * Difference: a time string is read by a small reader of the formats that
 * strtotime knows best (ISO and other numeric dates, times with am/pm and a
 * zone, month and weekday names, today/tomorrow/yesterday/noon/midnight,
 * "first/last day of", "+1 day", "next month", "last monday", "2 days ago",
 * "@timestamp"). Any other text throws. A zone inside the string is used to
 * place the instant, and the object is then shown in the timezone it was given.
 *
 * Difference: add and sub take a relative string such as "1 day" instead of
 * a DateInterval. Timezone arguments are a name, an offset ("+02:00",
 * "GMT+2") or a Java TimeZone, and getTimezone gives the Java TimeZone.
 * getCalendar gives a Java Calendar, not an IntlCalendar. The zone data of
 * the engine is older than the one of the original.
 *
 * Not ported yet: __unserialize, the digits of other scripts in
 * toLocalizedString (ar-SA), the locale data of IntlDateFormatter beyond what
 * SimpleDateFormat knows, and the letters of the ICU patterns other than
 * those of SimpleDateFormat plus c, e, L, Q and q.
--->

<!---
 * @var TimeZone (Java)
--->
<cfset this.timezone = "">

<!---
 * The Java calendar that holds the instant, in this.timezone.
--->
<cfset this.cal = "">

<!---
 * The microseconds, 0 to 999999 (the calendar holds the milliseconds).
--->
<cfset this.micro = 0>

<!---
 * @var string
--->
<cfset this.locale = "">

<!---
 * @var string
--->
<cfset this.toStringFormat = "yyyy-MM-dd HH:mm:ss">

<!---
 * The words that tell a relative time (see hasRelativeKeywords).
 *
 * @var string
--->
<cfset this.relativePattern = "this|next|last|tomorrow|yesterday|midnight|today|[+-]|first|ago">

<!---
 * The class that is created by the functions of the trait, TimeLegacy
 * changes it.
--->
<cffunction name="className_" access="private" returntype="string" output="no">
	<cfreturn "ColdIgniter\I18n\Time">
</cffunction>

<!---
 * The object that a function like modify changes. Time gives a copy,
 * TimeLegacy gives itself.
--->
<cffunction name="target_" access="private" returntype="any" output="no">
	<cfreturn copy_()>
</cffunction>

<!---
 * The key of the test instance in request.ColdIgniter, one per class.
--->
<cffunction name="testKey_" access="private" returntype="string" output="no">
	<cfreturn "testNow" & ListLast(className_(), "\")>
</cffunction>

<!--- ------------------------------------------------------------------ --->
<!--- Helpers (these have no counterpart in the original)                 --->
<!--- ------------------------------------------------------------------ --->

<!---
 * Gets a Java TimeZone from a name, an offset, a Java TimeZone, or an empty
 * string (null) for the default of the application (Config\App appTimezone).
 * TimeZone.getTimeZone gives GMT for a name it does not know, so that is
 * checked here and thrown.
--->
<cffunction name="tzOf_" access="private" returntype="any" output="no">
	<cfargument name="timezone" type="any" required="no" default="">
	<cfset var id = "">
	<cfset var tz = "">
	<cfset var cache = "">
	<cfset var ids = "">
	<cfset var i = 0>

	<cfif NOT IsSimpleValue(arguments.timezone)>
		<cfreturn arguments.timezone>
	</cfif>

	<cfset id = Trim(arguments.timezone)>

	<cfif id EQ "">
		<cfset id = config("Config\App").appTimezone>
	</cfif>

	<cfif NOT StructKeyExists(request.ColdIgniter, "timeZones")>
		<cfset request.ColdIgniter.timeZones = CreateObject("java", "java.util.HashMap").init()>
	</cfif>

	<cfset cache = request.ColdIgniter.timeZones>

	<!--- the cache is a Java map, as a struct would not tell "utc" from "UTC" --->
	<cfif cache.containsKey(JavaCast("string", id))>
		<cfreturn cache.get(JavaCast("string", id))>
	</cfif>

	<cfif Compare(id, "Z") EQ 0>
		<cfset id = "UTC">
	<cfelseif REFind("^[+-][0-9][0-9]?(:?[0-9][0-9])?$", id) GT 0>
		<cfset id = "GMT" & id>
	</cfif>

	<cfset tz = CreateObject("java", "java.util.TimeZone").getTimeZone(JavaCast("string", id))>

	<!--- an id is not case sensitive, as in the original: look for it by its other case --->
	<cfif Compare(tz.getID(), id) NEQ 0>
		<cfset ids = CreateObject("java", "java.util.TimeZone").getAvailableIDs()>

		<cfloop from="1" to="#ArrayLen(ids)#" index="i">
			<cfif CompareNoCase(ids[i], id) EQ 0>
				<cfset tz = CreateObject("java", "java.util.TimeZone").getTimeZone(ids[i])>
				<cfbreak>
			</cfif>
		</cfloop>
	</cfif>

	<cfif Compare(tz.getID(), id) NEQ 0 AND CompareNoCase(tz.getID(), id) NEQ 0 AND NOT REFind("^GMT[+-][0-9][0-9]?(:?[0-9][0-9])?$", id) GT 0>
		<cfthrow type="ColdIgniter.Exception" message="Unknown or bad timezone (#id#)">
	</cfif>

	<cfset cache.put(JavaCast("string", id), tz)>

	<cfreturn tz>
</cffunction>

<!---
 * Gets the default locale, as a string (Config\App defaultLocale).
--->
<cffunction name="localeOf_" access="private" returntype="string" output="no">
	<cfargument name="locale" type="any" required="no" default="">

	<cfif is_null(arguments.locale)>
		<cfreturn config("Config\App").defaultLocale>
	</cfif>

	<cfreturn arguments.locale>
</cffunction>

<!---
 * A new calendar in a timezone, that is set to the current time.
--->
<cffunction name="mkCal_" access="private" returntype="any" output="no">
	<cfargument name="tz" type="any" required="yes">
	<cfset var cal = CreateObject("java", "java.util.GregorianCalendar").init()>

	<cfset cal.setTimeZone(arguments.tz)>

	<cfreturn cal>
</cffunction>

<!---
 * A java.util.Date for a number of seconds since 1970-01-01 UTC.
 * The milliseconds do not fit in an integer, so they are built from text.
--->
<cffunction name="dateOf_" access="private" returntype="any" output="no">
	<cfargument name="seconds" type="numeric" required="yes">

	<cfreturn CreateObject("java", "java.util.Date").init(CreateObject("java", "java.lang.Long").parseLong(JavaCast("string", Int(arguments.seconds) & "000")))>
</cffunction>

<!---
 * A new object of this class, without running the constructor.
--->
<cffunction name="build_" access="private" returntype="any" output="no">
	<cfargument name="date" type="any" required="yes" hint="A java.util.Date">
	<cfargument name="tz" type="any" required="yes">
	<cfargument name="locale" type="string" required="yes">
	<cfargument name="micro" type="numeric" required="yes">
	<cfset var obj = request.ColdIgniter.autoloader.instantiate(className_())>

	<cfset obj.cal = mkCal_(arguments.tz)>
	<cfset obj.cal.setTime(arguments.date)>
	<cfset obj.timezone = arguments.tz>
	<cfset obj.locale = arguments.locale>
	<cfset obj.micro = arguments.micro>

	<cfreturn obj>
</cffunction>

<!---
 * A copy of this object, the same class, instant, timezone and format.
--->
<cffunction name="copy_" access="private" returntype="any" output="no">
	<cfset var obj = build_(this.cal.getTime(), this.timezone, this.locale, this.micro)>

	<cfset obj.toStringFormat = this.toStringFormat>

	<cfreturn obj>
</cffunction>

<!---
 * Gets a field of a calendar (the numbers are those of java.util.Calendar:
 * 1 year, 2 month from 0, 3 week of year, 4 week of month, 5 day of month,
 * 6 day of year, 7 day of week from Sunday as 1, 9 am/pm, 11 hour of day,
 * 12 minute, 13 second, 14 millisecond, 15 zone offset, 16 dst offset).
--->
<cffunction name="getF_" access="private" returntype="numeric" output="no">
	<cfargument name="cal" type="any" required="yes">
	<cfargument name="field" type="numeric" required="yes">

	<cfreturn arguments.cal.get(JavaCast("int", arguments.field))>
</cffunction>

<cffunction name="setF_" access="private" returntype="void" output="no">
	<cfargument name="cal" type="any" required="yes">
	<cfargument name="field" type="numeric" required="yes">
	<cfargument name="value" type="numeric" required="yes">

	<cfset arguments.cal.set(JavaCast("int", arguments.field), JavaCast("int", arguments.value))>
</cffunction>

<cffunction name="addF_" access="private" returntype="void" output="no">
	<cfargument name="cal" type="any" required="yes">
	<cfargument name="field" type="numeric" required="yes">
	<cfargument name="value" type="numeric" required="yes">

	<cfset arguments.cal.add(JavaCast("int", arguments.field), JavaCast("int", arguments.value))>
</cffunction>

<!---
 * Pads a number with zeros on the left.
--->
<cffunction name="pad_" access="private" returntype="string" output="no">
	<cfargument name="value" type="numeric" required="yes">
	<cfargument name="length" type="numeric" required="yes">

	<cfreturn Right(RepeatString("0", arguments.length) & Abs(arguments.value), arguments.length)>
</cffunction>

<!---
 * The Java Locale of a locale string such as "en", "en-US" or "en_US".
--->
<cffunction name="javaLocale_" access="private" returntype="any" output="no">
	<cfset var parts = ListToArray(Replace(this.locale, "-", "_", "all"), "_")>
	<cfset var locale = CreateObject("java", "java.util.Locale")>

	<cfif ArrayLen(parts) GTE 2>
		<cfreturn locale.init(JavaCast("string", LCase(parts[1])), JavaCast("string", UCase(parts[2])))>
	</cfif>

	<cfif ArrayLen(parts) EQ 1>
		<cfreturn locale.init(JavaCast("string", LCase(parts[1])))>
	</cfif>

	<cfreturn locale.init(JavaCast("string", "en"))>
</cffunction>

<!---
 * The Time of a value that is compared or measured: a Time stays as it is,
 * text is read in the timezone.
--->
<cffunction name="toTime_" access="private" returntype="any" output="no">
	<cfargument name="value" type="any" required="yes">
	<cfargument name="timezone" type="any" required="no" default="">

	<cfif IsObject(arguments.value)>
		<cfreturn arguments.value>
	</cfif>

	<cfif is_null(arguments.timezone)>
		<cfset arguments.timezone = this.timezone>
	</cfif>

	<cfreturn build_(CreateObject("java", "java.util.Date").init(), tzOf_(arguments.timezone), this.locale, 0).parseInto_(arguments.value)>
</cffunction>

<!--- ------------------------------------------------------------------ --->
<!--- Constructors                                                        --->
<!--- ------------------------------------------------------------------ --->

<!---
 * Constructor.
 *
 * @param string|null $time     A time string, empty for the current time
 * @param string|null $timezone A timezone name, offset, or Java TimeZone
 * @param string|null $locale
 *
 * @throws Exception
--->
<cffunction name="__construct" access="public" returntype="any" output="no">
	<cfargument name="time" type="any" required="no" default="">
	<cfargument name="timezone" type="any" required="no" default="">
	<cfargument name="locale" type="any" required="no" default="">
	<cfset var testNow = "">
	<cfset var date = "">

	<cfset this.locale = localeOf_(arguments.locale)>

	<!--- If a test instance has been provided, use it instead. --->
	<cfif arguments.time EQ "" AND StructKeyExists(request.ColdIgniter, testKey_())>
		<cfset testNow = request.ColdIgniter[testKey_()]>

		<cfif is_null(arguments.timezone)>
			<cfset this.timezone = testNow.timezone>
		<cfelse>
			<cfset this.timezone = tzOf_(arguments.timezone)>
		</cfif>

		<cfset this.cal = mkCal_(this.timezone)>
		<cfset this.cal.setTime(testNow.cal.getTime())>
		<cfset this.micro = testNow.micro>

		<cfreturn this>
	</cfif>

	<cfset this.timezone = tzOf_(arguments.timezone)>
	<cfset this.cal = mkCal_(this.timezone)>
	<cfset this.micro = getF_(this.cal, 14) * 1000>

	<cfif arguments.time NEQ "">
		<cfset parseInto_(arguments.time)>
	</cfif>

	<cfreturn this>
</cffunction>

<!---
 * Returns a new Time instance with the timezone set.
 *
 * Named now_, because Now is a built-in function.
--->
<cffunction name="now_" access="public" returntype="any" output="no">
	<cfargument name="timezone" type="any" required="no" default="">
	<cfargument name="locale" type="any" required="no" default="">

	<cfset var obj = request.ColdIgniter.autoloader.instantiate(className_())>

	<cfreturn obj.__construct("", arguments.timezone, arguments.locale)>
</cffunction>

<!---
 * Returns a new Time instance while parsing a datetime string.
 *
 * @throws Exception
--->
<cffunction name="parse" access="public" returntype="any" output="no">
	<cfargument name="datetime" type="string" required="yes">
	<cfargument name="timezone" type="any" required="no" default="">
	<cfargument name="locale" type="any" required="no" default="">

	<cfset var obj = request.ColdIgniter.autoloader.instantiate(className_())>

	<cfreturn obj.__construct(arguments.datetime, arguments.timezone, arguments.locale)>
</cffunction>

<!---
 * Return a new time with the time set to midnight.
--->
<cffunction name="today" access="public" returntype="any" output="no">
	<cfargument name="timezone" type="any" required="no" default="">
	<cfargument name="locale" type="any" required="no" default="">

	<cfreturn now_(arguments.timezone, arguments.locale).setTime(0, 0, 0, 0)>
</cffunction>

<!---
 * Returns an instance set to midnight yesterday morning.
--->
<cffunction name="yesterday" access="public" returntype="any" output="no">
	<cfargument name="timezone" type="any" required="no" default="">
	<cfargument name="locale" type="any" required="no" default="">

	<cfreturn now_(arguments.timezone, arguments.locale).modify("yesterday")>
</cffunction>

<!---
 * Returns an instance set to midnight tomorrow morning.
--->
<cffunction name="tomorrow" access="public" returntype="any" output="no">
	<cfargument name="timezone" type="any" required="no" default="">
	<cfargument name="locale" type="any" required="no" default="">

	<cfreturn now_(arguments.timezone, arguments.locale).modify("tomorrow")>
</cffunction>

<!---
 * Returns a new instance based on the year, month and day. If any of those
 * three are left empty (null), they will be set to the current value.
--->
<cffunction name="createFromDate" access="public" returntype="any" output="no">
	<cfargument name="year" type="any" required="no" default="">
	<cfargument name="month" type="any" required="no" default="">
	<cfargument name="day" type="any" required="no" default="">
	<cfargument name="timezone" type="any" required="no" default="">
	<cfargument name="locale" type="any" required="no" default="">

	<cfreturn create(arguments.year, arguments.month, arguments.day, "", "", "", arguments.timezone, arguments.locale)>
</cffunction>

<!---
 * Returns a new instance with the date set to today and the time set to the
 * values passed in.
--->
<cffunction name="createFromTime" access="public" returntype="any" output="no">
	<cfargument name="hour" type="any" required="no" default="">
	<cfargument name="minutes" type="any" required="no" default="">
	<cfargument name="seconds" type="any" required="no" default="">
	<cfargument name="timezone" type="any" required="no" default="">
	<cfargument name="locale" type="any" required="no" default="">

	<cfreturn create("", "", "", arguments.hour, arguments.minutes, arguments.seconds, arguments.timezone, arguments.locale)>
</cffunction>

<!---
 * Returns a new instance with the date time values individually set.
 *
 * Difference: an empty value is null. A month or a day out of range rolls
 * over to the next month or year (the original goes through strtotime, which
 * gives false for a month above 12 or a day above 31).
--->
<cffunction name="create" access="public" returntype="any" output="no">
	<cfargument name="year" type="any" required="no" default="">
	<cfargument name="month" type="any" required="no" default="">
	<cfargument name="day" type="any" required="no" default="">
	<cfargument name="hour" type="any" required="no" default="">
	<cfargument name="minutes" type="any" required="no" default="">
	<cfargument name="seconds" type="any" required="no" default="">
	<cfargument name="timezone" type="any" required="no" default="">
	<cfargument name="locale" type="any" required="no" default="">
	<cfset var tz = tzOf_(arguments.timezone)>
	<cfset var cal = "">
	<cfset var local = "">
	<cfset var obj = request.ColdIgniter.autoloader.instantiate(className_())>

	<cfif is_null(arguments.year) OR is_null(arguments.month) OR is_null(arguments.day)>
		<cfset local = mkCal_(tzOf_(""))>

		<cfif is_null(arguments.year)>
			<cfset arguments.year = getF_(local, 1)>
		</cfif>

		<cfif is_null(arguments.month)>
			<cfset arguments.month = getF_(local, 2) + 1>
		</cfif>

		<cfif is_null(arguments.day)>
			<cfset arguments.day = getF_(local, 5)>
		</cfif>
	</cfif>

	<cfif is_null(arguments.hour)>
		<cfset arguments.hour = 0>
	</cfif>

	<cfif is_null(arguments.minutes)>
		<cfset arguments.minutes = 0>
	</cfif>

	<cfif is_null(arguments.seconds)>
		<cfset arguments.seconds = 0>
	</cfif>

	<cfset cal = mkCal_(tz)>
	<cfset cal.clear()>
	<cfset setF_(cal, 1, arguments.year)>
	<cfset setF_(cal, 2, arguments.month - 1)>
	<cfset setF_(cal, 5, arguments.day)>
	<cfset setF_(cal, 11, arguments.hour)>
	<cfset setF_(cal, 12, arguments.minutes)>
	<cfset setF_(cal, 13, arguments.seconds)>

	<cfset obj.cal = cal>
	<cfset obj.timezone = tz>
	<cfset obj.locale = localeOf_(arguments.locale)>
	<cfset obj.micro = 0>

	<cfreturn obj>
</cffunction>

<!---
 * Provides a replacement for the createFromFormat of DateTime, that provides
 * more flexible timeZone handling.
 *
 * The format letters of date() are read: d j m n Y y M F D l H G h g i s u v
 * a A U e T O P, the characters ! | + ? * and a backslash, and any other
 * character as it is (a space also matches a run of white space). The fields
 * that are not read are those of the current time, unless a time field is
 * read (then the others of the time are 0), or the format has ! or |.
 *
 * Difference: the values are placed in the timezone argument (the default
 * timezone for none), unless the data holds U or a zone (e O P T), which
 * decide the instant that is shown in that timezone.
 *
 * Difference: the fields that the format leaves out are taken from the
 * current time in the timezone argument (the original takes the wall clock of
 * the default timezone and reads it in the timezone argument).
 *
 * @param string $format
 * @param string $datetime
 *
 * @throws Exception
--->
<cffunction name="createFromFormat" access="public" returntype="any" output="no">
	<cfargument name="format" type="string" required="yes">
	<cfargument name="datetime" type="string" required="yes">
	<cfargument name="timezone" type="any" required="no" default="">
	<cfset var tz = tzOf_(arguments.timezone)>
	<cfset var f = StructNew()>
	<cfset var fmt = arguments.format>
	<cfset var data = arguments.datetime>
	<cfset var p = 1>
	<cfset var i = 1>
	<cfset var ch = "">
	<cfset var n = "">
	<cfset var token = "">
	<cfset var now = mkCal_(tz)>
	<cfset var cal = "">
	<cfset var zone = "">
	<cfset var reset = false>
	<cfset var timeSeen = false>
	<cfset var dateSeen = false>
	<cfset var obj = "">
	<cfset var pm = -1>
	<cfset var micro = 0>
	<cfset var found = 0>
	<cfset var epoch = "">
	<cfset var trailing = true>

	<cfloop condition="i LTE Len(fmt)">
		<cfset ch = Mid(fmt, i, 1)>
		<cfset i = i + 1>

		<cfif Find(ch, "dj") GT 0>
			<cfset token = REReplace(Mid(data, p, 2), "[^0-9].*$", "")>
			<cfif token EQ "">
				<cfset static_("ColdIgniter\I18n\Exceptions\I18nException").forInvalidFormat(arguments.format)>
			</cfif>
			<cfset f.day = Val(token)>
			<cfset p = p + Len(token)>
			<cfset dateSeen = true>
		<cfelseif Find(ch, "mn") GT 0>
			<cfset token = REReplace(Mid(data, p, 2), "[^0-9].*$", "")>
			<cfif token EQ "">
				<cfset static_("ColdIgniter\I18n\Exceptions\I18nException").forInvalidFormat(arguments.format)>
			</cfif>
			<cfset f.month = Val(token)>
			<cfset p = p + Len(token)>
			<cfset dateSeen = true>
		<cfelseif Compare(ch, "Y") EQ 0>
			<cfset token = REReplace(Mid(data, p, 4), "[^0-9].*$", "")>
			<cfif token EQ "">
				<cfset static_("ColdIgniter\I18n\Exceptions\I18nException").forInvalidFormat(arguments.format)>
			</cfif>
			<cfset f.year = Val(token)>
			<cfset p = p + Len(token)>
			<cfset dateSeen = true>
		<cfelseif Compare(ch, "y") EQ 0>
			<cfset token = REReplace(Mid(data, p, 2), "[^0-9].*$", "")>
			<cfif Len(token) NEQ 2>
				<cfset static_("ColdIgniter\I18n\Exceptions\I18nException").forInvalidFormat(arguments.format)>
			</cfif>
			<cfset f.year = Val(token)>
			<cfif f.year LT 70>
				<cfset f.year = f.year + 2000>
			<cfelse>
				<cfset f.year = f.year + 1900>
			</cfif>
			<cfset p = p + 2>
			<cfset dateSeen = true>
		<cfelseif Find(ch, "MF") GT 0>
			<cfset token = LCase(REReplace(Mid(data, p, 9), "[^A-Za-z].*$", ""))>
			<cfset n = 0>
			<cfloop from="1" to="12" index="found">
				<cfif Len(token) GTE 3 AND Left(LCase(ListGetAt("January,February,March,April,May,June,July,August,September,October,November,December", found)), Len(token)) EQ token>
					<cfset n = found>
					<cfbreak>
				</cfif>
			</cfloop>
			<cfif n EQ 0>
				<cfset static_("ColdIgniter\I18n\Exceptions\I18nException").forInvalidFormat(arguments.format)>
			</cfif>
			<cfset f.month = n>
			<cfset p = p + Len(token)>
			<cfset dateSeen = true>
		<cfelseif Find(ch, "Dl") GT 0>
			<cfset token = REReplace(Mid(data, p, 9), "[^A-Za-z].*$", "")>
			<cfif Len(token) LT 3>
				<cfset static_("ColdIgniter\I18n\Exceptions\I18nException").forInvalidFormat(arguments.format)>
			</cfif>
			<cfset p = p + Len(token)>
		<cfelseif Find(ch, "HGhg") GT 0>
			<cfset token = REReplace(Mid(data, p, 2), "[^0-9].*$", "")>
			<cfif token EQ "">
				<cfset static_("ColdIgniter\I18n\Exceptions\I18nException").forInvalidFormat(arguments.format)>
			</cfif>
			<cfset f.hour = Val(token)>
			<cfset p = p + Len(token)>
			<cfset timeSeen = true>
		<cfelseif Compare(ch, "i") EQ 0>
			<cfset token = Mid(data, p, 2)>
			<cfif NOT REFind("^[0-9][0-9]$", token)>
				<cfset static_("ColdIgniter\I18n\Exceptions\I18nException").forInvalidFormat(arguments.format)>
			</cfif>
			<cfset f.minute = Val(token)>
			<cfset p = p + 2>
			<cfset timeSeen = true>
		<cfelseif Compare(ch, "s") EQ 0>
			<cfset token = Mid(data, p, 2)>
			<cfif NOT REFind("^[0-9][0-9]$", token)>
				<cfset static_("ColdIgniter\I18n\Exceptions\I18nException").forInvalidFormat(arguments.format)>
			</cfif>
			<cfset f.second = Val(token)>
			<cfset p = p + 2>
			<cfset timeSeen = true>
		<cfelseif Find(ch, "uv") GT 0>
			<cfset token = REReplace(Mid(data, p, 6), "[^0-9].*$", "")>
			<cfif token EQ "">
				<cfset static_("ColdIgniter\I18n\Exceptions\I18nException").forInvalidFormat(arguments.format)>
			</cfif>
			<cfset micro = Val(Left(token & "000000", 6))>
			<cfset p = p + Len(token)>
			<cfset timeSeen = true>
		<cfelseif Find(ch, "aA") GT 0>
			<cfset token = LCase(Mid(data, p, 2))>
			<cfif Compare(token, "am") EQ 0>
				<cfset pm = 0>
			<cfelseif Compare(token, "pm") EQ 0>
				<cfset pm = 1>
			<cfelse>
				<cfset static_("ColdIgniter\I18n\Exceptions\I18nException").forInvalidFormat(arguments.format)>
			</cfif>
			<cfset p = p + 2>
		<cfelseif Compare(ch, "U") EQ 0>
			<cfset token = REReplace(Mid(data, p, 20), "^(-?[0-9]+).*$", "\1")>
			<cfif NOT REFind("^-?[0-9]+$", token)>
				<cfset static_("ColdIgniter\I18n\Exceptions\I18nException").forInvalidFormat(arguments.format)>
			</cfif>
			<cfset epoch = Val(token)>
			<cfset p = p + Len(token)>
		<cfelseif Find(ch, "eTOP") GT 0>
			<cfset token = REReplace(Mid(data, p, 40), "^([A-Za-z_/]+|[+-][0-9][0-9]:?[0-9][0-9]|[+-][0-9][0-9]).*$", "\1")>
			<cfif token EQ "" OR token EQ Mid(data, p, 40) AND NOT REFind("^[A-Za-z_/+:0-9-]+$", token)>
				<cfset static_("ColdIgniter\I18n\Exceptions\I18nException").forInvalidFormat(arguments.format)>
			</cfif>
			<cfset zone = tzOf_(token)>
			<cfset p = p + Len(token)>
		<cfelseif Compare(ch, "!") EQ 0>
			<cfset reset = true>
			<cfset f = StructNew()>
			<cfset timeSeen = false>
		<cfelseif Compare(ch, "|") EQ 0>
			<cfset reset = true>
		<cfelseif Compare(ch, "+") EQ 0>
			<cfset trailing = false>
			<cfset p = Len(data) + 1>
		<cfelseif Compare(ch, "?") EQ 0>
			<cfset p = p + 1>
		<cfelseif Compare(ch, "*") EQ 0>
			<cfset p = Len(data) + 1 - Len(REReplace(Mid(data, p, Len(data)), "^[^ ,;:/.()-]*", ""))>
		<cfelse>
			<cfif Compare(ch, "\") EQ 0>
				<cfset ch = Mid(fmt, i, 1)>
				<cfset i = i + 1>
			</cfif>

			<cfif Compare(Mid(data, p, 1), ch) NEQ 0>
				<cfset static_("ColdIgniter\I18n\Exceptions\I18nException").forInvalidFormat(arguments.format)>
			</cfif>
			<cfset p = p + 1>
		</cfif>
	</cfloop>

	<cfif trailing AND p LTE Len(data)>
		<cfset static_("ColdIgniter\I18n\Exceptions\I18nException").forInvalidFormat(arguments.format)>
	</cfif>

	<!--- the 12 hour clock --->
	<cfif StructKeyExists(f, "hour") AND pm GTE 0>
		<cfif pm EQ 1 AND f.hour LT 12>
			<cfset f.hour = f.hour + 12>
		<cfelseif pm EQ 0 AND f.hour EQ 12>
			<cfset f.hour = 0>
		</cfif>
	</cfif>

	<cfset cal = mkCal_(tz)>

	<cfif epoch NEQ "">
		<cfset cal.setTime(dateOf_(epoch))>
		<cfset obj = build_(cal.getTime(), tz, localeOf_(""), micro)>
		<cfreturn obj>
	</cfif>

	<cfif NOT IsSimpleValue(zone)>
		<cfset cal.setTimeZone(zone)>
	</cfif>

	<cfif reset>
		<cfset cal.clear()>
		<cfif NOT StructKeyExists(f, "year")>
			<cfset f.year = 1970>
		</cfif>
		<cfif NOT StructKeyExists(f, "month")>
			<cfset f.month = 1>
		</cfif>
		<cfif NOT StructKeyExists(f, "day")>
			<cfset f.day = 1>
		</cfif>
		<cfset timeSeen = true>
	</cfif>

	<cfif NOT StructKeyExists(f, "year")>
		<cfset f.year = getF_(now, 1)>
	</cfif>

	<cfif NOT StructKeyExists(f, "month")>
		<cfset f.month = getF_(now, 2) + 1>
	</cfif>

	<cfif NOT StructKeyExists(f, "day")>
		<cfset f.day = getF_(now, 5)>
	</cfif>

	<cfif timeSeen>
		<cfif NOT StructKeyExists(f, "hour")>
			<cfset f.hour = 0>
		</cfif>
		<cfif NOT StructKeyExists(f, "minute")>
			<cfset f.minute = 0>
		</cfif>
		<cfif NOT StructKeyExists(f, "second")>
			<cfset f.second = 0>
		</cfif>
	<cfelse>
		<cfif NOT StructKeyExists(f, "hour")>
			<cfset f.hour = getF_(now, 11)>
		</cfif>
		<cfif NOT StructKeyExists(f, "minute")>
			<cfset f.minute = getF_(now, 12)>
		</cfif>
		<cfif NOT StructKeyExists(f, "second")>
			<cfset f.second = getF_(now, 13)>
		</cfif>
		<cfset micro = getF_(now, 14) * 1000>
	</cfif>

	<cfset cal.clear()>
	<cfset setF_(cal, 1, f.year)>
	<cfset setF_(cal, 2, f.month - 1)>
	<cfset setF_(cal, 5, f.day)>
	<cfset setF_(cal, 11, f.hour)>
	<cfset setF_(cal, 12, f.minute)>
	<cfset setF_(cal, 13, f.second)>

	<cfreturn build_(cal.getTime(), tz, localeOf_(""), micro)>
</cffunction>

<!---
 * Returns a new instance with the datetime set based on the provided UNIX
 * timestamp.
 *
 * @param float|int $timestamp
 *
 * @throws Exception
--->
<cffunction name="createFromTimestamp" access="public" returntype="any" output="no">
	<cfargument name="timestamp" type="numeric" required="yes">
	<cfargument name="timezone" type="any" required="no" default="">
	<cfargument name="locale" type="any" required="no" default="">
	<cfset var utc = tzOf_("UTC")>
	<cfset var fraction = Round((arguments.timestamp - Int(arguments.timestamp)) * 1000000)>
	<cfset var obj = build_(dateOf_(arguments.timestamp), utc, localeOf_(arguments.locale), 0)>

	<!--- the microseconds of the fraction, kept apart --->
	<cfset obj.micro = fraction>

	<cfif is_null(arguments.timezone)>
		<cfreturn obj>
	</cfif>

	<cfreturn obj.setTimezone(arguments.timezone)>
</cffunction>

<!---
 * Takes an instance of Time and returns an instance of this class with its
 * same values.
 *
 * @return static
 *
 * @throws Exception
--->
<cffunction name="createFromInstance" access="public" returntype="any" output="no">
	<cfargument name="dateTime" type="any" required="yes">
	<cfargument name="locale" type="any" required="no" default="">

	<cfreturn build_(arguments.dateTime.cal.getTime(), arguments.dateTime.timezone, localeOf_(arguments.locale), arguments.dateTime.micro)>
</cffunction>

<!---
 * Converts an instance to this class. Alias of createFromInstance.
 *
 * @deprecated Use createFromInstance() instead
--->
<cffunction name="instance" access="public" returntype="any" output="no">
	<cfargument name="dateTime" type="any" required="yes">
	<cfargument name="locale" type="any" required="no" default="">

	<cfreturn createFromInstance(arguments.dateTime, arguments.locale)>
</cffunction>

<!---
 * Converts the current instance to a mutable version, a TimeLegacy.
 *
 * Difference: there is no DateTime, so the result is a TimeLegacy.
--->
<cffunction name="toDateTime" access="public" returntype="any" output="no">
	<cfset var obj = request.ColdIgniter.autoloader.instantiate("ColdIgniter\I18n\TimeLegacy")>

	<cfset obj.cal = mkCal_(this.timezone)>
	<cfset obj.cal.setTime(this.cal.getTime())>
	<cfset obj.timezone = this.timezone>
	<cfset obj.locale = this.locale>
	<cfset obj.micro = this.micro>

	<cfreturn obj>
</cffunction>

<!--- ------------------------------------------------------------------ --->
<!--- For Testing                                                         --->
<!--- ------------------------------------------------------------------ --->

<!---
 * Creates an instance of Time that will be returned during testing
 * when calling 'Time::now' instead of the current time.
 *
 * @param Time|string|null $datetime  A Time, text, or empty (null) to reset
--->
<cffunction name="setTestNow" access="public" returntype="void" output="no">
	<cfargument name="datetime" type="any" required="no" default="">
	<cfargument name="timezone" type="any" required="no" default="">
	<cfargument name="locale" type="any" required="no" default="">
	<cfset var obj = "">
	<cfset var instant = arguments.datetime>

	<!--- Reset the test instance --->
	<cfif IsSimpleValue(instant) AND instant EQ "">
		<cfset StructDelete(request.ColdIgniter, testKey_())>
		<cfreturn>
	</cfif>

	<!--- Convert to a Time instance --->
	<cfif IsSimpleValue(instant)>
		<!--- a test instance set before must not decide the new one --->
		<cfset StructDelete(request.ColdIgniter, testKey_())>
		<cfset obj = request.ColdIgniter.autoloader.instantiate(className_())>
		<cfset instant = obj.__construct(instant, arguments.timezone, arguments.locale)>
	</cfif>

	<cfset request.ColdIgniter[testKey_()] = instant>
</cffunction>

<!---
 * Returns whether we have a testNow set.
--->
<cffunction name="hasTestNow" access="public" returntype="boolean" output="no">
	<cfreturn StructKeyExists(request.ColdIgniter, testKey_())>
</cffunction>

<!--- ------------------------------------------------------------------ --->
<!--- Getters                                                             --->
<!--- ------------------------------------------------------------------ --->

<!---
 * Returns the number of seconds since 1970-01-01 UTC.
--->
<cffunction name="getTimestamp" access="public" returntype="numeric" output="no">
	<cfreturn Int(this.cal.getTime().getTime() / 1000)>
</cffunction>

<!---
 * Returns the offset of the timezone from UTC in seconds at this instant.
--->
<cffunction name="getOffset" access="public" returntype="numeric" output="no">
	<cfreturn (getF_(this.cal, 15) + getF_(this.cal, 16)) / 1000>
</cffunction>

<!---
 * Returns the timezone (a Java TimeZone).
--->
<cffunction name="getTimezone" access="public" returntype="any" output="no">
	<cfreturn this.timezone>
</cffunction>

<!---
 * Returns the time as text, formatted with the letters of date().
 *
 * a A c d D e F g G h H i I j l L m M n N o O p P r s S t T u U v w W y Y z Z
 * and a backslash that keeps the next character.
 *
 * @param string $format
--->
<cffunction name="format" access="public" returntype="string" output="no">
	<cfargument name="format" type="string" required="yes">
	<cfset var out = "">
	<cfset var i = 1>
	<cfset var ch = "">
	<cfset var cal = this.cal>
	<cfset var dow = 0>
	<cfset var day = 0>
	<cfset var hour = 0>
	<cfset var offset = 0>
	<cfset var sign = "+">
	<cfset var iso = "">
	<cfset var week = 0>
	<cfset var year = 0>

	<cfloop condition="i LTE Len(arguments.format)">
		<cfset ch = Mid(arguments.format, i, 1)>
		<cfset i = i + 1>

		<cfif Find(ch, "dDjlNSwzWFmMntLoYyaAgGhHisuveIOPpTZcrU\") EQ 0>
			<cfset out = out & ch>
		<cfelseif Compare(ch, "d") EQ 0>
			<cfset out = out & pad_(getF_(cal, 5), 2)>
		<cfelseif Compare(ch, "D") EQ 0>
			<cfset out = out & ListGetAt("Sun,Mon,Tue,Wed,Thu,Fri,Sat", getF_(cal, 7))>
		<cfelseif Compare(ch, "j") EQ 0>
			<cfset out = out & getF_(cal, 5)>
		<cfelseif Compare(ch, "l") EQ 0>
			<cfset out = out & ListGetAt("Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday", getF_(cal, 7))>
		<cfelseif Compare(ch, "N") EQ 0>
			<cfset dow = getF_(cal, 7) - 1>
			<cfif dow EQ 0>
				<cfset dow = 7>
			</cfif>
			<cfset out = out & dow>
		<cfelseif Compare(ch, "S") EQ 0>
			<cfset day = getF_(cal, 5)>
			<cfif day GTE 11 AND day LTE 13>
				<cfset out = out & "th">
			<cfelseif day MOD 10 EQ 1>
				<cfset out = out & "st">
			<cfelseif day MOD 10 EQ 2>
				<cfset out = out & "nd">
			<cfelseif day MOD 10 EQ 3>
				<cfset out = out & "rd">
			<cfelse>
				<cfset out = out & "th">
			</cfif>
		<cfelseif Compare(ch, "w") EQ 0>
			<cfset out = out & (getF_(cal, 7) - 1)>
		<cfelseif Compare(ch, "z") EQ 0>
			<cfset out = out & (getF_(cal, 6) - 1)>
		<cfelseif Compare(ch, "W") EQ 0 OR Compare(ch, "o") EQ 0>
			<!--- the ISO week: weeks start on Monday, week 1 holds the 4th of January --->
			<cfset iso = CreateObject("java", "java.util.GregorianCalendar").init()>
			<cfset iso.setTimeZone(this.timezone)>
			<cfset iso.setTime(cal.getTime())>
			<cfset iso.setFirstDayOfWeek(JavaCast("int", 2))>
			<cfset iso.setMinimalDaysInFirstWeek(JavaCast("int", 4))>
			<cfset week = getF_(iso, 3)>
			<cfset year = getF_(iso, 1)>

			<cfif week GTE 52 AND getF_(iso, 2) EQ 0>
				<cfset year = year - 1>
			<cfelseif week EQ 1 AND getF_(iso, 2) EQ 11>
				<cfset year = year + 1>
			</cfif>

			<cfif Compare(ch, "W") EQ 0>
				<cfset out = out & pad_(week, 2)>
			<cfelse>
				<cfset out = out & year>
			</cfif>
		<cfelseif Compare(ch, "F") EQ 0>
			<cfset out = out & ListGetAt("January,February,March,April,May,June,July,August,September,October,November,December", getF_(cal, 2) + 1)>
		<cfelseif Compare(ch, "m") EQ 0>
			<cfset out = out & pad_(getF_(cal, 2) + 1, 2)>
		<cfelseif Compare(ch, "M") EQ 0>
			<cfset out = out & ListGetAt("Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec", getF_(cal, 2) + 1)>
		<cfelseif Compare(ch, "n") EQ 0>
			<cfset out = out & (getF_(cal, 2) + 1)>
		<cfelseif Compare(ch, "t") EQ 0>
			<cfset out = out & cal.getActualMaximum(JavaCast("int", 5))>
		<cfelseif Compare(ch, "L") EQ 0>
			<cfif cal.isLeapYear(JavaCast("int", getF_(cal, 1)))>
				<cfset out = out & "1">
			<cfelse>
				<cfset out = out & "0">
			</cfif>
		<cfelseif Compare(ch, "Y") EQ 0>
			<cfset out = out & pad_(getF_(cal, 1), 4)>
		<cfelseif Compare(ch, "y") EQ 0>
			<cfset out = out & pad_(getF_(cal, 1) MOD 100, 2)>
		<cfelseif Compare(ch, "a") EQ 0>
			<cfif getF_(cal, 11) LT 12>
				<cfset out = out & "am">
			<cfelse>
				<cfset out = out & "pm">
			</cfif>
		<cfelseif Compare(ch, "A") EQ 0>
			<cfif getF_(cal, 11) LT 12>
				<cfset out = out & "AM">
			<cfelse>
				<cfset out = out & "PM">
			</cfif>
		<cfelseif Compare(ch, "g") EQ 0 OR Compare(ch, "h") EQ 0>
			<cfset hour = getF_(cal, 11) MOD 12>
			<cfif hour EQ 0>
				<cfset hour = 12>
			</cfif>
			<cfif Compare(ch, "h") EQ 0>
				<cfset out = out & pad_(hour, 2)>
			<cfelse>
				<cfset out = out & hour>
			</cfif>
		<cfelseif Compare(ch, "G") EQ 0>
			<cfset out = out & getF_(cal, 11)>
		<cfelseif Compare(ch, "H") EQ 0>
			<cfset out = out & pad_(getF_(cal, 11), 2)>
		<cfelseif Compare(ch, "i") EQ 0>
			<cfset out = out & pad_(getF_(cal, 12), 2)>
		<cfelseif Compare(ch, "s") EQ 0>
			<cfset out = out & pad_(getF_(cal, 13), 2)>
		<cfelseif Compare(ch, "u") EQ 0>
			<cfset out = out & pad_(this.micro, 6)>
		<cfelseif Compare(ch, "v") EQ 0>
			<cfset out = out & pad_(Int(this.micro / 1000), 3)>
		<cfelseif Compare(ch, "e") EQ 0>
			<!--- Difference: an offset timezone is "GMT+02:00" here, "+02:00" in the original --->
			<cfset out = out & this.timezone.getID()>
		<cfelseif Compare(ch, "I") EQ 0>
			<cfif getF_(cal, 16) NEQ 0>
				<cfset out = out & "1">
			<cfelse>
				<cfset out = out & "0">
			</cfif>
		<cfelseif Compare(ch, "O") EQ 0 OR Compare(ch, "P") EQ 0 OR Compare(ch, "p") EQ 0>
			<cfset offset = getOffset()>
			<cfif Compare(ch, "p") EQ 0 AND offset EQ 0>
				<cfset out = out & "Z">
			<cfelse>
				<cfif offset LT 0>
					<cfset sign = "-">
				<cfelse>
					<cfset sign = "+">
				</cfif>
				<cfset offset = Abs(offset)>
				<cfif Compare(ch, "O") EQ 0>
					<cfset out = out & sign & pad_(Int(offset / 3600), 2) & pad_(Int(offset / 60) MOD 60, 2)>
				<cfelse>
					<cfset out = out & sign & pad_(Int(offset / 3600), 2) & ":" & pad_(Int(offset / 60) MOD 60, 2)>
				</cfif>
			</cfif>
		<cfelseif Compare(ch, "T") EQ 0>
			<cfset out = out & this.timezone.getDisplayName(JavaCast("boolean", getF_(cal, 16) NEQ 0), JavaCast("int", 0))>
		<cfelseif Compare(ch, "Z") EQ 0>
			<cfset out = out & getOffset()>
		<cfelseif Compare(ch, "c") EQ 0>
			<cfset out = out & format("Y-m-d\TH:i:sP")>
		<cfelseif Compare(ch, "r") EQ 0>
			<cfset out = out & format("D, d M Y H:i:s O")>
		<cfelseif Compare(ch, "U") EQ 0>
			<cfset out = out & getTimestamp()>
		<cfelseif Compare(ch, "\") EQ 0>
			<cfset out = out & Mid(arguments.format, i, 1)>
			<cfset i = i + 1>
		</cfif>
	</cfloop>

	<cfreturn out>
</cffunction>

<!---
 * Allow for property-type access to getter methods: __get("year") calls
 * getYear(). An unknown name gives an empty string (null).
--->
<cffunction name="__get" access="public" returntype="any" output="no">
	<cfargument name="name" type="string" required="yes">
	<cfset var method = "get" & UCase(Left(arguments.name, 1)) & Mid(arguments.name, 2, Len(arguments.name))>
	<cfset var result = "">

	<cfif StructKeyExists(this, method)>
		<cfinvoke component="#this#" method="#method#" returnvariable="result">
		<cfreturn result>
	</cfif>

	<cfreturn "">
</cffunction>

<!---
 * Allow for property-type checks of getter methods.
--->
<cffunction name="__isset" access="public" returntype="boolean" output="no">
	<cfargument name="name" type="string" required="yes">

	<cfreturn StructKeyExists(this, "get" & UCase(Left(arguments.name, 1)) & Mid(arguments.name, 2, Len(arguments.name)))>
</cffunction>

<!---
 * Returns the year number, "2017".
--->
<cffunction name="getYear" access="public" returntype="string" output="no">
	<cfreturn toLocalizedString("y")>
</cffunction>

<!---
 * Returns the month number, "1" to "12" (not padded).
--->
<cffunction name="getMonth" access="public" returntype="string" output="no">
	<cfreturn toLocalizedString("M")>
</cffunction>

<!---
 * Return the day of the month, "1" to "31" (not padded).
--->
<cffunction name="getDay" access="public" returntype="string" output="no">
	<cfreturn toLocalizedString("d")>
</cffunction>

<!---
 * Return the hour of the day, "0" to "23" (not padded).
--->
<cffunction name="getHour" access="public" returntype="string" output="no">
	<cfreturn toLocalizedString("H")>
</cffunction>

<!---
 * Return the minutes, "0" to "59" (not padded).
--->
<cffunction name="getMinute" access="public" returntype="string" output="no">
	<cfreturn toLocalizedString("m")>
</cffunction>

<!---
 * Return the seconds, "0" to "59" (not padded).
--->
<cffunction name="getSecond" access="public" returntype="string" output="no">
	<cfreturn toLocalizedString("s")>
</cffunction>

<!---
 * Return the day of the week, 1 (Sunday) to 7.
 *
 * Difference: the number of ICU 'c' depends on the first day of the week of
 * the locale, here Sunday is always 1.
--->
<cffunction name="getDayOfWeek" access="public" returntype="string" output="no">
	<cfreturn toLocalizedString("c")>
</cffunction>

<!---
 * Return the day of the year, 1 to 366.
--->
<cffunction name="getDayOfYear" access="public" returntype="string" output="no">
	<cfreturn toLocalizedString("D")>
</cffunction>

<!---
 * Return the week of the month, 1 to 6.
--->
<cffunction name="getWeekOfMonth" access="public" returntype="string" output="no">
	<cfreturn toLocalizedString("W")>
</cffunction>

<!---
 * Return the week of the year, 1 to 53.
--->
<cffunction name="getWeekOfYear" access="public" returntype="string" output="no">
	<cfreturn toLocalizedString("w")>
</cffunction>

<!---
 * Gets the age in years of this date, from now.
--->
<cffunction name="getAge" access="public" returntype="numeric" output="no">
	<cfset var years = difference(now_()).getYears()>

	<!--- future dates have no age --->
	<cfif years LT 0>
		<cfreturn 0>
	</cfif>

	<cfreturn years>
</cffunction>

<!---
 * Returns the quarter of the year, 1 to 4.
--->
<cffunction name="getQuarter" access="public" returntype="string" output="no">
	<cfreturn toLocalizedString("Q")>
</cffunction>

<!---
 * Are we in daylight savings time currently?
--->
<cffunction name="getDst" access="public" returntype="boolean" output="no">
	<cfreturn getF_(this.cal, 16) NEQ 0>
</cffunction>

<!---
 * Returns boolean whether the passed timezone is the same as the default
 * timezone of the application.
--->
<cffunction name="getLocal" access="public" returntype="boolean" output="no">
	<cfreturn Compare(tzOf_("").getID(), this.timezone.getID()) EQ 0>
</cffunction>

<!---
 * Returns boolean whether the timezone is UTC (an offset of 0).
--->
<cffunction name="getUtc" access="public" returntype="boolean" output="no">
	<cfreturn getOffset() EQ 0>
</cffunction>

<!---
 * Returns the name of the current timezone.
 *
 * Difference: a timezone that is an offset gives its Java id, "GMT+02:00",
 * where the original gives "+02:00".
--->
<cffunction name="getTimezoneName" access="public" returntype="string" output="no">
	<cfreturn this.timezone.getID()>
</cffunction>

<!--- ------------------------------------------------------------------ --->
<!--- Setters                                                             --->
<!--- ------------------------------------------------------------------ --->

<!---
 * Sets the current year for this instance.
 *
 * @param int|string $value
 *
 * @return static
--->
<cffunction name="setYear" access="public" returntype="any" output="no">
	<cfargument name="value" type="any" required="yes">

	<cfreturn setValue("year", arguments.value)>
</cffunction>

<!---
 * Sets the month of the year. The month can be a number (1 to 12) or a
 * name ("March", "Mar").
--->
<cffunction name="setMonth" access="public" returntype="any" output="no">
	<cfargument name="value" type="any" required="yes">
	<cfset var month = arguments.value>
	<cfset var found = 0>

	<cfif IsNumeric(month) AND (month LT 1 OR month GT 12)>
		<cfset static_("ColdIgniter\I18n\Exceptions\I18nException").forInvalidMonth(month)>
	</cfif>

	<cfif NOT IsNumeric(month)>
		<cfset found = ListFindNoCase("jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec", Left(month, 3))>
		<cfif found EQ 0 OR Len(month) LT 3>
			<cfthrow type="ColdIgniter.Exception" message="Failed to parse the month (#month#)">
		</cfif>
		<cfset month = found>
	</cfif>

	<cfreturn setValue("month", month)>
</cffunction>

<!---
 * Sets the day of the month.
--->
<cffunction name="setDay" access="public" returntype="any" output="no">
	<cfargument name="value" type="any" required="yes">
	<cfset var lastDay = 0>
	<cfset var date = "">

	<cfif arguments.value LT 1 OR arguments.value GT 31>
		<cfset static_("ColdIgniter\I18n\Exceptions\I18nException").forInvalidDay(arguments.value)>
	</cfif>

	<cfset date = create(getYear(), getMonth(), 1, "", "", "", this.timezone, this.locale)>
	<cfset lastDay = date.cal.getActualMaximum(JavaCast("int", 5))>

	<cfif arguments.value GT lastDay>
		<cfset static_("ColdIgniter\I18n\Exceptions\I18nException").forInvalidOverDay(lastDay, arguments.value)>
	</cfif>

	<cfreturn setValue("day", arguments.value)>
</cffunction>

<!---
 * Sets the hour of the day (24 hour cycle).
--->
<cffunction name="setHour" access="public" returntype="any" output="no">
	<cfargument name="value" type="any" required="yes">

	<cfif arguments.value LT 0 OR arguments.value GT 23>
		<cfset static_("ColdIgniter\I18n\Exceptions\I18nException").forInvalidHour(arguments.value)>
	</cfif>

	<cfreturn setValue("hour", arguments.value)>
</cffunction>

<!---
 * Sets the minute of the hour.
--->
<cffunction name="setMinute" access="public" returntype="any" output="no">
	<cfargument name="value" type="any" required="yes">

	<cfif arguments.value LT 0 OR arguments.value GT 59>
		<cfset static_("ColdIgniter\I18n\Exceptions\I18nException").forInvalidMinutes(arguments.value)>
	</cfif>

	<cfreturn setValue("minute", arguments.value)>
</cffunction>

<!---
 * Sets the second of the minute.
--->
<cffunction name="setSecond" access="public" returntype="any" output="no">
	<cfargument name="value" type="any" required="yes">

	<cfif arguments.value LT 0 OR arguments.value GT 59>
		<cfset static_("ColdIgniter\I18n\Exceptions\I18nException").forInvalidSeconds(arguments.value)>
	</cfif>

	<cfreturn setValue("second", arguments.value)>
</cffunction>

<!---
 * Helper method to do the any of the setX methods.
 *
 * @param string $name year, month, day, hour, minute or second
--->
<cffunction name="setValue" access="private" returntype="any" output="no">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="value" type="any" required="yes">
	<cfset var year = getF_(this.cal, 1)>
	<cfset var month = getF_(this.cal, 2) + 1>
	<cfset var day = getF_(this.cal, 5)>
	<cfset var hour = getF_(this.cal, 11)>
	<cfset var minute = getF_(this.cal, 12)>
	<cfset var second = getF_(this.cal, 13)>
	<cfset var obj = "">

	<cfif Compare(arguments.name, "year") EQ 0>
		<cfset year = arguments.value>
	<cfelseif Compare(arguments.name, "month") EQ 0>
		<cfset month = arguments.value>
	<cfelseif Compare(arguments.name, "day") EQ 0>
		<cfset day = arguments.value>
	<cfelseif Compare(arguments.name, "hour") EQ 0>
		<cfset hour = arguments.value>
	<cfelseif Compare(arguments.name, "minute") EQ 0>
		<cfset minute = arguments.value>
	<cfelse>
		<cfset second = arguments.value>
	</cfif>

	<cfset obj = create(year, month, day, hour, minute, second, this.timezone, this.locale)>
	<cfset obj.toStringFormat = this.toStringFormat>

	<cfreturn obj>
</cffunction>

<!---
 * Returns a new instance with the revised timezone.
 *
 * @param string|TimeZone $timezone
 *
 * @return static
--->
<cffunction name="setTimezone" access="public" returntype="any" output="no">
	<cfargument name="timezone" type="any" required="yes">

	<cfreturn build_(this.cal.getTime(), tzOf_(arguments.timezone), this.locale, this.micro)>
</cffunction>

<!---
 * Sets the time of day, and the microseconds (a new instance, or this
 * instance in TimeLegacy).
--->
<cffunction name="setTime" access="public" returntype="any" output="no">
	<cfargument name="hour" type="numeric" required="yes">
	<cfargument name="minute" type="numeric" required="yes">
	<cfargument name="second" type="numeric" required="no" default="0">
	<cfargument name="microsecond" type="numeric" required="no" default="0">
	<cfset var obj = target_()>

	<cfset setF_(obj.cal, 11, arguments.hour)>
	<cfset setF_(obj.cal, 12, arguments.minute)>
	<cfset setF_(obj.cal, 13, arguments.second)>
	<cfset setF_(obj.cal, 14, 0)>
	<cfset obj.micro = arguments.microsecond>

	<cfreturn obj>
</cffunction>

<!---
 * Sets the date (a new instance, or this instance in TimeLegacy).
--->
<cffunction name="setDate" access="public" returntype="any" output="no">
	<cfargument name="year" type="numeric" required="yes">
	<cfargument name="month" type="numeric" required="yes">
	<cfargument name="day" type="numeric" required="yes">
	<cfset var obj = target_()>

	<cfset setF_(obj.cal, 1, arguments.year)>
	<cfset setF_(obj.cal, 2, arguments.month - 1)>
	<cfset setF_(obj.cal, 5, arguments.day)>

	<cfreturn obj>
</cffunction>

<!---
 * Sets the instant from a number of seconds since 1970-01-01 UTC (a new
 * instance, or this instance in TimeLegacy). The microseconds are 0.
--->
<cffunction name="setTimestamp" access="public" returntype="any" output="no">
	<cfargument name="timestamp" type="numeric" required="yes">
	<cfset var obj = target_()>

	<cfset obj.cal.setTime(dateOf_(arguments.timestamp))>
	<cfset obj.micro = 0>

	<cfreturn obj>
</cffunction>

<!---
 * Changes the time by a relative text such as "+1 day" or "next monday"
 * (a new instance, or this instance in TimeLegacy).
 *
 * @throws Exception when the text is not understood
--->
<cffunction name="modify" access="public" returntype="any" output="no">
	<cfargument name="modifier" type="string" required="yes">
	<cfset var obj = target_()>

	<cfset obj.parseInto_(arguments.modifier, true)>

	<cfreturn obj>
</cffunction>

<!--- ------------------------------------------------------------------ --->
<!--- Add/Subtract                                                        --->
<!--- ------------------------------------------------------------------ --->

<!---
 * Returns a new instance with the interval added, a relative text such as
 * "1 day" or "2 months" (see the difference at the top).
--->
<cffunction name="add" access="public" returntype="any" output="no">
	<cfargument name="interval" type="string" required="yes">

	<cfreturn modify(arguments.interval)>
</cffunction>

<!---
 * Returns a new instance with the interval subtracted.
--->
<cffunction name="sub" access="public" returntype="any" output="no">
	<cfargument name="interval" type="string" required="yes">
	<cfset var text = Trim(arguments.interval)>
	<cfset var out = "">
	<cfset var matcher = CreateObject("java", "java.util.regex.Pattern").compile("([+-]?)([0-9]+)").matcher(JavaCast("string", text))>
	<cfset var last = 0>

	<!--- the sign of every number term is turned round, "1 day 2 hours" is "-1 day -2 hours" --->
	<cfloop condition="matcher.find()">
		<cfset out = out & Mid(text, last + 1, matcher.start() - last)>
		<cfset last = matcher.end()>

		<cfif Compare(matcher.group(1), "-") EQ 0>
			<cfset out = out & "+">
		<cfelse>
			<cfset out = out & "-">
		</cfif>

		<cfset out = out & matcher.group(2)>
	</cfloop>

	<cfset out = out & Mid(text, last + 1, Len(text) - last)>

	<cfreturn modify(out)>
</cffunction>

<!---
 * Adds a number of a unit to a copy (s second, i minute, h hour, d day,
 * m month, y year). Months and years roll over a short month, like a
 * DateInterval does: Jan 31 plus a month is Mar 3.
--->
<cffunction name="addUnit_" access="private" returntype="any" output="no">
	<cfargument name="unit" type="string" required="yes">
	<cfargument name="count" type="numeric" required="yes">
	<cfset var time = copy_()>

	<cfset time.applyUnit_(arguments.unit, arguments.count)>

	<cfreturn time>
</cffunction>

<cffunction name="applyUnit_" access="public" returntype="void" output="no">
	<cfargument name="unit" type="string" required="yes">
	<cfargument name="count" type="numeric" required="yes">

	<cfif Compare(arguments.unit, "s") EQ 0>
		<cfset addF_(this.cal, 13, arguments.count)>
	<cfelseif Compare(arguments.unit, "i") EQ 0>
		<cfset addF_(this.cal, 12, arguments.count)>
	<cfelseif Compare(arguments.unit, "h") EQ 0>
		<cfset addF_(this.cal, 11, arguments.count)>
	<cfelseif Compare(arguments.unit, "d") EQ 0>
		<cfset addF_(this.cal, 5, arguments.count)>
	<cfelseif Compare(arguments.unit, "m") EQ 0>
		<cfset setF_(this.cal, 2, getF_(this.cal, 2) + arguments.count)>
	<cfelse>
		<cfset setF_(this.cal, 1, getF_(this.cal, 1) + arguments.count)>
	</cfif>
</cffunction>

<cffunction name="addSeconds" access="public" returntype="any" output="no">
	<cfargument name="seconds" type="numeric" required="yes">

	<cfreturn addUnit_("s", arguments.seconds)>
</cffunction>

<cffunction name="addMinutes" access="public" returntype="any" output="no">
	<cfargument name="minutes" type="numeric" required="yes">

	<cfreturn addUnit_("i", arguments.minutes)>
</cffunction>

<cffunction name="addHours" access="public" returntype="any" output="no">
	<cfargument name="hours" type="numeric" required="yes">

	<cfreturn addUnit_("h", arguments.hours)>
</cffunction>

<cffunction name="addDays" access="public" returntype="any" output="no">
	<cfargument name="days" type="numeric" required="yes">

	<cfreturn addUnit_("d", arguments.days)>
</cffunction>

<cffunction name="addMonths" access="public" returntype="any" output="no">
	<cfargument name="months" type="numeric" required="yes">

	<cfreturn addUnit_("m", arguments.months)>
</cffunction>

<!---
 * Add months to the date, but keep the day of the month inside the new
 * month: Jan 31 plus a month is Feb 28 (or 29). The time stays.
--->
<cffunction name="addCalendarMonths" access="public" returntype="any" output="no">
	<cfargument name="months" type="numeric" required="yes">
	<cfset var year = getF_(this.cal, 1)>
	<cfset var month = getF_(this.cal, 2) + 1>
	<cfset var day = getF_(this.cal, 5)>
	<cfset var totalMonths = (year * 12 + month - 1) + arguments.months>
	<cfset var newYear = Fix(totalMonths / 12)>
	<cfset var newMonth = totalMonths - newYear * 12 + 1>
	<cfset var first = "">
	<cfset var lastDayOfMonth = 0>
	<cfset var obj = "">

	<!--- Get last day of new month --->
	<cfset first = create(newYear, newMonth, 1, "", "", "", this.timezone, this.locale)>
	<cfset lastDayOfMonth = first.cal.getActualMaximum(JavaCast("int", 5))>

	<cfif day GT lastDayOfMonth>
		<cfset day = lastDayOfMonth>
	</cfif>

	<cfset obj = create(newYear, newMonth, day, getF_(this.cal, 11), getF_(this.cal, 12), getF_(this.cal, 13), this.timezone, this.locale)>
	<cfset obj.toStringFormat = this.toStringFormat>

	<cfreturn obj>
</cffunction>

<cffunction name="subCalendarMonths" access="public" returntype="any" output="no">
	<cfargument name="months" type="numeric" required="yes">

	<cfreturn addCalendarMonths(-arguments.months)>
</cffunction>

<cffunction name="addYears" access="public" returntype="any" output="no">
	<cfargument name="years" type="numeric" required="yes">

	<cfreturn addUnit_("y", arguments.years)>
</cffunction>

<cffunction name="subSeconds" access="public" returntype="any" output="no">
	<cfargument name="seconds" type="numeric" required="yes">

	<cfreturn addUnit_("s", -arguments.seconds)>
</cffunction>

<cffunction name="subMinutes" access="public" returntype="any" output="no">
	<cfargument name="minutes" type="numeric" required="yes">

	<cfreturn addUnit_("i", -arguments.minutes)>
</cffunction>

<cffunction name="subHours" access="public" returntype="any" output="no">
	<cfargument name="hours" type="numeric" required="yes">

	<cfreturn addUnit_("h", -arguments.hours)>
</cffunction>

<cffunction name="subDays" access="public" returntype="any" output="no">
	<cfargument name="days" type="numeric" required="yes">

	<cfreturn addUnit_("d", -arguments.days)>
</cffunction>

<cffunction name="subMonths" access="public" returntype="any" output="no">
	<cfargument name="months" type="numeric" required="yes">

	<cfreturn addUnit_("m", -arguments.months)>
</cffunction>

<cffunction name="subYears" access="public" returntype="any" output="no">
	<cfargument name="years" type="numeric" required="yes">

	<cfreturn addUnit_("y", -arguments.years)>
</cffunction>

<!--- ------------------------------------------------------------------ --->
<!--- Formatters                                                          --->
<!--- ------------------------------------------------------------------ --->

<!---
 * Returns the localized value of the date in the format 'yyyy-MM-dd HH:mm:ss'
--->
<cffunction name="toDateTimeString" access="public" returntype="string" output="no">
	<cfreturn toLocalizedString("yyyy-MM-dd HH:mm:ss")>
</cffunction>

<!---
 * Returns a localized version of the date in Y-m-d format.
--->
<cffunction name="toDateString" access="public" returntype="string" output="no">
	<cfreturn toLocalizedString("yyyy-MM-dd")>
</cffunction>

<!---
 * Returns a localized version of the date in nice, human-readable
 * format, like "Jan 1, 2017".
--->
<cffunction name="toFormattedDateString" access="public" returntype="string" output="no">
	<cfreturn toLocalizedString("MMM d, yyyy")>
</cffunction>

<!---
 * Returns a localized version of the time in nice, human-readable
 * format, like "13:20:33".
--->
<cffunction name="toTimeString" access="public" returntype="string" output="no">
	<cfreturn toLocalizedString("HH:mm:ss")>
</cffunction>

<!---
 * Adds a value to the pattern as quoted text. A value right after a quoted
 * text is put in the same quotes: two quoted texts side by side would make
 * SimpleDateFormat read an apostrophe between them.
--->
<cffunction name="quoted_" access="private" returntype="string" output="no">
	<cfargument name="pattern" type="string" required="yes">
	<cfargument name="value" type="string" required="yes">

	<cfif Len(arguments.pattern) GT 1 AND Right(arguments.pattern, 1) EQ "'" AND Right(arguments.pattern, 2) NEQ "''">
		<cfreturn Left(arguments.pattern, Len(arguments.pattern) - 1) & arguments.value & "'">
	</cfif>

	<cfreturn arguments.pattern & "'" & arguments.value & "'">
</cffunction>

<!---
 * Returns the localized value of this instance in $format string, with the
 * pattern letters of SimpleDateFormat, plus c, e, L, Q and q of ICU.
 *
 * Difference: c and e give the day of the week with Sunday as 1 whatever the
 * locale. SSSSSS is fractional digits in ICU, but SimpleDateFormat pads the
 * milliseconds, so the digits after the third are zeros.
 *
 * @param string|null $format
--->
<cffunction name="toLocalizedString" access="public" returntype="string" output="no">
	<cfargument name="format" type="any" required="no" default="">
	<cfset var pattern = arguments.format>
	<cfset var out = "">
	<cfset var i = 1>
	<cfset var ch = "">
	<cfset var run = 0>
	<cfset var inQuote = false>
	<cfset var value = "">
	<cfset var df = "">
	<cfset var dow = 0>
	<cfset var month = 0>
	<cfset var quarter = 0>
	<cfset var yearRun = 0>

	<cfif is_null(pattern)>
		<cfset pattern = this.toStringFormat>
	</cfif>

	<!--- the letters that SimpleDateFormat lacks are worked out here and put in as quoted text --->
	<cfif REFind("[cQqeL]", pattern) GT 0>
		<cfset quarter = Int(getF_(this.cal, 2) / 3) + 1>
		<cfset dow = getF_(this.cal, 7)>
		<cfset month = getF_(this.cal, 2) + 1>

		<cfloop condition="i LTE Len(pattern)">
			<cfset ch = Mid(pattern, i, 1)>
			<cfset run = 1>

			<cfif Compare(ch, "'") EQ 0>
				<cfset inQuote = NOT inQuote>
				<cfset out = out & ch>
				<cfset i = i + 1>
			<cfelseif inQuote OR Find(ch, "cQqeL") EQ 0>
				<cfset out = out & ch>
				<cfset i = i + 1>
			<cfelse>
				<cfloop condition="i + run LTE Len(pattern) AND Compare(Mid(pattern, i + run, 1), ch) EQ 0">
					<cfset run = run + 1>
				</cfloop>

				<cfif Find(ch, "Qq") GT 0>
					<cfif run EQ 1>
						<cfset value = quarter>
					<cfelseif run EQ 2>
						<cfset value = pad_(quarter, 2)>
					<cfelseif run EQ 3>
						<cfset value = "Q" & quarter>
					<cfelse>
						<cfset value = ListGetAt("1st,2nd,3rd,4th", quarter) & " quarter">
					</cfif>
					<cfset out = quoted_(out, value)>
				<cfelseif Find(ch, "ce") GT 0>
					<cfif run EQ 1>
						<cfset out = quoted_(out, dow)>
					<cfelseif run EQ 2>
						<cfset out = quoted_(out, pad_(dow, 2))>
					<cfelseif run EQ 3>
						<cfset out = out & "EEE">
					<cfelse>
						<cfset out = out & "EEEE">
					</cfif>
				<cfelse>
					<cfif run EQ 1>
						<cfset out = quoted_(out, month)>
					<cfelseif run EQ 2>
						<cfset out = out & "MM">
					<cfelseif run EQ 3>
						<cfset out = out & "MMM">
					<cfelse>
						<cfset out = out & "MMMM">
					</cfif>
				</cfif>

				<cfset i = i + run>
			</cfif>
		</cfloop>

		<cfset pattern = out>
	</cfif>

	<!--- Difference: ICU gives the full year for a y run that is not yy, SimpleDateFormat only for yyyy --->
	<cfif Find("y", pattern) GT 0>
		<cfset out = "">
		<cfset i = 1>
		<cfset inQuote = false>

		<cfloop condition="i LTE Len(pattern)">
			<cfset ch = Mid(pattern, i, 1)>

			<cfif Compare(ch, "'") EQ 0>
				<cfset inQuote = NOT inQuote>
				<cfset out = out & ch>
				<cfset i = i + 1>
			<cfelseif inQuote OR Compare(ch, "y") NEQ 0>
				<cfset out = out & ch>
				<cfset i = i + 1>
			<cfelse>
				<cfset yearRun = 1>

				<cfloop condition="i + yearRun LTE Len(pattern) AND Compare(Mid(pattern, i + yearRun, 1), ""y"") EQ 0">
					<cfset yearRun = yearRun + 1>
				</cfloop>

				<cfif yearRun EQ 2>
					<cfset out = out & "yy">
				<cfelse>
					<cfset out = out & "yyyy">
				</cfif>

				<cfset i = i + yearRun>
			</cfif>
		</cfloop>

		<cfset pattern = out>
	</cfif>

	<cfset df = CreateObject("java", "java.text.SimpleDateFormat").init(JavaCast("string", pattern), javaLocale_())>
	<cfset df.setTimeZone(this.timezone)>

	<cfreturn df.format(this.cal.getTime())>
</cffunction>

<!--- ------------------------------------------------------------------ --->
<!--- Comparison                                                          --->
<!--- ------------------------------------------------------------------ --->

<!---
 * Determines if the datetime passed in is equal to the current instance.
 * Equal in this case means that they represent the same moment in time,
 * and are not required to be in the same timezone, as both times are
 * converted to UTC and compared that way.
 *
 * Named equals_, because Equals is a method of every Java object.
 *
 * @param Time|string $testTime
--->
<cffunction name="equals_" access="public" returntype="boolean" output="no">
	<cfargument name="testTime" type="any" required="yes">
	<cfargument name="timezone" type="any" required="no" default="">
	<cfset var test = toTime_(arguments.testTime, arguments.timezone)>

	<cfreturn test.getTimestamp() EQ getTimestamp() AND test.micro EQ this.micro>
</cffunction>

<!---
 * Ensures that the times are identical, taking timezone into account.
--->
<cffunction name="sameAs" access="public" returntype="boolean" output="no">
	<cfargument name="testTime" type="any" required="yes">
	<cfargument name="timezone" type="any" required="no" default="">
	<cfset var test = toTime_(arguments.testTime, arguments.timezone)>

	<cfreturn Compare(test.format("Y-m-d H:i:s.u O"), format("Y-m-d H:i:s.u O")) EQ 0>
</cffunction>

<!---
 * Determines if the current instance's time is before $testTime,
 * after converting to UTC.
--->
<cffunction name="isBefore" access="public" returntype="boolean" output="no">
	<cfargument name="testTime" type="any" required="yes">
	<cfargument name="timezone" type="any" required="no" default="">
	<cfset var test = toTime_(arguments.testTime, arguments.timezone)>
	<cfset var testTimestamp = test.getTimestamp()>
	<cfset var ourTimestamp = getTimestamp()>

	<cfif ourTimestamp EQ testTimestamp>
		<cfreturn this.micro LT test.micro>
	</cfif>

	<cfreturn ourTimestamp LT testTimestamp>
</cffunction>

<!---
 * Determines if the current instance's time is after $testTime,
 * after converting in UTC.
--->
<cffunction name="isAfter" access="public" returntype="boolean" output="no">
	<cfargument name="testTime" type="any" required="yes">
	<cfargument name="timezone" type="any" required="no" default="">
	<cfset var test = toTime_(arguments.testTime, arguments.timezone)>
	<cfset var testTimestamp = test.getTimestamp()>
	<cfset var ourTimestamp = getTimestamp()>

	<cfif ourTimestamp EQ testTimestamp>
		<cfreturn this.micro GT test.micro>
	</cfif>

	<cfreturn ourTimestamp GT testTimestamp>
</cffunction>

<!---
 * Determines if the current instance's time is in the past.
--->
<cffunction name="isPast" access="public" returntype="boolean" output="no">
	<cfreturn isBefore(now_(this.timezone))>
</cffunction>

<!---
 * Determines if the current instance's time is in the future.
--->
<cffunction name="isFuture" access="public" returntype="boolean" output="no">
	<cfreturn isAfter(now_(this.timezone))>
</cffunction>

<!--- ------------------------------------------------------------------ --->
<!--- Differences                                                         --->
<!--- ------------------------------------------------------------------ --->

<!---
 * Returns a text representation of the difference between the instance and
 * now, like "3 hours ago" or "in 2 weeks".
 *
 * Difference: the plural forms are those of English only (see Language).
--->
<cffunction name="humanize" access="public" returntype="string" output="no">
	<cfset var now = now_(this.timezone)>
	<cfset var time = this.cal.getTime()>
	<cfset var td = static_("ColdIgniter\I18n\TimeDifference")>
	<cfset var years = td.fieldDifference(now.cal, time, 1)>
	<cfset var months = td.fieldDifference(now.cal, time, 2)>
	<cfset var days = td.fieldDifference(now.cal, time, 6)>
	<cfset var hours = td.fieldDifference(now.cal, time, 11)>
	<cfset var minutes = td.fieldDifference(now.cal, time, 12)>
	<cfset var phrase = "">
	<cfset var before = false>
	<cfset var parameters = ArrayNew(1)>
	<cfset var weeks = 0>

	<cfif years NEQ 0>
		<cfset ArrayAppend(parameters, Abs(years))>
		<cfset phrase = lang("Time.years", parameters)>
		<cfset before = years LT 0>
	<cfelseif months NEQ 0>
		<cfset ArrayAppend(parameters, Abs(months))>
		<cfset phrase = lang("Time.months", parameters)>
		<cfset before = months LT 0>
	<cfelseif days NEQ 0 AND Abs(days) GTE 7>
		<cfset weeks = Ceiling(days / 7)>
		<cfset ArrayAppend(parameters, Abs(weeks))>
		<cfset phrase = lang("Time.weeks", parameters)>
		<cfset before = days LT 0>
	<cfelseif days NEQ 0>
		<cfset before = days LT 0>

		<!--- Yesterday/Tomorrow special cases --->
		<cfif Abs(days) EQ 1>
			<cfif before>
				<cfreturn lang("Time.yesterday")>
			</cfif>

			<cfreturn lang("Time.tomorrow")>
		</cfif>

		<cfset ArrayAppend(parameters, Abs(days))>
		<cfset phrase = lang("Time.days", parameters)>
	<cfelseif hours NEQ 0>
		<cfset ArrayAppend(parameters, Abs(hours))>
		<cfset phrase = lang("Time.hours", parameters)>
		<cfset before = hours LT 0>
	<cfelseif minutes NEQ 0>
		<cfset ArrayAppend(parameters, Abs(minutes))>
		<cfset phrase = lang("Time.minutes", parameters)>
		<cfset before = minutes LT 0>
	<cfelse>
		<cfreturn lang("Time.now")>
	</cfif>

	<cfset parameters = ArrayNew(1)>
	<cfset ArrayAppend(parameters, phrase)>

	<cfif before>
		<cfreturn lang("Time.ago", parameters)>
	</cfif>

	<cfreturn lang("Time.inFuture", parameters)>
</cffunction>

<!---
 * Allows for easily creating a TimeDifference instance between this
 * instance and another, in time or as text.
 *
 * @param Time|string $testTime
 *
 * @return TimeDifference
--->
<cffunction name="difference" access="public" returntype="any" output="no">
	<cfargument name="testTime" type="any" required="yes">
	<cfargument name="timezone" type="any" required="no" default="">
	<cfset var test = toTime_(arguments.testTime, arguments.timezone)>
	<cfset var ourTime = this>
	<cfset var diff = request.ColdIgniter.autoloader.instantiate("ColdIgniter\I18n\TimeDifference")>

	<cfif getOffset() NEQ test.getOffset()>
		<cfset test = getUTCObject(test, arguments.timezone)>
		<cfset ourTime = getUTCObject(this)>
	</cfif>

	<cfreturn diff.__construct(ourTime, test)>
</cffunction>

<!--- ------------------------------------------------------------------ --->
<!--- Utilities                                                           --->
<!--- ------------------------------------------------------------------ --->

<!---
 * Returns a Time instance with all of the timezone stuff set to UTC.
 *
 * @param Time|string $time
--->
<cffunction name="getUTCObject" access="public" returntype="any" output="no">
	<cfargument name="time" type="any" required="yes">
	<cfargument name="timezone" type="any" required="no" default="">

	<cfreturn toTime_(arguments.time, arguments.timezone).setTimezone("UTC")>
</cffunction>

<!---
 * Returns the calendar of this instance.
 *
 * Difference: a Java Calendar (a copy), not an IntlCalendar.
--->
<cffunction name="getCalendar" access="public" returntype="any" output="no">
	<cfset var cal = mkCal_(this.timezone)>

	<cfset cal.setTime(this.cal.getTime())>

	<cfreturn cal>
</cffunction>

<!---
 * Check if time string has relative keywords like "next monday".
 * Not static: the original is a protected static function.
--->
<cffunction name="hasRelativeKeywords" access="private" returntype="boolean" output="no">
	<cfargument name="time" type="string" required="yes">

	<!--- skip common format with a '-' in it --->
	<cfif REFind("[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}", arguments.time) EQ 0>
		<cfreturn REFindNoCase(this.relativePattern, arguments.time) GT 0>
	</cfif>

	<cfreturn false>
</cffunction>

<!---
 * Returns the time as "Y-m-d H:i:s".
--->
<cffunction name="__toString" access="public" returntype="string" output="no">
	<cfreturn format("Y-m-d H:i:s")>
</cffunction>

<!--- ------------------------------------------------------------------ --->
<!--- The reader of time strings (see the difference at the top)          --->
<!--- ------------------------------------------------------------------ --->

<!---
 * Matches a pattern at the start of the text, and gives the Java matcher,
 * or an empty string when there is no match. The compiled patterns are kept
 * for the request.
--->
<cffunction name="tok_" access="private" returntype="any" output="no">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="regex" type="string" required="yes">
	<cfargument name="text" type="string" required="yes">
	<cfset var m = "">

	<cfif NOT StructKeyExists(request.ColdIgniter, "timePatterns")>
		<cfset request.ColdIgniter.timePatterns = StructNew()>
	</cfif>

	<cfif NOT StructKeyExists(request.ColdIgniter.timePatterns, arguments.name)>
		<cfset request.ColdIgniter.timePatterns[arguments.name] = CreateObject("java", "java.util.regex.Pattern").compile(JavaCast("string", arguments.regex))>
	</cfif>

	<cfset m = request.ColdIgniter.timePatterns[arguments.name].matcher(JavaCast("string", arguments.text))>

	<cfif m.lookingAt()>
		<cfreturn m>
	</cfif>

	<cfreturn "">
</cffunction>

<!---
 * Reads a time string into this object: absolute parts replace the fields,
 * relative parts move them. It is public only so that another object of the
 * class can call it. The text is relative to the current time of the object
 * (the constructor gives it the current time, modify gives it its own time).
 *
 * @param boolean $relative  true from modify: a date alone keeps the time
 *
 * @return static this
 *
 * @throws Exception
--->
<cffunction name="parseInto_" access="public" returntype="any" output="no">
	<cfargument name="text" type="string" required="yes">
	<cfargument name="relative" type="boolean" required="no" default="false">
	<cfset var s = LCase(Trim(arguments.text))>
	<cfset var m = "">
	<cfset var mon = "(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|aug(?:ust)?|sep(?:t(?:ember)?)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)(?![a-z])">
	<cfset var dowRx = "(sun(?:day)?|mon(?:day)?|tue(?:s(?:day)?)?|wed(?:nesday)?|thu(?:r(?:s(?:day)?)?)?|fri(?:day)?|sat(?:urday)?)(?![a-z])">
	<cfset var unitRx = "(sec(?:ond)?s?|min(?:ute)?s?|hours?|days?|weeks?|fortnights?|months?|years?)(?![a-z])">
	<cfset var resetTime = false>
	<cfset var timeSet = false>
	<cfset var ry = 0>
	<cfset var rm = 0>
	<cfset var rd = 0>
	<cfset var rh = 0>
	<cfset var rn = 0>
	<cfset var rs = 0>
	<cfset var weekday = 0>
	<cfset var weekMode = 0>
	<cfset var firstLast = "">
	<cfset var zone = "">
	<cfset var hour = 0>
	<cfset var minute = 0>
	<cfset var second = 0>
	<cfset var amPm = "">
	<cfset var n = 0>
	<cfset var sign = 1>
	<cfset var unit = "">
	<cfset var word = "">
	<cfset var year = 0>
	<cfset var step = 0>
	<cfset var delta = 0>
	<cfset var tmp = "">
	<cfset var cur = 0>
	<cfset var done = false>
	<cfset var matched = false>
	<cfset var gotTime = false>
	<cfset var micro = -1>
	<cfset var frac = "">
	<cfset var offset = "">

	<!--- a CFML date value written as text: {ts '2017-01-01 10:00:00'} --->
	<cfif Left(s, 5) EQ "{ts '">
		<cfset s = REReplace(s, "^\{ts '([^']*)'\}$", "\1")>
	</cfif>

	<cfloop condition="NOT done">
		<cfset s = REReplace(s, "^[ ,]+", "")>

		<cfif s EQ "">
			<cfbreak>
		</cfif>

		<cfset matched = false>

		<cfif NOT matched><cfset m = tok_("epoch", "@(-?[0-9]+)(?:\.([0-9]+))?", s)></cfif>
		<cfif NOT matched AND NOT IsSimpleValue(m)>
			<cfset this.cal.setTime(dateOf_(Val(m.group(JavaCast("int", 1)))))>
			<cfset this.micro = 0>
			<cfset timeSet = true>
			<cfset s = Mid(s, m.end() + 1, Len(s))>
			<cfset matched = true>
		</cfif>

		<cfif NOT matched><cfset m = tok_("iso", "([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})(?![0-9])t?", s)></cfif>
		<cfif NOT matched AND NOT IsSimpleValue(m)>
			<cfset setF_(this.cal, 1, Val(m.group(JavaCast("int", 1))))>
			<cfset setF_(this.cal, 2, Val(m.group(JavaCast("int", 2))) - 1)>
			<cfset setF_(this.cal, 5, Val(m.group(JavaCast("int", 3))))>
			<cfif NOT arguments.relative><cfset resetTime = true></cfif>
			<cfset s = Mid(s, m.end() + 1, Len(s))>
			<cfset matched = true>
		</cfif>

		<cfif NOT matched><cfset m = tok_("isoshort", "([0-9]{4})-([0-9]{2})(?![0-9-])", s)></cfif>
		<cfif NOT matched AND NOT IsSimpleValue(m)>
			<cfset setF_(this.cal, 1, Val(m.group(JavaCast("int", 1))))>
			<cfset setF_(this.cal, 2, Val(m.group(JavaCast("int", 2))) - 1)>
			<cfset setF_(this.cal, 5, 1)>
			<cfif NOT arguments.relative><cfset resetTime = true></cfif>
			<cfset s = Mid(s, m.end() + 1, Len(s))>
			<cfset matched = true>
		</cfif>

		<cfif NOT matched><cfset m = tok_("ymd", "([0-9]{4})/([0-9]{1,2})/([0-9]{1,2})(?![0-9])", s)></cfif>
		<cfif NOT matched AND NOT IsSimpleValue(m)>
			<cfset setF_(this.cal, 1, Val(m.group(JavaCast("int", 1))))>
			<cfset setF_(this.cal, 2, Val(m.group(JavaCast("int", 2))) - 1)>
			<cfset setF_(this.cal, 5, Val(m.group(JavaCast("int", 3))))>
			<cfif NOT arguments.relative><cfset resetTime = true></cfif>
			<cfset s = Mid(s, m.end() + 1, Len(s))>
			<cfset matched = true>
		</cfif>

		<cfif NOT matched><cfset m = tok_("mdy", "([0-9]{1,2})/([0-9]{1,2})/([0-9]{4})(?![0-9])", s)></cfif>
		<cfif NOT matched AND NOT IsSimpleValue(m)>
			<cfset setF_(this.cal, 1, Val(m.group(JavaCast("int", 3))))>
			<cfset setF_(this.cal, 2, Val(m.group(JavaCast("int", 1))) - 1)>
			<cfset setF_(this.cal, 5, Val(m.group(JavaCast("int", 2))))>
			<cfif NOT arguments.relative><cfset resetTime = true></cfif>
			<cfset s = Mid(s, m.end() + 1, Len(s))>
			<cfset matched = true>
		</cfif>

		<cfif NOT matched><cfset m = tok_("md", "([0-9]{1,2})/([0-9]{1,2})(?![0-9/])", s)></cfif>
		<cfif NOT matched AND NOT IsSimpleValue(m)>
			<cfset setF_(this.cal, 2, Val(m.group(JavaCast("int", 1))) - 1)>
			<cfset setF_(this.cal, 5, Val(m.group(JavaCast("int", 2))))>
			<cfif NOT arguments.relative><cfset resetTime = true></cfif>
			<cfset s = Mid(s, m.end() + 1, Len(s))>
			<cfset matched = true>
		</cfif>

		<cfif NOT matched><cfset m = tok_("dmy", "([0-9]{1,2})[-.]([0-9]{1,2})[-.]([0-9]{4})(?![0-9])", s)></cfif>
		<cfif NOT matched AND NOT IsSimpleValue(m)>
			<cfset setF_(this.cal, 1, Val(m.group(JavaCast("int", 3))))>
			<cfset setF_(this.cal, 2, Val(m.group(JavaCast("int", 2))) - 1)>
			<cfset setF_(this.cal, 5, Val(m.group(JavaCast("int", 1))))>
			<cfif NOT arguments.relative><cfset resetTime = true></cfif>
			<cfset s = Mid(s, m.end() + 1, Len(s))>
			<cfset matched = true>
		</cfif>

		<!--- a relative number: "+1 day", "- 2 weeks", "3 months" --->
		<cfif NOT matched><cfset m = tok_("rel", "([+-]?) *([0-9]+) *" & unitRx, s)></cfif>
		<cfif NOT matched AND NOT IsSimpleValue(m)>
			<cfset n = Val(m.group(JavaCast("int", 2)))>
			<cfif Compare(m.group(JavaCast("int", 1)), "-") EQ 0>
				<cfset n = -n>
			</cfif>
			<cfset unit = Left(m.group(JavaCast("int", 3)), 3)>
			<cfset s = Mid(s, m.end() + 1, Len(s))>

			<cfif Compare(unit, "sec") EQ 0>
				<cfset rs = rs + n>
			<cfelseif Compare(unit, "min") EQ 0>
				<cfset rn = rn + n>
			<cfelseif Compare(unit, "hou") EQ 0>
				<cfset rh = rh + n>
			<cfelseif Compare(unit, "day") EQ 0>
				<cfset rd = rd + n>
			<cfelseif Compare(unit, "wee") EQ 0>
				<cfset rd = rd + n * 7>
			<cfelseif Compare(unit, "for") EQ 0>
				<cfset rd = rd + n * 14>
			<cfelseif Compare(unit, "mon") EQ 0>
				<cfset rm = rm + n>
			<cfelse>
				<cfset ry = ry + n>
			</cfif>
			<cfset matched = true>
		</cfif>

		<!--- a time: 10:30, 10:30:15.5, 10:30pm, 10pm, t10:30 --->
		<cfif NOT matched>
			<cfset m = tok_("time", "t?([0-9]{1,2}):([0-9]{2})(?::([0-9]{2})(?:[.,]([0-9]+))?)?(?: *([ap])\.?m\.?(?![a-z]))?", s)>
			<cfset gotTime = false>

			<cfif NOT matched AND NOT IsSimpleValue(m)>
				<cfset gotTime = true>
				<cfset hour = Val(m.group(JavaCast("int", 1)))>
				<cfset minute = Val(m.group(JavaCast("int", 2)))>
				<cfset second = 0>
				<cfset frac = "">
				<cfset amPm = "">

				<cfif m.start(JavaCast("int", 3)) GTE 0>
					<cfset second = Val(m.group(JavaCast("int", 3)))>
				</cfif>

				<cfif m.start(JavaCast("int", 4)) GTE 0>
					<cfset frac = m.group(JavaCast("int", 4))>
				</cfif>

				<cfif m.start(JavaCast("int", 5)) GTE 0>
					<cfset amPm = m.group(JavaCast("int", 5))>
				</cfif>
			<cfelse>
				<cfset m = tok_("hour12", "([0-9]{1,2}) *([ap])\.?m\.?(?![a-z])", s)>

				<cfif NOT matched AND NOT IsSimpleValue(m)>
					<cfset gotTime = true>
					<cfset hour = Val(m.group(JavaCast("int", 1)))>
					<cfset minute = 0>
					<cfset second = 0>
					<cfset frac = "">
					<cfset amPm = m.group(JavaCast("int", 2))>
				</cfif>
			</cfif>

			<cfif gotTime>
				<cfif hour GT 24 OR minute GT 59 OR second GT 60>
					<cfthrow type="ColdIgniter.Exception" message="Failed to parse time string (#arguments.text#)">
				</cfif>

				<cfif amPm EQ "p" AND hour LT 12>
					<cfset hour = hour + 12>
				<cfelseif amPm EQ "a" AND hour EQ 12>
					<cfset hour = 0>
				</cfif>

				<cfset setF_(this.cal, 11, hour)>
				<cfset setF_(this.cal, 12, minute)>
				<cfset setF_(this.cal, 13, second)>
				<cfset setF_(this.cal, 14, 0)>

				<cfif frac NEQ "">
					<cfset micro = Val(Left(frac & "000000", 6))>
				<cfelse>
					<cfset micro = 0>
				</cfif>

				<cfset timeSet = true>
				<cfset s = Mid(s, m.end() + 1, Len(s))>
				<cfset matched = true>
			</cfif>
		</cfif>

		<!--- a zone after a time --->
		<cfif NOT matched><cfset m = tok_("tzname", "(z|utc|gmt)(?![a-z])", s)></cfif>
		<cfif NOT matched AND NOT IsSimpleValue(m)>
			<cfset zone = tzOf_("UTC")>
			<cfset s = Mid(s, m.end() + 1, Len(s))>
			<cfset matched = true>
		</cfif>

		<cfif timeSet>
			<cfif NOT matched><cfset m = tok_("tzoff", "(?:gmt)?([+-])([0-9]{1,2}):?([0-9]{2})?(?![0-9])", s)></cfif>
			<cfif NOT matched AND NOT IsSimpleValue(m)>
				<cfset offset = m.group(JavaCast("int", 1)) & Right("0" & m.group(JavaCast("int", 2)), 2) & ":00">
				<cfif m.start(JavaCast("int", 3)) GTE 0>
					<cfset offset = m.group(JavaCast("int", 1)) & Right("0" & m.group(JavaCast("int", 2)), 2) & ":" & m.group(JavaCast("int", 3))>
				</cfif>
				<cfset zone = tzOf_(offset)>
				<cfset s = Mid(s, m.end() + 1, Len(s))>
				<cfset matched = true>
			</cfif>
		</cfif>

		<cfif NOT matched><cfset m = tok_("firstlast", "(first|last) day of(?![a-z])", s)></cfif>
		<cfif NOT matched AND NOT IsSimpleValue(m)>
			<cfset firstLast = m.group(JavaCast("int", 1))>
			<cfset s = Mid(s, m.end() + 1, Len(s))>
			<cfset matched = true>
		</cfif>

		<cfif NOT matched><cfset m = tok_("nextunit", "(next|last|previous|this) +" & unitRx, s)></cfif>
		<cfif NOT matched AND NOT IsSimpleValue(m)>
			<cfset word = m.group(JavaCast("int", 1))>
			<cfset n = 1>
			<cfif Compare(word, "this") EQ 0>
				<cfset n = 0>
			<cfelseif Compare(word, "next") NEQ 0>
				<cfset n = -1>
			</cfif>
			<cfset unit = Left(m.group(JavaCast("int", 2)), 3)>
			<cfset s = Mid(s, m.end() + 1, Len(s))>

			<cfif Compare(unit, "sec") EQ 0>
				<cfset rs = rs + n>
			<cfelseif Compare(unit, "min") EQ 0>
				<cfset rn = rn + n>
			<cfelseif Compare(unit, "hou") EQ 0>
				<cfset rh = rh + n>
			<cfelseif Compare(unit, "day") EQ 0>
				<cfset rd = rd + n>
			<cfelseif Compare(unit, "wee") EQ 0>
				<cfset rd = rd + n * 7>
			<cfelseif Compare(unit, "for") EQ 0>
				<cfset rd = rd + n * 14>
			<cfelseif Compare(unit, "mon") EQ 0>
				<cfset rm = rm + n>
			<cfelse>
				<cfset ry = ry + n>
			</cfif>
			<cfset matched = true>
		</cfif>

		<cfif NOT matched><cfset m = tok_("nextdow", "(next|last|previous|this) +" & dowRx, s)></cfif>
		<cfif NOT matched AND NOT IsSimpleValue(m)>
			<cfset word = m.group(JavaCast("int", 1))>
			<cfset weekMode = 0>
			<cfif Compare(word, "next") EQ 0>
				<cfset weekMode = 1>
			<cfelseif Compare(word, "this") NEQ 0>
				<cfset weekMode = -1>
			</cfif>
			<cfset weekday = ListFind("sun,mon,tue,wed,thu,fri,sat", Left(m.group(JavaCast("int", 2)), 3))>
			<cfset resetTime = true>
			<cfset s = Mid(s, m.end() + 1, Len(s))>
			<cfset matched = true>
		</cfif>

		<cfif NOT matched><cfset m = tok_("dow", dowRx, s)></cfif>
		<cfif NOT matched AND NOT IsSimpleValue(m)>
			<cfset weekMode = 0>
			<cfset weekday = ListFind("sun,mon,tue,wed,thu,fri,sat", Left(m.group(JavaCast("int", 1)), 3))>
			<cfset resetTime = true>
			<cfset s = Mid(s, m.end() + 1, Len(s))>
			<cfset matched = true>
		</cfif>

		<!--- month names: "March 5, 2017", "5 March 2017", "March 2017", "March" --->
		<cfif NOT matched><cfset m = tok_("mond", mon & " +([0-9]{1,2})(?:st|nd|rd|th)?(?![0-9a-z])(?:,? +([0-9]{4})(?![0-9:]))?", s)></cfif>
		<cfif NOT matched AND NOT IsSimpleValue(m)>
			<cfset setF_(this.cal, 2, ListFind("jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec", Left(m.group(JavaCast("int", 1)), 3)) - 1)>
			<cfset setF_(this.cal, 5, Val(m.group(JavaCast("int", 2))))>

			<cfif m.start(JavaCast("int", 3)) GTE 0>
				<cfset setF_(this.cal, 1, Val(m.group(JavaCast("int", 3))))>
			</cfif>

			<cfif NOT arguments.relative><cfset resetTime = true></cfif>
			<cfset s = Mid(s, m.end() + 1, Len(s))>
			<cfset matched = true>
		</cfif>

		<cfif NOT matched><cfset m = tok_("dmon", "([0-9]{1,2})(?:st|nd|rd|th)?[ -]+" & mon & "(?:[ ,-]+([0-9]{4})(?![0-9:]))?", s)></cfif>
		<cfif NOT matched AND NOT IsSimpleValue(m)>
			<cfset setF_(this.cal, 2, ListFind("jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec", Left(m.group(JavaCast("int", 2)), 3)) - 1)>
			<cfset setF_(this.cal, 5, Val(m.group(JavaCast("int", 1))))>

			<cfif m.start(JavaCast("int", 3)) GTE 0>
				<cfset setF_(this.cal, 1, Val(m.group(JavaCast("int", 3))))>
			</cfif>

			<cfif NOT arguments.relative><cfset resetTime = true></cfif>
			<cfset s = Mid(s, m.end() + 1, Len(s))>
			<cfset matched = true>
		</cfif>

		<cfif NOT matched><cfset m = tok_("monyear", mon & " +([0-9]{4})(?![0-9:])", s)></cfif>
		<cfif NOT matched AND NOT IsSimpleValue(m)>
			<cfset setF_(this.cal, 2, ListFind("jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec", Left(m.group(JavaCast("int", 1)), 3)) - 1)>
			<cfset setF_(this.cal, 5, 1)>
			<cfset setF_(this.cal, 1, Val(m.group(JavaCast("int", 2))))>
			<cfif NOT arguments.relative><cfset resetTime = true></cfif>
			<cfset s = Mid(s, m.end() + 1, Len(s))>
			<cfset matched = true>
		</cfif>

		<cfif NOT matched><cfset m = tok_("monalone", mon, s)></cfif>
		<cfif NOT matched AND NOT IsSimpleValue(m)>
			<cfset setF_(this.cal, 2, ListFind("jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec", Left(m.group(JavaCast("int", 1)), 3)) - 1)>
			<cfset resetTime = true>
			<cfset s = Mid(s, m.end() + 1, Len(s))>
			<cfset matched = true>
		</cfif>

		<cfif NOT matched><cfset m = tok_("word", "(now|today|midnight|noon|tomorrow|yesterday|ago)(?![a-z])", s)></cfif>
		<cfif NOT matched AND NOT IsSimpleValue(m)>
			<cfset word = m.group(JavaCast("int", 1))>
			<cfset s = Mid(s, m.end() + 1, Len(s))>

			<cfif Compare(word, "today") EQ 0 OR Compare(word, "midnight") EQ 0>
				<cfset resetTime = true>
			<cfelseif Compare(word, "noon") EQ 0>
				<cfset setF_(this.cal, 11, 12)>
				<cfset setF_(this.cal, 12, 0)>
				<cfset setF_(this.cal, 13, 0)>
				<cfset setF_(this.cal, 14, 0)>
				<cfset micro = 0>
				<cfset timeSet = true>
			<cfelseif Compare(word, "tomorrow") EQ 0>
				<cfset rd = rd + 1>
				<cfset resetTime = true>
			<cfelseif Compare(word, "yesterday") EQ 0>
				<cfset rd = rd - 1>
				<cfset resetTime = true>
			<cfelseif Compare(word, "ago") EQ 0>
				<cfset ry = -ry>
				<cfset rm = -rm>
				<cfset rd = -rd>
				<cfset rh = -rh>
				<cfset rn = -rn>
				<cfset rs = -rs>
			</cfif>
			<cfset matched = true>
		</cfif>

		<cfif NOT matched>
			<cfthrow type="ColdIgniter.Exception" message="Failed to parse time string (#arguments.text#) at (#Left(s, 12)#)">
		</cfif>
	</cfloop>

	<!--- a zone in the text: the fields read so far are the clock of that zone --->
	<cfif NOT IsSimpleValue(zone)>
		<cfset tmp = mkCal_(zone)>
		<cfset tmp.clear()>
		<cfset setF_(tmp, 1, getF_(this.cal, 1))>
		<cfset setF_(tmp, 2, getF_(this.cal, 2))>
		<cfset setF_(tmp, 5, getF_(this.cal, 5))>
		<cfset setF_(tmp, 11, getF_(this.cal, 11))>
		<cfset setF_(tmp, 12, getF_(this.cal, 12))>
		<cfset setF_(tmp, 13, getF_(this.cal, 13))>
		<cfset this.cal.setTime(tmp.getTime())>
	</cfif>

	<!--- a date, a weekday or a keyword that is not followed by a time sets the time to 0 (not in modify for a bare weekday or relative text) --->
	<cfif resetTime AND NOT timeSet>
		<cfset setF_(this.cal, 11, 0)>
		<cfset setF_(this.cal, 12, 0)>
		<cfset setF_(this.cal, 13, 0)>
		<cfset setF_(this.cal, 14, 0)>
		<cfset this.micro = 0>
	</cfif>

	<cfif micro GTE 0>
		<cfset this.micro = micro>
	</cfif>

	<!--- first/last day of: the months are counted from the first of the month --->
	<cfif firstLast NEQ "">
		<cfset setF_(this.cal, 5, 1)>
	</cfif>

	<cfif ry NEQ 0 OR rm NEQ 0>
		<cfset year = getF_(this.cal, 1)>
		<cfset n = getF_(this.cal, 2)>
		<cfset setF_(this.cal, 1, year + ry)>
		<cfset setF_(this.cal, 2, n + rm)>
	</cfif>

	<cfif firstLast EQ "last">
		<cfset setF_(this.cal, 5, this.cal.getActualMaximum(JavaCast("int", 5)))>
	</cfif>

	<cfif rd NEQ 0>
		<cfset addF_(this.cal, 5, rd)>
	</cfif>

	<cfif weekday GT 0>
		<cfset cur = getF_(this.cal, 7)>
		<cfset delta = weekday - cur>

		<cfif weekMode EQ 0>
			<cfif delta LT 0>
				<cfset delta = delta + 7>
			</cfif>
		<cfelseif weekMode EQ 1>
			<cfif delta LTE 0>
				<cfset delta = delta + 7>
			</cfif>
		<cfelse>
			<cfif delta GTE 0>
				<cfset delta = delta - 7>
			</cfif>
		</cfif>

		<cfset addF_(this.cal, 5, delta)>
	</cfif>

	<cfif rh NEQ 0>
		<cfset addF_(this.cal, 11, rh)>
	</cfif>

	<cfif rn NEQ 0>
		<cfset addF_(this.cal, 12, rn)>
	</cfif>

	<cfif rs NEQ 0>
		<cfset addF_(this.cal, 13, rs)>
	</cfif>

	<cfreturn this>
</cffunction>
