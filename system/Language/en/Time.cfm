<!---
 * Time language settings
 *
 * A language file is included by the Language component, and has to
 * set the variable "lines" to a map (see array_()); that stands in for
 * the "return [...]" of the original. The keys keep their order.
 *
 * The plural forms are read by Language (English plural rules only).
--->
<cfset lines = array_()>

<cfset lines["invalidFormat"] = """{0}"" is not a valid datetime format">
<cfset lines["invalidMonth"] = "Months must be between 1 and 12. Given: {0}">
<cfset lines["invalidDay"] = "Days must be between 1 and 31. Given: {0}">
<cfset lines["invalidOverDay"] = "Days must be between 1 and {0}. Given: {1}">
<cfset lines["invalidHours"] = "Hours must be between 0 and 23. Given: {0}">
<cfset lines["invalidMinutes"] = "Minutes must be between 0 and 59. Given: {0}">
<cfset lines["invalidSeconds"] = "Seconds must be between 0 and 59. Given: {0}">
<cfset lines["years"] = "{0, plural, =1{## year} other{## years}}">
<cfset lines["months"] = "{0, plural, =1{## month} other{## months}}">
<cfset lines["weeks"] = "{0, plural, =1{## week} other{## weeks}}">
<cfset lines["days"] = "{0, plural, =1{## day} other{## days}}">
<cfset lines["hours"] = "{0, plural, =1{## hour} other{## hours}}">
<cfset lines["minutes"] = "{0, plural, =1{## minute} other{## minutes}}">
<cfset lines["seconds"] = "{0, plural, =1{## second} other{## seconds}}">
<cfset lines["ago"] = "{0} ago">
<cfset lines["inFuture"] = "in {0}">
<cfset lines["yesterday"] = "Yesterday">
<cfset lines["tomorrow"] = "Tomorrow">
<cfset lines["now"] = "Just now">
