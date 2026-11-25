<!---
 * This class is the core of the framework, and will analyse the
 * request, route it to a controller, and send back the response.
 * Of course, there are variations to that flow, but this is the
 * objective.
 *
 * Not ported yet: Kint, forceSecureAccess, the previous URL, the
 * controller attributes, closures as controllers and _remap.
--->
<cfcomponent output="no" hint="The core of the framework">

	<!---
	 * The current version of ColdIgniter Framework
	--->
	<cfset this.CI_VERSION = "4.0.0">

	<!---
	 * App startup time.
	--->
	<cfset this.startTime = "">

	<!---
	 * Total app execution time
	--->
	<cfset this.totalTime = 0>

	<!---
	 * Main application configuration
	--->
	<cfset this.config = "">

	<!---
	 * Timer instance.
	--->
	<cfset this.benchmark = "">

	<!---
	 * Current request.
	 *
	 * Named with an underscore, because "request" is a scope.
	--->
	<cfset this.request_ = "">

	<!---
	 * Current response.
	--->
	<cfset this.response = "">

	<!---
	 * Router to use.
	--->
	<cfset this.router = "">

	<!---
	 * Controller to use.
	--->
	<cfset this.controller = "">

	<!---
	 * Controller method to invoke.
	--->
	<cfset this.method = "">

	<!---
	 * Output handler to use.
	--->
	<cfset this.output = "">

	<!---
	 * Context
	 *  web:     Invoked by HTTP request
	--->
	<cfset this.context = "">

	<!---
	 * Whether to enable Control Filters.
	--->
	<cfset this.enableFilters = true>

	<!---
	 * Whether to return Response object or send response.
	--->
	<cfset this.returnResponse = false>

	<!---
	 * Constructor.
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">

		<cfset this.startTime = microtime(true)>
		<cfset this.config = arguments.config>
		<!--- Not ported yet: the response cache --->

		<cfreturn this>
	</cffunction>

	<!---
	 * Handles some basic app and environment setup.
	 *
	 * Named with an underscore, because "initialize" is taken by a
	 * built-in function.
	--->
	<cffunction name="initialize_"access="public" returntype="void" output="no">
		<!--- Not ported yet: the default locale and the default timezone of the server --->
	</cffunction>

	<!---
	 * Launch the application!
	 *
	 * This is "the loop" if you will. The main entry point into the script
	 * that gets the required class instances, fires off the filters,
	 * tries to route the response, loads the controller and generally
	 * makes all the pieces work together.
	 *
	 * @param routes         An empty string, or the RouteCollection
	 * @param returnResponse Used for testing purposes only.
	 *
	 * @return The response if returnResponse is true, or an empty string
	--->
	<cffunction name="run" access="public" returntype="any" output="no">
		<cfargument name="routes" type="any" required="no" default="">
		<cfargument name="returnResponse" type="boolean" required="no" default="false">
		<cfset var e = "">
		<cfset var filters = "">
		<cfset var possibleResponse = "">

		<cfif is_null(this.context)>
			<cfthrow type="ColdIgniter.Exceptions.LogicException" message="Context must be set before run() is called.">
		</cfif>

		<cfset service("responsecache").setTtl(0)>

		<!--- Not ported yet: the output buffer level --->

		<cfset startBenchmark()>

		<cfset getRequestObject()>
		<cfset getResponseObject()>

		<cfset static_("ColdIgniter\Events\Events").trigger("pre_system")>

		<cfset this.benchmark.stop("bootstrap")>

		<cfset this.benchmark.start("required_before_filters")>

		<!---
		 * Difference: a page that is in the page cache is looked up here
		 * first, before the filters are made, when the required filters
		 * are the stock ones (see getCachedPage()). Then the required
		 * filters do not run, as their work for such a request is done.
		--->
		<cfset possibleResponse = getCachedPage()>

		<cfif NOT instanceof_(possibleResponse, "ColdIgniter\HTTP\ResponseInterface")>
			<!--- Start up the filters --->
			<cfset filters = static_("Config\Services").filters()>

			<!--- Run required before filters --->
			<cfset possibleResponse = runRequiredBeforeFilters(filters)>
		</cfif>

		<cfset this.benchmark.stop("required_before_filters")>

		<!--- If a ResponseInterface instance is returned then send it back to the client and stop --->
		<cfif instanceof_(possibleResponse, "ColdIgniter\HTTP\ResponseInterface")>
			<cfset this.response = possibleResponse>
		<cfelse>
			<!--- Not ported yet: ResponsableInterface --->
			<cftry>
				<cfset this.response = handleRequest(arguments.routes, "", arguments.returnResponse)>

				<cfcatch type="ColdIgniter.Exceptions.PageNotFoundException">
					<cfset e = StructNew()>
					<cfset e.message = cfcatch.message>
					<cfset e.code = 404>
					<cfset this.response = display404errors(e)>
				</cfcatch>
			</cftry>
		</cfif>

		<!--- Difference: there are no filters when the page came from the cache early, see above. --->
		<cfif IsObject(filters)>
			<cfset runRequiredAfterFilters(filters)>
		</cfif>

		<!---
		 Upstream the required after filter "performance" does this, in
		 runRequiredAfterFilters, so it comes before the post-system event.
		 The filter is not ported (there is no benchmark service), so its
		 work is done here.
		--->
		<cfset this.totalTime = this.benchmark.getElapsedTime("total_execution")>
		<cfif IsSimpleValue(this.response.getBody())>
			<cfset this.response.setBody(displayPerformanceMetrics(this.response.getBody()))>
		</cfif>

		<!--- Is there a post-system event? --->
		<cfset static_("ColdIgniter\Events\Events").trigger("post_system")>

		<!---
		 * Difference: the session is written and closed here, where the
		 * engine of the original does it when the script ends. It only
		 * does something when the request has started the session.
		--->
		<cfset session_write_close()>

		<cfif arguments.returnResponse>
			<cfreturn this.response>
		</cfif>

		<cfset sendResponse()>

		<cfreturn "">
	</cffunction>

	<!---
	 * Returns an array with our basic performance stats collected.
	 *
	 * @return A map with the keys startTime and totalTime
	--->
	<cffunction name="getPerformanceStats" access="public" returntype="any" output="no">
		<!--- After filter debug toolbar requires 'total_execution'. --->
		<cfset this.totalTime = this.benchmark.getElapsedTime("total_execution")>

		<cfreturn array_("startTime", this.startTime, "totalTime", this.totalTime)>
	</cffunction>

	<!---
	 * Replaces the elapsed_time and memory_usage tag.
	 *
	 * The memory is what the Java runtime has in use, for all requests.
	--->
	<cffunction name="displayPerformanceMetrics" access="public" returntype="string" output="no">
		<cfargument name="output" type="string" required="yes">
		<cfset var runtime = CreateObject("java", "java.lang.Runtime").getRuntime()>

		<cfset arguments.output = Replace(arguments.output, "{elapsed_time}", NumberFormat(this.totalTime, "0.0000"), "all")>
		<cfset arguments.output = Replace(arguments.output, "{memory_usage}", NumberFormat((runtime.totalMemory() - runtime.freeMemory()) / 1024 / 1024, "0.000"), "all")>

		<cfreturn arguments.output>
	</cffunction>

	<!---
	 * Difference: not in the original. Looks up the page cache before the
	 * required filters are made, so a hit does not make the filters, the
	 * force https and page cache filters and the debug toolbar filter.
	 *
	 * It is done only when the result is the one that the required filters
	 * would give: only a GET request, the filters enabled, the required
	 * before filters are forcehttps and pagecache, the required after
	 * filters are pagecache and toolbar (all with the stock classes),
	 * forceGlobalSecureRequests is off (the force https filter has nothing
	 * to do), and CI_DEBUG is off (the toolbar filter has nothing to do).
	 * The page cache filter after a hit only stores the page when the TTL
	 * is not 0, and it is 0 for a hit, so nothing is lost. In every other
	 * case the filters do it as in the original.
	 *
	 * @return The response from the cache, or an empty string
	--->
	<cffunction name="getCachedPage" access="private" returntype="any" output="no">
		<cfset var filtersConfig = "">
		<cfset var appConfig = "">
		<cfset var cached = "">

		<cfif NOT this.enableFilters OR Compare(this.request_.getMethod(), "GET") NEQ 0 OR request.CI_DEBUG>
			<cfreturn "">
		</cfif>

		<cfset appConfig = config("Config\App")>

		<cfif IsBoolean(appConfig.forceGlobalSecureRequests) AND appConfig.forceGlobalSecureRequests>
			<cfreturn "">
		</cfif>

		<cfset filtersConfig = config("Config\Filters")>

		<cfif NOT onlyRequired(filtersConfig, "before", "forcehttps,pagecache", "pagecache")
			OR NOT onlyRequired(filtersConfig, "after", "pagecache,toolbar", "pagecache")>
			<cfreturn "">
		</cfif>

		<cfset cached = service("responsecache").get(this.request_, service("response"))>

		<!--- The front controller serves the page itself from now on, when the option is on. --->
		<cfif IsObject(cached)>
			<cfset service("responsecache").keepFront(cached)>
		</cfif>

		<cfreturn cached>
	</cffunction>

	<!---
	 * Difference: not in the original. Whether the required filters of a
	 * position are all in the list, with the stock classes, and the
	 * wanted one is among them.
	 *
	 * @param position "before" or "after"
	 * @param allowed  A list of aliases
	 * @param wanted   An alias that must be there
	--->
	<cffunction name="onlyRequired" access="private" returntype="boolean" output="no">
		<cfargument name="filtersConfig" type="any" required="yes">
		<cfargument name="position" type="string" required="yes">
		<cfargument name="allowed" type="string" required="yes">
		<cfargument name="wanted" type="string" required="yes">
		<cfset var list = "">
		<cfset var found = false>
		<cfset var i = 0>
		<cfset var alias = "">

		<cfif NOT StructKeyExists(arguments.filtersConfig.required, arguments.position)>
			<cfreturn false>
		</cfif>

		<cfset list = arguments.filtersConfig.required[arguments.position]>

		<cfloop index="i" from="1" to="#ArrayLen(list)#">
			<cfset alias = list[i]>

			<cfif NOT IsSimpleValue(alias) OR NOT ListFind(arguments.allowed, alias) OR NOT arguments.filtersConfig.aliases.containsKey(alias)>
				<cfreturn false>
			</cfif>

			<!--- an alias can stand for a list of classes --->
			<cfif NOT IsSimpleValue(arguments.filtersConfig.aliases.get(alias))>
				<cfreturn false>
			</cfif>

			<!--- the alias is the name of the stock class --->
			<cfif Compare(arguments.filtersConfig.aliases.get(alias), "ColdIgniter\Filters\" & ListGetAt("ForceHTTPS,PageCache,DebugToolbar", ListFind("forcehttps,pagecache,toolbar", alias))) NEQ 0>
				<cfreturn false>
			</cfif>

			<cfif Compare(alias, arguments.wanted) EQ 0>
				<cfset found = true>
			</cfif>
		</cfloop>

		<cfreturn found>
	</cffunction>

	<!---
	 * Run required before filters.
	 *
	 * @return The response a filter returned, or an empty string.
	--->
	<cffunction name="runRequiredBeforeFilters" access="private" returntype="any" output="no">
		<cfargument name="filters" type="any" required="yes">
		<cfset var possibleResponse = arguments.filters.runRequired("before")>

		<!--- If a ResponseInterface instance is returned then send it back to the client and stop --->
		<cfif instanceof_(possibleResponse, "ColdIgniter\HTTP\ResponseInterface")>
			<cfreturn possibleResponse>
		</cfif>

		<cfreturn "">
	</cffunction>

	<!---
	 * Run required after filters.
	--->
	<cffunction name="runRequiredAfterFilters" access="private" returntype="void" output="no">
		<cfargument name="filters" type="any" required="yes">
		<cfset var response = "">

		<cfset arguments.filters.setResponse(this.response)>

		<!--- Run required after filters --->
		<cfset this.benchmark.start("required_after_filters")>
		<cfset response = arguments.filters.runRequired("after")>
		<cfset this.benchmark.stop("required_after_filters")>

		<cfif instanceof_(response, "ColdIgniter\HTTP\ResponseInterface")>
			<cfset this.response = response>
		</cfif>
	</cffunction>

	<!---
	 * Web access?
	--->
	<cffunction name="isWeb" access="private" returntype="boolean" output="no">
		<cfreturn this.context EQ "web">
	</cffunction>

	<!---
	 * Disables Controller Filters.
	--->
	<cffunction name="disableFilters" access="public" returntype="void" output="no">
		<cfset this.enableFilters = false>
	</cffunction>

	<!---
	 * Handles the main request logic and fires the controller.
	--->
	<cffunction name="handleRequest" access="private" returntype="any" output="no">
		<cfargument name="routes" type="any" required="no" default="">
		<cfargument name="cacheConfig" type="any" required="no" default="">
		<cfargument name="returnResponse" type="boolean" required="no" default="false">
		<cfset var routeFilters = "">
		<cfset var uri = "">
		<cfset var returned = "">
		<cfset var controller = "">
		<cfset var filters = "">
		<cfset var possibleResponse = "">
		<cfset var response = "">

		<cfif this.request_.getMethod() EQ "CLI">
			<cfreturn this.response.setStatusCode(405).setBody("Method Not Allowed")>
		</cfif>

		<cfset routeFilters = tryToRouteIt(arguments.routes)>

		<!--- uri is URL-encoded. --->
		<cfset uri = this.request_.getPath()>

		<cfif this.enableFilters>
			<cfset filters = service("filters")>

			<!---
			 If any filters were specified within the routes file,
			 we need to ensure it's active for the current request
			--->
			<cfif IsArray(routeFilters)>
				<cfset filters.enableFilters(routeFilters, "before")>

				<!--- Not ported yet: Feature oldFilterOrder, the new order is always used. --->
				<cfset routeFilters = array_reverse(routeFilters)>

				<cfset filters.enableFilters(routeFilters, "after")>
			</cfif>

			<!--- Run "before" filters --->
			<cfset this.benchmark.start("before_filters")>
			<cfset possibleResponse = filters.run(uri, "before")>
			<cfset this.benchmark.stop("before_filters")>

			<!--- If a ResponseInterface instance is returned then send it back to the client and stop --->
			<cfif instanceof_(possibleResponse, "ColdIgniter\HTTP\ResponseInterface")>
				<!--- Not ported yet: outputBufferingEnd --->
				<cfreturn possibleResponse>
			</cfif>

			<cfif instanceof_(possibleResponse, "ColdIgniter\HTTP\IncomingRequest")>
				<cfset this.request_ = possibleResponse>
			</cfif>
		</cfif>

		<cfset returned = startController()>

		<cfset controller = createController()>

		<cfif NOT method_exists(controller, this.method)>
			<cfset static_("ColdIgniter\Exceptions\PageNotFoundException").forMethodNotFound(this.method)>
		</cfif>

		<!--- Is there a "post_controller_constructor" event? --->
		<cfset static_("ColdIgniter\Events\Events").trigger("post_controller_constructor")>

		<cfset returned = runController(controller)>

		<!---
		 If returned is a string, then the controller output something,
		 probably a view, instead of echoing it directly. Send it along
		 so it can be used with the output.
		--->
		<cfset gatherOutput(arguments.cacheConfig, returned)>

		<cfif this.enableFilters>
			<cfset filters = service("filters")>
			<cfset filters.setResponse(this.response)>

			<!--- Run "after" filters --->
			<cfset this.benchmark.start("after_filters")>
			<cfset response = filters.run(uri, "after")>
			<cfset this.benchmark.stop("after_filters")>

			<cfif instanceof_(response, "ColdIgniter\HTTP\ResponseInterface")>
				<cfset this.response = response>
			</cfif>
		</cfif>

		<!--- Not ported yet: the controller attributes and the previous URL --->

		<cfreturn this.response>
	</cffunction>

	<!---
	 * Get our Request object, (either IncomingRequest or CLIRequest).
	--->
	<cffunction name="getRequestObject" access="private" returntype="void" output="no">
		<cfif IsObject(this.request_)>
			<cfset spoofRequestMethod()>
			<cfreturn>
		</cfif>

		<cfset static_("Config\Services").createRequest(this.config)>

		<cfset this.request_ = service("request")>

		<cfset spoofRequestMethod()>
	</cffunction>

	<!---
	 * Modifies the Request Object to use a different method if a POST
	 * variable called _method is found.
	--->
	<cffunction name="spoofRequestMethod" access="public" returntype="void" output="no">
		<cfset var method = "">
		<cfset var httpMethod = static_("ColdIgniter\HTTP\Method")>

		<!--- Only works with POSTED forms --->
		<cfif Compare(this.request_.getMethod(), httpMethod.POST) NEQ 0>
			<cfreturn>
		</cfif>

		<cfset method = this.request_.getPost("_method")>

		<!--- a missing key comes back as an empty string here, which fails every compare below, so the result matches the original --->
		<cfif is_null(method)>
			<cfreturn>
		</cfif>

		<!--- Difference: an array or map value (_method[]=PUT) cannot be compared, the original strict in_array just finds no match --->
		<cfif NOT IsSimpleValue(method)>
			<cfreturn>
		</cfif>

		<!--- Only allows PUT, PATCH, DELETE --->
		<cfif Compare(method, httpMethod.PUT) EQ 0 OR Compare(method, httpMethod.PATCH) EQ 0 OR Compare(method, httpMethod.DELETE) EQ 0>
			<cfset this.request_ = this.request_.setMethod(method)>
		</cfif>
	</cffunction>

	<!---
	 * Get our Response object, and set some default values, including
	 * the HTTP protocol version and a default successful response.
	--->
	<cffunction name="getResponseObject" access="private" returntype="void" output="no">
		<cfset this.response = static_("Config\Services").response(this.config)>

		<cfif isWeb()>
			<cfset this.response.setProtocolVersion(this.request_.getProtocolVersion())>
		</cfif>

		<!--- Assume success until proven otherwise. --->
		<cfset this.response.setStatusCode(200)>
	</cffunction>

	<!---
	 * Try to Route It - As it sounds like, works with the router to
	 * match a route against the current URI. If the route is a
	 * "redirect route", will also handle the redirect.
	 *
	 * @param routes A collection interface to use in place
	 *               of the config file.
	 *
	 * @return Route filters, that is, the filters specified in the routes file
	--->
	<cffunction name="tryToRouteIt" access="private" returntype="any" output="no">
		<cfargument name="routes" type="any" required="no" default="">
		<cfset var uri = "">

		<cfset this.benchmark.start("routing")>

		<cfif NOT IsObject(arguments.routes)>
			<cfset arguments.routes = service("routes").loadRoutes()>
		</cfif>

		<!--- routes is defined in Config/Routes.cfm --->
		<cfset this.router = static_("Config\Services").router(arguments.routes, this.request_)>

		<!--- uri is URL-encoded. --->
		<cfset uri = this.request_.getPath()>

		<cfset this.controller = this.router.handle(uri)>
		<cfset this.method = this.router.methodName()>

		<!---
		 If a {locale} segment was matched in the final route,
		 then we need to set the correct locale on our Request.
		--->
		<cfif this.router.hasLocale()>
			<cfset this.request_.setLocale_(this.router.getLocale_())>
		</cfif>

		<cfset this.benchmark.stop("routing")>

		<cfreturn this.router.getFilters()>
	</cffunction>

	<!---
	 * Now that everything has been setup, this method attempts to run the
	 * controller method and make the script go. If it's not able to, will
	 * show the appropriate Page Not Found error.
	--->
	<cffunction name="startController" access="private" returntype="any" output="no">
		<cfset this.benchmark.start("controller")>
		<cfset this.benchmark.start("controller_constructor")>

		<!--- Not ported yet: Is it routed to a Closure? --->

		<!--- No controller specified - we don't know what to do now. --->
		<cfif is_null(this.controller)>
			<cfset static_("ColdIgniter\Exceptions\PageNotFoundException").forEmptyController()>
		</cfif>

		<!--- Try to autoload the class --->
		<cfif NOT class_exists(this.controller, true)
			OR (Left(this.method, 1) EQ "_" AND this.method NEQ "__invoke")>
			<cfset static_("ColdIgniter\Exceptions\PageNotFoundException").forControllerNotFound(this.controller, this.method)>
		</cfif>

		<!--- Not ported yet: the before() methods of the route attributes --->

		<cfreturn "">
	</cffunction>

	<!---
	 * Instantiates the controller class.
	--->
	<cffunction name="createController" access="private" returntype="any" output="no">
		<cfset var class = new_(this.controller)>

		<cfset class.initController(this.request_, this.response, service("logger"))>

		<cfset this.benchmark.stop("controller_constructor")>

		<cfreturn class>
	</cffunction>

	<!---
	 * Runs the controller, allowing for _remap methods to function.
	 *
	 * CI4 supports three types of requests:
	 *  1. Web: URI segments become parameters, sent to Controllers via Routes,
	 *      output controlled by Headers to browser
	 *
	 * @param class The controller
	--->
	<cffunction name="runController" access="private" returntype="any" output="no">
		<cfargument name="class" type="any" required="yes">
		<cfset var params = this.router.params()>
		<cfset var list = "">
		<cfset var i = 0>
		<cfset var output = "">

		<!--- Not ported yet: _remap --->
		<cfloop from="1" to="#ArrayLen(params)#" index="i">
			<cfset list = ListAppend(list, "params[#i#]")>
		</cfloop>

		<cfset output = Evaluate("arguments.class.#this.method#(#list#)")>

		<cfset this.benchmark.stop("controller")>

		<!--- A method that returns nothing leaves the variable undefined. --->
		<cfif NOT IsDefined("output")>
			<cfreturn "">
		</cfif>

		<cfreturn output>
	</cffunction>

	<!---
	 * Displays a 404 Page Not Found error. If set, will try to
	 * call the 404Override controller/method that was set in routing config.
	 *
	 * @param e The message and the code of the exception
	--->
	<cffunction name="display404errors" access="private" returntype="any" output="no">
		<cfargument name="e" type="struct" required="yes">
		<cfset var override = "">
		<cfset var returned = "">
		<cfset var controller = "">
		<cfset var message = "">

		<cfset this.response.setStatusCode(arguments.e.code)>

		<!--- Is there a 404 Override available? --->
		<cfset override = "">
		<cfif IsObject(this.router)>
			<cfset override = this.router.get404Override()>
		</cfif>

		<cfif NOT is_null(override)>
			<cfset returned = "">

			<!--- Not ported yet: a closure as the override --->
			<cfif IsArray(override)>
				<cfset this.controller = override[1]>
				<cfset this.method = override[2]>

				<cfset this.benchmark.start("controller")>
				<cfset this.benchmark.start("controller_constructor")>

				<cfset controller = createController()>

				<cfset message = arguments.e.message>
				<cfset returned = Evaluate("controller.#this.method#(message)")>
				<cfset this.benchmark.stop("controller")>
				<cfif NOT IsDefined("returned")>
					<cfset returned = "">
				</cfif>
			</cfif>

			<cfset gatherOutput("", returned)>

			<cfreturn this.response>
		</cfif>

		<!--- Throws new PageNotFoundException and remove exception message on production. --->
		<cfif request.ENVIRONMENT NEQ "production" OR NOT isWeb()>
			<cfset static_("ColdIgniter\Exceptions\PageNotFoundException").forPageNotFound(arguments.e.message)>
		</cfif>
		<cfset static_("ColdIgniter\Exceptions\PageNotFoundException").forPageNotFound("")>
	</cffunction>

	<!---
	 * Gathers the script output from the buffer, replaces some execution
	 * time tag in the output and displays the debug toolbar, if required.
	 *
	 * There is no output buffer here: nothing can be written from inside
	 * a method, so the output is only what the controller returned.
	 *
	 * @param returned A string, a response, or an empty string
	--->
	<cffunction name="gatherOutput" access="private" returntype="void" output="no">
		<cfargument name="cacheConfig" type="any" required="no" default="">
		<cfargument name="returned" type="any" required="no" default="">

		<cfset this.output = "">

		<!--- Not ported yet: DownloadResponse --->

		<!---
		 If the controller returned a response object,
		 we need to grab the body from it so it can
		 be added to anything else that might have been
		 echoed already.
		 We also need to save the instance locally
		 so that any status code changes, etc, take place.
		--->
		<cfif IsObject(arguments.returned)>
			<cfset this.response = arguments.returned>
			<cfset arguments.returned = arguments.returned.getBody()>
		</cfif>

		<cfif IsSimpleValue(arguments.returned)>
			<cfset this.output = this.output & arguments.returned>
		</cfif>

		<cfset this.response.setBody(this.output)>
	</cffunction>

	<!---
	 * Sends the output of this request back to the client.
	 * This is what they've been waiting for!
	--->
	<cffunction name="sendResponse" access="private" returntype="void" output="no">
		<cfset this.response.send()>
	</cffunction>

	<!---
	 * Start the Benchmark
	 *
	 * The timer is used to display total script execution both in the
	 * debug toolbar, and potentially on the displayed page.
	--->
	<cffunction name="startBenchmark" access="private" returntype="void" output="no">
		<cfif is_null(this.startTime)>
			<cfset this.startTime = microtime(true)>
		</cfif>

		<cfset this.benchmark = static_("Config\Services").timer()>
		<cfset this.benchmark.start("total_execution", this.startTime)>
		<cfset this.benchmark.start("bootstrap")>
	</cffunction>

	<!---
	 * Sets the app context.
	--->
	<cffunction name="setContext" access="public" returntype="any" output="no">
		<cfargument name="context" type="string" required="yes">

		<cfset this.context = arguments.context>

		<cfreturn this>
	</cffunction>

</cfcomponent>
