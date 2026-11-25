<!---
 * FileNotFoundException is thrown for a file that does not exist.
 *
 * An exception is not an object here. The method throws the exception
 * itself, with the type "ColdIgniter.Files.Exceptions.FileNotFoundException":
 *
 *     <cfset static_("ColdIgniter\Files\Exceptions\FileNotFoundException").forFileNotFound(path)>
--->
<cfcomponent output="no" parent="ColdIgniter\Exceptions\FrameworkException" hint="File not found exception">

	<cffunction name="forFileNotFound" access="public" returntype="void" output="no">
		<cfargument name="path" type="string" required="yes">
		<cfset var args = ArrayNew(1)>

		<cfset ArrayAppend(args, arguments.path)>

		<cfthrow type="ColdIgniter.Files.Exceptions.FileNotFoundException" errorcode="500" message="#lang("Files.fileNotFound", args)#">
	</cffunction>

</cfcomponent>
