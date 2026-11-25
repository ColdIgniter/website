<!---
 * The CookieStore object represents an immutable collection of `Cookie` value objects.
 *
 * Difference: there is no Countable and no IteratorAggregate. count() is a
 * method as in the original, and getIterator() returns a list of the cookies
 * that a loop can walk. The static fromCookieHeaders() is called on
 * static_("ColdIgniter\Cookie\CookieStore"). A copy is made by clone_()
 * (see Cookie).
--->
<cfcomponent output="no" hint="An immutable collection of Cookie value objects">

	<!---
	 * The cookie collection.
	 *
	 * @var a map (see array_()) of Cookie, by the id of the cookie
	--->
	<cfset this.cookies = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Creates a CookieStore from a list of `Set-Cookie` headers.
	 *
	 * @param headers list of strings
	 *
	 * @return static
	 *
	 * @throws CookieException
	--->
	<cffunction name="fromCookieHeaders" access="public" returntype="any" output="no">
		<cfargument name="headers" type="any" required="yes">
		<cfargument name="raw" type="boolean" required="no" default="false">
		<cfset var cookies = ArrayNew(1)>
		<cfset var cookie_ = "">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(arguments.headers)#" index="i">
			<cftry>
				<cfset cookie_ = static_("ColdIgniter\Cookie\Cookie").fromHeaderString(arguments.headers[i], arguments.raw)>
				<cfset ArrayAppend(cookies, cookie_)>

				<cfcatch type="ColdIgniter.Cookie.Exceptions.CookieException">
					<cfset log_message("error", cfcatch.type & ": " & cfcatch.message)>
				</cfcatch>
			</cftry>
		</cfloop>

		<cfreturn new_("ColdIgniter\Cookie\CookieStore", cookies)>
	</cffunction>

	<!---
	 * @param cookies list of Cookie
	 *
	 * @throws CookieException
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="cookies" type="any" required="yes">
		<cfset var i = 0>

		<cfset validateCookies(arguments.cookies)>

		<cfloop from="1" to="#ArrayLen(arguments.cookies)#" index="i">
			<cfset this.cookies[arguments.cookies[i].getId()] = arguments.cookies[i]>
		</cfloop>

		<cfreturn this>
	</cffunction>

	<!---
	 * Checks if a `Cookie` object identified by name and
	 * prefix is present in the collection.
	 *
	 * @param value A string, or an empty string for any value; as an empty
	 *              string cannot be told from null, a cookie with an empty
	 *              value is found by the name alone
	--->
	<cffunction name="has" access="public" returntype="boolean" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="prefix" type="string" required="no" default="">
		<cfargument name="value" type="any" required="no" default="">
		<cfset var name_ = arguments.prefix & arguments.name>
		<cfset var id = "">

		<cfloop collection="#this.cookies#" item="id">
			<cfif Compare(this.cookies[id].getPrefixedName(), name_) EQ 0>
				<cfif is_null(arguments.value)>
					<cfreturn true><!--- for BC --->
				</cfif>

				<cfreturn Compare(this.cookies[id].getValue(), arguments.value) EQ 0>
			</cfif>
		</cfloop>

		<cfreturn false>
	</cffunction>

	<!---
	 * Retrieves an instance of `Cookie` identified by a name and prefix.
	 * This throws an exception if not found.
	 *
	 * @throws CookieException
	--->
	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="prefix" type="string" required="no" default="">
		<cfset var name_ = arguments.prefix & arguments.name>
		<cfset var id = "">

		<cfloop collection="#this.cookies#" item="id">
			<cfif Compare(this.cookies[id].getPrefixedName(), name_) EQ 0>
				<cfreturn this.cookies[id]>
			</cfif>
		</cfloop>

		<cfset static_("ColdIgniter\Cookie\Exceptions\CookieException").forUnknownCookieInstance(name_, arguments.prefix)>
	</cffunction>

	<!---
	 * Store a new cookie and return a new collection. The original collection
	 * is left unchanged.
	 *
	 * @return static
	--->
	<cffunction name="put" access="public" returntype="any" output="no">
		<cfargument name="cookie_" type="any" required="yes">
		<cfset var store = clone_()>

		<cfset store.cookies[arguments.cookie_.getId()] = arguments.cookie_>

		<cfreturn store>
	</cffunction>

	<!---
	 * Removes a cookie from a collection and returns an updated collection.
	 * The original collection is left unchanged.
	 *
	 * Removing a cookie from the store **DOES NOT** delete it from the browser.
	 * If you intend to delete a cookie *from the browser*, you must put an empty
	 * value cookie with the same name to the store.
	 *
	 * @return static
	--->
	<cffunction name="remove" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="prefix" type="string" required="no" default="">
		<cfset var default = static_("ColdIgniter\Cookie\Cookie").setDefaults()>
		<cfset var parts = ArrayNew(1)>
		<cfset var id = "">
		<cfset var store = clone_()>

		<cfset ArrayAppend(parts, arguments.prefix & arguments.name)>
		<cfset ArrayAppend(parts, default["path"])>
		<cfset ArrayAppend(parts, default["domain"])>
		<cfset id = implode(";", parts)>

		<cfset StructDelete(store.cookies, id)>

		<cfreturn store>
	</cffunction>

	<!---
	 * Returns all cookie instances in store.
	 *
	 * @return a map of Cookie, by id
	--->
	<cffunction name="display" access="public" returntype="any" output="no">
		<cfreturn this.cookies>
	</cffunction>

	<!---
	 * Clears the cookie collection.
	--->
	<cffunction name="clear" access="public" returntype="void" output="no">
		<cfset this.cookies = CreateObject("java", "java.util.LinkedHashMap").init()>
	</cffunction>

	<!---
	 * Gets the Cookie count in this collection.
	--->
	<cffunction name="count" access="public" returntype="numeric" output="no">
		<cfreturn StructCount(this.cookies)>
	</cffunction>

	<!---
	 * Gets the iterator for the cookie collection.
	 *
	 * Difference: it is a list of the cookies, in order.
	--->
	<cffunction name="getIterator" access="public" returntype="any" output="no">
		<cfset var list = ArrayNew(1)>
		<cfset var id = "">

		<cfloop collection="#this.cookies#" item="id">
			<cfset ArrayAppend(list, this.cookies[id])>
		</cfloop>

		<cfreturn list>
	</cffunction>

	<!---
	 * Makes a copy of this store, that put() and remove() then change.
	 *
	 * Difference: the original uses the clone operator, see Cookie.clone_().
	--->
	<cffunction name="clone_" access="private" returntype="any" output="no">
		<cfset var store = request.ColdIgniter.autoloader.instantiate(this.__class)>

		<cfset store.cookies = array_merge(this.cookies)>

		<cfreturn store>
	</cffunction>

	<!---
	 * Validates all cookies passed to be instances of Cookie.
	 *
	 * @param cookies list of Cookie
	 *
	 * @throws CookieException
	--->
	<cffunction name="validateCookies" access="private" returntype="void" output="no">
		<cfargument name="cookies" type="any" required="yes">
		<cfset var i = 0>
		<cfset var type = "">

		<cfloop from="1" to="#ArrayLen(arguments.cookies)#" index="i">
			<cfif NOT instanceof_(arguments.cookies[i], "ColdIgniter\Cookie\Cookie")>
				<cfif IsObject(arguments.cookies[i])>
					<cfset type = arguments.cookies[i].__class>
				<cfelse>
					<cfset type = "string">
				</cfif>

				<cfset static_("ColdIgniter\Cookie\Exceptions\CookieException").forInvalidCookieInstance(this.__class, "ColdIgniter\Cookie\Cookie", type, i - 1)>
			</cfif>
		</cfloop>
	</cffunction>

</cfcomponent>
