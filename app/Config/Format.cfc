<!---
 * Format configuration.
 *
 * Difference: the arrays of the original are lists (ArrayNew(1)) and maps
 * (a LinkedHashMap, which keeps the order of the keys). The JSON constants
 * are written as their numbers: 256 is JSON_UNESCAPED_UNICODE and 64 is
 * JSON_UNESCAPED_SLASHES, so 320 is both. JSONFormatter honours those two,
 * JSON_PRETTY_PRINT (128) and JSON_UNESCAPED_LINE_TERMINATORS (2048).
--->
<cfcomponent output="no" parent="ColdIgniter\Config\BaseConfig" hint="Format configuration">

	<!---
	 * --------------------------------------------------------------------------
	 * Available Response Formats
	 * --------------------------------------------------------------------------
	 *
	 * When you perform content negotiation with the request, these are the
	 * available formats that your application supports. This is currently
	 * only used with the API\ResponseTrait. A valid Formatter must exist
	 * for the specified format.
	 *
	 * These formats are only checked when the data passed to the respond()
	 * method is an array.
	 *
	 * @var list<string>
	--->
	<cfset this.supportedResponseFormats = ArrayNew(1)>
	<cfset ArrayAppend(this.supportedResponseFormats, "application/json")>
	<cfset ArrayAppend(this.supportedResponseFormats, "application/xml")> <!--- machine-readable XML --->
	<cfset ArrayAppend(this.supportedResponseFormats, "text/xml")> <!--- human-readable XML --->

	<!---
	 * --------------------------------------------------------------------------
	 * Formatters
	 * --------------------------------------------------------------------------
	 *
	 * Lists the class to use to format responses with of a particular type.
	 * For each type of response, provide the class to use to format it.
	 *
	 * @var array<string, string>
	--->
	<cfset this.formatters = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.formatters["application/json"] = "ColdIgniter\Format\JSONFormatter">
	<cfset this.formatters["application/xml"] = "ColdIgniter\Format\XMLFormatter">
	<cfset this.formatters["text/xml"] = "ColdIgniter\Format\XMLFormatter">

	<!---
	 * --------------------------------------------------------------------------
	 * Formatters Options
	 * --------------------------------------------------------------------------
	 *
	 * Additional Options to adjust default formatters behaviour.
	 * For each mime type, provide the necessary configuration, if needed.
	 *
	 * @var array<string, int>
	--->
	<cfset this.formatterOptions = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.formatterOptions["application/json"] = 320> <!--- JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES --->
	<cfset this.formatterOptions["application/xml"] = 0>
	<cfset this.formatterOptions["text/xml"] = 0>

	<!---
	 * --------------------------------------------------------------------------
	 * Maximum depth for JSON encoding
	 * --------------------------------------------------------------------------
	 *
	 * This value determines how deep the JSON encoder will traverse nested structures.
	 *
	 * @var int
	--->
	<cfset this.jsonEncodeDepth = 512>

</cfcomponent>
