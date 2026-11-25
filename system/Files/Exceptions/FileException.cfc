<!---
 * FileException is thrown for a file that cannot be moved or is not what
 * was expected.
 *
 * An exception is not an object here. The methods throw the exception
 * themselves, with the type "ColdIgniter.Files.Exceptions.FileException":
 *
 *     <cfset static_("ColdIgniter\Files\Exceptions\FileException").forUnableToMove(from, to, error)>
 *
 * Difference: the original makes an exception of the class it is called on
 * ("static"); the type is always the one of this class.
 *
 * Not ported yet: forExpectedDirectory() and forExpectedFile(), which
 * belong to the file collection of the Files folder.
--->
<cfcomponent output="no" parent="ColdIgniter\Exceptions\FrameworkException" hint="File exceptions">

	<cffunction name="forUnableToMove" access="public" returntype="void" output="no">
		<cfargument name="from" type="string" required="no" default="">
		<cfargument name="to" type="string" required="no" default="">
		<cfargument name="error" type="string" required="no" default="">
		<cfset var args = ArrayNew(1)>

		<cfset ArrayAppend(args, arguments.from)>
		<cfset ArrayAppend(args, arguments.to)>
		<cfset ArrayAppend(args, arguments.error)>

		<cfthrow type="ColdIgniter.Files.Exceptions.FileException" errorcode="500" message="#lang("Files.cannotMove", args)#">
	</cffunction>

</cfcomponent>
