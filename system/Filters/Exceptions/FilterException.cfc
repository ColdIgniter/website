<!---
 * FilterException
 *
 * Not ported yet: the messages come from the language files in the
 * original (Filters.noFilter and Filters.incorrectInterface); they are
 * written out here until the language service is ported. The original
 * extends ConfigException, which is not ported either.
 *
 * An exception is not an object here. The methods throw the exception
 * themselves, with the type "ColdIgniter.Filters.Exceptions.FilterException":
 *
 *     <cfset static_("ColdIgniter\Filters\Exceptions\FilterException").forNoAlias(alias)>
--->
<cfcomponent output="no" hint="FilterException">

	<!---
	 * Thrown when the provided alias is not within
	 * the list of configured filter aliases.
	--->
	<cffunction name="forNoAlias" access="public" returntype="void" output="no">
		<cfargument name="alias" type="string" required="yes">

		<cfthrow type="ColdIgniter.Filters.Exceptions.FilterException" errorcode="500" message="""#arguments.alias#"" filter must have a matching alias defined.">
	</cffunction>

	<!---
	 * Thrown when the filter class does not implement FilterInterface.
	--->
	<cffunction name="forIncorrectInterface" access="public" returntype="void" output="no">
		<cfargument name="class" type="string" required="yes">

		<cfthrow type="ColdIgniter.Filters.Exceptions.FilterException" errorcode="500" message="""#arguments.class#"" must implement ColdIgniter\Filters\FilterInterface.">
	</cffunction>

</cfcomponent>
