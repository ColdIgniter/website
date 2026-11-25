<cfcomponent output="no" extends="BaseController">

	<cffunction name="index" access="public" returntype="string" output="no">
		<cfreturn view("welcome_message")>
	</cffunction>

</cfcomponent>
