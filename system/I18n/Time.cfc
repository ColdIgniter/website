<!---
 * A localized date/time class.
 *
 * Difference: the original extends DateTimeImmutable and implements
 * Stringable. Here the instant is kept by TimeTrait.cfm in a Java calendar,
 * see the differences at the top of that file.
--->
<cfcomponent output="no" hint="A localized date/time class">

	<!--- use TimeTrait --->
	<cfinclude template="TimeTrait.cfm">

</cfcomponent>
