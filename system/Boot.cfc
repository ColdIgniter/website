<!---
 * Bootstrap for the application
--->
<cfcomponent output="no" hint="Bootstrap for the application">

	<!---
	 * Not in the original. What the runtime keeps for one request: the
	 * global functions, the autoloader, the objects that stand in for
	 * static classes, the files that require_once() has loaded, the helpers
	 * that helper() has loaded (a static variable in the original), the options
	 * that ini_set() keeps, the environment values (what $_ENV, $_SERVER and
	 * getenv() hold), and the body that the response leaves for the
	 * front controller to print.
	--->
	<cfset request.ColdIgniter = StructNew()>
	<cfset request.ColdIgniter.functions = CreateObject("component", "Polyfills.Functions")>
	<!--- Difference: the functions of Polyfills.cfm are taken from that object, which has included the file, so the file is read once per request and not twice --->
	<cfset StructAppend(variables, request.ColdIgniter.functions.__functions(), false)>
	<cfset request.ColdIgniter.autoloader = "">
	<cfset request.ColdIgniter.statics = StructNew()>
	<cfset request.ColdIgniter.instanceofs = StructNew()>
	<cfset request.ColdIgniter.included = StructNew()>
	<cfset request.ColdIgniter.helpers = StructNew()>
	<cfset request.ColdIgniter.ini = StructNew()>
	<cfset request.ColdIgniter.env = StructNew()>
	<cfset request.ColdIgniter.output = "">
	<!--- the patterns that preg_pattern() has compiled in this request --->
	<cfset request.ColdIgniter.patterns = CreateObject("java", "java.util.HashMap").init()>

	<cfset define("DIRECTORY_SEPARATOR", Right(GetDirectoryFromPath(GetCurrentTemplatePath()), 1))>

	<!---
	 * The constants of the filters of filter_var() (see Polyfills/filter_var.cfm), with the values of the original.
	 * Not ported yet: FILTER_VALIDATE_DOMAIN, _MAC, FILTER_SANITIZE_STRING, FILTER_CALLBACK and the flags that filter_value_() does not read.
	--->
	<cfset request.FILTER_FLAG_NONE = 0>
	<cfset request.FILTER_REQUIRE_SCALAR = 33554432>
	<cfset request.FILTER_REQUIRE_ARRAY = 16777216>
	<cfset request.FILTER_FORCE_ARRAY = 67108864>
	<cfset request.FILTER_NULL_ON_FAILURE = 134217728>
	<cfset request.FILTER_VALIDATE_INT = 257>
	<cfset request.FILTER_VALIDATE_BOOLEAN = 258>
	<cfset request.FILTER_VALIDATE_BOOL = 258>
	<cfset request.FILTER_VALIDATE_FLOAT = 259>
	<cfset request.FILTER_VALIDATE_REGEXP = 272>
	<cfset request.FILTER_VALIDATE_URL = 273>
	<cfset request.FILTER_VALIDATE_EMAIL = 274>
	<cfset request.FILTER_VALIDATE_IP = 275>
	<cfset request.FILTER_DEFAULT = 516>
	<cfset request.FILTER_UNSAFE_RAW = 516>
	<cfset request.FILTER_SANITIZE_ENCODED = 514>
	<cfset request.FILTER_SANITIZE_SPECIAL_CHARS = 515>
	<cfset request.FILTER_SANITIZE_EMAIL = 517>
	<cfset request.FILTER_SANITIZE_URL = 518>
	<cfset request.FILTER_SANITIZE_NUMBER_INT = 519>
	<cfset request.FILTER_SANITIZE_NUMBER_FLOAT = 520>
	<cfset request.FILTER_SANITIZE_FULL_SPECIAL_CHARS = 522>
	<cfset request.FILTER_SANITIZE_ADD_SLASHES = 523>
	<cfset request.FILTER_FLAG_STRIP_LOW = 4>
	<cfset request.FILTER_FLAG_STRIP_HIGH = 8>
	<cfset request.FILTER_FLAG_STRIP_BACKTICK = 512>
	<cfset request.FILTER_FLAG_NO_ENCODE_QUOTES = 128>
	<cfset request.FILTER_FLAG_ALLOW_FRACTION = 4096>
	<cfset request.FILTER_FLAG_ALLOW_THOUSAND = 8192>
	<cfset request.FILTER_FLAG_ALLOW_SCIENTIFIC = 16384>
	<cfset request.FILTER_FLAG_IPV4 = 1048576>
	<cfset request.FILTER_FLAG_IPV6 = 2097152>
	<cfset request.FILTER_FLAG_NO_RES_RANGE = 4194304>
	<cfset request.FILTER_FLAG_NO_PRIV_RANGE = 8388608>
	<cfset request.FILTER_FLAG_GLOBAL_RANGE = 268435456>

	<!---
	 * Used by `public/index.cfm`
	 *
	 * Context
	 *   web:     Invoked by HTTP request
	 *
	 * @return int Exit code.
	--->
	<cffunction name="bootWeb" access="public" returntype="numeric" output="no">
		<cfargument name="paths" type="any" required="yes">
		<cfset var app = "">
		<cfset var uploadKey = "">
		<cfset var uploadList = "">

		<cfset definePathConstants(arguments.paths)>
		<cfif NOT defined("APP_NAMESPACE")>
			<cfset loadConstants()>
		</cfif>
		<!--- Not ported yet: checkMissingExtensions --->

		<cfset loadDotEnv(arguments.paths)>
		<cfset defineEnvironment()>
		<cfset loadEnvironmentBootstrap(arguments.paths)>

		<cfset loadCommonFunctions()>
		<cfset loadAutoloader()>
		<cfset setExceptionHandler()>
		<!--- Not ported yet: initializeKint --->
		<cfset autoloadHelpers()>

		<!---
		 There is no set_exception_handler, so the error that the
		 request ends with is caught here and passed to the handler
		 that setExceptionHandler() would have registered.
		--->
		<cftry>
			<cfset app = initializeColdIgniter()>
			<cfset runColdIgniter(app)>

			<!---
			 Difference: there is no exit, so exit_() throws ColdIgniter.Exit
			 and the request ends here, with the output that was set so far.
			--->
			<cfcatch type="ColdIgniter.Exit">
				<cfset request.ColdIgniter.exited = true>
			</cfcatch>

			<cfcatch type="any">
				<cftry>
					<cfset static_("Config\Services").exceptions().exceptionHandler(cfcatch)>

					<!---
					 An error in the handler itself must not reach the
					 error page of the server, which shows details.
					--->
					<cfcatch type="any">
						<cfheader statuscode="500" statustext="Internal Server Error">
						<cfset request.ColdIgniter.output = "<h1>500 - Internal Server Error</h1>">
					</cfcatch>
				</cftry>
			</cfcatch>
		</cftry>

		<!---
		 Difference: the saved files of the uploads of this request (see
		 Superglobals.readFiles()) are in a folder of their own in the temp
		 folder, which is removed here, as the files of an upload are
		 removed by the server at the end of the request in the original.
		--->
		<cfif StructKeyExists(request.ColdIgniter, "uploadDirs")>
			<cfloop collection="#request.ColdIgniter.uploadDirs#" item="uploadKey">
				<cftry>
					<!--- cfdirectory has no recurse here, and the folder is flat --->
					<cfdirectory action="list" directory="#request.ColdIgniter.uploadDirs[uploadKey]#" name="uploadList">

					<cfloop query="uploadList">
						<cfif uploadList.type EQ "File">
							<cffile action="delete" file="#request.ColdIgniter.uploadDirs[uploadKey]##uploadList.name#">
						</cfif>
					</cfloop>

					<cfdirectory action="delete" directory="#request.ColdIgniter.uploadDirs[uploadKey]#">

					<cfcatch type="any"></cfcatch>
				</cftry>
			</cfloop>
		</cfif>

		<!---
		 Exits the application, setting the exit code for CLI-based
		 applications that might be watching.
		--->
		<cfreturn request.EXIT_SUCCESS>
	</cffunction>

	<!---
	 * Load environment settings from .env files into the environment values
	 * (request.ColdIgniter.env, see Config/DotEnv.cfc)
	--->
	<cffunction name="loadDotEnv" access="private" returntype="void" output="no">
		<cfargument name="paths" type="any" required="yes">
		<cfset var dotEnv = request.ColdIgniter.functions.__inject(CreateObject("component", "Config.DotEnv"))>

		<!--- There is no require_once: the autoloader does not exist yet, so the file is created by hand. --->
		<cfset dotEnv.__construct(arguments.paths.envDirectory)>
		<cfset dotEnv.load()>
	</cffunction>

	<!---
	 * Difference: the order of the original is $_ENV, $_SERVER, getenv(),
	 * here only the values from the .env file are read. The CGI scope is not
	 * a source: a request header is read by name through it (verified on
	 * the server), so a client could set the environment with a header.
	--->
	<cffunction name="defineEnvironment" access="private" returntype="void" output="no">
		<cfset var env = "">

		<cfif NOT defined("ENVIRONMENT")>
			<cfif StructKeyExists(request.ColdIgniter.env, "CI_ENVIRONMENT")>
				<cfset env = request.ColdIgniter.env["CI_ENVIRONMENT"]>
			</cfif>
			<cfif Compare(env, "") EQ 0>
				<cfset env = "production">
			</cfif>

			<cfset define("ENVIRONMENT", env)>
		</cfif>
	</cffunction>

	<cffunction name="loadEnvironmentBootstrap" access="private" returntype="void" output="no">
		<cfargument name="paths" type="any" required="yes">
		<cfargument name="exit" type="boolean" required="no" default="true">

		<cfif is_file(arguments.paths.appDirectory & "/Config/Boot/" & request.ENVIRONMENT & ".cfm")>
			<cfinclude template="#includePath(arguments.paths.appDirectory & "/Config/Boot/" & request.ENVIRONMENT & ".cfm")#">

			<cfreturn>
		</cfif>

		<cfif arguments.exit>
			<cfheader statuscode="503" statustext="Service Unavailable">
			<cfset WriteOutput("The application environment is not set correctly.")>

			<!--- exit(EXIT_ERROR): a request has no exit code --->
			<cfabort>
		</cfif>
	</cffunction>

	<!---
	 * The path constants provide convenient access to the folders throughout
	 * the application. We have to set them up here, so they are available in
	 * the config files that are loaded.
	--->
	<cffunction name="definePathConstants" access="private" returntype="void" output="no">
		<cfargument name="paths" type="any" required="yes">
		<cfset var writePath = "">

		<!--- The path to the application directory. --->
		<cfif NOT defined("APPPATH")>
			<cfset define("APPPATH", realpath(REReplace(arguments.paths.appDirectory, "[\\/ ]+$", "")) & request.DIRECTORY_SEPARATOR)>
		</cfif>

		<!--- The path to the project root directory. Just above APPPATH. --->
		<cfif NOT defined("ROOTPATH")>
			<cfset define("ROOTPATH", realpath(request.APPPATH & "../") & request.DIRECTORY_SEPARATOR)>
		</cfif>

		<!--- The path to the system directory. --->
		<cfif NOT defined("SYSTEMPATH")>
			<cfset define("SYSTEMPATH", realpath(REReplace(arguments.paths.systemDirectory, "[\\/ ]+$", "")) & request.DIRECTORY_SEPARATOR)>
		</cfif>

		<!--- The path to the writable directory. --->
		<cfif NOT defined("WRITEPATH")>
			<cfset writePath = realpath(REReplace(arguments.paths.writableDirectory, "[\\/ ]+$", ""))>

			<cfif writePath EQ "">
				<cfheader statuscode="503" statustext="Service Unavailable">
				<cfset WriteOutput("The WRITEPATH is not set correctly.")>

				<!--- EXIT_ERROR is not yet defined --->
				<cfabort>
			</cfif>
			<cfset define("WRITEPATH", writePath & request.DIRECTORY_SEPARATOR)>
		</cfif>

		<!--- The path to the tests directory --->
		<cfif NOT defined("TESTPATH")>
			<cfset define("TESTPATH", realpath(REReplace(arguments.paths.testsDirectory, "[\\/ ]+$", "")) & request.DIRECTORY_SEPARATOR)>
		</cfif>
	</cffunction>

	<cffunction name="loadConstants" access="private" returntype="void" output="no">
		<cfinclude template="#includePath(request.APPPATH & "Config/Constants.cfm")#">
	</cffunction>

	<cffunction name="loadCommonFunctions" access="private" returntype="void" output="no">
		<!--- Require app/Common.cfm file if exists. --->
		<cfif is_file(request.APPPATH & "Common.cfm")>
			<cfset require_once(request.APPPATH & "Common.cfm")>
		</cfif>

		<!--- Require system/Common.cfm --->
		<cfset require_once(request.SYSTEMPATH & "Common.cfm")>
	</cffunction>

	<!---
	 * The autoloader allows all of the pieces to work together in the
	 * framework. We have to load it here, though, so that the config
	 * files can use the path constants.
	--->
	<cffunction name="loadAutoloader" access="private" returntype="void" output="no">
		<!---
		 A class file is not loaded ahead of time: the autoloader finds it
		 when an object is created. So where the original requires the
		 class files, a first autoloader is made here by hand, which only
		 knows the two namespaces that are needed to create the real one.
		--->
		<cfset var loader = request.ColdIgniter.functions.__inject(CreateObject("component", "Autoloader.Autoloader"))>

		<cfset loader.addNamespace("ColdIgniter", request.SYSTEMPATH)>
		<cfset loader.addNamespace("Config", request.APPPATH & "Config")>
		<cfset loader.register()>

		<!--- Initialize and register the loader with the SPL autoloader stack. --->
		<cfset static_("Config\Services").autoloader().initialize_(new_("Config\Autoload"), new_("Config\Modules")).register()>
	</cffunction>

	<cffunction name="autoloadHelpers" access="private" returntype="void" output="no">
		<cfset service("autoloader").loadHelpers()>
	</cffunction>

	<cffunction name="initializeColdIgniter" access="private" returntype="any" output="no">
		<cfset var app = static_("Config\Services").coldigniter()>
		<cfset app.initialize_()>

		<cfreturn app>
	</cffunction>

	<cffunction name="setExceptionHandler" access="private" returntype="void" output="no">
		<cfset static_("Config\Services").exceptions().initialize_()>
	</cffunction>

	<!---
	 * Now that everything is set up, it's time to actually fire
	 * up the engines and make this app do its thang.
	--->
	<cffunction name="runColdIgniter" access="private" returntype="void" output="no">
		<cfargument name="app" type="any" required="yes">

		<!--- Not ported yet: is_cli(), so the context is always "web" --->
		<cfset arguments.app.setContext("web")>

		<cfset arguments.app.run()>
	</cffunction>

</cfcomponent>
