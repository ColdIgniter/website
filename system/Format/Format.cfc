<!---
 * Class Format
 *
 * The Format class is a convenient place to create Formatters.
 *
 * Difference: the property config is read as this.config, and
 * getFormatter() gives the formatter without a type check by the language:
 * instanceof_() matches FormatterInterface by its short name. A class that
 * has no component is not a valid Formatter class.
--->
<cfcomponent output="no" hint="A convenient place to create Formatters">

	<!---
	 * @param config The Config\Format
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">

		<cfset this.config = arguments.config>

		<cfreturn this>
	</cffunction>

	<!---
	 * Returns the current configuration instance.
	--->
	<cffunction name="getConfig" access="public" returntype="any" output="no">

		<cfreturn this.config>
	</cffunction>

	<!---
	 * A Factory method to return the appropriate formatter for the given mime type.
	 *
	 * @throws FormatException
	--->
	<cffunction name="getFormatter" access="public" returntype="any" output="no">
		<cfargument name="mime" type="string" required="yes">
		<cfset var className = "">
		<cfset var class_ = "">

		<cfif NOT array_key_exists(arguments.mime, this.config.formatters)>
			<cfset static_("ColdIgniter\Format\Exceptions\FormatException").forInvalidMime(arguments.mime)>
		</cfif>

		<cfset className = this.config.formatters[arguments.mime]>

		<cfif NOT class_exists(className)>
			<cfset static_("ColdIgniter\Format\Exceptions\FormatException").forInvalidFormatter(className)>
		</cfif>

		<cfset class_ = new_(className)>

		<cfif NOT instanceof_(class_, "ColdIgniter\Format\FormatterInterface")>
			<cfset static_("ColdIgniter\Format\Exceptions\FormatException").forInvalidFormatter(className)>
		</cfif>

		<cfreturn class_>
	</cffunction>

</cfcomponent>
