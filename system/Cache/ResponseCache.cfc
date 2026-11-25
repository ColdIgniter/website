<!---
 * Web Page Caching
 *
 * Difference: the response is handed to the cache as a map {headers,
 * output, status, reason} and not as serialize() text: the cache handler
 * stores the map as it is. A response header is a single value line here
 * (there are no Header objects), so a header is saved and set as that
 * line.
 *
 * Difference: the cache handler in use must store a map and give it back
 * as a map. The file and dummy handlers do. A cached empty string reads
 * as a miss, as it does in the cache handlers. Any other cached value
 * that is not such a map is an error, as invalid data is in the original.
 *
 * Difference: a handler that has getShared() (the file handler) gives the
 * cached map from a map in the application scope, and the map is not
 * changed here (the headers and the body are only read), so it is shared by
 * all requests. See the file handler.
 *
 * Not ported yet: the CLI request (CLIRequest), so only IncomingRequest.
--->
<cfcomponent output="no" hint="Web Page Caching">

	<!---
	 * Whether to take the URL query string into consideration when generating
	 * output cache files. Valid options are:
	 *
	 *    false      = Disabled
	 *    true       = Enabled, take all query parameters into account.
	 *                 Please be aware that this may result in numerous cache
	 *                 files generated for the same page over and over again.
	 *    array('q') = Enabled, but only take into account the specified list
	 *                 of query parameters.
	 *
	 * @var boolean|array
	--->
	<cfset this.cacheQueryString = false>

	<!---
	 * Cache time to live (TTL) in seconds.
	--->
	<cfset this.ttl = 0>

	<!---
	 * The cache handler.
	--->
	<cfset this.cache = "">

	<!---
	 * Difference: not in the original. Whether a page from the cache is
	 * also kept for the front controller (the option frontPages of
	 * Config\Cache, see keepFront()).
	--->
	<cfset this.frontPages = false>

	<!---
	 * The entry in the memory of the cache handler that the last get()
	 * gave the page from, or an empty string.
	--->
	<cfset this.frontEntry = "">

	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">
		<cfargument name="cache" type="any" required="yes">

		<cfset this.cache = arguments.cache>
		<cfset this.cacheQueryString = arguments.config.cacheQueryString>

		<cfif StructKeyExists(arguments.config, "frontPages") AND IsBoolean(arguments.config.frontPages)>
			<cfset this.frontPages = arguments.config.frontPages>
		</cfif>

		<cfreturn this>
	</cffunction>

	<cffunction name="setTtl" access="public" returntype="any" output="no">
		<cfargument name="ttl" type="numeric" required="yes">

		<cfset this.ttl = arguments.ttl>

		<cfreturn this>
	</cffunction>

	<!---
	 * Generates the cache key to use from the current request.
	 *
	 * Difference: the URI of the port keeps the query as text, so it is
	 * parsed here with parse_str() and built again with http_build_query(),
	 * as getQuery() of the original does, with the option only when
	 * cacheQueryString is a list. The names are compared after decoding,
	 * as the controller reads them.
	 *
	 * @internal for testing purposes only
	--->
	<cffunction name="generateCacheKey" access="public" returntype="string" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfset var uri = arguments.request_.getUri()>
		<cfset var query = "">
		<cfset var vars = "">
		<cfset var temp = "">
		<cfset var i = 0>

		<cfif IsArray(this.cacheQueryString) OR Compare(this.cacheQueryString, "true") EQ 0>
			<cfset vars = parse_str(uri.getQuery())>

			<cfif IsArray(this.cacheQueryString)>
				<cfset temp = CreateObject("java", "java.util.LinkedHashMap").init()>

				<cfloop index="i" from="1" to="#ArrayLen(this.cacheQueryString)#">
					<cfif vars.containsKey(this.cacheQueryString[i])>
						<cfset temp.put(this.cacheQueryString[i], vars.get(this.cacheQueryString[i]))>
					</cfif>
				</cfloop>

				<cfset vars = temp>
			</cfif>

			<cfif NOT vars.isEmpty()>
				<cfset query = http_build_query(vars)>
			</cfif>
		</cfif>

		<cfreturn md5(arguments.request_.getMethod() & ":" & uri.createURIString(uri.getScheme(), uri.getAuthority(), uri.getPath(), query, ""))>
	</cffunction>

	<!---
	 * Caches the response.
	--->
	<cffunction name="make" access="public" returntype="boolean" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="response" type="any" required="yes">
		<cfset var headers = CreateObject("java", "java.util.LinkedHashMap").init()>
		<cfset var all = arguments.response.headers()>
		<cfset var name = "">
		<cfset var lines = "">
		<cfset var i = 0>
		<cfset var contents = CreateObject("java", "java.util.LinkedHashMap").init()>

		<cfif this.ttl EQ 0>
			<cfreturn true>
		</cfif>

		<cfloop collection="#all#" item="name">
			<cfif IsArray(all[name])>
				<!--- several headers of the same name: a list of lines --->
				<cfset lines = ArrayNew(1)>

				<cfloop from="1" to="#ArrayLen(all[name])#" index="i">
					<cfset ArrayAppend(lines, all[name][i].getValueLine())>
				</cfloop>

				<cfset headers.put(name, lines)>
			<cfelse>
				<cfset headers.put(name, all[name].getValueLine())>
			</cfif>
		</cfloop>

		<cfset contents.put("headers", headers)>
		<cfset contents.put("output", arguments.response.getBody())>
		<cfset contents.put("status", JavaCast("string", arguments.response.getStatusCode()))>
		<cfset contents.put("reason", arguments.response.getReasonPhrase())>

		<cfreturn this.cache.save(generateCacheKey(arguments.request_), contents, this.ttl)>
	</cffunction>

	<!---
	 * Gets the cached response for the request.
	 *
	 * @return The response, or an empty string (null)
	--->
	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="response" type="any" required="yes">
		<cfset var key = generateCacheKey(arguments.request_)>
		<cfset var cachedResponse = "">
		<cfset var headers = "">
		<cfset var current = "">
		<cfset var keys = "">
		<cfset var i = 0>
		<cfset var name = "">
		<cfset var status = 200>
		<cfset var reason = "">

		<cfset this.frontEntry = "">

		<cfif method_exists(this.cache, "getShared")>
			<cfset cachedResponse = this.cache.getShared(key)>

			<cfif StructKeyExists(this.cache, "sharedEntry")>
				<cfset this.frontEntry = this.cache.sharedEntry>
			</cfif>
		<cfelse>
			<cfset cachedResponse = this.cache.get(key)>
		</cfif>

		<cfif IsSimpleValue(cachedResponse) AND Compare(cachedResponse, "") EQ 0>
			<cfreturn "">
		</cfif>

		<cfif NOT IsStruct(cachedResponse) OR NOT StructKeyExists(cachedResponse, "output") OR NOT StructKeyExists(cachedResponse, "headers") OR NOT IsStruct(cachedResponse["headers"])>
			<cfthrow type="ColdIgniter.Exceptions.RuntimeException" errorcode="500" message="Error unserializing page cache">
		</cfif>

		<cfset headers = cachedResponse["headers"]>

		<cfif StructKeyExists(cachedResponse, "status")>
			<cfset status = cachedResponse["status"]>
		</cfif>

		<cfif StructKeyExists(cachedResponse, "reason")>
			<cfset reason = cachedResponse["reason"]>
		</cfif>

		<!--- Clear all default headers --->
		<cfset current = arguments.response.headers()>
		<cfset keys = CreateObject("java", "java.util.ArrayList").init(current.keySet())>

		<cfloop index="i" from="0" to="#keys.size() - 1#">
			<cfset arguments.response.removeHeader(keys.get(JavaCast("int", i)))>
		</cfloop>

		<!--- Set cached headers --->
		<cfloop collection="#headers#" item="name">
			<cfif IsArray(headers[name])>
				<!--- several headers of the same name (see addHeader) --->
				<cfloop index="i" from="1" to="#ArrayLen(headers[name])#">
					<cfset arguments.response.addHeader(name, headers[name][i])>
				</cfloop>
			<cfelse>
				<cfset arguments.response.setHeader(name, headers[name])>
			</cfif>
		</cfloop>

		<cfset arguments.response.setBody(cachedResponse["output"])>
		<cfset arguments.response.setStatusCode(status, reason)>

		<cfreturn arguments.response>
	</cffunction>

	<!---
	 * Difference: not in the original. Keeps the page that get() has just
	 * given for the front controller, which then serves it from the memory
	 * of the server before the framework starts (see Cache/FrontPage.cfm).
	 *
	 * The caller makes sure that nothing but the page cache has a say in
	 * the response (see getCachedPage() of ColdIgniter\ColdIgniter). Here:
	 * the option is on, the front controller has made a signature of the
	 * request, the page came from the memory of the cache handler, the
	 * body is text, and the response has no cookies.
	 *
	 * The item holds the entry of the cache handler, not a copy, so the
	 * handler can switch it off. Only the application scope of this site
	 * is used.
	 *
	 * The item also holds the configuration files that decide all of this
	 * (Config\App, Config\Cache, Config\Filters, Config/Events.cfm, the
	 * boot file of the environment and the .env file) with their modified
	 * times. The front controller serves the page only while they are the
	 * same, so a change of the configuration is seen with the next request.
	 *
	 * A page is not kept while the events pre_system or post_system have a
	 * listener: the listener would not run for the kept page, and a header
	 * that it sets for one request would be sent to all.
	--->
	<cffunction name="keepFront" access="public" returntype="void" output="no">
		<cfargument name="response" type="any" required="yes">
		<cfset var page = "">
		<cfset var pages = "">
		<cfset var headers = "">
		<cfset var names = "">
		<cfset var values = "">
		<cfset var name = "">
		<cfset var contentType = "">
		<cfset var output = "">
		<cfset var head = "">
		<cfset var expires = 0>
		<cfset var limit = 100>
		<cfset var files = "">
		<cfset var stamp = "">
		<cfset var file_ = "">
		<cfset var path = "">
		<cfset var events = "">
		<cfset var i = 0>

		<cfif NOT this.frontPages OR IsSimpleValue(this.frontEntry) OR NOT StructKeyExists(request, "ColdIgniterFront") OR Len(request.ColdIgniterFront.signature) EQ 0>
			<cfreturn>
		</cfif>

		<!---
		 Difference: a page is not kept in front when the policy is on. The
		 front page is served without send(), so it would go out with no
		 policy header and with the nonce tags taken out; upstream runs
		 finalize() again for a cached response, to make fresh nonces.
		--->
		<cfif config("Config\App").CSPEnabled>
			<cfreturn>
		</cfif>

		<cftry>
			<cfset events = static_("ColdIgniter\Events\Events")>

			<cfif ArrayLen(events.listeners("pre_system")) GT 0 OR ArrayLen(events.listeners("post_system")) GT 0>
				<cfreturn>
			</cfif>

			<cfset output = arguments.response.getBody()>

			<cfif NOT IsSimpleValue(output) OR ArrayLen(arguments.response.cookieStore.getIterator()) GT 0>
				<cfreturn>
			</cfif>

			<!--- What send() of the response does to the body, with the policy off. --->
			<cfset output = Replace(output, "{csp-style-nonce}", "", "all")>
			<cfset output = Replace(output, "{csp-script-nonce}", "", "all")>

			<cfset names = CreateObject("java", "java.util.ArrayList").init()>
			<cfset values = CreateObject("java", "java.util.ArrayList").init()>
			<cfset headers = arguments.response.headers()>

			<cfloop collection="#headers#" item="name">
				<cfif name EQ "Content-Type" AND NOT IsArray(headers[name])>
					<cfset contentType = headers[name].getValueLine()>
				<cfelse>
					<cfif IsArray(headers[name])>
						<!--- one entry for each of several headers of the same name --->
						<cfloop index="i" from="1" to="#ArrayLen(headers[name])#">
							<cfset names.add(JavaCast("string", name))>
							<cfset values.add(JavaCast("string", headers[name][i].getValueLine()))>
						</cfloop>
					<cfelse>
						<cfset names.add(JavaCast("string", name))>
						<cfset values.add(JavaCast("string", headers[name].getValueLine()))>
					</cfif>
				</cfif>
			</cfloop>

			<cfset head = this.frontEntry["item"]>

			<cfif Val(head["ttl"]) GT 0>
				<cfset expires = Val(head["time"]) + Val(head["ttl"])>
			</cfif>

			<!--- A file that is not there has the time 0, and is seen when it is made. --->
			<cfset files = CreateObject("java", "java.util.ArrayList").init()>

			<cfloop index="i" from="1" to="6">
				<cfif i LTE 3>
					<cfset path = request.APPPATH & "Config/" & ListGetAt("App,Cache,Filters", i) & ".cfc">
				<cfelseif i EQ 4>
					<cfset path = request.APPPATH & "Config/Events.cfm">
				<cfelseif i EQ 5>
					<cfset path = request.APPPATH & "Config/Boot/" & request.ENVIRONMENT & ".cfm">
				<cfelse>
					<cfset path = new_("Config\Paths").envDirectory & "/.env">
				</cfif>

				<cfset file_ = CreateObject("java", "java.io.File").init(JavaCast("string", path))>
				<cfset files.add(file_)>
				<cfset stamp = stamp & file_.lastModified() & ",">
			</cfloop>

			<cfset page = CreateObject("java", "java.util.HashMap").init()>
			<cfset page.put("entry", this.frontEntry)>
			<cfset page.put("files", files)>
			<cfset page.put("stamp", JavaCast("string", stamp))>
			<cfset page.put("expires", expires)>
			<cfset page.put("status", JavaCast("string", arguments.response.getStatusCode()))>
			<cfset page.put("reason", JavaCast("string", arguments.response.getReasonPhrase()))>
			<cfset page.put("contentType", JavaCast("string", contentType))>
			<cfset page.put("names", names)>
			<cfset page.put("values", values)>
			<cfset page.put("output", JavaCast("string", output))>
			<cfset page.put("elapsed", Find("{elapsed_time}", output) GT 0)>
			<cfset page.put("memory", Find("{memory_usage}", output) GT 0)>

			<cfif NOT StructKeyExists(application.ColdIgniter, "frontPages")>
				<cflock scope="application" type="exclusive" timeout="10">
					<cfif NOT StructKeyExists(application.ColdIgniter, "frontPages")>
						<cfset application.ColdIgniter.frontPages = CreateObject("java", "java.util.Collections").synchronizedMap(
							CreateObject("java", "java.util.HashMap").init()
						)>
					</cfif>
				</cflock>
			</cfif>

			<cfset pages = application.ColdIgniter.frontPages>

			<cfif StructKeyExists(this.cache, "memoryEntries")>
				<cfset limit = this.cache.memoryEntries>
			</cfif>

			<!--- Full: one item goes, as in the memory of the file handler. --->
			<cfif pages.size() GTE limit AND NOT pages.containsKey(request.ColdIgniterFront.signature)>
				<cftry>
					<cfset pages.remove(pages.keySet().iterator().next())>

					<cfcatch type="any">
						<cfset pages.clear()>
					</cfcatch>
				</cftry>
			</cfif>

			<cfset pages.put(request.ColdIgniterFront.signature, page)>

			<cfcatch type="any"></cfcatch>
		</cftry>
	</cffunction>

</cfcomponent>
