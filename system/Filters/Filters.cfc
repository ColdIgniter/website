<!---
 * Filters
 *
 * The lists of filters (before and after) are lists of strings: an alias,
 * or an alias with its arguments ("alias:arg1,arg2"). The lists of classes
 * are lists of two: the class and the list of arguments (empty when there
 * are none, and then the filter is given an empty string).
 *
 * The config (see Config\Filters) holds maps (array_()) and lists.
 *
 * There are no interfaces here. The check that a filter class implements
 * FilterInterface and the check of a value for ResponseInterface and
 * RequestInterface are done with instanceof_(), by the short name of the
 * class. A filter written in the application names ColdIgniter\Filters\FilterInterface
 * as its parent.
 *
 * Not ported yet: the discovery of Config/Filters in the modules (needs the
 * locator), the toolbar (the filter is not ported, so the code that moves
 * it to the last position is only kept), and Feature oldFilterOrder (the
 * new order is always used).
--->
<cfcomponent output="no" hint="Filters">

	<!---
	 * The Config\Filters instance
	--->
	<cfset this.config = "">

	<!---
	 * The active IncomingRequest or CLIRequest
	--->
	<cfset this.request_ = "">

	<!---
	 * The active Response instance
	--->
	<cfset this.response = "">

	<!---
	 * The Config\Modules instance
	--->
	<cfset this.modules = "">

	<!---
	 * Whether we've done initial processing on the filter lists.
	--->
	<cfset this.initialized = false>

	<!---
	 * The filter list to execute for the current request (URI path).
	 *
	 * This property is for display. Use filtersClass to execute filters.
	 * This does not include "Required Filters".
	 *
	 * A map with the keys before and after, each a list of strings:
	 *
	 * [
	 *     'before' => [
	 *         'alias',
	 *         'alias:arg1',
	 *         'alias:arg1,arg2',
	 *     ],
	 *     'after'  => [
	 *         'alias',
	 *         'alias:arg1',
	 *         'alias:arg1,arg2',
	 *     ],
	 * ]
	--->
	<cfset this.filters = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.filters["before"] = ArrayNew(1)>
	<cfset this.filters["after"] = ArrayNew(1)>

	<!---
	 * The collection of filter classnames and their arguments to execute for
	 * the current request (URI path).
	 *
	 * This does not include "Required Filters".
	 *
	 * A map with the keys before and after, each a list of lists of two,
	 * the classname and its arguments:
	 *
	 * [
	 *     'before' => [
	 *         [classname, arguments],
	 *     ],
	 *     'after'  => [
	 *         [classname, arguments],
	 *     ],
	 * ]
	--->
	<cfset this.filtersClass = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.filtersClass["before"] = ArrayNew(1)>
	<cfset this.filtersClass["after"] = ArrayNew(1)>

	<!---
	 * List of filter class instances, a map of the class name to the filter
	 * [classname => instance].
	--->
	<cfset this.filterClassInstances = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Any arguments to be passed to filters.
	 *
	 * A map [name => params]. Deprecated upstream (4.6.0), no longer used.
	--->
	<cfset this.arguments_ = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Any arguments to be passed to filtersClass.
	 *
	 * A map [classname => arguments]. Deprecated upstream (4.6.0), no longer used.
	--->
	<cfset this.argumentsClass = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * @param config   The Config\Filters
	 * @param request_ The request
	 * @param response The response
	 * @param modules  An empty string, or the Config\Modules
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="response" type="any" required="yes">
		<cfargument name="modules" type="any" required="no" default="">

		<cfset this.config = arguments.config>
		<cfset this.request_ = arguments.request_>
		<cfset setResponse(arguments.response)>

		<cfif IsObject(arguments.modules)>
			<cfset this.modules = arguments.modules>
		<cfelse>
			<cfset this.modules = new_("Config\Modules")>
		</cfif>

		<!--- Not ported yet: discoverFilters(), when modules.shouldDiscover("filters"). --->

		<cfreturn this>
	</cffunction>

	<!---
	 * Set the response explicitly.
	--->
	<cffunction name="setResponse" access="public" returntype="void" output="no">
		<cfargument name="response" type="any" required="yes">

		<cfset this.response = arguments.response>
	</cffunction>

	<!---
	 * Runs through all of the filters for the specified
	 * uri and position.
	 *
	 * @param uri      URI path relative to baseURL (word 'before' or 'after')
	 * @param position "before" or "after"
	 *
	 * @return The request (or one a filter returned), a response, or a string
	 *         for "before"; the response for "after".
	--->
	<cffunction name="run" access="public" returntype="any" output="no">
		<cfargument name="uri" type="string" required="yes">
		<cfargument name="position" type="string" required="no" default="before">

		<cfset initialize_(LCase(arguments.uri))>

		<cfif Compare(arguments.position, "before") EQ 0>
			<cfreturn runBefore(this.filtersClass[arguments.position])>
		</cfif>

		<!--- After --->
		<cfreturn runAfter(this.filtersClass[arguments.position])>
	</cffunction>

	<!---
	 * Runs "before" filters.
	 *
	 * @param filterClassList A list of lists of the class and its arguments
	--->
	<cffunction name="runBefore" access="private" returntype="any" output="no">
		<cfargument name="filterClassList" type="array" required="yes">
		<cfset var filterClassInfo = "">
		<cfset var instance = "">
		<cfset var filterArguments = "">
		<cfset var result = "">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(arguments.filterClassList)#" index="i">
			<cfset filterClassInfo = arguments.filterClassList[i]>
			<cfset filterArguments = "">
			<cfif ArrayLen(filterClassInfo[2]) GT 0>
				<cfset filterArguments = filterClassInfo[2]>
			</cfif>

			<cfset instance = createFilter(filterClassInfo[1])>

			<cfset result = instance.before(this.request_, filterArguments)>
			<cfif NOT IsDefined("result")>
				<cfset result = "">
			</cfif>

			<cfif instanceof_(result, "ColdIgniter\HTTP\RequestInterface")>
				<cfset this.request_ = result>
			<cfelseif instanceof_(result, "ColdIgniter\HTTP\ResponseInterface")>
				<!--- short circuit - bypass any other filters --->
				<cfreturn result>
			<cfelseif IsSimpleValue(result) AND Len(result) GT 0 AND NOT IsBoolean(result)>
				<!---
				 An empty result is ignored.
				 Difference: a value that is boolean-like is ignored too (true, false,
				 yes, no in any case, and any number, also a java.lang.Boolean). The
				 original stops only for a string, and a boolean is not one there, but
				 here the literal false is the string "false" and cannot be told apart
				 from it. A filter that returns false must not stop the chain with
				 the controller still running.
				--->
				<cfreturn result>
			</cfif>
		</cfloop>

		<cfreturn this.request_>
	</cffunction>

	<!---
	 * Runs "after" filters.
	 *
	 * @param filterClassList A list of lists of the class and its arguments
	 *
	 * @return The response
	--->
	<cffunction name="runAfter" access="private" returntype="any" output="no">
		<cfargument name="filterClassList" type="array" required="yes">
		<cfset var filterClassInfo = "">
		<cfset var instance = "">
		<cfset var filterArguments = "">
		<cfset var result = "">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(arguments.filterClassList)#" index="i">
			<cfset filterClassInfo = arguments.filterClassList[i]>
			<cfset filterArguments = "">
			<cfif ArrayLen(filterClassInfo[2]) GT 0>
				<cfset filterArguments = filterClassInfo[2]>
			</cfif>

			<cfset instance = createFilter(filterClassInfo[1])>

			<cfset result = instance.after(this.request_, this.response, filterArguments)>
			<cfif NOT IsDefined("result")>
				<cfset result = "">
			</cfif>

			<cfif instanceof_(result, "ColdIgniter\HTTP\ResponseInterface")>
				<cfset this.response = result>
			</cfif>
		</cfloop>

		<cfreturn this.response>
	</cffunction>

	<!---
	 * Returns the filter instance, one per class for the request.
	--->
	<cffunction name="createFilter" access="private" returntype="any" output="no">
		<cfargument name="className" type="string" required="yes">
		<cfset var instance = "">

		<cfif StructKeyExists(this.filterClassInstances, arguments.className)>
			<cfreturn this.filterClassInstances[arguments.className]>
		</cfif>

		<cfset instance = new_(arguments.className)>

		<cfif NOT instanceof_(instance, "ColdIgniter\Filters\FilterInterface")>
			<cfset static_("ColdIgniter\Filters\Exceptions\FilterException").forIncorrectInterface(arguments.className)>
		</cfif>

		<cfset this.filterClassInstances[arguments.className] = instance>

		<cfreturn instance>
	</cffunction>

	<!---
	 * Returns the filter classes of the required filters: a list of lists
	 * of the class and an empty list of arguments.
	--->
	<cffunction name="getRequiredClasses" access="public" returntype="array" output="no">
		<cfargument name="position" type="string" required="yes">
		<cfset var req = getRequiredFilters(arguments.position)>
		<cfset var requiredFilters = req[1]>
		<cfset var aliases = req[2]>
		<cfset var filterClassList = ArrayNew(1)>
		<cfset var pair = "">
		<cfset var i = 0>
		<cfset var j = 0>

		<cfif ArrayLen(requiredFilters) EQ 0>
			<cfreturn ArrayNew(1)>
		</cfif>

		<cfloop from="1" to="#ArrayLen(requiredFilters)#" index="i">
			<cfif IsArray(aliases[requiredFilters[i]])>
				<cfloop from="1" to="#ArrayLen(this.config.aliases[requiredFilters[i]])#" index="j">
					<cfset pair = ArrayNew(1)>
					<cfset ArrayAppend(pair, this.config.aliases[requiredFilters[i]][j])>
					<cfset ArrayAppend(pair, ArrayNew(1))>
					<cfset ArrayAppend(filterClassList, pair)>
				</cfloop>
			<cfelse>
				<cfset pair = ArrayNew(1)>
				<cfset ArrayAppend(pair, aliases[requiredFilters[i]])>
				<cfset ArrayAppend(pair, ArrayNew(1))>
				<cfset ArrayAppend(filterClassList, pair)>
			</cfif>
		</cfloop>

		<cfreturn filterClassList>
	</cffunction>

	<!---
	 * Runs required filters for the position.
	 *
	 * @param position "before" or "after"
	--->
	<cffunction name="runRequired" access="public" returntype="any" output="no">
		<cfargument name="position" type="string" required="no" default="before">
		<cfset var filterClassList = getRequiredClasses(arguments.position)>

		<cfif ArrayLen(filterClassList) EQ 0>
			<cfif Compare(arguments.position, "before") EQ 0>
				<cfreturn this.request_>
			</cfif>

			<cfreturn this.response>
		</cfif>

		<cfif Compare(arguments.position, "before") EQ 0>
			<cfreturn runBefore(filterClassList)>
		</cfif>

		<!--- After --->
		<cfreturn runAfter(filterClassList)>
	</cffunction>

	<!---
	 * Returns the required filters for the position, and the aliases:
	 * a list of two, the list of the required filters and the aliases.
	--->
	<cffunction name="getRequiredFilters" access="public" returntype="array" output="no">
		<cfargument name="position" type="string" required="no" default="before">
		<cfset var baseConfig = "">
		<cfset var requiredFilters = ArrayNew(1)>
		<cfset var aliases = "">
		<cfset var result = ArrayNew(1)>
		<cfset var i = 0>

		<!--- For backward compatibility. For users who do not update Config\Filters. --->
		<cfif NOT StructKeyExists(this.config.required, arguments.position)>
			<cfset baseConfig = new_("ColdIgniter\Config\Filters")>
			<cfset requiredFilters = baseConfig.required[arguments.position]>
			<cfset aliases = baseConfig.aliases>
		<cfelse>
			<cfset requiredFilters = this.config.required[arguments.position]>
			<cfset aliases = this.config.aliases>
		</cfif>

		<cfif ArrayLen(requiredFilters) EQ 0>
			<cfset ArrayAppend(result, ArrayNew(1))>
			<cfset ArrayAppend(result, aliases)>

			<cfreturn result>
		</cfif>

		<cfif Compare(arguments.position, "after") EQ 0>
			<cfif in_array("toolbar", this.filters["after"])>
				<!--- It was already run in globals filters. So remove it. --->
				<cfset requiredFilters = setToolbarToLast(requiredFilters, true)>
			<cfelse>
				<!--- Set the toolbar filter to the last position to be executed --->
				<cfset requiredFilters = setToolbarToLast(requiredFilters)>
			</cfif>
		</cfif>

		<cfloop from="1" to="#ArrayLen(requiredFilters)#" index="i">
			<cfif NOT array_key_exists(requiredFilters[i], aliases)>
				<cfset static_("ColdIgniter\Filters\Exceptions\FilterException").forNoAlias(requiredFilters[i])>
			</cfif>
		</cfloop>

		<cfset ArrayAppend(result, requiredFilters)>
		<cfset ArrayAppend(result, aliases)>

		<cfreturn result>
	</cffunction>

	<!---
	 * Set the toolbar filter to the last position to be executed.
	 *
	 * @param filters A list of aliases
	 * @param remove  If true, remove the toolbar filter
	--->
	<cffunction name="setToolbarToLast" access="private" returntype="array" output="no">
		<cfargument name="filters" type="array" required="yes">
		<cfargument name="remove" type="boolean" required="no" default="false">
		<cfset var afters = ArrayNew(1)>
		<cfset var found = false>
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(arguments.filters)#" index="i">
			<cfif Compare(arguments.filters[i], "toolbar") EQ 0>
				<cfset found = true>
			<cfelse>
				<cfset ArrayAppend(afters, arguments.filters[i])>
			</cfif>
		</cfloop>

		<cfif found AND NOT arguments.remove>
			<cfset ArrayAppend(afters, "toolbar")>
		</cfif>

		<cfreturn afters>
	</cffunction>

	<!---
	 * Ensures that specific filters are on and enabled for the current request.
	 *
	 * Filters can have "arguments" in the form of "filter:arg1,arg2".
	 *
	 * @param uri The URI path relative to the baseURL
	 *
	 * @return this
	--->
	<cffunction name="initialize_" access="public" returntype="any" output="no">
		<cfargument name="uri" type="string" required="no" default="">

		<cfif this.initialized>
			<cfreturn this>
		</cfif>

		<!---
		 Decode URL-encoded string.
		 Difference: URLDecode() throws for a percent sign that is not followed
		 by two hexadecimal digits, and urldecode() of the original keeps
		 such a sign, so parse_str_decode() is used (see parse_str.cfm).
		--->
		<cfset arguments.uri = parse_str_decode(arguments.uri)>

		<!--- Not ported yet: Feature oldFilterOrder, the new order is always used. --->
		<cfset processFilters(arguments.uri)>
		<cfset processMethods()>
		<cfset processGlobals(arguments.uri)>

		<!--- Set the toolbar filter to the last position to be executed --->
		<cfset this.filters["after"] = setToolbarToLast(this.filters["after"])>

		<!---
		 Since some filters like rate limiters rely on being executed once a request,
		 we filter em here.
		--->
		<cfset this.filters["before"] = array_unique(this.filters["before"])>
		<cfset this.filters["after"] = array_unique(this.filters["after"])>

		<cfset processAliasesToClass("before")>
		<cfset processAliasesToClass("after")>

		<cfset this.initialized = true>

		<cfreturn this>
	</cffunction>

	<!---
	 * Restores instance to its original state to
	 * make that instance reusable for another request.
	--->
	<cffunction name="reset" access="public" returntype="any" output="no">
		<cfset this.initialized = false>

		<cfset this.arguments_ = CreateObject("java", "java.util.LinkedHashMap").init()>
		<cfset this.argumentsClass = CreateObject("java", "java.util.LinkedHashMap").init()>

		<cfset this.filters = CreateObject("java", "java.util.LinkedHashMap").init()>
		<cfset this.filters["before"] = ArrayNew(1)>
		<cfset this.filters["after"] = ArrayNew(1)>

		<cfset this.filtersClass = CreateObject("java", "java.util.LinkedHashMap").init()>
		<cfset this.filtersClass["before"] = ArrayNew(1)>
		<cfset this.filtersClass["after"] = ArrayNew(1)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Returns the processed filters array.
	--->
	<cffunction name="getFilters" access="public" returntype="any" output="no">
		<cfreturn this.filters>
	</cffunction>

	<!---
	 * Returns the filtersClass array.
	--->
	<cffunction name="getFiltersClass" access="public" returntype="any" output="no">
		<cfreturn this.filtersClass>
	</cffunction>

	<!---
	 * Adds a new alias to the config.
	 *
	 * @param class    The class name
	 * @param alias    An alias, or an empty string to use a hash of the class
	 * @param position "before" or "after"
	 * @param section  "globals", "methods" or "filters" of the config
	 *
	 * @return this
	 *
	 * Not ported yet: sections other than "globals" (the entry of a section
	 * that is a map of lists).
	--->
	<cffunction name="addFilter" access="public" returntype="any" output="no">
		<cfargument name="class" type="string" required="yes">
		<cfargument name="alias" type="string" required="no" default="">
		<cfargument name="position" type="string" required="no" default="before">
		<cfargument name="section" type="string" required="no" default="globals">
		<cfset var sectionMap = this.config[arguments.section]>

		<cfif is_null(arguments.alias)>
			<cfset arguments.alias = LCase(Hash(arguments.class))>
		</cfif>

		<cfif NOT StructKeyExists(sectionMap, arguments.position)>
			<cfset sectionMap[arguments.position] = ArrayNew(1)>
		</cfif>

		<cfset this.config.aliases[arguments.alias] = arguments.class>
		<cfset ArrayAppend(sectionMap[arguments.position], arguments.alias)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Ensures that a specific filter is on and enabled for the current request.
	 *
	 * Filters can have "arguments" in the form of "filter:arg1,arg2".
	--->
	<cffunction name="enableFilter" access="private" returntype="void" output="no">
		<cfargument name="filter" type="string" required="yes">
		<cfargument name="position" type="string" required="no" default="before">
		<cfset var clean = ArrayNew(1)>
		<cfset var alias = "">
		<cfset var filterArguments = ArrayNew(1)>

		<!--- Normalize the arguments. --->
		<cfset clean = getCleanName(arguments.filter)>
		<cfset alias = clean[1]>
		<cfset filterArguments = clean[2]>

		<cfif ArrayLen(filterArguments) EQ 0>
			<cfset arguments.filter = alias>
		<cfelse>
			<cfset arguments.filter = alias & ":" & implode(",", filterArguments)>
		</cfif>

		<cfif class_exists(alias)>
			<cfset this.config.aliases[alias] = alias>
		<cfelseif NOT array_key_exists(alias, this.config.aliases)>
			<cfset static_("ColdIgniter\Filters\Exceptions\FilterException").forNoAlias(alias)>
		</cfif>

		<cfset ArrayAppend(this.filters[arguments.position], arguments.filter)>

		<!---
		 Since some filters like rate limiters rely on being executed once a request,
		 we filter em here.
		--->
		<cfset this.filters[arguments.position] = array_unique(this.filters[arguments.position])>
	</cffunction>

	<!---
	 * Get the alias and the arguments of a filter name.
	 *
	 * @return A list of two: the alias and the list of arguments.
	--->
	<cffunction name="getCleanName" access="private" returntype="array" output="no">
		<cfargument name="filter" type="string" required="yes">
		<cfset var result = ArrayNew(1)>
		<cfset var parts = ArrayNew(1)>
		<cfset var filterArguments = ArrayNew(1)>
		<cfset var i = 0>

		<cfif NOT Find(":", arguments.filter)>
			<cfset ArrayAppend(result, arguments.filter)>
			<cfset ArrayAppend(result, filterArguments)>

			<cfreturn result>
		</cfif>

		<cfset parts = explode(":", arguments.filter)>
		<cfset filterArguments = explode(",", parts[2])>

		<cfloop from="1" to="#ArrayLen(filterArguments)#" index="i">
			<cfset filterArguments[i] = Trim(filterArguments[i])>
		</cfloop>

		<cfset ArrayAppend(result, parts[1])>
		<cfset ArrayAppend(result, filterArguments)>

		<cfreturn result>
	</cffunction>

	<!---
	 * Ensures that specific filters are on and enabled for the current request.
	 *
	 * Filters can have "arguments" in the form of "filter:arg1,arg2".
	 *
	 * @param filters A list of filter names
	 * @param when    "before" or "after"
	 *
	 * @return this
	--->
	<cffunction name="enableFilters" access="public" returntype="any" output="no">
		<cfargument name="filters" type="array" required="yes">
		<cfargument name="when" type="string" required="no" default="before">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(arguments.filters)#" index="i">
			<cfset enableFilter(arguments.filters[i], arguments.when)>
		</cfloop>

		<cfreturn this>
	</cffunction>

	<!---
	 * Returns the arguments for a specified key, or all.
	--->
	<cffunction name="getArguments" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="no" default="">

		<cfif is_null(arguments.key)>
			<cfreturn this.arguments_>
		</cfif>

		<cfreturn this.arguments_[arguments.key]>
	</cffunction>

	<!---
	 * --------------------------------------------------------------------
	 * Processors
	 * --------------------------------------------------------------------
	--->

	<!---
	 * Add any applicable (not excluded) global filter settings to the mix.
	 *
	 * @param uri The URI path relative to the baseURL
	--->
	<cffunction name="processGlobals" access="private" returntype="void" output="no">
		<cfargument name="uri" type="string" required="no" default="">
		<cfset var sets = ArrayNew(1)>
		<cfset var found = array_("before", ArrayNew(1), "after", ArrayNew(1))>
		<cfset var set = "">
		<cfset var entries = "">
		<cfset var alias = "">
		<cfset var rules = "">
		<cfset var keep = true>
		<cfset var i = 0>
		<cfset var s = 0>

		<cfset arguments.uri = LCase(trim_(arguments.uri, "/ "))>

		<!--- Add any global filters, unless they are excluded for this URI --->
		<cfset ArrayAppend(sets, "before")>
		<cfset ArrayAppend(sets, "after")>

		<cfloop from="1" to="#ArrayLen(sets)#" index="s">
			<cfset set = sets[s]>

			<cfif StructKeyExists(this.config.globals, set)>
				<cfset entries = this.config.globals[set]>

				<cfif IsArray(entries)>
					<!--- a list of aliases --->
					<cfloop from="1" to="#ArrayLen(entries)#" index="i">
						<cfset ArrayAppend(found[set], entries[i])>
					</cfloop>
				<cfelse>
					<!--- look at each alias in the group --->
					<cfloop collection="#entries#" item="alias">
						<cfset rules = entries[alias]>
						<cfset keep = true>

						<cfif IsStruct(rules)>
							<!--- see if it should be excluded --->
							<cfif StructKeyExists(rules, "except")>
								<!--- grab the exclusion rules --->
								<cfif checkExcept(arguments.uri, rules["except"])>
									<cfset keep = false>
								</cfif>
							</cfif>
						<cfelse>
							<!--- simple name of filter to apply --->
							<cfset alias = rules>
						</cfif>

						<cfif keep>
							<cfset ArrayAppend(found[set], alias)>
						</cfif>
					</cfloop>
				</cfif>
			</cfif>
		</cfloop>

		<!--- Not ported yet: Feature oldFilterOrder, the new order is always used. --->
		<cfif ArrayLen(found["before"]) GT 0>
			<cfset this.filters["before"] = array_merge(found["before"], this.filters["before"])>
		</cfif>

		<cfif ArrayLen(found["after"]) GT 0>
			<cfset this.filters["after"] = array_merge(this.filters["after"], found["after"])>
		</cfif>
	</cffunction>

	<!---
	 * Add any method-specific filters to the mix.
	--->
	<cffunction name="processMethods" access="private" returntype="void" output="no">
		<cfset var method = this.request_.getMethod()>

		<!--- Not ported yet: the lowercase HTTP method keys, deprecated in the original. --->
		<cfif StructKeyExists(this.config.methods, method)>
			<cfset this.filters["before"] = array_merge(this.config.methods[method], this.filters["before"])>
		</cfif>
	</cffunction>

	<!---
	 * Add any applicable configured filters to the mix.
	 *
	 * @param uri The URI path relative to the baseURL
	--->
	<cffunction name="processFilters" access="private" returntype="void" output="no">
		<cfargument name="uri" type="string" required="no" default="">
		<cfset var found = array_("before", ArrayNew(1), "after", ArrayNew(1))>
		<cfset var filter = "">
		<cfset var settings = "">
		<cfset var clean = ArrayNew(1)>
		<cfset var alias = "">
		<cfset var filterArguments = ArrayNew(1)>
		<cfset var name = "">

		<cfif StructCount(this.config.filters) EQ 0>
			<cfreturn>
		</cfif>

		<cfset arguments.uri = LCase(trim_(arguments.uri, "/ "))>

		<!--- Add any filters that apply to this URI --->
		<cfloop collection="#this.config.filters#" item="name">
			<cfset settings = this.config.filters[name]>

			<!--- Normalize the arguments. --->
			<cfset clean = getCleanName(name)>
			<cfset alias = clean[1]>
			<cfset filterArguments = clean[2]>

			<cfif ArrayLen(filterArguments) EQ 0>
				<cfset filter = alias>
			<cfelse>
				<cfset filter = alias & ":" & implode(",", filterArguments)>
			</cfif>

			<!--- Look for inclusion rules --->
			<cfif StructKeyExists(settings, "before")>
				<cfif pathApplies(arguments.uri, settings["before"])>
					<cfset ArrayAppend(found["before"], filter)>
				</cfif>
			</cfif>

			<cfif StructKeyExists(settings, "after")>
				<cfif pathApplies(arguments.uri, settings["after"])>
					<cfset ArrayAppend(found["after"], filter)>
				</cfif>
			</cfif>
		</cfloop>

		<!--- Not ported yet: Feature oldFilterOrder, the new order is always used. --->
		<cfif ArrayLen(found["before"]) GT 0>
			<cfset this.filters["before"] = array_merge(found["before"], this.filters["before"])>
		</cfif>

		<cfif ArrayLen(found["after"]) GT 0>
			<cfset found["after"] = array_reverse(found["after"])>
			<cfset this.filters["after"] = array_merge(this.filters["after"], found["after"])>
		</cfif>
	</cffunction>

	<!---
	 * Maps filter aliases to the full filter class names.
	 *
	 * @param position "before" or "after"
	--->
	<cffunction name="processAliasesToClass" access="private" returntype="void" output="no">
		<cfargument name="position" type="string" required="yes">
		<cfset var filterClassList = ArrayNew(1)>
		<cfset var clean = ArrayNew(1)>
		<cfset var alias = "">
		<cfset var filterArguments = ArrayNew(1)>
		<cfset var pair = "">
		<cfset var i = 0>
		<cfset var j = 0>

		<cfloop from="1" to="#ArrayLen(this.filters[arguments.position])#" index="i">
			<!--- Get arguments and clean alias --->
			<cfset clean = getCleanName(this.filters[arguments.position][i])>
			<cfset alias = clean[1]>
			<cfset filterArguments = clean[2]>

			<cfif NOT array_key_exists(alias, this.config.aliases)>
				<cfset static_("ColdIgniter\Filters\Exceptions\FilterException").forNoAlias(alias)>
			</cfif>

			<cfif IsArray(this.config.aliases[alias])>
				<cfloop from="1" to="#ArrayLen(this.config.aliases[alias])#" index="j">
					<cfset pair = ArrayNew(1)>
					<cfset ArrayAppend(pair, this.config.aliases[alias][j])>
					<cfset ArrayAppend(pair, filterArguments)>
					<cfset ArrayAppend(filterClassList, pair)>
				</cfloop>
			<cfelse>
				<cfset pair = ArrayNew(1)>
				<cfset ArrayAppend(pair, this.config.aliases[alias])>
				<cfset ArrayAppend(pair, filterArguments)>
				<cfset ArrayAppend(filterClassList, pair)>
			</cfif>
		</cfloop>

		<cfif Compare(arguments.position, "before") EQ 0>
			<cfset this.filtersClass[arguments.position] = array_merge(filterClassList, this.filtersClass[arguments.position])>
		<cfelse>
			<cfset this.filtersClass[arguments.position] = array_merge(this.filtersClass[arguments.position], filterClassList)>
		</cfif>
	</cffunction>

	<!---
	 * Check paths for match for URI.
	 *
	 * @param uri   URI to test against
	 * @param paths The test path (a string), or a list of them
	 *
	 * @return True if any of the paths apply to the URI
	--->
	<cffunction name="pathApplies" access="private" returntype="boolean" output="no">
		<cfargument name="uri" type="string" required="yes">
		<cfargument name="paths" type="any" required="yes">
		<cfset var pathList = arguments.paths>

		<!--- empty path matches all --->
		<cfif IsSimpleValue(pathList) AND Len(pathList) EQ 0>
			<cfreturn true>
		</cfif>

		<cfif IsArray(pathList) AND ArrayLen(pathList) EQ 0>
			<cfreturn true>
		</cfif>

		<!--- make sure the paths are iterable --->
		<cfif IsSimpleValue(pathList)>
			<cfset pathList = ArrayNew(1)>
			<cfset ArrayAppend(pathList, arguments.paths)>
		</cfif>

		<cfreturn checkPseudoRegex(arguments.uri, pathList)>
	</cffunction>

	<!---
	 * Check except paths.
	 *
	 * @param uri   URI path relative to baseURL
	 * @param paths The except path (a string), or a list of them
	 *
	 * @return True if any of the paths apply to the URI
	--->
	<cffunction name="checkExcept" access="private" returntype="boolean" output="no">
		<cfargument name="uri" type="string" required="yes">
		<cfargument name="paths" type="any" required="yes">
		<cfset var pathList = arguments.paths>

		<!--- empty array does not match anything --->
		<cfif IsArray(pathList) AND ArrayLen(pathList) EQ 0>
			<cfreturn false>
		</cfif>

		<!--- make sure the paths are iterable --->
		<cfif IsSimpleValue(pathList)>
			<cfset pathList = ArrayNew(1)>
			<cfset ArrayAppend(pathList, arguments.paths)>
		</cfif>

		<cfreturn checkPseudoRegex(arguments.uri, pathList)>
	</cffunction>

	<!---
	 * Check the URI against a list of paths, as pseudo-regular
	 * expressions: a slash is a slash and an asterisk is any characters.
	 * The match is done with the Java regular expression, over the whole URI
	 * and without regard to case.
	--->
	<cffunction name="checkPseudoRegex" access="private" returntype="boolean" output="no">
		<cfargument name="uri" type="string" required="yes">
		<cfargument name="paths" type="array" required="yes">
		<cfset var pattern = CreateObject("java", "java.util.regex.Pattern")>
		<cfset var path = "">
		<cfset var i = 0>

		<!--- treat each path as pseudo-regex --->
		<cfloop from="1" to="#ArrayLen(arguments.paths)#" index="i">
			<!--- need to escape path separators --->
			<cfset path = Replace(trim_(arguments.paths[i], "/ "), "/", "\/", "all")>

			<!--- need to make pseudo wildcard real --->
			<cfset path = LCase(Replace(path, "*", ".*", "all"))>

			<!--- Does this rule apply here? --->
			<cfset regex_guard_(arguments.uri)>
			<cfif pattern.compile("\A" & path & "\z").matcher(JavaCast("string", arguments.uri)).find()>
				<cfreturn true>
			</cfif>
		</cfloop>

		<cfreturn false>
	</cffunction>

</cfcomponent>
