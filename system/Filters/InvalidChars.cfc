<!---
 * InvalidChars filter.
 *
 * Check if user input data (GET, POST, cookies, the raw input) do not contain
 * invalid characters:
 *   - invalid UTF-8 characters
 *   - control characters except line break and tab code
 *
 * Difference: the engine decodes the input before this filter sees it,
 * and a byte that is not valid UTF-8 is already the replacement character
 * (U+FFFD) in the value. That character is what is looked for, so the
 * check also refuses input that really holds U+FFFD.
--->
<cfcomponent output="no" extends="FilterInterface" hint="InvalidChars filter">

	<!---
	 * Data source
	--->
	<cfset this.source = "">

	<!---
	 * Regular expression for valid control codes. It is a Java regular
	 * expression that has to match the whole string. As the original, which
	 * uses [:^cntrl:] with the u modifier (Unicode property mode), it
	 * refuses every character of the Cc category, so also U+0080 to U+009F,
	 * and lets carriage return, line feed and tab through.
	--->
	<cfset this.controlCodeRegex = "[\r\n\t\P{Cc}]*">

	<!---
	 * Check invalid characters.
	 *
	 * @param arguments_ An empty string, or a list of strings
	--->
	<cffunction name="before" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="arguments_" type="any" required="no" default="">
		<cfset var data = "">
		<cfset var source = "">

		<cfif NOT instanceof_(arguments.request_, "ColdIgniter\HTTP\IncomingRequest")>
			<cfreturn "">
		</cfif>

		<cfset data = array_("get", arguments.request_.getGet(), "post", arguments.request_.getPost(), "cookie", arguments.request_.getCookie(), "rawInput", arguments.request_.getRawInput())>

		<cfloop collection="#data#" item="source">
			<cfset this.source = source>
			<cfset checkEncoding(data[source])>
			<cfset checkControl(data[source])>
		</cfloop>

		<cfreturn "">
	</cffunction>

	<!---
	 * We don't have anything to do here.
	 *
	 * @param arguments_ An empty string, or a list of strings
	--->
	<cffunction name="after" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="response" type="any" required="yes">
		<cfargument name="arguments_" type="any" required="no" default="">

		<cfreturn "">
	</cffunction>

	<!---
	 * Check the character encoding is valid UTF-8. A map or a list is
	 * checked in all of its values, and the keys of a map.
	 *
	 * @param value A map, a list or a string
	--->
	<cffunction name="checkEncoding" access="private" returntype="void" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfset var key = "">
		<cfset var i = 0>

		<cfif IsArray(arguments.value)>
			<cfloop from="1" to="#ArrayLen(arguments.value)#" index="i">
				<cfset checkEncoding(arguments.value[i])>
			</cfloop>

			<cfreturn>
		</cfif>

		<cfif IsStruct(arguments.value)>
			<cfloop collection="#arguments.value#" item="key">
				<cfset checkEncoding(key)>
				<cfset checkEncoding(arguments.value[key])>
			</cfloop>

			<cfreturn>
		</cfif>

		<cfif NOT IsSimpleValue(arguments.value)>
			<cfreturn>
		</cfif>

		<cfif Find(Chr(65533), arguments.value) GT 0>
			<cfset static_("ColdIgniter\Security\Exceptions\SecurityException").forInvalidUTF8Chars(this.source, arguments.value)>
		</cfif>
	</cffunction>

	<!---
	 * Check for the presence of control characters except line breaks and tabs.
	 *
	 * @param value A map, a list or a string
	--->
	<cffunction name="checkControl" access="private" returntype="void" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfset var pattern = CreateObject("java", "java.util.regex.Pattern")>
		<cfset var key = "">
		<cfset var i = 0>

		<cfif IsArray(arguments.value)>
			<cfloop from="1" to="#ArrayLen(arguments.value)#" index="i">
				<cfset checkControl(arguments.value[i])>
			</cfloop>

			<cfreturn>
		</cfif>

		<cfif IsStruct(arguments.value)>
			<cfloop collection="#arguments.value#" item="key">
				<cfset checkControl(key)>
				<cfset checkControl(arguments.value[key])>
			</cfloop>

			<cfreturn>
		</cfif>

		<cfif NOT IsSimpleValue(arguments.value)>
			<cfreturn>
		</cfif>

		<cfif NOT pattern.matches(this.controlCodeRegex, JavaCast("string", arguments.value))>
			<cfset static_("ColdIgniter\Security\Exceptions\SecurityException").forInvalidControlChars(this.source, arguments.value)>
		</cfif>
	</cffunction>

</cfcomponent>
