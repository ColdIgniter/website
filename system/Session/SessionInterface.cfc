<!---
 * Expected behavior of a session container used with ColdIgniter.
 *
 * Difference: there are no interfaces; this component holds the methods,
 * each of which throws, and Session extends it. The doc comments of the
 * original are kept on Session.
--->
<cfcomponent output="no" hint="Expected behavior of a session container used with ColdIgniter">

	<cffunction name="notImplemented" access="private" returntype="void" output="no">
		<cfthrow type="ColdIgniter.Exceptions.FrameworkException" errorcode="500" message="Method not implemented by the session container.">
	</cffunction>

	<!---
	 * Regenerates the session ID.
	 *
	 * @param destroy Should old session data be destroyed?
	--->
	<cffunction name="regenerate" access="public" returntype="void" output="no">
		<cfargument name="destroy" type="boolean" required="no" default="false">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Destroys the current session.
	--->
	<cffunction name="destroy" access="public" returntype="void" output="no">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Sets user data into the session.
	--->
	<cffunction name="set" access="public" returntype="void" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfargument name="value" type="any" required="no" default="">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Get user data that has been set in the session.
	--->
	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="no" default="">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Returns whether an index exists in the session array.
	--->
	<cffunction name="has" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Remove one or more session properties.
	--->
	<cffunction name="remove" access="public" returntype="void" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Sets data into the session that will only last for a single request.
	--->
	<cffunction name="setFlashdata" access="public" returntype="void" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfargument name="value" type="any" required="no" default="">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Retrieve one or more items of flash data from the session.
	--->
	<cffunction name="getFlashdata" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="no" default="">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Keeps a single piece of flash data alive for one more request.
	--->
	<cffunction name="keepFlashdata" access="public" returntype="void" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Mark a session property or properties as flashdata. This returns
	 * `false` if any of the properties were not already set.
	--->
	<cffunction name="markAsFlashdata" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Unmark data in the session as flashdata.
	--->
	<cffunction name="unmarkFlashdata" access="public" returntype="void" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Retrieve all of the keys for session data marked as flashdata.
	--->
	<cffunction name="getFlashKeys" access="public" returntype="array" output="no">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Sets new data into the session, and marks it as temporary data
	 * with a set lifespan.
	--->
	<cffunction name="setTempdata" access="public" returntype="void" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfargument name="value" type="any" required="no" default="">
		<cfargument name="ttl" type="numeric" required="no" default="300">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Returns either a single piece of tempdata, or all temp data currently
	 * in the session.
	--->
	<cffunction name="getTempdata" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="no" default="">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Removes a single piece of temporary data from the session.
	--->
	<cffunction name="removeTempdata" access="public" returntype="void" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Mark one of more pieces of data as being temporary, meaning that
	 * it has a set lifespan within the session.
	 *
	 * Returns `false` if any of the properties were not set.
	--->
	<cffunction name="markAsTempdata" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfargument name="ttl" type="numeric" required="no" default="300">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Unmarks temporary data in the session, effectively removing its
	 * lifespan and allowing it to live as long as the session does.
	--->
	<cffunction name="unmarkTempdata" access="public" returntype="void" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfset notImplemented()>
	</cffunction>

	<!---
	 * Retrieve the keys of all session data that have been marked as temporary data.
	--->
	<cffunction name="getTempKeys" access="public" returntype="array" output="no">
		<cfset notImplemented()>
	</cffunction>

</cfcomponent>
