<!---
 * Legacy Time class, the mutable version.
 *
 * Difference: the original extends DateTime, so modify, add, sub, setTime
 * and setDate change the object (setTimestamp gives a new one). Here it
 * extends Time and target_ gives the object itself in place of a copy, which
 * has the same effect for those functions. The functions of the trait that
 * clone first (addDays and so on) still give a new object, as in the original.
--->
<cfcomponent output="no" extends="Time" hint="Legacy Time class, the mutable version">

	<!---
	 * The class that is created by the functions of the trait.
	--->
	<cffunction name="className_" access="private" returntype="string" output="no">
		<cfreturn "ColdIgniter\I18n\TimeLegacy">
	</cffunction>

	<!---
	 * The object that a function like modify changes: this one.
	--->
	<cffunction name="target_" access="private" returntype="any" output="no">
		<cfreturn this>
	</cffunction>

	<!---
	 * Returns a new object for a number of seconds: the wall clock of the
	 * timestamp in the default timezone is read again in the timezone of
	 * the object (the original goes through date() and parse() the same way),
	 * so the microseconds are 0.
	 *
	 * @param int $timestamp
	 *
	 * @return static
	--->
	<cffunction name="setTimestamp" access="public" returntype="any" output="no">
		<cfargument name="timestamp" type="numeric" required="yes">
		<cfset var wall = build_(dateOf_(arguments.timestamp), tzOf_(""), this.locale, 0)>

		<cfreturn parse(wall.format("Y-m-d H:i:s"), this.timezone, this.locale)>
	</cffunction>

</cfcomponent>
