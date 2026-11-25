<!---
 * Enable/disable backward compatibility breaking features.
--->
<cfcomponent output="no" parent="ColdIgniter\Config\BaseConfig" hint="Enable/disable backward compatibility breaking features">

	<!---
	 * Use improved new auto routing instead of the legacy version.
	--->
	<cfset this.autoRoutesImproved = true>

	<!---
	 * Use filter execution order in 4.4 or before.
	--->
	<cfset this.oldFilterOrder = false>

	<!---
	 * The behavior of `limit(0)` in Query Builder.
	 *
	 * If true, `limit(0)` returns all records. (the behavior of 4.4.x or before in version 4.x.)
	 * If false, `limit(0)` returns no records. (the behavior of 3.1.9 or later in version 3.x.)
	--->
	<cfset this.limitZeroAsAll = true>

	<!---
	 * Use strict location negotiation.
	 *
	 * By default, the locale is selected based on a loose comparison of the language code (ISO 639-1)
	 * Enabling strict comparison will also consider the region code (ISO 3166-1 alpha-2).
	--->
	<cfset this.strictLocaleNegotiation = false>
</cfcomponent>
