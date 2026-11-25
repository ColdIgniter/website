<!---
 * PagerException is thrown for a template or a group the Pager does not know.
 *
 * An exception is not an object here. The methods throw the exception
 * themselves, with the type "ColdIgniter.Pager.Exceptions.PagerException":
 *
 *     <cfset static_("ColdIgniter\Pager\Exceptions\PagerException").forInvalidTemplate(template)>
 *
 * Difference: the original makes an exception of the class it is called on
 * ("static"); the type is always the one of this class.
--->
<cfcomponent output="no" parent="ColdIgniter\Exceptions\FrameworkException" hint="Pager exceptions">

	<!---
	 * Throws when the template is invalid.
	--->
	<cffunction name="forInvalidTemplate" access="public" returntype="void" output="no">
		<cfargument name="template" type="string" required="no" default="">
		<cfset var args = ArrayNew(1)>

		<cfset ArrayAppend(args, arguments.template)>

		<cfthrow type="ColdIgniter.Pager.Exceptions.PagerException" errorcode="500" message="#lang("Pager.invalidTemplate", args)#">
	</cffunction>

	<!---
	 * Throws when the group is invalid.
	--->
	<cffunction name="forInvalidPaginationGroup" access="public" returntype="void" output="no">
		<cfargument name="group" type="string" required="no" default="">
		<cfset var args = ArrayNew(1)>

		<cfset ArrayAppend(args, arguments.group)>

		<cfthrow type="ColdIgniter.Pager.Exceptions.PagerException" errorcode="500" message="#lang("Pager.invalidPaginationGroup", args)#">
	</cffunction>

</cfcomponent>
