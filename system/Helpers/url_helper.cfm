<!---
 * ColdIgniter URL Helpers
 *
 * Not ported yet: parse_subdomain (it needs Config\Hostnames and
 * FILTER_VALIDATE_IP), and in the functions below what is marked.
 *
 * A function here has no guard against a second definition (the original
 * checks function_exists): helper() keeps the first definition of a name.
 *
 * Where the original takes null for scheme or config, the argument is
 * left out, because null and an empty string cannot be told apart
 * (an empty scheme asks for a protocol-relative link).
--->

<!---
 * Returns a site URL as defined by the App config.
 *
 * @param relativePath URI string or array of URI segments.
 * @param scheme       URI scheme. E.g., http, ftp. If empty
 *                     string '' is set, a protocol-relative
 *                     link is returned.
 * @param config_      Alternate configuration to use.
--->
<cffunction name="site_url" returntype="string" output="no" hint="Returns a site URL as defined by the App config">
	<cfargument name="relativePath" type="any" required="no" default="">
	<cfargument name="scheme" type="string" required="no">
	<cfargument name="config_" type="any" required="no">
	<cfset var currentURI = service("request").getUri()>
	<cfset var args = StructNew()>

	<!--- Not ported yet: assert currentURI instanceof SiteURI --->

	<cfset args["relativePath"] = arguments.relativePath>
	<cfif IsDefined("arguments.scheme")>
		<cfset args["scheme"] = arguments.scheme>
	</cfif>
	<cfif IsDefined("arguments.config_")>
		<cfset args["config_"] = arguments.config_>
	</cfif>

	<cfreturn currentURI.siteUrl(argumentCollection=args)>
</cffunction>

<!---
 * Returns the base URL as defined by the App config.
 * Base URLs are trimmed site URLs without the index page.
 *
 * @param relativePath URI string or array of URI segments.
 * @param scheme       URI scheme. E.g., http, ftp. If empty
 *                     string '' is set, a protocol-relative
 *                     link is returned.
--->
<cffunction name="base_url" returntype="string" output="no" hint="Returns the base URL as defined by the App config">
	<cfargument name="relativePath" type="any" required="no" default="">
	<cfargument name="scheme" type="string" required="no">
	<cfset var currentURI = service("request").getUri()>
	<cfset var args = StructNew()>

	<!--- Not ported yet: assert currentURI instanceof SiteURI --->

	<cfset args["relativePath"] = arguments.relativePath>
	<cfif IsDefined("arguments.scheme")>
		<cfset args["scheme"] = arguments.scheme>
	</cfif>

	<cfreturn currentURI.baseUrl_(argumentCollection=args)>
</cffunction>

<!---
 * Returns the current full URL based on the Config\App settings and IncomingRequest.
 *
 * @param returnObject True to return an object instead of a string
 * @param request_     A request to use when retrieving the path
 *
 * @return When returning string, the query and fragment parts are removed.
 *         When returning URI, the query and fragment parts are preserved.
--->
<cffunction name="current_url" returntype="any" output="no" hint="Returns the current full URL based on the Config\App settings and IncomingRequest">
	<cfargument name="returnObject" type="boolean" required="no" default="false">
	<cfargument name="request_" type="any" required="no" default="">
	<cfset var uri = "">

	<cfif is_null(arguments.request_)>
		<cfset arguments.request_ = service("request")>
	</cfif>

	<!--- CLIRequest|IncomingRequest --->
	<cfset uri = arguments.request_.getUri()>

	<cfif arguments.returnObject>
		<cfreturn uri>
	</cfif>

	<cfreturn static_("ColdIgniter\HTTP\URI").createURIString(uri.getScheme(), uri.getAuthority(), uri.getPath())>
</cffunction>

<!---
 * Returns the previous URL the current visitor was on. For security reasons
 * we first check in a saved session variable, if it exists, and use that.
 * If that's not available, however, we'll use a sanitized url from the server value HTTP_REFERER
 * which can be set by the user so is untrusted and not set by certain browsers/servers.
 *
 * @return URI or string
--->
<cffunction name="previous_url" returntype="any" output="no" hint="Returns the previous URL the current visitor was on">
	<cfargument name="returnObject" type="boolean" required="no" default="false">
	<cfset var referer = "">

	<!---
	 Grab from the session first, if we have it,
	 since it's more reliable and safer.
	--->
	<!--- Not ported yet: referer = session("_ci_previous_url") when a session exists --->

	<!--- Otherwise, grab a sanitized version from the server values. --->
	<!--- Not ported yet: FILTER_SANITIZE_URL --->
	<cfif is_null(referer)>
		<cfset referer = request_().getServer("HTTP_REFERER")>
	</cfif>
	<cfif is_null(referer)>
		<cfset referer = site_url("/")>
	</cfif>

	<cfif arguments.returnObject>
		<cfreturn new_("ColdIgniter\HTTP\URI", referer)>
	</cfif>

	<cfreturn referer>
</cffunction>

<!---
 * URL String
 *
 * Returns the path part (relative to baseURL) of the current URL
--->
<cffunction name="uri_string" returntype="string" output="no" hint="Returns the path part (relative to baseURL) of the current URL">
	<cfset var uri = "">
	<cfset var path = "">

	<!---
	 The value of service("request").getUri().getPath() returns
	 full URI path.
	--->
	<cfset uri = service("request").getUri()>

	<!--- A SiteURI is told from a URI by its getRoutePath method. --->
	<cfif StructKeyExists(uri, "getRoutePath")>
		<cfset path = uri.getRoutePath()>
	<cfelse>
		<cfset path = uri.getPath()>
	</cfif>

	<cfreturn ltrim_(path, "/")>
</cffunction>

<!---
 * Index page
 *
 * Returns the "index_page" from your config file
 *
 * @param altConfig Alternate configuration to use
--->
<cffunction name="index_page" returntype="string" output="no" hint="Returns the index_page from your config file">
	<cfargument name="altConfig" type="any" required="no" default="">
	<cfset var config_ = "">

	<!--- use alternate config if provided, else default one --->
	<cfif is_null(arguments.altConfig)>
		<cfset config_ = config("Config\App")>
	<cfelse>
		<cfset config_ = arguments.altConfig>
	</cfif>

	<cfreturn config_.indexPage>
</cffunction>

<!---
 * Anchor Link
 *
 * Creates an anchor based on the local URL.
 *
 * @param uri        URI string or array of URI segments
 * @param title      The link title
 * @param attributes Any attributes (a string, or a struct or an array_() of them)
 * @param altConfig  Alternate configuration to use
--->
<cffunction name="anchor" returntype="string" output="no" hint="Creates an anchor based on the local URL">
	<cfargument name="uri" type="any" required="no" default="">
	<cfargument name="title" type="string" required="no" default="">
	<cfargument name="attributes" type="any" required="no" default="">
	<cfargument name="altConfig" type="any" required="no" default="">
	<cfset var config_ = "">
	<cfset var siteUrl = "">

	<!--- use alternate config if provided, else default one --->
	<cfif is_null(arguments.altConfig)>
		<cfset config_ = config("Config\App")>
	<cfelse>
		<cfset config_ = arguments.altConfig>
	</cfif>

	<cfif IsArray(arguments.uri)>
		<cfset siteUrl = site_url(relativePath=arguments.uri, config_=config_)>
	<cfelseif REFindNoCase("^(\w+:)?//", arguments.uri) GT 0>
		<cfset siteUrl = arguments.uri>
	<cfelse>
		<cfset siteUrl = site_url(relativePath=arguments.uri, config_=config_)>
	</cfif>

	<!--- eliminate trailing slash --->
	<cfset siteUrl = rtrim_(siteUrl, "/")>

	<cfif arguments.title EQ "">
		<cfset arguments.title = siteUrl>
	</cfif>

	<cfif NOT (IsSimpleValue(arguments.attributes) AND arguments.attributes EQ "")>
		<cfset arguments.attributes = stringify_attributes(arguments.attributes)>
	</cfif>

	<cfreturn "<a href=""" & siteUrl & """" & arguments.attributes & ">" & arguments.title & "</a>">
</cffunction>

<!---
 * Anchor Link - Pop-up version
 *
 * Creates an anchor based on the local URL. The link
 * opens a new window based on the attributes specified.
 *
 * @param uri        the URL
 * @param title      the link title
 * Only false (as the original compares with ===) gives the plain
 * window.open(); so does an argument that is not passed, as its default
 * is false. On the server the literal false is the string "false" (only
 * the result of a comparison is a Boolean), so that string, written
 * exactly, and a Boolean false count as false. "no", "0" and the
 * number 0 are attribute strings.
 *
 * A struct made with dot notation has upper-case keys, so the keys that
 * are looked up (window_name and the window features) are matched
 * without regard to case: they are stored in lower case when the
 * attributes are copied. Other keys stay as they are.
 *
 * @param attributes any attributes: false, a string, or a struct or an
 *                   array_() of them (the attributes are not changed)
 * @param altConfig  Alternate configuration to use
--->
<cffunction name="anchor_popup" returntype="string" output="no" hint="Creates an anchor based on the local URL that opens a new window">
	<cfargument name="uri" type="any" required="no" default="">
	<cfargument name="title" type="string" required="no" default="">
	<cfargument name="attributes" type="any" required="no">
	<cfargument name="altConfig" type="any" required="no" default="">
	<cfset var config_ = "">
	<cfset var isFalse = false>
	<cfset var siteUrl = "">
	<cfset var attributes_ = array_()>
	<cfset var windowName = "">
	<cfset var atts = array_()>
	<cfset var defaults = array_("width", "800", "height", "600", "scrollbars", "yes", "menubar", "no", "status", "yes", "resizable", "yes", "screenx", "0", "screeny", "0")>
	<cfset var key = "">
	<cfset var i = 0>

	<!--- use alternate config if provided, else default one --->
	<cfif is_null(arguments.altConfig)>
		<cfset config_ = config("Config\App")>
	<cfelse>
		<cfset config_ = arguments.altConfig>
	</cfif>

	<cfif REFindNoCase("^(\w+:)?//", arguments.uri) GT 0>
		<cfset siteUrl = arguments.uri>
	<cfelse>
		<cfset siteUrl = site_url(relativePath=arguments.uri, config_=config_)>
	</cfif>
	<cfset siteUrl = rtrim_(siteUrl, "/")>

	<cfif arguments.title EQ "">
		<cfset arguments.title = siteUrl>
	</cfif>

	<!--- $attributes === false (the default is false) --->
	<cfif NOT IsDefined("arguments.attributes")>
		<cfset isFalse = true>
	<cfelseif IsSimpleValue(arguments.attributes) AND IsBoolean(arguments.attributes)
		AND (Compare(arguments.attributes.getClass().getName(), "java.lang.String") EQ 0 AND Compare(arguments.attributes, "false") EQ 0
			OR Compare(arguments.attributes.getClass().getName(), "java.lang.Boolean") EQ 0 AND NOT arguments.attributes)>
		<cfset isFalse = true>
	</cfif>

	<cfif isFalse>
		<cfreturn "<a href=""" & siteUrl & """ onclick=""window.open('" & siteUrl & "', '_blank'); return false;"">" & arguments.title & "</a>">
	</cfif>

	<cfif NOT is_array(arguments.attributes)>
		<cfset attributes_["0"] = arguments.attributes>

		<!--- Ref: http://www.w3schools.com/jsref/met_win_open.asp --->
		<cfset windowName = "_blank">
	<cfelse>
		<!--- a copy, because the original works on a copy of the array --->
		<cfif IsStruct(arguments.attributes)>
			<cfloop collection="#arguments.attributes#" item="key">
				<cfif ListFindNoCase("window_name,width,height,scrollbars,menubar,status,resizable,screenx,screeny", key) GT 0>
					<cfset attributes_[LCase(key)] = arguments.attributes[key]>
				<cfelse>
					<cfset attributes_[key] = arguments.attributes[key]>
				</cfif>
			</cfloop>
		<cfelse>
			<cfloop from="1" to="#ArrayLen(arguments.attributes)#" index="i">
				<cfset attributes_[i - 1] = arguments.attributes[i]>
			</cfloop>
		</cfif>

		<cfif array_key_exists("window_name", attributes_) AND attributes_["window_name"] NEQ "">
			<cfset windowName = attributes_["window_name"]>
			<cfset attributes_.remove("window_name")>
		<cfelse>
			<cfset windowName = "_blank">
		</cfif>
	</cfif>

	<cfloop collection="#defaults#" item="key">
		<cfif array_key_exists(key, attributes_)>
			<cfset atts[key] = attributes_[key]>
		<cfelse>
			<cfset atts[key] = defaults[key]>
		</cfif>
		<cfset attributes_.remove(key)>
	</cfloop>

	<cfset arguments.attributes = stringify_attributes(attributes_)>

	<cfreturn "<a href=""" & siteUrl
			& """ onclick=""window.open('" & siteUrl & "', '" & windowName & "', '" & stringify_attributes(atts, true) & "'); return false;"""
			& arguments.attributes & ">" & arguments.title & "</a>">
</cffunction>

<!---
 * Mailto Link
 *
 * @param email      the email address
 * @param title      the link title
 * @param attributes any attributes
--->
<cffunction name="mailto" returntype="string" output="no" hint="Mailto Link">
	<cfargument name="email" type="string" required="yes">
	<cfargument name="title" type="string" required="no" default="">
	<cfargument name="attributes" type="any" required="no" default="">

	<cfif Trim(arguments.title) EQ "">
		<cfset arguments.title = arguments.email>
	</cfif>

	<cfreturn "<a href=""mailto:" & arguments.email & """" & stringify_attributes(arguments.attributes) & ">" & arguments.title & "</a>">
</cffunction>

<!---
 * Encoded Mailto Link
 *
 * Create a spam-protected mailto link written in Javascript
 *
 * The original reads the UTF-8 bytes and puts them together again
 * to get the number of a character. A CFML string holds characters,
 * so Asc() gives that number at once.
 *
 * @param email      the email address
 * @param title      the link title
 * @param attributes any attributes
--->
<cffunction name="safe_mailto" returntype="string" output="no" hint="Create a spam-protected mailto link written in Javascript">
	<cfargument name="email" type="string" required="yes">
	<cfargument name="title" type="string" required="no" default="">
	<cfargument name="attributes" type="any" required="no" default="">
	<cfset var x = ArrayNew(1)>
	<cfset var reversed = ArrayNew(1)>
	<cfset var prefix = "<a href=""mailto:">
	<cfset var i = 0>
	<cfset var key = "">
	<cfset var j = 0>
	<cfset var cspNonce = "">
	<cfset var output = "">

	<cfif Trim(arguments.title) EQ "">
		<cfset arguments.title = arguments.email>
	</cfif>

	<cfloop from="1" to="#Len(prefix)#" index="i">
		<cfset ArrayAppend(x, Mid(prefix, i, 1))>
	</cfloop>

	<cfloop from="1" to="#Len(arguments.email)#" index="i">
		<cfset ArrayAppend(x, "|" & Asc(Mid(arguments.email, i, 1)))>
	</cfloop>

	<cfset ArrayAppend(x, """")>

	<cfif NOT (IsSimpleValue(arguments.attributes) AND arguments.attributes EQ "")>
		<cfif is_array(arguments.attributes)>
			<cfif IsStruct(arguments.attributes)>
				<cfloop collection="#arguments.attributes#" item="key">
					<cfset ArrayAppend(x, " " & key & "=""")>

					<cfloop from="1" to="#Len(arguments.attributes[key])#" index="i">
						<cfset ArrayAppend(x, "|" & Asc(Mid(arguments.attributes[key], i, 1)))>
					</cfloop>

					<cfset ArrayAppend(x, """")>
				</cfloop>
			<cfelse>
				<!--- a list: the keys are the positions, counted from zero --->
				<cfloop from="1" to="#ArrayLen(arguments.attributes)#" index="j">
					<cfset ArrayAppend(x, " " & (j - 1) & "=""")>

					<cfloop from="1" to="#Len(arguments.attributes[j])#" index="i">
						<cfset ArrayAppend(x, "|" & Asc(Mid(arguments.attributes[j], i, 1)))>
					</cfloop>

					<cfset ArrayAppend(x, """")>
				</cfloop>
			</cfif>
		<cfelse>
			<cfloop from="1" to="#Len(arguments.attributes)#" index="i">
				<cfset ArrayAppend(x, Mid(arguments.attributes, i, 1))>
			</cfloop>
		</cfif>
	</cfif>

	<cfset ArrayAppend(x, ">")>

	<cfloop from="1" to="#Len(arguments.title)#" index="i">
		<cfset ArrayAppend(x, "|" & Asc(Mid(arguments.title, i, 1)))>
	</cfloop>

	<cfset ArrayAppend(x, "<")>
	<cfset ArrayAppend(x, "/")>
	<cfset ArrayAppend(x, "a")>
	<cfset ArrayAppend(x, ">")>

	<!--- array_reverse --->
	<cfloop from="#ArrayLen(x)#" to="1" index="i" step="-1">
		<cfset ArrayAppend(reversed, x[i])>
	</cfloop>

	<!--- improve obfuscation by eliminating newlines & whitespace --->
	<cfset cspNonce = csp_script_nonce()>
	<cfif cspNonce NEQ "">
		<cfset cspNonce = " " & cspNonce>
	</cfif>
	<cfset output = "<script" & cspNonce & ">" & "var l=new Array();">

	<cfloop from="1" to="#ArrayLen(reversed)#" index="i">
		<cfset output = output & "l[" & (i - 1) & "] = '" & reversed[i] & "';">
	</cfloop>

	<cfreturn output & "for (var i = l.length-1; i >= 0; i=i-1) {"
			& "if (l[i].substring(0, 1) === '|') document.write(""&##""+unescape(l[i].substring(1))+"";"");"
			& "else document.write(unescape(l[i]));"
			& "}"
			& "</script>">
</cffunction>

<!---
 * Auto-linker
 *
 * Automatically links URL and Email addresses.
 * Note: There's a bit of extra code here to deal with
 * URLs or emails that end in a period. We'll strip these
 * off and add them after the link.
 *
 * The patterns are Java regular expressions.
 *
 * Difference: a match of the scheme or of the local part of an email is
 * only tried at the left edge of a run of its characters (a look-behind),
 * because a try from every position of a long run is quadratic. A scheme
 * glued to a digit, a plus, a hyphen or a dot ("1http://x.example") is
 * no longer linked (a "www." after it still is), nor an email glued to
 * such a run, nor an email that starts right where the one before it
 * ended ("x@a.bc_y@e.fg": only the first is linked).
 *
 * Not ported yet: FILTER_VALIDATE_EMAIL, so every match of the email
 * pattern is linked.
 *
 * @param str   the string
 * @param type  the type: email, url, or both
 * @param popup whether to create pop-up links
--->
<cffunction name="auto_link" returntype="string" output="no" hint="Automatically links URL and Email addresses">
	<cfargument name="str" type="string" required="yes">
	<cfargument name="type" type="string" required="no" default="both">
	<cfargument name="popup" type="boolean" required="no" default="false">
	<cfset var Pattern = CreateObject("java", "java.util.regex.Pattern")>
	<cfset var matcher = "">
	<cfset var starts = ArrayNew(1)>
	<cfset var ends = ArrayNew(1)>
	<cfset var prefixes = ArrayNew(1)>
	<cfset var target = "">
	<cfset var a = "">
	<cfset var matched = "">
	<cfset var i = 0>

	<!--- Find and replace any URLs. --->
	<cfif Compare(arguments.type, "email") NEQ 0>
		<cfset matcher = Pattern.compile("((?<![a-z0-9+\-.])[a-z][a-z0-9+\-.]*://|www\.)[a-z0-9]+(-+[a-z0-9]+)*(\.[a-z0-9]+(-+[a-z0-9]+)*)+(/([^\s()<>;]+\w)?/?)?", JavaCast("int", 2)).matcher(arguments.str)>

		<cfloop condition="matcher.find()">
			<cfset ArrayAppend(starts, matcher.start())>
			<cfset ArrayAppend(ends, matcher.end())>
			<cfset ArrayAppend(prefixes, matcher.group(1))>
		</cfloop>

		<cfif ArrayLen(starts) GTE 1>
			<!--- Set our target HTML if using popup links. --->
			<cfif arguments.popup>
				<cfset target = " target=""_blank""">
			</cfif>

			<!---
			 We process the links in reverse order (last -> first) so that
			 the returned string offsets are not moved as we add more HTML.
			--->
			<cfloop from="#ArrayLen(starts)#" to="1" index="i" step="-1">
				<cfset matched = Mid(arguments.str, starts[i] + 1, ends[i] - starts[i])>
				<cfif Find("/", prefixes[i]) GT 0>
					<cfset a = "<a href=""" & matched & """" & target & ">" & matched & "</a>">
				<cfelse>
					<cfset a = "<a href=""http://" & matched & """" & target & ">" & matched & "</a>">
				</cfif>
				<cfset arguments.str = Left(arguments.str, starts[i]) & a & Mid(arguments.str, ends[i] + 1, Len(arguments.str))>
			</cfloop>
		</cfif>
	</cfif>

	<!--- Find and replace any emails. --->
	<cfif Compare(arguments.type, "url") NEQ 0>
		<cfset starts = ArrayNew(1)>
		<cfset ends = ArrayNew(1)>
		<cfset matcher = Pattern.compile("((?<![\w.\-+])[\w\.\-\+]+@[a-z0-9\-]+\.[a-z0-9\-\.]+[^\p{Punct}\s])", JavaCast("int", 2)).matcher(arguments.str)>

		<cfloop condition="matcher.find()">
			<cfset ArrayAppend(starts, matcher.start())>
			<cfset ArrayAppend(ends, matcher.end())>
		</cfloop>

		<cfloop from="#ArrayLen(starts)#" to="1" index="i" step="-1">
			<cfset matched = Mid(arguments.str, starts[i] + 1, ends[i] - starts[i])>

			<!--- Not ported yet: filter_var(matched, FILTER_VALIDATE_EMAIL) --->
			<cfset arguments.str = Left(arguments.str, starts[i]) & safe_mailto(matched) & Mid(arguments.str, ends[i] + 1, Len(arguments.str))>
		</cfloop>
	</cfif>

	<cfreturn arguments.str>
</cffunction>

<!---
 * Prep URL - Simply adds the http:// or https:// part if no scheme is included.
 *
 * Formerly used URI, but that does not play nicely with URIs missing
 * the scheme.
 *
 * @param str    the URL
 * @param secure set true if you want to force https://
--->
<cffunction name="prep_url" returntype="string" output="no" hint="Simply adds the http:// or https:// part if no scheme is included">
	<cfargument name="str" type="string" required="no" default="">
	<cfargument name="secure" type="boolean" required="no" default="false">
	<cfset var empty = ArrayNew(1)>

	<cfset ArrayAppend(empty, "http://")>
	<cfset ArrayAppend(empty, "https://")>
	<cfset ArrayAppend(empty, "//")>
	<cfset ArrayAppend(empty, "")>

	<cfif in_array(arguments.str, empty)>
		<cfreturn "">
	</cfif>

	<cfif NOT StructKeyExists(parse_url(arguments.str), "scheme")>
		<cfset arguments.str = "http://" & ltrim_(arguments.str, "/")>
	</cfif>

	<!--- force replace http:// with https:// --->
	<cfif arguments.secure>
		<cfreturn REReplaceNoCase(arguments.str, "^http:", "https:")>
	</cfif>

	<cfreturn arguments.str>
</cffunction>

<!---
 * Removes every "&" up to the next ";" (an entity such as &amp;), as
 * the pattern &.+?; does: at least one character in between, none of
 * them a line terminator.
 *
 * Difference: not in the original. The helper stands in for the pattern
 * in url_title(), which is quadratic on a long run of "&", and scans the
 * string once. The line terminators are those that "." does not match.
 *
 * @param str the string
--->
<cffunction name="strip_entities_" returntype="string" output="no" hint="Removes every ampersand up to the next semicolon">
	<cfargument name="str" type="string" required="yes">
	<cfset var terminators = CreateObject("java", "java.util.regex.Pattern").compile("[\n\r\u0085\u2028\u2029]")>
	<cfset var matcher = terminators.matcher(JavaCast("string", arguments.str))>
	<cfset var buffer = CreateObject("java", "java.lang.StringBuffer").init()>
	<cfset var length = Len(arguments.str)>
	<cfset var position = 1>
	<cfset var amp = 0>
	<cfset var semi = -1>
	<cfset var term = -1>

	<cfloop condition="position LTE length">
		<cfset amp = Find("&", arguments.str, position)>
		<cfif amp EQ 0>
			<cfbreak>
		</cfif>

		<!--- the first ";" from two characters on; kept while it still lies ahead --->
		<cfif semi NEQ 0 AND semi LT amp + 2>
			<cfif amp + 2 GT length>
				<cfset semi = 0>
			<cfelse>
				<cfset semi = Find(";", arguments.str, amp + 2)>
			</cfif>
		</cfif>
		<cfif semi EQ 0>
			<cfbreak>
		</cfif>

		<!--- the first line terminator after the "&", kept while it still lies ahead --->
		<cfif term NEQ 0 AND term LT amp + 1>
			<cfif matcher.find(JavaCast("int", amp))>
				<cfset term = matcher.start() + 1>
			<cfelse>
				<cfset term = 0>
			</cfif>
		</cfif>

		<cfif term EQ 0 OR semi LT term>
			<cfset buffer.append(JavaCast("string", Mid(arguments.str, position, amp - position)))>
			<cfset position = semi + 1>
		<cfelse>
			<!--- no "&" before the terminator can match: go on from it --->
			<cfset buffer.append(JavaCast("string", Mid(arguments.str, position, term - position)))>
			<cfset position = term>
		</cfif>
	</cfloop>

	<cfset buffer.append(JavaCast("string", Mid(arguments.str, position, length - position + 1)))>

	<cfreturn buffer.toString()>
</cffunction>

<!---
 * Create URL Title
 *
 * Takes a "title" string as input and creates a
 * human-friendly URL string with a "separator" string
 * as the word separator.
 *
 * The patterns are Java regular expressions.
 *
 * @param str       Input string
 * @param separator Word separator (usually '-' or '_')
 * @param lowercase Whether to transform the output string to lowercase
--->
<cffunction name="url_title" returntype="string" output="no" hint="Creates a human-friendly URL string with a separator as the word separator">
	<cfargument name="str" type="string" required="yes">
	<cfargument name="separator" type="string" required="no" default="-">
	<cfargument name="lowercase" type="boolean" required="no" default="false">
	<cfset var qSeparator = JavaCast("string", arguments.separator).replaceAll("([^A-Za-z0-9])", "\\$1")>
	<cfset var replacement = Replace(Replace(arguments.separator, "\", "\\", "all"), "$", "\$", "all")>
	<cfset var trans = array_("[^\w\d\pL\pM _-]", "", "\s+", replacement, "(" & qSeparator & ")+", replacement)>
	<cfset var key = "">

	<cfset arguments.str = strip_tags(arguments.str)>
	<cfset arguments.str = strip_entities_(arguments.str)>

	<cfloop collection="#trans#" item="key">
		<cfset arguments.str = JavaCast("string", arguments.str).replaceAll("(?iu)" & key, trans[key])>
	</cfloop>

	<cfif arguments.lowercase>
		<cfset arguments.str = LCase(arguments.str)>
	</cfif>

	<cfreturn Trim(trim_(arguments.str, arguments.separator))>
</cffunction>

<!---
 * Create URL Title that takes into account accented characters
 *
 * Takes a "title" string as input and creates a
 * human-friendly URL string with a "separator" string
 * as the word separator.
 *
 * Not ported yet: helper("text") and convert_accented_characters(), so
 * accented characters are not converted.
 *
 * @param str       Input string
 * @param separator Word separator (usually '-' or '_')
 * @param lowercase Whether to transform the output string to lowercase
--->
<cffunction name="mb_url_title" returntype="string" output="no" hint="Creates a URL title that takes into account accented characters">
	<cfargument name="str" type="string" required="yes">
	<cfargument name="separator" type="string" required="no" default="-">
	<cfargument name="lowercase" type="boolean" required="no" default="false">

	<!--- Not ported yet: helper("text") --->

	<cfreturn url_title(arguments.str, arguments.separator, arguments.lowercase)>
</cffunction>

<!---
 * Get the full, absolute URL to a route name or controller method
 * (with additional arguments)
 *
 * NOTE: This requires the controller/method to
 * have a route defined in the routes Config file.
 *
 * Not ported yet: RouteCollection::reverseRoute (see route_to), so a
 * route is never found.
 *
 * @param controller Route name or Controller::method
 * @param args       One or more parameters to be passed to the route.
 *                   The last parameter allows you to set the locale.
 *
 * @throws RouterException
--->
<cffunction name="url_to" returntype="string" output="no" hint="Get the full, absolute URL to a route name or controller method">
	<cfargument name="controller" type="string" required="yes">
	<cfset var call = "arguments.controller">
	<cfset var route = "">
	<cfset var parts = "">
	<cfset var i = 0>

	<cfloop from="2" to="#ArrayLen(arguments)#" index="i">
		<cfset call = ListAppend(call, "arguments[#i#]")>
	</cfloop>

	<cfset route = Evaluate("route_to(#call#)")>

	<cfif (IsBoolean(route) AND NOT route) OR route EQ "">
		<cfset parts = explode("::", arguments.controller)>

		<cfif ArrayLen(parts) GTE 2>
			<cfthrow type="ColdIgniter.Router.Exceptions.RouterException" message="Controller or its method is not found: #parts[1]#::#parts[2]#">
		</cfif>

		<cfthrow type="ColdIgniter.Router.Exceptions.RouterException" message="The route for ""#arguments.controller#"" cannot be found.">
	</cfif>

	<cfreturn site_url(route)>
</cffunction>

<!---
 * Determines if current url path contains
 * the given path. It may contain a wildcard (*)
 * which will allow any valid character.
 *
 * Example:
 *   if (url_is('admin*')) ...
 *
 * Difference: a * becomes \S* where the original writes (\S)*, the same
 * match without a repeated group. A path longer than the limit of
 * regex_guard_() is refused.
--->
<cffunction name="url_is" returntype="boolean" output="no" hint="Determines if current url path contains the given path">
	<cfargument name="path" type="string" required="yes">
	<cfset var currentPath = "">

	<!--- Setup our regex to allow wildcards --->
	<cfset arguments.path = "/" & trim_(Replace(arguments.path, "*", "\S*", "all"), "/ ")>
	<cfset currentPath = "/" & trim_(uri_string(), "/ ")>

	<cfset regex_guard_(currentPath)>

	<cfreturn REFind("^" & arguments.path & "$", currentPath) GT 0>
</cffunction>

<!--- Not ported yet: parse_subdomain --->
