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
 * Warning: To allow overrides by service providers do not use static calls,
 * instead call out to \Config\Services (imported as AppServices).
 *
 * The class is static in the original. Here it is used through
 * static_("Config\Services"), which is the AppServices of the original.
 *
 * Not ported yet: service discovery in modules, mocks, reset, locator,
 * and the lower-case lookup of __callStatic.
--->
<cfcomponent output="no" hint="Services Configuration file">

	<!---
	 * Cache for instance of any services that
	 * have been requested as a "shared" instance.
	 * Keys should be lowercase service names.
	--->
	<cfset this.instances = StructNew()>

	<!---
	 * Simple method to get an entry fast.
	 *
	 * @param key Identifier of the entry to look for.
	 *
	 * @return The entry, or an empty string if it does not exist.
	--->
	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">

		<cfif StructKeyExists(this.instances, arguments.key)>
			<cfreturn this.instances[arguments.key]>
		</cfif>

		<cfreturn __callStatic(arguments.key, ArrayNew(1))>
	</cffunction>

	<!---
	 * Checks if a service instance has been created.
	 *
	 * @param key Identifier of the entry to check.
	--->
	<cffunction name="has" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="string" required="yes">

		<cfreturn StructKeyExists(this.instances, arguments.key)>
	</cffunction>

	<!---
	 * Returns a shared instance of any of the class' services.
	 *
	 * getSharedInstance(key, param, param, ...)
	 *
	 * $key must be a name matching a service.
	--->
	<cffunction name="getSharedInstance" access="private" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfset var call = "">
		<cfset var i = 0>

		<cfset arguments.key = LCase(arguments.key)>

		<cfif NOT StructKeyExists(this.instances, arguments.key)>
			<!--- Make sure $getShared is false --->
			<cfloop from="2" to="#ArrayLen(arguments)#" index="i">
				<cfset call = ListAppend(call, "arguments[#i#]")>
			</cfloop>
			<cfset call = ListAppend(call, "false")>

			<!--- Called through "this": a service named like a scope (request) cannot be called without it. --->
			<cfset this.instances[arguments.key] = Evaluate("this.#arguments.key#(#call#)")>
		</cfif>

		<cfreturn this.instances[arguments.key]>
	</cffunction>

	<!---
	 * The Autoloader class is the central class that handles our
	 * spl_autoload_register method, and helper methods.
	--->
	<cffunction name="autoloader" access="public" returntype="any" output="no">
		<cfargument name="getShared" type="boolean" required="no" default="true">

		<cfif arguments.getShared>
			<cfif NOT StructKeyExists(this.instances, "autoloader")>
				<cfset this.instances["autoloader"] = new_("ColdIgniter\Autoloader\Autoloader")>
			</cfif>

			<cfreturn this.instances["autoloader"]>
		</cfif>

		<cfreturn new_("ColdIgniter\Autoloader\Autoloader")>
	</cffunction>

	<!---
	 * Provides the ability to perform case-insensitive calling of service
	 * names.
	 *
	 * @return The service, or an empty string if there is none of that name.
	--->
	<cffunction name="__callStatic" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="arguments_" type="array" required="yes">
		<cfset var call = "">
		<cfset var i = 0>

		<cfif NOT StructKeyExists(this, arguments.name) OR NOT IsCustomFunction(this[arguments.name])>
			<cfreturn "">
		</cfif>

		<cfloop from="1" to="#ArrayLen(arguments.arguments_)#" index="i">
			<cfset call = ListAppend(call, "arguments.arguments_[#i#]")>
		</cfloop>

		<cfreturn Evaluate("this.#arguments.name#(#call#)")>
	</cffunction>

</cfcomponent>
