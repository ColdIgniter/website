<!---
 * Class TimeDifference
 *
 * Difference: the original keeps IntlCalendar objects. Here currentTime is a
 * Java calendar (a copy, in the timezone of the first Time) and testTime is a
 * java.util.Date. fieldDifference, which IntlCalendar has, is here a method
 * of this component, and Time::humanize uses it too.
 *
 * Not ported yet: the digits of other scripts.
--->
<cfcomponent output="no" hint="Class TimeDifference">

	<!---
	 * The calendar of the current time.
	 *
	 * @var Calendar (Java)
	--->
	<cfset this.currentTime = "">

	<!---
	 * The time to test against.
	 *
	 * @var Date (Java)
	--->
	<cfset this.testTime = "">

	<!---
	 * @var int
	--->
	<cfset this.eras = 0>

	<!---
	 * @var int
	--->
	<cfset this.years = 0>

	<!---
	 * @var int
	--->
	<cfset this.months = 0>

	<!---
	 * @var int
	--->
	<cfset this.weeks = 0>

	<!---
	 * @var int
	--->
	<cfset this.days = 0>

	<!---
	 * @var int
	--->
	<cfset this.hours = 0>

	<!---
	 * @var int
	--->
	<cfset this.minutes = 0>

	<!---
	 * @var int
	--->
	<cfset this.seconds = 0>

	<!---
	 * @var int
	--->
	<cfset this.difference = 0>

	<!---
	 * Constructor.
	 *
	 * @param Time $currentTime
	 * @param Time $testTime
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="currentTime" type="any" required="yes">
		<cfargument name="testTime" type="any" required="yes">

		<cfset this.difference = arguments.currentTime.getTimestamp() - arguments.testTime.getTimestamp()>

		<cfset this.currentTime = arguments.currentTime.getCalendar()>
		<cfset this.testTime = arguments.testTime.cal.getTime()>

		<cfreturn this>
	</cffunction>

	<!---
	 * The number of full units (a field of the calendar) that have to be added
	 * to the calendar to reach the date, as IntlCalendar::fieldDifference
	 * gives: positive when the date is later, cut towards zero. The calendar
	 * is not changed. field is a number of java.util.Calendar: 1 year,
	 * 2 month, 6 day of year, 11 hour of day, 12 minute, 13 second.
	 *
	 * @param Calendar $start A Java calendar
	 * @param Date     $end   A java.util.Date
	 * @param int      $field
	--->
	<cffunction name="fieldDifference" access="public" returntype="numeric" output="no">
		<cfargument name="start" type="any" required="yes">
		<cfargument name="end" type="any" required="yes">
		<cfargument name="field" type="numeric" required="yes">
		<cfset var startMs = arguments.start.getTime().getTime()>
		<cfset var endMs = arguments.end.getTime()>
		<cfset var diff = endMs - startMs>
		<cfset var estimate = 0>
		<cfset var k = 0>

		<cfif diff EQ 0>
			<cfreturn 0>
		</cfif>

		<!--- an estimate from the length of the unit, then corrected by adding to the start --->
		<cfif arguments.field EQ 13>
			<cfset estimate = diff / 1000>
		<cfelseif arguments.field EQ 12>
			<cfset estimate = diff / 60000>
		<cfelseif arguments.field EQ 11>
			<cfset estimate = diff / 3600000>
		<cfelseif arguments.field EQ 6>
			<cfset estimate = diff / 86400000>
		<cfelseif arguments.field EQ 2>
			<cfset estimate = diff / 2629746000>
		<cfelse>
			<cfset estimate = diff / 31556952000>
		</cfif>

		<cfset k = Fix(estimate)>

		<cfif diff GT 0>
			<cfloop condition="k GT 0 AND addedMs_(arguments.start, arguments.field, k) GT endMs">
				<cfset k = k - 1>
			</cfloop>

			<cfloop condition="addedMs_(arguments.start, arguments.field, k + 1) LTE endMs">
				<cfset k = k + 1>
			</cfloop>
		<cfelse>
			<cfloop condition="k LT 0 AND addedMs_(arguments.start, arguments.field, k) LT endMs">
				<cfset k = k + 1>
			</cfloop>

			<cfloop condition="addedMs_(arguments.start, arguments.field, k - 1) GTE endMs">
				<cfset k = k - 1>
			</cfloop>
		</cfif>

		<cfreturn k>
	</cffunction>

	<!---
	 * The time in milliseconds of a copy of the calendar with a number of a
	 * unit added.
	--->
	<cffunction name="addedMs_" access="private" returntype="numeric" output="no">
		<cfargument name="start" type="any" required="yes">
		<cfargument name="field" type="numeric" required="yes">
		<cfargument name="count" type="numeric" required="yes">
		<cfset var cal = CreateObject("java", "java.util.GregorianCalendar").init()>

		<cfset cal.setTimeZone(arguments.start.getTimeZone())>
		<cfset cal.setTime(arguments.start.getTime())>
		<cfset cal.add(JavaCast("int", arguments.field), JavaCast("int", arguments.count))>

		<cfreturn cal.getTime().getTime()>
	</cffunction>

	<!---
	 * Gets the difference in full years
	 *
	 * @return float|int
	--->
	<cffunction name="getYears" access="public" returntype="numeric" output="no">
		<cfargument name="raw" type="boolean" required="no" default="false">

		<cfif arguments.raw>
			<cfreturn this.difference / request.YEAR>
		</cfif>

		<cfreturn fieldDifference(this.currentTime, this.testTime, 1)>
	</cffunction>

	<!---
	 * Gets the difference in full months
	 *
	 * @return float|int
	--->
	<cffunction name="getMonths" access="public" returntype="numeric" output="no">
		<cfargument name="raw" type="boolean" required="no" default="false">

		<cfif arguments.raw>
			<cfreturn this.difference / request.MONTH>
		</cfif>

		<cfreturn fieldDifference(this.currentTime, this.testTime, 2)>
	</cffunction>

	<!---
	 * Gets the difference in weeks
	 *
	 * @return float|int
	--->
	<cffunction name="getWeeks" access="public" returntype="numeric" output="no">
		<cfargument name="raw" type="boolean" required="no" default="false">

		<cfif arguments.raw>
			<cfreturn this.difference / request.WEEK>
		</cfif>

		<cfreturn Fix(fieldDifference(this.currentTime, this.testTime, 6) / 7)>
	</cffunction>

	<!---
	 * Gets the difference in days
	 *
	 * @return float|int
	--->
	<cffunction name="getDays" access="public" returntype="numeric" output="no">
		<cfargument name="raw" type="boolean" required="no" default="false">

		<cfif arguments.raw>
			<cfreturn this.difference / request.DAY>
		</cfif>

		<cfreturn fieldDifference(this.currentTime, this.testTime, 6)>
	</cffunction>

	<!---
	 * Gets the difference in hours
	 *
	 * @return float|int
	--->
	<cffunction name="getHours" access="public" returntype="numeric" output="no">
		<cfargument name="raw" type="boolean" required="no" default="false">

		<cfif arguments.raw>
			<cfreturn this.difference / request.HOUR>
		</cfif>

		<cfreturn fieldDifference(this.currentTime, this.testTime, 11)>
	</cffunction>

	<!---
	 * Gets the difference in minutes
	 *
	 * @return float|int
	--->
	<cffunction name="getMinutes" access="public" returntype="numeric" output="no">
		<cfargument name="raw" type="boolean" required="no" default="false">

		<cfif arguments.raw>
			<cfreturn this.difference / request.MINUTE>
		</cfif>

		<cfreturn fieldDifference(this.currentTime, this.testTime, 12)>
	</cffunction>

	<!---
	 * Gets the difference in seconds
	 *
	 * @return float|int
	--->
	<cffunction name="getSeconds" access="public" returntype="numeric" output="no">
		<cfargument name="raw" type="boolean" required="no" default="false">

		<cfif arguments.raw>
			<cfreturn this.difference>
		</cfif>

		<cfreturn fieldDifference(this.currentTime, this.testTime, 13)>
	</cffunction>

	<!---
	 * Convert the time difference to a human-readable format, such as
	 * "3 hours ago" or "in 2 weeks".
	 *
	 * Difference: the plural forms are those of English only (see Language).
	 *
	 * @param string|null $locale
	--->
	<cffunction name="humanize" access="public" returntype="string" output="no">
		<cfargument name="locale" type="any" required="no" default="">
		<cfset var years = fieldDifference(this.currentTime, this.testTime, 1)>
		<cfset var months = fieldDifference(this.currentTime, this.testTime, 2)>
		<cfset var days = fieldDifference(this.currentTime, this.testTime, 6)>
		<cfset var hours = fieldDifference(this.currentTime, this.testTime, 11)>
		<cfset var minutes = fieldDifference(this.currentTime, this.testTime, 12)>
		<cfset var phrase = "">
		<cfset var before = false>
		<cfset var parameters = ArrayNew(1)>

		<cfif years NEQ 0>
			<cfset ArrayAppend(parameters, Abs(years))>
			<cfset phrase = lang("Time.years", parameters, arguments.locale)>
			<cfset before = years LT 0>
		<cfelseif months NEQ 0>
			<cfset ArrayAppend(parameters, Abs(months))>
			<cfset phrase = lang("Time.months", parameters, arguments.locale)>
			<cfset before = months LT 0>
		<cfelseif days NEQ 0 AND Abs(days) GTE 7>
			<cfset ArrayAppend(parameters, Abs(Ceiling(days / 7)))>
			<cfset phrase = lang("Time.weeks", parameters, arguments.locale)>
			<cfset before = days LT 0>
		<cfelseif days NEQ 0>
			<cfset ArrayAppend(parameters, Abs(days))>
			<cfset phrase = lang("Time.days", parameters, arguments.locale)>
			<cfset before = days LT 0>
		<cfelseif hours NEQ 0>
			<cfset ArrayAppend(parameters, Abs(hours))>
			<cfset phrase = lang("Time.hours", parameters, arguments.locale)>
			<cfset before = hours LT 0>
		<cfelseif minutes NEQ 0>
			<cfset ArrayAppend(parameters, Abs(minutes))>
			<cfset phrase = lang("Time.minutes", parameters, arguments.locale)>
			<cfset before = minutes LT 0>
		<cfelse>
			<cfreturn lang("Time.now", "", arguments.locale)>
		</cfif>

		<cfset parameters = ArrayNew(1)>
		<cfset ArrayAppend(parameters, phrase)>

		<cfif before>
			<cfreturn lang("Time.ago", parameters, arguments.locale)>
		</cfif>

		<cfreturn lang("Time.inFuture", parameters, arguments.locale)>
	</cffunction>

	<!---
	 * Allow property-like access to the getters: __get("years") calls
	 * getYears(). An unknown name gives an empty string (null).
	--->
	<cffunction name="__get" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfset var method = "get" & UCase(Left(arguments.name, 1)) & LCase(Mid(arguments.name, 2, Len(arguments.name)))>
		<cfset var result = "">

		<cfif StructKeyExists(this, method)>
			<cfinvoke component="#this#" method="#method#" returnvariable="result">
			<cfreturn result>
		</cfif>

		<cfreturn "">
	</cffunction>

	<cffunction name="__isset" access="public" returntype="boolean" output="no">
		<cfargument name="name" type="string" required="yes">

		<cfreturn StructKeyExists(this, "get" & UCase(Left(arguments.name, 1)) & LCase(Mid(arguments.name, 2, Len(arguments.name))))>
	</cffunction>

</cfcomponent>
