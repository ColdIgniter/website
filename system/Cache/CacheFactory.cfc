<!---
 * A factory for loading the desired
 *
 * Difference: the properties are read on the object that static_() gives.
 *
 * Not ported yet: the handlers apcu, memcached, predis, redis and wincache
 * (the map validHandlers of the Cache config lists the ones that exist),
 * and MockCache, so mockClass names a class that does not exist yet.
--->
<cfcomponent output="no" hint="A factory for loading the desired">

	<!---
	 * The class to use when mocking
	 *
	 * Not ported yet: MockCache.
	 *
	 * @var string
	--->
	<cfset this.mockClass = "ColdIgniter\Cache\MockCache">

	<!---
	 * The service to inject the mock as
	 *
	 * @var string
	--->
	<cfset this.mockServiceName = "cache">

	<!---
	 * Attempts to create the desired cache handler, based upon the
	 *
	 * @param config  The Cache config
	 * @param handler A handler name, or an empty string (null)
	 * @param backup  A handler name, or an empty string (null)
	 *
	 * @return CacheInterface
	--->
	<cffunction name="getHandler" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">
		<cfargument name="handler" type="string" required="no" default="">
		<cfargument name="backup" type="string" required="no" default="">
		<cfset var adapter = "">
		<cfset var critical = false>
		<cfset var message = "">

		<cfif arguments.config.validHandlers.size() EQ 0>
			<cfset static_("ColdIgniter\Cache\Exceptions\CacheException").forInvalidHandlers()>
		</cfif>

		<cfif is_null(arguments.handler)>
			<cfset arguments.handler = arguments.config.handler>
		</cfif>

		<cfif is_null(arguments.backup)>
			<cfset arguments.backup = arguments.config.backupHandler>
		</cfif>

		<cfif NOT arguments.config.validHandlers.containsKey(arguments.handler) OR NOT arguments.config.validHandlers.containsKey(arguments.backup)>
			<cfset static_("ColdIgniter\Cache\Exceptions\CacheException").forHandlerNotFound()>
		</cfif>

		<cfset adapter = new_(arguments.config.validHandlers.get(arguments.handler), arguments.config)>

		<cfif NOT adapter.isSupported()>
			<cfset adapter = new_(arguments.config.validHandlers.get(arguments.backup), arguments.config)>

			<cfif NOT adapter.isSupported()>
				<!--- Fall back to the dummy adapter. --->
				<cfset adapter = new_(arguments.config.validHandlers.get("dummy"))>
			</cfif>
		</cfif>

		<!---
		 If adapter.initialize_() throws a CriticalError exception, we will attempt to
		 use the backup handler, if that also fails, we resort to the dummy handler.
		 Difference: no handler that is ported throws it.
		--->
		<cftry>
			<cfset adapter.initialize_()>

			<cfcatch type="ColdIgniter.Exceptions.CriticalError">
				<cfset critical = true>
				<cfset message = cfcatch.message>
			</cfcatch>
		</cftry>

		<cfif critical>
			<cfset log_message("critical", message & " Resorting to using " & arguments.backup & " handler.")>

			<!--- get the next best cache handler (or dummy if the backup also fails) --->
			<cfset adapter = getHandler(arguments.config, arguments.backup, "dummy")>
		</cfif>

		<cfreturn adapter>
	</cffunction>

</cfcomponent>
