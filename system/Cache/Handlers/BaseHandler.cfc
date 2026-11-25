<!---
 * Base class for cache handlers.
 *
 * Difference: BaseHandler extends CacheInterface, which holds the methods
 * of the interface as stubs that throw (there are no interfaces here, and
 * no abstract classes).
 *
 * Difference: validateKey() is a static method in the original. Here it is
 * a method of the object, and a handler that needs it without an object
 * calls it on static_("ColdIgniter\Cache\Handlers\BaseHandler"). It reads
 * the constant MAX_KEY_LENGTH of the object it is called on, as
 * "static::MAX_KEY_LENGTH" does, so a handler sets this.MAX_KEY_LENGTH
 * in its body.
 *
 * Difference: a key that is not a string is a struct, a list or an object;
 * a number is a string here (a literal is text), so the key 42 is valid.
--->
<cfcomponent output="no" parent="ColdIgniter\Cache\CacheInterface" hint="Base class for cache handlers">

	<!---
	 * Reserved characters that cannot be used in a key.
	 *
	 * @var string
	--->
	<cfset this.RESERVED_CHARACTERS = "{}()/\@:">

	<!---
	 * Maximum key length.
	 *
	 * The original has the largest integer; a text of that number gives
	 * the same result in a comparison.
	 *
	 * @var int
	--->
	<cfset this.MAX_KEY_LENGTH = "9223372036854775807">

	<!---
	 * Prefix to apply to cache keys.
	 * May not be used by all handlers.
	 *
	 * @var string
	--->
	<cfset this.prefix = "">

	<!---
	 * Validates a cache key according to PSR-6.
	 * Keys that exceed MAX_KEY_LENGTH are hashed.
	 *
	 * @param key    The cache key to validate
	 * @param prefix Optional prefix
	 *
	 * @throws InvalidArgumentException When the key is not valid.
	--->
	<cffunction name="validateKey" access="public" returntype="string" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfargument name="prefix" type="string" required="no" default="">
		<cfset var reserved = "">

		<cfif NOT IsSimpleValue(arguments.key)>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" errorcode="500" message="Cache key must be a string">
		</cfif>

		<cfif Compare(arguments.key, "") EQ 0>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" errorcode="500" message="Cache key cannot be empty.">
		</cfif>

		<cfset reserved = config("Config\Cache").reservedCharacters>

		<!--- strpbrk() looks at one character at a time, so the key never becomes a pattern --->
		<cfif Compare(reserved, "") NEQ 0 AND Len(strpbrk(arguments.key, reserved)) GT 0>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" errorcode="500" message="Cache key contains reserved characters #reserved#">
		</cfif>

		<!--- If the key with prefix exceeds the length then return the hashed version --->
		<cfif Len(arguments.prefix & arguments.key) GT this.MAX_KEY_LENGTH>
			<cfreturn arguments.prefix & md5(arguments.key)>
		</cfif>

		<cfreturn arguments.prefix & arguments.key>
	</cffunction>

	<!---
	 * Get an item from the cache, or execute the callback
	 * and save the result to the cache for the specified TTL.
	 *
	 * Difference: the callback is the callable form [object, "method"] (or
	 * the text "Class::method"), called with no arguments. The method name
	 * must be a plain name.
	 *
	 * Difference: a null is an empty string, so a cached empty string is
	 * taken for a miss and the callback runs again.
	 *
	 * @param key      Cache item name
	 * @param ttl      Time To Live, in seconds
	 * @param callback The callable form [object, "method"]
	--->
	<cffunction name="remember" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="ttl" type="numeric" required="yes">
		<cfargument name="callback" type="any" required="yes">
		<cfset var value = get(arguments.key)>
		<cfset var target = "">
		<cfset var method = "">

		<cfif NOT is_null(value)>
			<cfreturn value>
		</cfif>

		<cfif IsArray(arguments.callback)>
			<cfset target = arguments.callback[1]>
			<cfset method = arguments.callback[2]>
		<cfelse>
			<cfset target = ListFirst(Replace(arguments.callback, "::", Chr(1)), Chr(1))>
			<cfset method = ListLast(Replace(arguments.callback, "::", Chr(1)), Chr(1))>
		</cfif>

		<cfif NOT IsObject(target)>
			<cfset target = static_(target)>
		</cfif>

		<!--- the name goes into Evaluate(), so only a plain name is let through --->
		<cfif NOT CreateObject("java", "java.lang.String").init(method).matches("[A-Za-z_][A-Za-z0-9_]*")>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" errorcode="500" message="The cache callback is not a valid method name.">
		</cfif>

		<cfset value = Evaluate("target.#method#()")>

		<cfif NOT IsDefined("value")>
			<cfset value = "">
		</cfif>

		<cfset save(arguments.key, value, arguments.ttl)>

		<cfreturn value>
	</cffunction>

	<!---
	 * Ping the handler to see if it is still connected.
	--->
	<cffunction name="ping" access="public" returntype="boolean" output="no">
		<cfreturn true>
	</cffunction>

	<!---
	 * Reconnect to the handler.
	--->
	<cffunction name="reconnect" access="public" returntype="boolean" output="no">
		<cfreturn true>
	</cffunction>

</cfcomponent>
