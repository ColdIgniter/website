<!---
 * Session handler for Postgre
 *
 * Difference: the original extends DatabaseHandler. This class is in
 * another folder, so it is mixed in with parent (see the reference, "How
 * components are located").
 *
 * Difference: the original base64_decode() and bin2hex() of a string are
 * written with the Java classes: the text is taken as UTF-8 bytes, and
 * decodeData() gives false for text that is not base64, as the strict
 * mode of base64_decode() does.
 *
 * Difference: the lock is the text of the argument list of the advisory
 * lock, as in the original, and a failed query is the text "false".
--->
<cfcomponent output="no" parent="ColdIgniter\Session\Handlers\DatabaseHandler" hint="Session handler for Postgre">

	<!---
	 * Sets SELECT clause
	--->
	<cffunction name="setSelect" access="private" returntype="void" output="no">
		<cfargument name="builder" type="any" required="yes">

		<cfset arguments.builder.select("encode(data, 'base64') AS data")>
	</cffunction>

	<!---
	 * Decodes column data
	 *
	 * @param data
	 *
	 * @return false|string
	--->
	<cffunction name="decodeData" access="private" returntype="any" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfset var text = Replace(Replace(rtrim_(arguments.data), Chr(10), "", "all"), Chr(13), "", "all")>
		<cfset var bytes = "">

		<cfif NOT Len(text)>
			<cfreturn "">
		</cfif>

		<cfif REFind("^[A-Za-z0-9+/]*={0,2}$", text) EQ 0>
			<cfreturn false>
		</cfif>

		<cfset bytes = ToBinary(text)>

		<cfreturn CreateObject("java", "java.lang.String").init(bytes, JavaCast("string", "UTF-8"))>
	</cffunction>

	<!---
	 * Prepare data to insert/update
	--->
	<cffunction name="prepareData" access="private" returntype="string" output="no">
		<cfargument name="data" type="string" required="yes">

		<cfreturn "\x" & bin2hex(JavaCast("string", arguments.data).getBytes("UTF-8"))>
	</cffunction>

	<!---
	 * Cleans up expired sessions.
	 *
	 * @param max_lifetime Sessions that have not updated
	 *                     for the last max_lifetime seconds will be removed.
	 *
	 * @return false|int
	--->
	<cffunction name="gc" access="public" returntype="any" output="no">
		<cfargument name="max_lifetime" type="numeric" required="yes">
		<cfset var interval = "'" & arguments.max_lifetime & " second'">

		<cfif identical_(this.db.table(this.table).where("timestamp <", "now() - INTERVAL " & interval, false).delete(), "false")>
			<cfreturn fail()>
		</cfif>

		<cfreturn 1>
	</cffunction>

	<!---
	 * Lock the session.
	--->
	<cffunction name="lockSession" access="private" returntype="boolean" output="no">
		<cfargument name="sessionID" type="string" required="yes">
		<cfset var arg = "hashtext('" & arguments.sessionID & "')">

		<cfif this.matchIP>
			<cfset arg = arg & ", hashtext('" & this.ipAddress & "')">
		</cfif>

		<cfif NOT identical_(this.db.simpleQuery("SELECT pg_advisory_lock(" & arg & ")"), "false")>
			<cfset this.lock = arg>

			<cfreturn true>
		</cfif>

		<cfreturn fail()>
	</cffunction>

	<!---
	 * Releases the lock, if any.
	--->
	<cffunction name="releaseLock" access="private" returntype="boolean" output="no">

		<cfif NOT hasLock_()>
			<cfreturn true>
		</cfif>

		<cfif NOT identical_(this.db.simpleQuery("SELECT pg_advisory_unlock(" & this.lock & ")"), "false")>
			<cfset this.lock = false>

			<cfreturn true>
		</cfif>

		<cfreturn fail()>
	</cffunction>

</cfcomponent>
