<!---
 | --------------------------------------------------------------------
 | App Namespace
 | --------------------------------------------------------------------
 |
 | This defines the default Namespace that is used throughout
 | ColdIgniter to refer to the Application directory. Change
 | this constant to change the namespace that all application
 | classes should use.
 |
 | NOTE: changing this will require manually modifying the
 | existing namespaces of App\* namespaced-classes.
--->
<cfset defined("APP_NAMESPACE") OR define("APP_NAMESPACE", "App")>

<!---
 |--------------------------------------------------------------------------
 | Timing Constants
 |--------------------------------------------------------------------------
 |
 | Provide simple ways to work with the myriad of functions that
 | require information to be in seconds.
--->
<cfset defined("SECOND") OR define("SECOND", 1)>
<cfset defined("MINUTE") OR define("MINUTE", 60)>
<cfset defined("HOUR")   OR define("HOUR", 3600)>
<cfset defined("DAY")    OR define("DAY", 86400)>
<cfset defined("WEEK")   OR define("WEEK", 604800)>
<cfset defined("MONTH")  OR define("MONTH", 2592000)>
<cfset defined("YEAR")   OR define("YEAR", 31536000)>
<cfset defined("DECADE") OR define("DECADE", 315360000)>

<!---
 | --------------------------------------------------------------------------
 | Exit Status Codes
 | --------------------------------------------------------------------------
 |
 | Used to indicate the conditions under which the script is exit()ing.
 | While there is no universal standard for error codes, there are some
 | broad conventions.  Three such conventions are mentioned below, for
 | those who wish to make use of them.  The ColdIgniter defaults were
 | chosen for the least overlap with these conventions, while still
 | leaving room for others to be defined in future versions and user
 | applications.
 |
 | The three main conventions used for determining exit status codes
 | are as follows:
 |
 |    Standard C/C++ Library (stdlibc):
 |       http://www.gnu.org/software/libc/manual/html_node/Exit-Status.html
 |       (This link also contains other GNU-specific conventions)
 |    BSD sysexits.h:
 |       http://www.gsp.com/cgi-bin/man.cgi?section=3&topic=sysexits
 |    Bash scripting:
 |       http://tldp.org/LDP/abs/html/exitcodes.html
 |
--->
<cfset defined("EXIT_SUCCESS")        OR define("EXIT_SUCCESS", 0)>        <!--- no errors --->
<cfset defined("EXIT_ERROR")          OR define("EXIT_ERROR", 1)>          <!--- generic error --->
<cfset defined("EXIT_CONFIG")         OR define("EXIT_CONFIG", 3)>         <!--- configuration error --->
<cfset defined("EXIT_UNKNOWN_FILE")   OR define("EXIT_UNKNOWN_FILE", 4)>   <!--- file not found --->
<cfset defined("EXIT_UNKNOWN_CLASS")  OR define("EXIT_UNKNOWN_CLASS", 5)>  <!--- unknown class --->
<cfset defined("EXIT_UNKNOWN_METHOD") OR define("EXIT_UNKNOWN_METHOD", 6)> <!--- unknown class member --->
<cfset defined("EXIT_USER_INPUT")     OR define("EXIT_USER_INPUT", 7)>     <!--- invalid user input --->
<cfset defined("EXIT_DATABASE")       OR define("EXIT_DATABASE", 8)>       <!--- database error --->
<cfset defined("EXIT__AUTO_MIN")      OR define("EXIT__AUTO_MIN", 9)>      <!--- lowest automatically-assigned error code --->
<cfset defined("EXIT__AUTO_MAX")      OR define("EXIT__AUTO_MAX", 125)>    <!--- highest automatically-assigned error code --->
