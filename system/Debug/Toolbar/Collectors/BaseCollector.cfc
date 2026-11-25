<!---
 * Base Toolbar collector
 *
 * Difference: an array of the original is a list (ArrayNew(1)) or a map
 * (see array_()), and a null is an empty string. A true or false that has
 * to stay one in the JSON of the toolbar is made with JavaCast("boolean").
--->
<cfcomponent output="no" hint="Base Toolbar collector">

	<!---
	 * Whether this collector has data that can
	 * be displayed in the Timeline.
	--->
	<cfset this.hasTimeline = false>

	<!---
	 * Whether this collector needs to display
	 * content in a tab or not.
	--->
	<cfset this.hasTabContent = false>

	<!---
	 * Whether this collector needs to display
	 * a label or not.
	--->
	<cfset this.hasLabel = false>

	<!---
	 * Whether this collector has data that
	 * should be shown in the Vars tab.
	--->
	<cfset this.hasVarData = false>

	<!---
	 * The 'title' of this Collector.
	 * Used to name things in the toolbar HTML.
	--->
	<cfset this.title = "">

	<!---
	 * Gets the Collector's title.
	--->
	<cffunction name="getTitle" access="public" returntype="string" output="no">
		<cfargument name="safe" type="boolean" required="no" default="false">

		<cfif arguments.safe>
			<cfreturn Replace(LCase(this.title), " ", "-", "all")>
		</cfif>

		<cfreturn this.title>
	</cffunction>

	<!---
	 * Returns any information that should be shown next to the title.
	--->
	<cffunction name="getTitleDetails" access="public" returntype="string" output="no">
		<cfreturn "">
	</cffunction>

	<!---
	 * Does this collector need it's own tab?
	--->
	<cffunction name="hasTabContent_" access="public" returntype="boolean" output="no">
		<cfreturn this.hasTabContent IS true>
	</cffunction>

	<!---
	 * Does this collector have a label?
	--->
	<cffunction name="hasLabel_" access="public" returntype="boolean" output="no">
		<cfreturn this.hasLabel IS true>
	</cffunction>

	<!---
	 * Does this collector have information for the timeline?
	--->
	<cffunction name="hasTimelineData" access="public" returntype="boolean" output="no">
		<cfreturn this.hasTimeline IS true>
	</cffunction>

	<!---
	 * Grabs the data for the timeline, properly formatted,
	 * or returns an empty array.
	 *
	 * @return A list of maps
	--->
	<cffunction name="timelineData" access="public" returntype="any" output="no">
		<cfif NOT this.hasTimeline>
			<cfreturn ArrayNew(1)>
		</cfif>

		<cfreturn formatTimelineData()>
	</cffunction>

	<!---
	 * Does this Collector have data that should be shown in the
	 * 'Vars' tab?
	--->
	<cffunction name="hasVarData_" access="public" returntype="boolean" output="no">
		<cfreturn this.hasVarData IS true>
	</cffunction>

	<!---
	 * Gets a collection of data that should be shown in the 'Vars' tab.
	 * The format is a map of sections, each with their own map
	 * of key/value pairs:
	 *
	 *  array_(
	 *      "section 1", array_("foo", "bar", "bar", "baz"),
	 *      "section 2", array_("foo", "bar", "bar", "baz")
	 *  )
	 *
	 * @return A map, or an empty string
	--->
	<cffunction name="getVarData" access="public" returntype="any" output="no">
		<cfreturn "">
	</cffunction>

	<!---
	 * Child classes should implement this to return the timeline data
	 * formatted for correct usage.
	 *
	 * Timeline data should be formatted into maps that look like:
	 *
	 *  array_(
	 *      "name",      "Database::Query",
	 *      "component", "Database",
	 *      "start",     10,      // seconds
	 *      "duration",  15       // seconds
	 *  )
	 *
	 * @return A list of maps
	--->
	<cffunction name="formatTimelineData" access="private" returntype="any" output="no">
		<cfreturn ArrayNew(1)>
	</cffunction>

	<!---
	 * Returns the data of this collector to be formatted in the toolbar
	 *
	 * @return A map, or a string
	--->
	<cffunction name="display" access="public" returntype="any" output="no">
		<cfreturn ArrayNew(1)>
	</cffunction>

	<!---
	 * This makes nicer looking paths for the error output.
	 *
	 * @deprecated Use the dedicated `clean_path()` function.
	--->
	<cffunction name="cleanPath" access="public" returntype="string" output="no">
		<cfargument name="file" type="string" required="yes">

		<cfreturn clean_path(arguments.file)>
	</cffunction>

	<!---
	 * Gets the "badge" value for the button.
	 *
	 * @return A number, or an empty string
	--->
	<cffunction name="getBadgeValue" access="public" returntype="any" output="no">
		<cfreturn "">
	</cffunction>

	<!---
	 * Does this collector have any data collected?
	 *
	 * If not, then the toolbar button won't get shown.
	--->
	<cffunction name="isEmpty" access="public" returntype="boolean" output="no">
		<cfreturn false>
	</cffunction>

	<!---
	 * Returns the HTML to display the icon. Should either
	 * be SVG, or a base-64 encoded.
	 *
	 * Recommended dimensions are 24px x 24px
	--->
	<cffunction name="icon" access="public" returntype="string" output="no">
		<cfreturn "">
	</cffunction>

	<!---
	 * Return settings as a map.
	 *
	 * Difference: hasTabContent, hasLabel and hasVarData are properties and
	 * methods with the same name in the original. A property and a method
	 * cannot share a name here, so the methods have a trailing underscore.
	--->
	<cffunction name="getAsArray" access="public" returntype="any" output="no">
		<cfreturn array_(
			"title", getTitle(),
			"titleSafe", getTitle(true),
			"titleDetails", getTitleDetails(),
			"display", display(),
			"badgeValue", getBadgeValue(),
			"isEmpty", JavaCast("boolean", isEmpty()),
			"hasTabContent", JavaCast("boolean", hasTabContent_()),
			"hasLabel", JavaCast("boolean", hasLabel_()),
			"icon", icon(),
			"hasTimelineData", JavaCast("boolean", hasTimelineData()),
			"timelineData", timelineData()
		)>
	</cffunction>

</cfcomponent>
