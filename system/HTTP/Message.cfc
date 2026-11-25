<!---
 * An HTTP message
 *
 * A header is a Header object, or an array of Header objects for several
 * headers of the same name (addHeader).
--->
<cfcomponent output="no" hint="An HTTP message">

	<!---
	 * List of all HTTP request headers.
	 *
	 * [name => Header|Header[]]
	 *
	 * Named with an underscore, because headers() is a method.
	--->
	<cfset this.headers_ = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Holds a map of lower-case header names
	 * and their normal-case key as it is in headers.
	 * Used for case-insensitive header access.
	--->
	<cfset this.headerMap = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Protocol version
	--->
	<cfset this.protocolVersion = "">

	<!---
	 * List of valid protocol versions
	--->
	<cfset this.validProtocolVersions = "1.0,1.1,2.0,3.0">

	<!---
	 * Message body
	--->
	<cfset this.body = "">

	<!---
	 * Returns the Message's body.
	--->
	<cffunction name="getBody" access="public" returntype="any" output="no">
		<cfreturn this.body>
	</cffunction>

	<!---
	 * Sets the body of the current message.
	--->
	<cffunction name="setBody" access="public" returntype="any" output="no">
		<cfargument name="data" type="any" required="yes">

		<cfset this.body = arguments.data>

		<cfreturn this>
	</cffunction>

	<!---
	 * Appends data to the body of the current message.
	--->
	<cffunction name="appendBody" access="public" returntype="any" output="no">
		<cfargument name="data" type="any" required="yes">

		<cfset this.body = this.body & arguments.data>

		<cfreturn this>
	</cffunction>

	<!---
	 * Populates the headers with the request headers.
	--->
	<cffunction name="populateHeaders" access="public" returntype="void" output="no">
		<cfset var headers = http_request_data().headers>
		<cfset var name = "">

		<cfloop collection="#headers#" item="name">
			<cfif IsSimpleValue(headers[name])>
				<cfset setHeader(name, headers[name])>
			</cfif>
		</cfloop>
	</cffunction>

	<!---
	 * Returns an array containing all Headers.
	 *
	 * @return A map of the headers, by name: a Header, or an array of
	 *         Headers for a header that was added more than once
	 *
	 * Difference: the original calls populateHeaders() when no header is
	 * set. Here it does not: IncomingRequest populates its headers in the
	 * constructor, and on a response the call would fill an empty header
	 * map with the request headers (ResponseCache empties it first).
	--->
	<cffunction name="headers" access="public" returntype="any" output="no">
		<cfreturn this.headers_>
	</cffunction>

	<!---
	 * Returns a single Header object. If multiple headers with the same
	 * name exist, then will return an array of header objects.
	 *
	 * @return array|Header|null An empty string (null) if there is none
	--->
	<cffunction name="header" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfset var origName = getHeaderName(arguments.name)>

		<cfif StructKeyExists(this.headers_, origName)>
			<cfreturn this.headers_[origName]>
		</cfif>

		<cfreturn "">
	</cffunction>

	<!---
	 * Sets a header and it's value.
	 *
	 * The Header is made with CreateObject() and its __construct(), the
	 * cheapest way to make an object here (see the class Header).
	 *
	 * @param value array|string|null
	--->
	<cffunction name="setHeader" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="value" type="any" required="yes">
		<cfset var origName = getHeaderName(arguments.name)>
		<cfset var existing = "">
		<cfset var obj = "">
		<cfset var values = "">
		<cfset var i = 0>

		<cfif StructKeyExists(this.headers_, origName)>
			<cfset existing = this.headers_[origName]>

			<!--- checkMultipleHeaders(), with the name that is already looked up --->
			<cfif IsArray(existing)>
				<cfset checkMultipleHeaders(arguments.name)>
			</cfif>

			<cfif IsArray(existing.getValue())>
				<cfif NOT IsArray(arguments.value)>
					<cfset values = ArrayNew(1)>
					<cfset ArrayAppend(values, arguments.value)>
					<cfset arguments.value = values>
				</cfif>

				<cfloop from="1" to="#ArrayLen(arguments.value)#" index="i">
					<cfset appendHeader(origName, arguments.value[i])>
				</cfloop>

				<cfreturn this>
			</cfif>
		</cfif>

		<cfset obj = CreateObject("component", "Header")>
		<cfset obj.__construct(origName, arguments.value)>

		<cfset this.headers_[origName] = obj>
		<cfset this.headerMap[LCase(origName)] = origName>

		<cfreturn this>
	</cffunction>

	<!---
	 * Removes a header from the list of headers we track.
	--->
	<cffunction name="removeHeader" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfset var origName = getHeaderName(arguments.name)>

		<cfset StructDelete(this.headers_, origName)>
		<cfset StructDelete(this.headerMap, LCase(arguments.name))>

		<cfreturn this>
	</cffunction>

	<!---
	 * Determines whether a header exists.
	--->
	<cffunction name="hasHeader" access="public" returntype="boolean" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfset var origName = getHeaderName(arguments.name)>

		<cfreturn StructKeyExists(this.headers_, origName)>
	</cffunction>

	<!---
	 * Returns an array containing all Headers.
	 *
	 * @return A map of the headers, by name
	--->
	<cffunction name="getHeaders" access="public" returntype="any" output="no">
		<cfreturn headers()>
	</cffunction>

	<!---
	 * Returns a single Header object. If multiple headers with the same
	 * name exist, then will return an array of header objects.
	 *
	 * @return array|Header|null
	--->
	<cffunction name="getHeader" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">

		<cfreturn header(arguments.name)>
	</cffunction>

	<cffunction name="hasMultipleHeaders" access="private" returntype="boolean" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfset var origName = getHeaderName(arguments.name)>

		<cfreturn StructKeyExists(this.headers_, origName) AND IsArray(this.headers_[origName])>
	</cffunction>

	<cffunction name="checkMultipleHeaders" access="private" returntype="void" output="no">
		<cfargument name="name" type="string" required="yes">

		<cfif hasMultipleHeaders(arguments.name)>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="The header ""#arguments.name#"" already has multiple headers. You cannot change them. If you really need to change, remove the header first.">
		</cfif>
	</cffunction>

	<!---
	 * Adds an additional header value to any headers that accept
	 * multiple values (i.e. are an array or implement ArrayAccess).
	 *
	 * Difference: a value that is an empty string stands for null: nothing
	 * is added to a header that exists.
	--->
	<cffunction name="appendHeader" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="value" type="any" required="no" default="">
		<cfset var origName = "">

		<cfset checkMultipleHeaders(arguments.name)>

		<cfset origName = getHeaderName(arguments.name)>

		<cfif StructKeyExists(this.headers_, origName)>
			<cfif NOT is_null(arguments.value)>
				<cfset this.headers_[origName].appendValue(arguments.value)>
			</cfif>
		<cfelse>
			<cfset setHeader(arguments.name, arguments.value)>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds a header (not a header value) with the same name.
	 * Use this only when you set multiple headers with the same name,
	 * typically, for `Set-Cookie`.
	--->
	<cffunction name="addHeader" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="value" type="string" required="yes">
		<cfset var origName = getHeaderName(arguments.name)>
		<cfset var list = "">
		<cfset var obj = "">

		<cfif NOT StructKeyExists(this.headers_, origName)>
			<cfset setHeader(arguments.name, arguments.value)>
			<cfreturn this>
		</cfif>

		<cfif NOT IsArray(this.headers_[origName])>
			<cfset list = ArrayNew(1)>
			<cfset ArrayAppend(list, this.headers_[origName])>
			<cfset this.headers_[origName] = list>
		</cfif>

		<!--- Add the header. --->
		<cfset obj = CreateObject("component", "Header")>
		<cfset obj.__construct(origName, arguments.value)>
		<cfset ArrayAppend(this.headers_[origName], obj)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds a value in front of the values of a header.
	 *
	 * Difference: a header that does not exist is set (the original
	 * fails on a missing header).
	--->
	<cffunction name="prependHeader" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="value" type="string" required="yes">
		<cfset var origName = "">

		<cfset checkMultipleHeaders(arguments.name)>

		<cfset origName = getHeaderName(arguments.name)>

		<cfif NOT StructKeyExists(this.headers_, origName)>
			<cfset setHeader(arguments.name, arguments.value)>
			<cfreturn this>
		</cfif>

		<cfset this.headers_[origName].prependValue(arguments.value)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Retrieves a comma-separated string of the values for a single header.
	 *
	 * NOTE: Not all header values may be appropriately represented using
	 * comma concatenation. For such headers, use getHeader() instead
	 * and supply your own delimiter when concatenating.
	 *
	 * @see https://www.w3.org/Protocols/rfc2616/rfc2616-sec4.html#sec4.2
	--->
	<cffunction name="getHeaderLine" access="public" returntype="string" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfset var origName = getHeaderName(arguments.name)>

		<cfif NOT StructKeyExists(this.headers_, origName)>
			<cfreturn "">
		</cfif>

		<cfif IsArray(this.headers_[origName])>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="The header ""#arguments.name#"" already has multiple headers. You cannot use getHeaderLine().">
		</cfif>

		<cfreturn this.headers_[origName].getValueLine()>
	</cffunction>

	<!---
	 * Returns the HTTP Protocol Version.
	--->
	<cffunction name="getProtocolVersion" access="public" returntype="string" output="no">
		<cfif this.protocolVersion EQ "">
			<cfreturn "1.1">
		</cfif>

		<cfreturn this.protocolVersion>
	</cffunction>

	<!---
	 * Sets the HTTP protocol version.
	--->
	<cffunction name="setProtocolVersion" access="public" returntype="any" output="no">
		<cfargument name="version" type="string" required="yes">

		<cfif NOT IsNumeric(arguments.version)>
			<cfset arguments.version = Mid(arguments.version, Find("/", arguments.version) + 1, Len(arguments.version))>
		</cfif>

		<!--- Make sure that version is in the correct format --->
		<cfset arguments.version = NumberFormat(arguments.version, "9.0")>
		<cfset arguments.version = Trim(arguments.version)>

		<cfif ListFind(this.validProtocolVersions, arguments.version) EQ 0>
			<cfthrow type="ColdIgniter.HTTP.Exceptions.HTTPException" message="Invalid HTTP Protocol Version. Must be one of: #this.validProtocolVersions#">
		</cfif>

		<cfset this.protocolVersion = arguments.version>

		<cfreturn this>
	</cffunction>

	<!---
	 * Takes a header name in any case, and returns the
	 * normal-case version of the header.
	--->
	<cffunction name="getHeaderName" access="private" returntype="string" output="no">
		<cfargument name="name" type="string" required="yes">

		<cfif StructKeyExists(this.headerMap, LCase(arguments.name))>
			<cfreturn this.headerMap[LCase(arguments.name)]>
		</cfif>

		<cfreturn arguments.name>
	</cffunction>

</cfcomponent>
