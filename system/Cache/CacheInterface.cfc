<!---
 * Cache interface
 *
 * Difference: there are no interfaces; this component holds the methods,
 * each of which throws, and BaseHandler extends it. The doc comments of the
 * original are kept on the handlers.
 *
 * Difference: initialize() is initialize_() and getMetaData() is
 * getMetaData_(), as both names are built-in functions. A null is an empty
 * string (see is_null()), so get() returns an empty string for a missing
 * key, and a callback is the callable form [object, "method"].
--->
<cfcomponent output="no" hint="Cache interface">

	<cffunction name="notImplemented" access="private" returntype="void" output="no">
		<cfthrow type="ColdIgniter.Exceptions.FrameworkException" errorcode="500" message="Method not implemented by the cache handler.">
	</cffunction>

	<!---
	 * Takes care of any handler-specific setup that must be done.
	--->
	<cffunction name="initialize_" access="public" returntype="void" output="no">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Attempts to fetch an item from the cache store.
	 *
	 * @param key Cache item name
	 *
	 * @return The value, or an empty string (null) when it is not found
	--->
	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Saves an item to the cache store.
	 *
	 * The $raw parameter is only utilized by Mamcache in order to
	 * allow usage of increment() and decrement().
	 *
	 * @param key   Cache item name
	 * @param value The data to save
	 * @param ttl   Time To Live, in seconds (default 60)
	 *
	 * @return Success or failure
	--->
	<cffunction name="save" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="ttl" type="numeric" required="no" default="60">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Get an item from the cache, or execute the callback
	 * and save the result to the cache for the specified TTL.
	 *
	 * @param key      Cache item name
	 * @param ttl      Time To Live, in seconds
	 * @param callback The callable form [object, "method"]
	--->
	<cffunction name="remember" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="ttl" type="numeric" required="yes">
		<cfargument name="callback" type="any" required="yes">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Deletes a specific item from the cache store.
	 *
	 * @param key Cache item name
	 *
	 * @return Success or failure
	--->
	<cffunction name="delete" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Deletes items from the cache store matching a given pattern.
	 *
	 * @param pattern Cache items glob-style pattern
	 *
	 * @return The number of deleted items
	--->
	<cffunction name="deleteMatching" access="public" returntype="numeric" output="no">
		<cfargument name="pattern" type="string" required="yes">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Performs atomic incrementation of a raw stored value.
	 *
	 * @param key    Cache ID
	 * @param offset Step/value to increase by
	 *
	 * @return The new value, or false
	--->
	<cffunction name="increment" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="offset" type="numeric" required="no" default="1">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Performs atomic decrementation of a raw stored value.
	 *
	 * @param key    Cache ID
	 * @param offset Step/value to increase by
	 *
	 * @return The new value, or false
	--->
	<cffunction name="decrement" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="offset" type="numeric" required="no" default="1">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Will delete all items in the entire cache.
	 *
	 * @return Success or failure
	--->
	<cffunction name="clean" access="public" returntype="boolean" output="no">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Returns information on the entire cache.
	 *
	 * The information returned and the structure of the data
	 * varies depending on the handler.
	 *
	 * @return A map of the cache items, or an empty string (null)
	--->
	<cffunction name="getCacheInfo" access="public" returntype="any" output="no">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Returns detailed information about the specific item in the cache.
	 *
	 * @param key Cache item name.
	 *
	 * @return A map with expire, mtime and data, or an empty string (null)
	 *         when the item is not found
	--->
	<cffunction name="getMetaData_" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Determines if the driver is supported on this system.
	--->
	<cffunction name="isSupported" access="public" returntype="boolean" output="no">
		<cfset notImplemented()>
	</cffunction>

</cfcomponent>
