<!---
 * Cache exceptions.
 *
 * An exception is not an object here. The methods throw the exception
 * themselves, with the type "ColdIgniter.Cache.Exceptions.CacheException":
 *
 *     <cfset static_("ColdIgniter\Cache\Exceptions\CacheException").forUnableToWrite(path)>
 *
 * The messages come from the language file Language/en/Cache.cfm.
 *
 * Not ported yet: DebugTraceableTrait.
--->
<cfcomponent output="no" hint="Cache exceptions">

	<cffunction name="forUnableToWrite" access="public" returntype="void" output="no">
		<cfargument name="path" type="string" required="yes">
		<cfset var parameters = ArrayNew(1)>

		<cfset ArrayAppend(parameters, arguments.path)>
		<cfthrow type="ColdIgniter.Cache.Exceptions.CacheException" errorcode="500" message="#lang('Cache.unableToWrite', parameters)#">
	</cffunction>

	<cffunction name="forInvalidHandlers" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Cache.Exceptions.CacheException" errorcode="500" message="#lang('Cache.invalidHandlers')#">
	</cffunction>

	<cffunction name="forNoBackup" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Cache.Exceptions.CacheException" errorcode="500" message="#lang('Cache.noBackup')#">
	</cffunction>

	<cffunction name="forHandlerNotFound" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Cache.Exceptions.CacheException" errorcode="500" message="#lang('Cache.handlerNotFound')#">
	</cffunction>

</cfcomponent>
