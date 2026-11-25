<!---
 * Services Configuration file.
 *
 * Services are simply other classes/libraries that the system uses
 * to do its job. This is used by ColdIgniter to allow the core of the
 * framework to be swapped out easily without affecting the usage within
 * the rest of your application.
 *
 * This is used in place of a Dependency Injection container primarily
 * due to its simplicity, which allows a better long-term maintenance
 * of the applications built on top of ColdIgniter. A bonus side-effect
 * is that IDEs are able to determine what class you are calling
 * whereas with DI Containers there usually isn't a way for them to do this.
 *
 * @see http://blog.ircmaxell.com/2015/11/simple-easy-risk-and-change.html
 * @see http://www.infoq.com/presentations/Simple-Made-Easy
 *
 * AppServices in the original is static_("Config\Services") here.
 * Where the original takes the locator, an empty string is passed until
 * it is ported.
 *
 * Not ported yet: every service that is not listed below.
--->
<cfcomponent output="no" extends="BaseService" hint="Services Configuration file">

	<!---
	 * The cache class provides a simple way to store and retrieve
	 * complex data for later.
	--->
	<cffunction name="cache" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("cache", arguments.config)>
		</cfif>

		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\Cache")>
		</cfif>

		<cfreturn static_("ColdIgniter\Cache\CacheFactory").getHandler(arguments.config)>
	</cffunction>

	<!---
	 * ColdIgniter, the core of the framework.
	--->
	<cffunction name="coldigniter" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("coldigniter", arguments.config)>
		</cfif>

		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\App")>
		</cfif>

		<cfreturn new_("ColdIgniter\ColdIgniter", arguments.config)>
	</cffunction>

	<!---
	 * The Content Security Policy class provides the tools needed to build
	 * a secure Content-Security-Policy header.
	--->
	<cffunction name="csp" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("csp", arguments.config)>
		</cfif>

		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\ContentSecurityPolicy")>
		</cfif>

		<cfreturn new_("ColdIgniter\HTTP\ContentSecurityPolicy", arguments.config)>
	</cffunction>

	<!---
	 * The Encryption class provides two-way encryption.
	 *
	 * Difference: getShared is false by default, as in the original. The
	 * handler is returned as it is made: a KeyRotationDecorator when the
	 * config has previous keys.
	 *
	 * @param config The Config\Encryption, or an empty string (null)
	 *
	 * @return EncrypterInterface Encryption handler
	--->
	<cffunction name="encrypter" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="false">
		<cfset var encryption = "">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("encrypter", arguments.config)>
		</cfif>

		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\Encryption")>
		</cfif>

		<cfset encryption = new_("ColdIgniter\Encryption\Encryption", arguments.config)>

		<cfreturn encryption.initialize_(arguments.config)>
	</cffunction>

	<!---
	 * The Exceptions class holds the Exception handler.
	--->
	<cffunction name="exceptions" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("exceptions", arguments.config)>
		</cfif>

		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\Exceptions")>
		</cfif>

		<cfreturn new_("ColdIgniter\Debug\Exceptions", arguments.config)>
	</cffunction>

	<!---
	 * Filters allow you to run tasks before and/or after a controller
	 * is executed. During before filters, the request can be modified,
	 * and the response can be used to stop the execution.
	--->
	<cffunction name="filters" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("filters", arguments.config)>
		</cfif>

		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\Filters")>
		</cfif>

		<cfreturn new_("ColdIgniter\Filters\Filters", arguments.config, static_("Config\Services").get("request"), static_("Config\Services").get("response"))>
	</cffunction>

	<!---
	 * The Format class is a convenient place to create Formatters.
	 *
	 * @param config The Config\Format, or an empty string (null)
	--->
	<cffunction name="format" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("format", arguments.config)>
		</cfif>

		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\Format")>
		</cfif>

		<cfreturn new_("ColdIgniter\Format\Format", arguments.config)>
	</cffunction>

	<!---
	 * The Honeypot provides a simple way to protect forms from bots.
	 *
	 * @param config The Config\Honeypot, or an empty string (null)
	--->
	<cffunction name="honeypot" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("honeypot", arguments.config)>
		</cfif>

		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\Honeypot")>
		</cfif>

		<cfreturn new_("ColdIgniter\Honeypot\Honeypot", arguments.config)>
	</cffunction>

	<!---
	 * Responsible for loading the language string translations.
	--->
	<cffunction name="language" access="public" returntype="any" output="no">
		<cfargument name="locale" type="string" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">
		<cfset var requestLocale = "">
		<cfset var requestObject = "">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("language", arguments.locale).setLocale_(arguments.locale)>
		</cfif>

		<cfset requestObject = static_("Config\Services").get("request")>

		<cfif instanceof_(requestObject, "ColdIgniter\HTTP\IncomingRequest")>
			<cfset requestLocale = requestObject.getLocale_()>
		<cfelse>
			<!--- Difference: Locale::getDefault() is the default locale of the application here. --->
			<cfset requestLocale = variables.config("Config\App").defaultLocale>
		</cfif>

		<!--- Use '?:' for empty string check --->
		<cfif arguments.locale EQ "" OR arguments.locale EQ "0">
			<cfset arguments.locale = requestLocale>
		</cfif>

		<cfreturn new_("ColdIgniter\Language\Language", arguments.locale)>
	</cffunction>

	<!---
	 * The Logger class is a PSR-3 compatible Logging class that supports
	 * multiple handlers that process the actual logging.
	 *
	 * Not ported yet: PSR-3 (the Psr\Log interfaces are not ported).
	--->
	<cffunction name="logger" access="public" returntype="any" output="no">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("logger")>
		</cfif>

		<cfreturn new_("ColdIgniter\Log\Logger", variables.config("Config\Logger"))>
	</cffunction>

	<!---
	 * The Migrations class runs the migrations of the database. It is
	 * called from code (there is no command line).
	--->
	<cffunction name="migrations" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfargument name="db" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("migrations", arguments.config, arguments.db)>
		</cfif>

		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\Migrations")>
		</cfif>

		<cfreturn new_("ColdIgniter\Database\MigrationRunner", arguments.config, arguments.db)>
	</cffunction>

	<!---
	 * The Negotiate class provides the content negotiation features for
	 * working the request to determine correct language, encoding, charset,
	 * and more.
	--->
	<cffunction name="negotiator" access="public" returntype="any" output="no">
		<cfargument name="request" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("negotiator", arguments.request)>
		</cfif>

		<cfif is_null(arguments.request)>
			<cfset arguments.request = static_("Config\Services").get("request")>
		</cfif>

		<cfreturn new_("ColdIgniter\HTTP\Negotiate", arguments.request)>
	</cffunction>

	<!---
	 * The response cache stores whole responses, for the PageCache filter.
	--->
	<cffunction name="responsecache" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfargument name="cache" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("responsecache", arguments.config, arguments.cache)>
		</cfif>

		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\Cache")>
		</cfif>
		<cfif is_null(arguments.cache)>
			<cfset arguments.cache = static_("Config\Services").get("cache")>
		</cfif>

		<cfreturn new_("ColdIgniter\Cache\ResponseCache", arguments.config, arguments.cache)>
	</cffunction>

	<!---
	 * Return the appropriate pagination handler.
	--->
	<cffunction name="pager" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfargument name="view" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("pager", arguments.config, arguments.view)>
		</cfif>

		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\Pager")>
		</cfif>

		<cfif is_null(arguments.view)>
			<cfset arguments.view = static_("Config\Services").get("renderer")>
		</cfif>

		<cfreturn new_("ColdIgniter\Pager\Pager", arguments.config, arguments.view)>
	</cffunction>

	<!---
	 * The Parser is a simple template parser.
	 *
	 * Not ported yet: the file locator (service("locator")).
	--->
	<cffunction name="parser" access="public" returntype="any" output="no">
		<cfargument name="viewPath" type="string" required="no" default="">
		<cfargument name="config" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("parser", arguments.viewPath, arguments.config)>
		</cfif>

		<cfif arguments.viewPath EQ "" OR arguments.viewPath EQ "0">
			<cfset arguments.viewPath = new_("Config\Paths").viewDirectory>
		</cfif>
		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\View")>
		</cfif>

		<cfreturn new_("ColdIgniter\View\Parser", arguments.config, arguments.viewPath, "", request.CI_DEBUG, static_("Config\Services").get("logger"))>
	</cffunction>

	<!---
	 * The Renderer class is the class that actually displays a file to the user.
	 * The default View class within ColdIgniter is intentionally simple, but this
	 * service could easily be replaced by a template engine if the user needed to.
	--->
	<cffunction name="renderer" access="public" returntype="any" output="no">
		<cfargument name="viewPath" type="string" required="no" default="">
		<cfargument name="config" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("renderer", arguments.viewPath, arguments.config)>
		</cfif>

		<cfif arguments.viewPath EQ "" OR arguments.viewPath EQ "0">
			<cfset arguments.viewPath = new_("Config\Paths").viewDirectory>
		</cfif>
		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\View")>
		</cfif>

		<cfreturn new_("ColdIgniter\View\View", arguments.config, arguments.viewPath, "", request.CI_DEBUG, static_("Config\Services").get("logger"))>
	</cffunction>

	<!---
	 * Returns the current Request object.
	 *
	 * createRequest() injects IncomingRequest or CLIRequest.
	--->
	<cffunction name="request" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("request", arguments.config)>
		</cfif>

		<!--- @TODO remove the following code for backward compatibility --->
		<cfreturn static_("Config\Services").incomingrequest(arguments.config, arguments.getShared)>
	</cffunction>

	<!---
	 * Create the current Request object, either IncomingRequest or CLIRequest.
	 *
	 * This method is called from ColdIgniter::getRequestObject().
	--->
	<cffunction name="createRequest" access="public" returntype="void" output="no">
		<cfargument name="config" type="any" required="yes">
		<cfargument name="isCli" type="boolean" required="no" default="false">
		<cfset var request_ = "">

		<!--- Not ported yet: clirequest --->
		<cfset request_ = static_("Config\Services").incomingrequest(arguments.config, false)>

		<!--- guess at protocol if needed --->
		<cfset request_.setProtocolVersion(static_("Config\Services").superglobals().server("SERVER_PROTOCOL", "HTTP/1.1"))>

		<!--- Inject the request object into Services. --->
		<cfset this.instances["request"] = request_>
	</cffunction>

	<!---
	 * The IncomingRequest class models an HTTP request.
	--->
	<cffunction name="incomingrequest" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("request", arguments.config)>
		</cfif>

		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\App")>
		</cfif>

		<cfreturn new_("ColdIgniter\HTTP\IncomingRequest", arguments.config, static_("Config\Services").get("uri"), "", new_("ColdIgniter\HTTP\UserAgent"))>
	</cffunction>

	<!---
	 * The Response class models an HTTP response.
	--->
	<cffunction name="response" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("response", arguments.config)>
		</cfif>

		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\App")>
		</cfif>

		<cfreturn new_("ColdIgniter\HTTP\Response", arguments.config)>
	</cffunction>

	<!---
	 * The Redirect class provides nice way of working with redirects.
	--->
	<cffunction name="redirectresponse" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">
		<cfset var response = "">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("redirectresponse", arguments.config)>
		</cfif>

		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\App")>
		</cfif>

		<cfset response = new_("ColdIgniter\HTTP\RedirectResponse", arguments.config)>
		<cfset response.setProtocolVersion(static_("Config\Services").get("request").getProtocolVersion())>

		<cfreturn response>
	</cffunction>

	<!---
	 * The Routes service is a class that allows for easily building
	 * a collection of routes.
	--->
	<cffunction name="routes" access="public" returntype="any" output="no">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("routes")>
		</cfif>

		<cfreturn new_("ColdIgniter\Router\RouteCollection", "", new_("Config\Modules"), config("Config\Routing"))>
	</cffunction>

	<!---
	 * The Router class uses a RouteCollection's array of routes, and determines
	 * the correct Controller and Method to execute.
	--->
	<cffunction name="router" access="public" returntype="any" output="no">
		<cfargument name="routes" type="any" required="no" default="">
		<cfargument name="request_" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("router", arguments.routes, arguments.request_)>
		</cfif>

		<cfif is_null(arguments.routes)>
			<cfset arguments.routes = static_("Config\Services").get("routes")>
		</cfif>
		<cfif is_null(arguments.request_)>
			<cfset arguments.request_ = static_("Config\Services").get("request")>
		</cfif>

		<cfreturn new_("ColdIgniter\Router\Router", arguments.routes, arguments.request_)>
	</cffunction>

	<!---
	 * The Security class provides methods for handling CSRF protection.
	 *
	 * @param config The Config\Security, or an empty string (null)
	--->
	<cffunction name="security" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("security", arguments.config)>
		</cfif>

		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\Security")>
		</cfif>

		<cfreturn new_("ColdIgniter\Security\Security", arguments.config)>
	</cffunction>

	<!---
	 * Return the session manager.
	 *
	 * The session is started the first time it is asked for, so a request
	 * that never asks for it has no session, sends no session cookie and
	 * writes no file.
	 *
	 * Not ported yet: the MemcachedHandler and the RedisHandler, and the
	 * check that the driver is a session handler (any component that can be
	 * created is used; a handler is checked by the name of its base only).
	 *
	 * Difference: the Cache-Control header of the response is kept, as no
	 * engine sets one of its own for the session.
	 *
	 * Difference: the platform SQLSRV is also supported for the
	 * DatabaseHandler (SQLSRVHandler), as it is the only database here.
	--->
	<cffunction name="session" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">
		<cfset var logger = "">
		<cfset var driverName = "">
		<cfset var driver = "">
		<cfset var session_ = "">
		<cfset var DBGroup = "">
		<cfset var driverPlatform = "">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("session", arguments.config)>
		</cfif>

		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\Session")>
		</cfif>

		<cfset logger = static_("Config\Services").get("logger")>

		<cfset driverName = arguments.config.driver>

		<cfif Compare(driverName, "ColdIgniter\Session\Handlers\DatabaseHandler") EQ 0>
			<cfset DBGroup = arguments.config.DBGroup>

			<cfif is_null(DBGroup)>
				<cfset DBGroup = variables.config("Config\Database").defaultGroup>
			</cfif>

			<cfset driverPlatform = db_connect(DBGroup).getPlatform()>

			<cfif Compare(driverPlatform, "MySQLi") EQ 0>
				<cfset driverName = "ColdIgniter\Session\Handlers\Database\MySQLiHandler">
			<cfelseif Compare(driverPlatform, "Postgre") EQ 0>
				<cfset driverName = "ColdIgniter\Session\Handlers\Database\PostgreHandler">
			<cfelseif Compare(driverPlatform, "SQLSRV") EQ 0>
				<!--- Difference: the original supports MySQLi and Postgre only --->
				<cfset driverName = "ColdIgniter\Session\Handlers\Database\SQLSRVHandler">
			<cfelse>
				<cfthrow type="ColdIgniter.InvalidArgumentException" errorcode="500" message="Invalid session database handler ""#driverPlatform#"" provided. Only ""MySQLi"", ""Postgre"" and ""SQLSRV"" are supported.">
			</cfif>
		</cfif>

		<cfif NOT class_exists(driverName)>
			<cfthrow type="ColdIgniter.InvalidArgumentException" errorcode="500" message="Invalid session handler ""#driverName#"" provided.">
		</cfif>

		<cfset driver = new_(driverName, arguments.config, static_("Config\Services").get("request").getIPAddress())>

		<cfif NOT instanceof_(driver, "ColdIgniter\Session\Handlers\BaseHandler")>
			<cfthrow type="ColdIgniter.InvalidArgumentException" errorcode="500" message="Invalid session handler ""#driverName#"" provided.">
		</cfif>

		<cfset driver.setLogger(logger)>

		<cfset session_ = new_("ColdIgniter\Session\Session", driver, arguments.config)>
		<cfset session_.setLogger(logger)>

		<cfif Compare(session_status(), "none") EQ 0>
			<cfset session_.start()>
		</cfif>

		<cfreturn session_>
	</cffunction>

	<!---
	 * The Factory for SiteURI.
	--->
	<cffunction name="siteurifactory" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfargument name="superglobals" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("siteurifactory", arguments.config, arguments.superglobals)>
		</cfif>

		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("App")>
		</cfif>
		<cfif is_null(arguments.superglobals)>
			<cfset arguments.superglobals = static_("Config\Services").get("superglobals")>
		</cfif>

		<cfreturn new_("ColdIgniter\HTTP\SiteURIFactory", arguments.config, arguments.superglobals)>
	</cffunction>

	<!---
	 * Superglobals.
	--->
	<cffunction name="superglobals" access="public" returntype="any" output="no">
		<cfargument name="server" type="any" required="no" default="">
		<cfargument name="get" type="any" required="no" default="">
		<cfargument name="post" type="any" required="no" default="">
		<cfargument name="cookie" type="any" required="no" default="">
		<cfargument name="files" type="any" required="no" default="">
		<cfargument name="request_" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("superglobals", arguments.server, arguments.get, arguments.post, arguments.cookie, arguments.files, arguments.request_)>
		</cfif>

		<cfreturn new_("ColdIgniter\Superglobals", arguments.server, arguments.get, arguments.post, arguments.cookie, arguments.files, arguments.request_)>
	</cffunction>

	<!---
	 * The Timer class provides a simple way to Benchmark portions of your
	 * application.
	--->
	<cffunction name="timer" access="public" returntype="any" output="no">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("timer")>
		</cfif>

		<cfreturn new_("ColdIgniter\Debug\Timer")>
	</cffunction>

	<!---
	 * Return the debug toolbar.
	--->
	<cffunction name="toolbar" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("toolbar", arguments.config)>
		</cfif>

		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\Toolbar")>
		</cfif>

		<cfreturn new_("ColdIgniter\Debug\Toolbar", arguments.config)>
	</cffunction>

	<!---
	 * The URI class provides a way to model and manipulate URIs.
	--->
	<cffunction name="uri" access="public" returntype="any" output="no">
		<cfargument name="uri" type="string" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">
		<cfset var appConfig = "">
		<cfset var factory = "">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("uri", arguments.uri)>
		</cfif>

		<cfif is_null(arguments.uri)>
			<cfset appConfig = config("Config\App")>
			<cfset factory = static_("Config\Services").siteurifactory(appConfig, static_("Config\Services").get("superglobals"))>

			<cfreturn factory.createFromGlobals()>
		</cfif>

		<cfreturn new_("ColdIgniter\HTTP\URI", arguments.uri)>
	</cffunction>

	<!---
	 * The Validation class provides tools for validating input data.
	--->
	<cffunction name="validation" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfreturn getSharedInstance("validation", arguments.config)>
		</cfif>

		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\Validation")>
		</cfif>

		<cfreturn new_("ColdIgniter\Validation\Validation", arguments.config, static_("Config\Services").get("renderer"))>
	</cffunction>

</cfcomponent>
