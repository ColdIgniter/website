<!---
 * Class HTTPException
 *
 * Over time, we will add more and more exceptions to this file; for now it
 * has the ones for uploaded files.
 *
 * Not ported yet: the other methods of the original. The messages that the
 * rest of the port throws as "ColdIgniter.HTTP.Exceptions.HTTPException"
 * are written out where they are used.
 *
 * An exception is not an object here. The methods throw the exception
 * themselves, with the type "ColdIgniter.HTTP.Exceptions.HTTPException":
 *
 *     <cfset static_("ColdIgniter\HTTP\Exceptions\HTTPException").forAlreadyMoved()>
--->
<cfcomponent output="no" parent="ColdIgniter\Exceptions\FrameworkException" hint="HTTP exceptions">

	<!---
	 * For Uploaded file move
	--->
	<cffunction name="forAlreadyMoved" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.HTTP.Exceptions.HTTPException" errorcode="500" message="#lang("HTTP.alreadyMoved")#">
	</cffunction>

	<!---
	 * For Uploaded file move
	--->
	<cffunction name="forInvalidFile" access="public" returntype="void" output="no">
		<cfargument name="path" type="string" required="no" default="">

		<cfthrow type="ColdIgniter.HTTP.Exceptions.HTTPException" errorcode="500" message="#lang("HTTP.invalidFile")#">
	</cffunction>

	<!---
	 * For Uploaded file move
	--->
	<cffunction name="forMoveFailed" access="public" returntype="void" output="no">
		<cfargument name="source" type="string" required="yes">
		<cfargument name="target" type="string" required="yes">
		<cfargument name="error" type="string" required="yes">
		<cfset var args = ArrayNew(1)>

		<cfset ArrayAppend(args, arguments.source)>
		<cfset ArrayAppend(args, arguments.target)>
		<cfset ArrayAppend(args, arguments.error)>

		<cfthrow type="ColdIgniter.HTTP.Exceptions.HTTPException" errorcode="500" message="#lang("HTTP.moveFailed", args)#">
	</cffunction>

</cfcomponent>
