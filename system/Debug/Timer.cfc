<!---
 * Class Timer
 *
 * Provides a simple way to measure the amount of time
 * that elapses between two points.
 *
 * Difference: the times are seconds with a millisecond resolution (see
 * microtime()), and an end that is not set yet is an empty string, as
 * there is no null.
--->
<cfcomponent output="no" hint="Class Timer">

	<!---
	 * List of all timers.
	 *
	 * A map (see array_()) of timer names to a map with the keys start,
	 * end and duration.
	--->
	<cfset this.timers = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Starts a timer running.
	 *
	 * Multiple calls can be made to this method so that several
	 * execution points can be measured.
	 *
	 * @param name The name of this timer.
	 * @param time Allows user to provide time.
	 *
	 * @return this
	--->
	<cffunction name="start" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="time" type="any" required="no" default="">

		<cfif is_null(arguments.time)>
			<cfset arguments.time = microtime(true)>
		</cfif>

		<cfset this.timers[LCase(arguments.name)] = array_("start", arguments.time, "end", "")>

		<cfreturn this>
	</cffunction>

	<!---
	 * Stops a running timer.
	 *
	 * If the timer is not stopped before the timers() method is called,
	 * it will be automatically stopped at that point.
	 *
	 * @param name The name of this timer.
	 *
	 * @return this
	--->
	<cffunction name="stop" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">

		<cfset arguments.name = LCase(arguments.name)>

		<cfif NOT array_key_exists(arguments.name, this.timers)>
			<cfthrow type="ColdIgniter.Exceptions.RuntimeException" message="Cannot stop timer: invalid name given.">
		</cfif>

		<cfset this.timers[arguments.name]["end"] = microtime(true)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Returns the duration of a recorded timer.
	 *
	 * @param name     The name of the timer.
	 * @param decimals Number of decimal places.
	 *
	 * @return The duration, or an empty string if there is no timer of that name
	--->
	<cffunction name="getElapsedTime" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="decimals" type="numeric" required="no" default="4">
		<cfset var timer = "">
		<cfset var end = "">

		<cfset arguments.name = LCase(arguments.name)>

		<cfif NOT array_key_exists(arguments.name, this.timers)>
			<cfreturn "">
		</cfif>

		<cfset timer = this.timers[arguments.name]>

		<cfset end = timer["end"]>
		<cfif is_null(end)>
			<cfset end = microtime(true)>
		</cfif>

		<cfreturn Val(number_format(end - timer["start"], arguments.decimals, ".", ""))>
	</cffunction>

	<!---
	 * Returns the array of timers, with the duration of each.
	 *
	 * @param decimals Number of decimal places
	 *
	 * @return A map of timer names to maps with the keys start, end and duration
	--->
	<cffunction name="getTimers" access="public" returntype="any" output="no">
		<cfargument name="decimals" type="numeric" required="no" default="4">
		<cfset var timers = CreateObject("java", "java.util.LinkedHashMap").init()>
		<cfset var name = "">
		<cfset var timer = "">
		<cfset var copy = "">
		<cfset var it = this.timers.keySet().iterator()>

		<!--- Difference: the timers are copied, as a map is not copied on assignment. --->
		<cfloop condition="it.hasNext()">
			<cfset name = it.next()>
			<cfset timer = this.timers[name]>
			<cfset copy = array_("start", timer["start"], "end", timer["end"])>
			<cfif is_null(copy["end"])>
				<cfset copy["end"] = microtime(true)>
			</cfif>
			<cfset copy["duration"] = Val(number_format(copy["end"] - copy["start"], arguments.decimals, ".", ""))>
			<cfset timers[name] = copy>
		</cfloop>

		<cfreturn timers>
	</cffunction>

	<!---
	 * Returns whether or not a timer has been started.
	 *
	 * @param name The name of the timer.
	--->
	<cffunction name="has" access="public" returntype="boolean" output="no">
		<cfargument name="name" type="string" required="yes">

		<cfreturn array_key_exists(LCase(arguments.name), this.timers)>
	</cffunction>

	<!---
	 * Not ported yet: record(name, callable), as a function is not a
	 * value that can be called on this platform.
	--->

</cfcomponent>
