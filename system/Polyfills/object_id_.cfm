<!---
 * Not in the original: gives a new id for an object. The object keeps the
 * id and compares it where the original uses spl_object_id() or the
 * identity operator (CFML has neither).
 *
 * The id is a counter of the request, so it is unique among the objects
 * of one request only. CreateUUID() is not used: it waits for the next
 * tick of the clock (about 15 ms on Windows) on every call.
--->
<cffunction name="object_id_" returntype="string" output="no" hint="Gives a new id for an object">

	<cfif NOT StructKeyExists(request.ColdIgniter, "objectId")>
		<cfset request.ColdIgniter.objectId = 0>
	</cfif>
	<cfset request.ColdIgniter.objectId = request.ColdIgniter.objectId + 1>

	<cfreturn JavaCast("string", request.ColdIgniter.objectId)>
</cffunction>
