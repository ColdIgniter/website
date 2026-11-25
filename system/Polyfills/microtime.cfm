<!---
 * Returns the current Unix timestamp with fractions, in seconds.
 *
 * Difference: only the form that gives a float (true) exists. The clock
 * of the platform counts whole milliseconds and on some systems moves in
 * steps of 15 or 16 of them, so the first call of a request reads that
 * clock once and every call adds the time passed since then, taken from
 * the high resolution counter of the virtual machine (sun.misc.Perf).
 * Where that counter does not exist, the millisecond clock is used.
--->
<cffunction name="microtime" returntype="numeric" output="no" hint="Returns the current Unix timestamp with fractions">
	<cfargument name="asFloat" type="any" required="no" default="true">
	<cfset var clock = "">

	<cfif NOT StructKeyExists(request, "CI_MICROTIME")>
		<cfset clock = StructNew()>
		<cfset clock.start = CreateObject("java", "java.lang.System").currentTimeMillis() / 1000>
		<cfset clock.frequency = 0>

		<cftry>
			<cfset clock.perf = CreateObject("java", "sun.misc.Perf").getPerf()>
			<cfset clock.counter = clock.perf.highResCounter()>
			<cfset clock.frequency = clock.perf.highResFrequency()>

			<cfcatch type="any">
				<cfset clock.frequency = 0>
			</cfcatch>
		</cftry>

		<cfset request.CI_MICROTIME = clock>
	</cfif>

	<cfset clock = request.CI_MICROTIME>

	<cfif clock.frequency GT 0>
		<cfreturn clock.start + (clock.perf.highResCounter() - clock.counter) / clock.frequency>
	</cfif>

	<cfreturn CreateObject("java", "java.lang.System").currentTimeMillis() / 1000>
</cffunction>
