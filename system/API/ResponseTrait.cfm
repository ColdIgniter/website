<!---
 * Response Trait
 *
 * Provides common, more readable, methods to provide
 * consistent HTTP responses under a variety of common
 * situations when working as an API.
 *
 * A trait is a file of properties and functions that the component
 * includes where the original says "use ResponseTrait". The component
 * has this.request_ (a request) and this.response, and may have
 * this.stringAsHtml (whether to treat string data as HTML in a JSON
 * response; setting true is only for backward compatibility).
 *
 * Difference: a null is an empty string (see is_null()), so respond("")
 * is respond(null), and a number is a string, so format() cannot tell a
 * number from a string: with a mime type other than JSON it is sent as
 * text. There is no setJSON() or setXML() on the response yet, and the
 * body of respond() is already formatted text by then, so it is set with
 * setBody() (format() has set the content type).
 *
 * Difference: the property format is this.format_, as the component has
 * a method format().
 *
 * Difference: the data is not converted to arrays with
 * json_decode(json_encode()) for a mime type other than JSON: the XML
 * formatter reads a list, a map (see array_()) and a component with
 * __toString() as they are.
--->

<!---
 * Allows child classes to override the
 * status code that is used in their API.
--->
<cfset this.codes = StructNew()>
<cfset this.codes["created"] = 201>
<cfset this.codes["deleted"] = 200>
<cfset this.codes["updated"] = 200>
<cfset this.codes["no_content"] = 204>
<cfset this.codes["invalid_request"] = 400>
<cfset this.codes["unsupported_response_type"] = 400>
<cfset this.codes["invalid_scope"] = 400>
<cfset this.codes["temporarily_unavailable"] = 400>
<cfset this.codes["invalid_grant"] = 400>
<cfset this.codes["invalid_credentials"] = 400>
<cfset this.codes["invalid_refresh"] = 400>
<cfset this.codes["no_data"] = 400>
<cfset this.codes["invalid_data"] = 400>
<cfset this.codes["access_denied"] = 401>
<cfset this.codes["unauthorized"] = 401>
<cfset this.codes["invalid_client"] = 401>
<cfset this.codes["forbidden"] = 403>
<cfset this.codes["resource_not_found"] = 404>
<cfset this.codes["not_acceptable"] = 406>
<cfset this.codes["resource_exists"] = 409>
<cfset this.codes["conflict"] = 409>
<cfset this.codes["resource_gone"] = 410>
<cfset this.codes["payload_too_large"] = 413>
<cfset this.codes["unsupported_media_type"] = 415>
<cfset this.codes["too_many_requests"] = 429>
<cfset this.codes["server_error"] = 500>
<cfset this.codes["unsupported_grant_type"] = 501>
<cfset this.codes["not_implemented"] = 501>

<!---
 * How to format the response data.
 * Either 'json' or 'xml'. If an empty string (null) is set, it will be
 * determined through content negotiation.
--->
<cfset this.format_ = "json">

<!---
 * Current Formatter instance. This is usually set by ResponseTrait::format
--->
<cfset this.formatter = "">

<!---
 * Provides a single, simple method to return an API response, formatted
 * to match the requested format, with proper content-type and status code.
 *
 * @param data    A map, a list or a string; an empty string is null
 * @param status  The status code, an empty string is null
 * @param message
--->
<cffunction name="respond" access="private" returntype="any" output="no">
	<cfargument name="data" type="any" required="no" default="">
	<cfargument name="status" type="any" required="no" default="">
	<cfargument name="message" type="string" required="no" default="">
	<cfset var status_ = arguments.status>
	<cfset var output = "">

	<cfif is_null(arguments.data) AND is_null(arguments.status)>
		<cfset status_ = 404>
		<cfset format(arguments.data)>
	<cfelseif is_null(arguments.data) AND IsNumeric(arguments.status)>
		<cfset format(arguments.data)>
	<cfelse>
		<cfif is_null(status_)>
			<cfset status_ = 200>
		</cfif>

		<cfset output = format(arguments.data)>
	</cfif>

	<!--- Difference: setJSON() and setXML() are not ported; format() has set the content type and made the text --->
	<cfset this.response.setBody(output)>

	<cfreturn this.response.setStatusCode(status_, arguments.message)>
</cffunction>

<!---
 * Used for generic failures that no custom methods exist for.
 *
 * @param messages      A string, or a map or a list of strings
 * @param status        HTTP status code
 * @param code          Custom, API-specific, error code; an empty string is null
 * @param customMessage
--->
<cffunction name="fail" access="private" returntype="any" output="no">
	<cfargument name="messages" type="any" required="yes">
	<cfargument name="status" type="numeric" required="no" default="400">
	<cfargument name="code" type="string" required="no" default="">
	<cfargument name="customMessage" type="string" required="no" default="">
	<cfset var messages_ = arguments.messages>
	<cfset var status_ = JavaCast("int", arguments.status)>
	<cfset var response_ = "">

	<cfif NOT is_array(messages_)>
		<cfset messages_ = array_("error", messages_)>
	</cfif>

	<cfif is_null(arguments.code)>
		<cfset response_ = array_("status", status_, "error", status_, "messages", messages_)>
	<cfelse>
		<cfset response_ = array_("status", status_, "error", arguments.code, "messages", messages_)>
	</cfif>

	<cfreturn respond(response_, status_, arguments.customMessage)>
</cffunction>

<!---
 * Response Helpers
--->

<!---
 * Used after successfully creating a new resource.
--->
<cffunction name="respondCreated" access="private" returntype="any" output="no">
	<cfargument name="data" type="any" required="no" default="">
	<cfargument name="message" type="string" required="no" default="">

	<cfreturn respond(arguments.data, this.codes["created"], arguments.message)>
</cffunction>

<!---
 * Used after a resource has been successfully deleted.
--->
<cffunction name="respondDeleted" access="private" returntype="any" output="no">
	<cfargument name="data" type="any" required="no" default="">
	<cfargument name="message" type="string" required="no" default="">

	<cfreturn respond(arguments.data, this.codes["deleted"], arguments.message)>
</cffunction>

<!---
 * Used after a resource has been successfully updated.
--->
<cffunction name="respondUpdated" access="private" returntype="any" output="no">
	<cfargument name="data" type="any" required="no" default="">
	<cfargument name="message" type="string" required="no" default="">

	<cfreturn respond(arguments.data, this.codes["updated"], arguments.message)>
</cffunction>

<!---
 * Used after a command has been successfully executed but there is no
 * meaningful reply to send back to the client.
--->
<cffunction name="respondNoContent" access="private" returntype="any" output="no">
	<cfargument name="message" type="string" required="no" default="No Content">

	<cfreturn respond("", this.codes["no_content"], arguments.message)>
</cffunction>

<!---
 * Used when the client is either didn't send authorization information,
 * or had bad authorization credentials. User is encouraged to try again
 * with the proper information.
--->
<cffunction name="failUnauthorized" access="private" returntype="any" output="no">
	<cfargument name="description" type="string" required="no" default="Unauthorized">
	<cfargument name="code" type="string" required="no" default="">
	<cfargument name="message" type="string" required="no" default="">

	<cfreturn fail(arguments.description, this.codes["unauthorized"], arguments.code, arguments.message)>
</cffunction>

<!---
 * Used when access is always denied to this resource and no amount
 * of trying again will help.
--->
<cffunction name="failForbidden" access="private" returntype="any" output="no">
	<cfargument name="description" type="string" required="no" default="Forbidden">
	<cfargument name="code" type="string" required="no" default="">
	<cfargument name="message" type="string" required="no" default="">

	<cfreturn fail(arguments.description, this.codes["forbidden"], arguments.code, arguments.message)>
</cffunction>

<!---
 * Used when a specified resource cannot be found.
--->
<cffunction name="failNotFound" access="private" returntype="any" output="no">
	<cfargument name="description" type="string" required="no" default="Not Found">
	<cfargument name="code" type="string" required="no" default="">
	<cfargument name="message" type="string" required="no" default="">

	<cfreturn fail(arguments.description, this.codes["resource_not_found"], arguments.code, arguments.message)>
</cffunction>

<!---
 * Used when the data provided by the client cannot be validated on one or more fields.
 *
 * @param errors A string, or a map or a list of strings
--->
<cffunction name="failValidationErrors" access="private" returntype="any" output="no">
	<cfargument name="errors" type="any" required="yes">
	<cfargument name="code" type="string" required="no" default="">
	<cfargument name="message" type="string" required="no" default="">

	<cfreturn fail(arguments.errors, this.codes["invalid_data"], arguments.code, arguments.message)>
</cffunction>

<!---
 * Use when trying to create a new resource and it already exists.
--->
<cffunction name="failResourceExists" access="private" returntype="any" output="no">
	<cfargument name="description" type="string" required="no" default="Conflict">
	<cfargument name="code" type="string" required="no" default="">
	<cfargument name="message" type="string" required="no" default="">

	<cfreturn fail(arguments.description, this.codes["resource_exists"], arguments.code, arguments.message)>
</cffunction>

<!---
 * Use when a resource was previously deleted. This is different than
 * Not Found, because here we know the data previously existed, but is now gone,
 * where Not Found means we simply cannot find any information about it.
--->
<cffunction name="failResourceGone" access="private" returntype="any" output="no">
	<cfargument name="description" type="string" required="no" default="Gone">
	<cfargument name="code" type="string" required="no" default="">
	<cfargument name="message" type="string" required="no" default="">

	<cfreturn fail(arguments.description, this.codes["resource_gone"], arguments.code, arguments.message)>
</cffunction>

<!---
 * Used when the user has made too many requests for the resource recently.
--->
<cffunction name="failTooManyRequests" access="private" returntype="any" output="no">
	<cfargument name="description" type="string" required="no" default="Too Many Requests">
	<cfargument name="code" type="string" required="no" default="">
	<cfargument name="message" type="string" required="no" default="">

	<cfreturn fail(arguments.description, this.codes["too_many_requests"], arguments.code, arguments.message)>
</cffunction>

<!---
 * Used when there is a server error.
 *
 * @param description The error message to show the user.
 * @param code        A custom, API-specific, error code.
 * @param message     A custom "reason" message to return.
--->
<cffunction name="failServerError" access="private" returntype="any" output="no">
	<cfargument name="description" type="string" required="no" default="Internal Server Error">
	<cfargument name="code" type="string" required="no" default="">
	<cfargument name="message" type="string" required="no" default="">

	<cfreturn fail(arguments.description, this.codes["server_error"], arguments.code, arguments.message)>
</cffunction>

<!---
 * Utility Methods
--->

<!---
 * Handles formatting a response. Currently, makes some heavy assumptions
 * and needs updating! :)
 *
 * @param data A map, a list or a string; an empty string is null
 *
 * @return The text, or an empty string (null)
--->
<cffunction name="format" access="private" returntype="any" output="no">
	<cfargument name="data" type="any" required="no" default="">
	<cfset var formatService = service("format")>
	<cfset var supported = formatService.getConfig().supportedResponseFormats>
	<cfset var mime = "">
	<cfset var asHtml = false>
	<cfset var contentType = "">

	<cfif is_null(this.format_)>
		<cfset mime = supported[1]>
	<cfelse>
		<cfset mime = "application/" & this.format_>
	</cfif>

	<!--- Determine correct response type through content negotiation if not explicitly declared --->
	<cfif Compare(this.format_, "json") NEQ 0 AND Compare(this.format_, "xml") NEQ 0>
		<cfif instanceof_(this.request_, "ColdIgniter\HTTP\IncomingRequest")>
			<cfset mime = this.request_.negotiate("media", supported, false)>
		</cfif>
	</cfif>

	<cfset this.response.setContentType(mime)>

	<!--- if we don't have a formatter, make one --->
	<cfif is_null(this.formatter)>
		<cfset this.formatter = formatService.getFormatter(mime)>
	</cfif>

	<cfif StructKeyExists(this, "stringAsHtml")>
		<cfset asHtml = this.stringAsHtml>
	</cfif>

	<cfif IsSimpleValue(arguments.data) AND NOT is_null(arguments.data)>
		<cfif Compare(mime, "application/json") NEQ 0 OR asHtml>
			<!--- The content type should be text/... and not application/... --->
			<cfset contentType = this.response.getHeaderLine("Content-Type")>
			<cfset contentType = Replace(contentType, "application/json", "text/html", "all")>
			<cfset contentType = Replace(contentType, "application/", "text/", "all")>
			<cfset this.response.setContentType(contentType)>
			<cfset this.format_ = "html">

			<cfreturn arguments.data>
		</cfif>
	</cfif>

	<cfreturn this.formatter.format(arguments.data)>
</cffunction>

<!---
 * Sets the format the response should be in.
 *
 * @param format Response format, json or xml; an empty string is null
 *
 * @return $this
--->
<cffunction name="setResponseFormat" access="private" returntype="any" output="no">
	<cfargument name="format" type="string" required="no" default="">

	<cfset this.format_ = LCase(arguments.format)>

	<cfreturn this>
</cffunction>

<!---
 * Pagination Methods
--->

<!---
 * Paginates the given model or query builder and returns
 * an array containing the paginated results along with
 * metadata such as total items, total pages, current page,
 * and items per page.
 *
 * The result would be in the following format:
 * [
 *   'data' => [...],
 *   'meta' => [
 *       'page' => 1,
 *       'perPage' => 20,
 *       'total' => 100,
 *       'totalPages' => 5,
 *   ],
 *   'links' => [
 *       'self' => '/api/items?page=1&perPage=20',
 *       'first' => '/api/items?page=1&perPage=20',
 *       'last' => '/api/items?page=5&perPage=20',
 *       'prev' => null,
 *       'next' => '/api/items?page=2&perPage=20',
 *   ]
 * ]
 *
 * Difference: the query builder is not cloned (a component cannot be copied),
 * so the rows are counted with countAllResults(false), which keeps the query.
 *
 * @param resource      A Model or a query builder
 * @param perPage
 * @param transformWith The class of a TransformerInterface; an empty string is null
--->
<cffunction name="paginate" access="private" returntype="any" output="no">
	<cfargument name="resource" type="any" required="yes">
	<cfargument name="perPage" type="numeric" required="no" default="20">
	<cfargument name="transformWith" type="string" required="no" default="">
	<cfset var page = 1>
	<cfset var data = "">
	<cfset var pager = "">
	<cfset var meta = "">
	<cfset var offset = 0>
	<cfset var total = 0>
	<cfset var rows = "">
	<cfset var transformer = "">
	<cfset var links = "">

	<cftry>
		<cfset page = this.request_.getGet("page")>

		<cfif IsSimpleValue(page)>
			<cfset page = Max(1, Fix(Val(page)))>
		<cfelse>
			<cfset page = 1>
		</cfif>

		<!--- If using a Model we can use its built-in paginate method --->
		<cfif instanceof_(arguments.resource, "ColdIgniter\Model")>
			<cfset data = arguments.resource.paginate(arguments.perPage, "default", page)>
			<cfset pager = arguments.resource.pager>

			<cfset meta = array_("page", JavaCast("int", pager.getCurrentPage()), "perPage", JavaCast("int", pager.getPerPage()), "total", JavaCast("int", pager.getTotal()), "totalPages", JavaCast("int", pager.getPageCount()))>
		<cfelse>
			<!--- Query Builder, we need to handle pagination manually --->
			<cfset offset = (page - 1) * arguments.perPage>
			<cfset total = arguments.resource.countAllResults(false)>
			<cfset arguments.resource.limit(arguments.perPage, offset)>
			<cfset rows = arguments.resource.get()>
			<cfset data = rows.getResultArray()>

			<cfset meta = array_("page", JavaCast("int", page), "perPage", JavaCast("int", arguments.perPage), "total", JavaCast("int", total), "totalPages", JavaCast("int", Ceiling(total / arguments.perPage)))>
		</cfif>

		<!--- Transform data if a transformer is provided --->
		<cfif NOT is_null(arguments.transformWith)>
			<cfif NOT class_exists(arguments.transformWith)>
				<cfset static_("ColdIgniter\API\ApiException").forTransformerNotFound(arguments.transformWith)>
			</cfif>

			<cfset transformer = new_(arguments.transformWith, this.request_)>

			<cfif NOT instanceof_(transformer, "ColdIgniter\API\TransformerInterface")>
				<cfset static_("ColdIgniter\API\ApiException").forInvalidTransformer(arguments.transformWith)>
			</cfif>

			<cfset data = transformer.transformMany(data)>
		</cfif>

		<cfset links = buildLinks(meta)>

		<cfset this.response.setHeader("Link", linkHeader(links))>
		<cfset this.response.setHeader("X-Total-Count", JavaCast("string", meta["total"]))>

		<cfreturn respond(array_("data", data, "meta", meta, "links", links))>

		<!--- Re-throw ApiExceptions so they can be handled by the caller --->
		<cfcatch type="ColdIgniter.API.ApiException">
			<cfrethrow>
		</cfcatch>

		<cfcatch type="ColdIgniter.Database.Exceptions.DatabaseException">
			<cfset log_message("error", lang("RESTful.cannotPaginate") & " " & cfcatch.message)>

			<cfreturn failServerError(lang("RESTful.cannotPaginate"))>
		</cfcatch>

		<cfcatch type="any">
			<cfset log_message("error", lang("RESTful.paginateError") & " " & cfcatch.message)>

			<cfreturn failServerError(lang("RESTful.paginateError"))>
		</cfcatch>
	</cftry>
</cffunction>

<!---
 * Builds pagination links based on the current request URI and pagination metadata.
 *
 * Difference: the closure of the original is the method pageLink().
 * A null is the marker NullValue, so that the JSON has null.
 *
 * @param meta Pagination metadata (page, perPage, total, totalPages)
 *
 * @return A map of pagination links with relations as keys
--->
<cffunction name="buildLinks" access="private" returntype="any" output="no">
	<cfargument name="meta" type="any" required="yes">
	<cfset var uri = "">
	<cfset var query = this.request_.getGet()>
	<cfset var totalPages = Max(1, Fix(Val(arguments.meta["totalPages"])))>
	<cfset var page = Fix(Val(arguments.meta["page"]))>
	<cfset var links = array_()>

	<!--- Difference: the URL helper is loaded here, the original expects the application to have done it --->
	<cfset helper("url")>

	<cfset uri = current_url(true)>

	<cfset links["self"] = pageLink(uri, query, arguments.meta, page)>
	<cfset links["first"] = pageLink(uri, query, arguments.meta, 1)>
	<cfset links["last"] = pageLink(uri, query, arguments.meta, totalPages)>

	<cfif page GT 1>
		<cfset links["prev"] = pageLink(uri, query, arguments.meta, page - 1)>
	<cfelse>
		<cfset links["prev"] = new_("ColdIgniter\Database\NullValue")>
	</cfif>

	<cfif page LT totalPages>
		<cfset links["next"] = pageLink(uri, query, arguments.meta, page + 1)>
	<cfelse>
		<cfset links["next"] = new_("ColdIgniter\Database\NullValue")>
	</cfif>

	<cfreturn links>
</cffunction>

<!---
 * Builds the link to a page: the closure $set of buildLinks().
 *
 * The query is the map of getGet(), which is a new map on each call,
 * so it can be changed here.
--->
<cffunction name="pageLink" access="private" returntype="string" output="no">
	<cfargument name="uri" type="any" required="yes">
	<cfargument name="query" type="any" required="yes">
	<cfargument name="meta" type="any" required="yes">
	<cfargument name="page" type="numeric" required="yes">
	<cfset var params = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset var keys = CreateObject("java", "java.util.ArrayList").init(arguments.query.keySet())>
	<cfset var key = "">
	<cfset var i = 0>
	<cfset var link = "">

	<!--- the map is copied, as the original gets a copy of the array --->
	<cfloop from="0" to="#keys.size() - 1#" index="i">
		<cfset key = keys.get(JavaCast("int", i))>
		<cfset params[key] = arguments.query[key]>
	</cfloop>

	<cfset params["page"] = JavaCast("int", arguments.page)>

	<!--- Ensure perPage is in the links if it's not default --->
	<cfif NOT StructKeyExists(params, "perPage") AND arguments.meta["perPage"] NEQ 20>
		<cfset params["perPage"] = arguments.meta["perPage"]>
	</cfif>

	<cfset link = new_("ColdIgniter\HTTP\URI", arguments.uri.__toString())>
	<cfset link.setQuery(http_build_query(params))>

	<cfreturn link.__toString()>
</cffunction>

<!---
 * Formats the pagination links into a single Link header string
 * for middleware/machine use.
 *
 * @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Link
 * @see https://datatracker.ietf.org/doc/html/rfc8288
 *
 * @param links Pagination links with relations as keys
 *
 * @return Formatted Link header value
--->
<cffunction name="linkHeader" access="private" returntype="string" output="no">
	<cfargument name="links" type="any" required="yes">
	<cfset var parts = ArrayNew(1)>
	<cfset var rels = ListToArray("self,first,prev,next,last")>
	<cfset var i = 0>
	<cfset var rel = "">
	<cfset var link = "">

	<cfloop from="1" to="#ArrayLen(rels)#" index="i">
		<cfset rel = rels[i]>
		<cfset link = arguments.links[rel]>

		<!--- a null is the marker NullValue, which is not a simple value --->
		<cfif IsSimpleValue(link) AND link NEQ "">
			<cfset ArrayAppend(parts, "<" & link & ">; rel=""" & rel & """")>
		</cfif>
	</cfloop>

	<cfreturn implode(", ", parts)>
</cffunction>
