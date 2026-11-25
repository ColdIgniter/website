<!---
 * Class View
 *
 * Not ported yet: layouts and sections, include, renderString, the
 * cache options, decorators and the file locator.
--->
<cfcomponent output="no" hint="Class View">

	<!---
	 * Saved Data.
	--->
	<cfset this.data = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Data for the variables that are available in the Views.
	 * An empty string until it is set.
	--->
	<cfset this.tempData = "">

	<!---
	 * The base directory to look in for our Views.
	--->
	<cfset this.viewPath = "">

	<!---
	 * Data for rendering including Caching and Debug Toolbar data.
	--->
	<cfset this.renderVars = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Instance of FileLocator for when
	 * we need to attempt to find a view
	 * that's not in standard place.
	--->
	<cfset this.loader = "">

	<!---
	 * Logger instance.
	--->
	<cfset this.logger = "">

	<!---
	 * Should we store performance info?
	--->
	<cfset this.debug = false>

	<!---
	 * Cache stats about our performance here,
	 * when CI_DEBUG = true
	 *
	 * A list of maps with the keys start, end and view.
	--->
	<cfset this.performanceData = ArrayNew(1)>

	<!---
	 * Whether data should be saved between renders.
	--->
	<cfset this.saveData = false>

	<cfset this.config = "">

	<!---
	 * The number of views rendered, for the comments of the debug toolbar.
	--->
	<cfset this.viewsCount = 0>

	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">
		<cfargument name="viewPath" type="string" required="no" default="">
		<cfargument name="loader" type="any" required="no" default="">
		<cfargument name="debug" type="any" required="no" default="">
		<cfargument name="logger" type="any" required="no" default="">

		<cfset this.config = arguments.config>
		<cfset this.viewPath = REReplace(arguments.viewPath, "[\\/ ]+$", "") & request.DIRECTORY_SEPARATOR>
		<!--- Not ported yet: service("locator") --->
		<cfset this.loader = arguments.loader>
		<cfif is_null(arguments.logger)>
			<cfset this.logger = service("logger")>
		<cfelse>
			<cfset this.logger = arguments.logger>
		</cfif>
		<cfif is_null(arguments.debug)>
			<cfset this.debug = request.CI_DEBUG>
		<cfelse>
			<cfset this.debug = arguments.debug>
		</cfif>
		<cfset this.saveData = arguments.config.saveData IS true>

		<cfreturn this>
	</cffunction>

	<!---
	 * Builds the output based upon a file name and any
	 * data that has already been set.
	 *
	 * Valid options:
	 *  - cache      Number of seconds to cache for
	 *  - cache_name Name to use for cache
	 *
	 * @param view     File name of the view source
	 * @param options  Reserved for 3rd-party uses since
	 *                 it might be needed to pass additional info
	 *                 to other template engines.
	 * @param saveData If true, will save data for use with any other calls,
	 *                 if false, will clean the data after displaying the view,
	 *                 if not given, use the config setting.
	--->
	<cffunction name="render" access="public" returntype="string" output="no">
		<cfargument name="view" type="string" required="yes">
		<cfargument name="options" type="any" required="no" default="">
		<cfargument name="saveData" type="any" required="no" default="">
		<cfset var fileExt = "">
		<cfset var output = "">
		<cfset var filters = "">
		<cfset var requiredAfterFilters = "">
		<cfset var requiredResult = "">
		<cfset var filtersClass = "">
		<cfset var debugBarEnabled = false>
		<cfset var debugOption = true>

		<cfset this.renderVars["start"] = microtime(true)>

		<!---
		 Store the results here so even if
		 multiple views are called in a view, it won't
		 clean it unless we mean it to.
		--->
		<cfif is_null(arguments.saveData)>
			<cfset arguments.saveData = this.saveData>
		</cfif>

		<cfif Find(".", ListLast(arguments.view, "\/")) GT 0>
			<cfset fileExt = ListLast(arguments.view, ".")>
		</cfif>
		<!--- allow Views as .html, .tpl, etc (from CI3) --->
		<cfif fileExt EQ "">
			<cfset this.renderVars["view"] = arguments.view & ".cfm">
		<cfelse>
			<cfset this.renderVars["view"] = arguments.view>
		</cfif>

		<cfif is_null(arguments.options)>
			<cfset this.renderVars["options"] = array_()>
		<cfelse>
			<cfset this.renderVars["options"] = arguments.options>
		</cfif>

		<!--- Not ported yet: Was it cached? --->

		<!--- Not ported yet: the overrides folder --->
		<cfset this.renderVars["file"] = this.viewPath & this.renderVars["view"]>

		<!---
		 Difference: a namespaced view (with a backslash) is found through the namespaces
		 of the autoloader, instead of service("locator").locateFile().
		--->
		<cfif Find("\", this.renderVars["view"]) GT 0>
			<cfset this.renderVars["file"] = locateNamespacedView(this.renderVars["view"])>
		</cfif>

		<!--- Not ported yet: the file locator --->
		<cfif NOT is_file(this.renderVars["file"])>
			<cfthrow type="ColdIgniter.View.Exceptions.ViewException" message="Invalid file: ""#this.renderVars["view"]#""">
		</cfif>

		<!--- Make our view data available to the view. --->
		<cfset prepareTemplateData(arguments.saveData)>

		<!---
		 The file is included in an object of its own, which is thrown
		 away after the render: an include inside a method copies the
		 variables of that method into the object.
		--->
		<cfset output = new_("ColdIgniter\View\Closure").call(this.renderVars["file"], this.tempData)>

		<!--- Not ported yet: layouts, decorators, cache --->

		<cfset logPerformance(this.renderVars["start"], microtime(true), this.renderVars["view"])>

		<!--- Check if DebugToolbar is enabled. --->
		<cfset filters = service("filters")>
		<cfset requiredResult = filters.getRequiredFilters("after")>
		<cfset requiredAfterFilters = requiredResult[1]>
		<cfif in_array("toolbar", requiredAfterFilters)>
			<cfset debugBarEnabled = true>
		<cfelse>
			<cfset filtersClass = filters.getFiltersClass()>
			<cfset debugBarEnabled = in_array("ColdIgniter\Filters\DebugToolbar", filtersClass["after"])>
		</cfif>

		<!---
		 Difference: the original compares with ===, so only the boolean true
		 counts, not 1 or "yes". A literal true is the text "true" on this
		 server, so that text counts as well as a Boolean object.
		--->
		<cfif NOT is_null(arguments.options) AND array_key_exists("debug", arguments.options)>
			<cfif IsSimpleValue(arguments.options["debug"])>
				<cfif Compare(arguments.options["debug"].getClass().getName(), "java.lang.Boolean") EQ 0>
					<cfset debugOption = arguments.options["debug"]>
				<cfelse>
					<cfset debugOption = Compare(arguments.options["debug"], "true") EQ 0>
				</cfif>
			<cfelse>
				<cfset debugOption = false>
			</cfif>
		</cfif>

		<cfif this.debug AND debugBarEnabled AND debugOption>
			<cfif in_array("ColdIgniter\Debug\Toolbar\Collectors\Views", config("Config\Toolbar").collectors)>
				<!--- Clean up our path names to make them a little cleaner --->
				<cfset this.renderVars["file"] = clean_path(this.renderVars["file"])>
				<cfset this.viewsCount = this.viewsCount + 1>
				<cfset this.renderVars["file"] = this.viewsCount & " " & this.renderVars["file"]>

				<cfset output = "<!-- DEBUG-VIEW START " & this.renderVars["file"] & " -->" & Chr(10) & output & Chr(10) & "<!-- DEBUG-VIEW ENDED " & this.renderVars["file"] & " -->" & Chr(10)>
			</cfif>
		</cfif>

		<cfset this.tempData = "">

		<cfreturn output>
	</cffunction>

	<!---
	 * Finds the file of a namespaced view, like
	 * "ColdIgniter\Validation\Views\list.cfm": the longest namespace of the
	 * autoloader that starts the name gives the folder, and the rest is the
	 * path below it.
	 *
	 * @return The full path of the file, or an empty string if there is none
	--->
	<cffunction name="locateNamespacedView" access="private" returntype="string" output="no">
		<cfargument name="view" type="string" required="yes">
		<cfset var prefixes = request.ColdIgniter.autoloader.prefixes>
		<cfset var best = "">
		<cfset var prefix = "">
		<cfset var file = "">
		<cfset var i = 0>

		<cfloop collection="#prefixes#" item="prefix">
			<cfif Len(prefix) GT Len(best) AND Left(arguments.view, Len(prefix) + 1) EQ prefix & "\">
				<cfset best = prefix>
			</cfif>
		</cfloop>

		<cfif best EQ "">
			<cfreturn "">
		</cfif>

		<cfloop from="1" to="#ArrayLen(prefixes[best])#" index="i">
			<cfset file = prefixes[best][i] & Replace(Mid(arguments.view, Len(best) + 2, Len(arguments.view)), "\", request.DIRECTORY_SEPARATOR, "all")>

			<cfif is_file(file)>
				<cfreturn file>
			</cfif>
		</cfloop>

		<cfreturn "">
	</cffunction>

	<!---
	 * Removes all of the view data from the system.
	--->
	<cffunction name="resetData" access="public" returntype="any" output="no">
		<cfset this.data = array_()>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets several pieces of view data at once.
	 *
	 * @param context The context to escape it for.
	 *                If 'raw', no escaping will happen.
	--->
	<cffunction name="setData" access="public" returntype="any" output="no">
		<cfargument name="data" type="any" required="no" default="">
		<cfargument name="context" type="string" required="no" default="">

		<cfif is_null(arguments.data)>
			<cfset arguments.data = array_()>
		</cfif>

		<!--- Not ported yet: esc(data, context) --->

		<cfif is_null(this.tempData)>
			<cfset this.tempData = this.data>
		</cfif>
		<cfset this.tempData = array_merge(this.tempData, arguments.data)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets a single piece of view data.
	 *
	 * @param value
	 * @param context The context to escape it for.
	 *                If 'raw', no escaping will happen.
	--->
	<cffunction name="setVar" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="value" type="any" required="no" default="">
		<cfargument name="context" type="string" required="no" default="">

		<!--- Not ported yet: esc(value, context) --->

		<cfif is_null(this.tempData)>
			<cfset this.tempData = array_merge(this.data)>
		</cfif>
		<cfset this.tempData[arguments.name] = arguments.value>

		<cfreturn this>
	</cffunction>

	<!---
	 * Returns the current data that will be displayed in the view.
	--->
	<cffunction name="getData" access="public" returntype="any" output="no">
		<cfif is_null(this.tempData)>
			<cfreturn this.data>
		</cfif>

		<cfreturn this.tempData>
	</cffunction>

	<!---
	 * Returns the performance data that might have been collected
	 * during the execution. Used primarily in the Debug Toolbar.
	 *
	 * @return A list of maps with the keys start, end and view
	--->
	<cffunction name="getPerformanceData" access="public" returntype="any" output="no">
		<cfreturn this.performanceData>
	</cffunction>

	<!---
	 * Logs performance data for rendering a view.
	--->
	<cffunction name="logPerformance" access="public" returntype="void" output="no">
		<cfargument name="start" type="numeric" required="yes">
		<cfargument name="end" type="numeric" required="yes">
		<cfargument name="view" type="string" required="yes">

		<cfif this.debug>
			<cfset ArrayAppend(this.performanceData, array_("start", arguments.start, "end", arguments.end, "view", arguments.view))>
		</cfif>
	</cffunction>

	<cffunction name="prepareTemplateData" access="private" returntype="void" output="no">
		<cfargument name="saveData" type="boolean" required="yes">

		<cfif is_null(this.tempData)>
			<cfset this.tempData = this.data>
		</cfif>

		<cfif arguments.saveData>
			<cfset this.data = this.tempData>
		</cfif>
	</cffunction>

</cfcomponent>
