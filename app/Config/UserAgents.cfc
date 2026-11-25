<!---
 * -------------------------------------------------------------------
 * User Agents
 * -------------------------------------------------------------------
 *
 * This file contains four arrays of user agent data. It is used by the
 * User Agent Class to help identify browser, platform, robot, and
 * mobile device data. The array keys are used to identify the device
 * and the array values are used to set the actual name of the item.
 *
 * Difference: each array is a map that keeps the order of the keys (a
 * LinkedHashMap), as the first match wins.
--->
<cfcomponent output="no" parent="ColdIgniter\Config\BaseConfig" hint="User agents configuration">

	<!---
	 * -------------------------------------------------------------------
	 * OS Platforms
	 * -------------------------------------------------------------------
	 *
	 * @var array<string, string>
	--->
	<cfset this.platforms = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.platforms["windows nt 10.0"] = "Windows 10">
	<cfset this.platforms["windows nt 6.3"] = "Windows 8.1">
	<cfset this.platforms["windows nt 6.2"] = "Windows 8">
	<cfset this.platforms["windows nt 6.1"] = "Windows 7">
	<cfset this.platforms["windows nt 6.0"] = "Windows Vista">
	<cfset this.platforms["windows nt 5.2"] = "Windows 2003">
	<cfset this.platforms["windows nt 5.1"] = "Windows XP">
	<cfset this.platforms["windows nt 5.0"] = "Windows 2000">
	<cfset this.platforms["windows nt 4.0"] = "Windows NT 4.0">
	<cfset this.platforms["winnt4.0"] = "Windows NT 4.0">
	<cfset this.platforms["winnt 4.0"] = "Windows NT">
	<cfset this.platforms["winnt"] = "Windows NT">
	<cfset this.platforms["windows 98"] = "Windows 98">
	<cfset this.platforms["win98"] = "Windows 98">
	<cfset this.platforms["windows 95"] = "Windows 95">
	<cfset this.platforms["win95"] = "Windows 95">
	<cfset this.platforms["windows phone"] = "Windows Phone">
	<cfset this.platforms["windows"] = "Unknown Windows OS">
	<cfset this.platforms["android"] = "Android">
	<cfset this.platforms["blackberry"] = "BlackBerry">
	<cfset this.platforms["iphone"] = "iOS">
	<cfset this.platforms["ipad"] = "iOS">
	<cfset this.platforms["ipod"] = "iOS">
	<cfset this.platforms["os x"] = "Mac OS X">
	<cfset this.platforms["ppc mac"] = "Power PC Mac">
	<cfset this.platforms["freebsd"] = "FreeBSD">
	<cfset this.platforms["ppc"] = "Macintosh">
	<cfset this.platforms["linux"] = "Linux">
	<cfset this.platforms["debian"] = "Debian">
	<cfset this.platforms["sunos"] = "Sun Solaris">
	<cfset this.platforms["beos"] = "BeOS">
	<cfset this.platforms["apachebench"] = "ApacheBench">
	<cfset this.platforms["aix"] = "AIX">
	<cfset this.platforms["irix"] = "Irix">
	<cfset this.platforms["osf"] = "DEC OSF">
	<cfset this.platforms["hp-ux"] = "HP-UX">
	<cfset this.platforms["netbsd"] = "NetBSD">
	<cfset this.platforms["bsdi"] = "BSDi">
	<cfset this.platforms["openbsd"] = "OpenBSD">
	<cfset this.platforms["gnu"] = "GNU/Linux">
	<cfset this.platforms["unix"] = "Unknown Unix OS">
	<cfset this.platforms["symbian"] = "Symbian OS">

	<!---
	 * -------------------------------------------------------------------
	 * Browsers
	 * -------------------------------------------------------------------
	 *
	 * The order of this array should NOT be changed. Many browsers return
	 * multiple browser types so we want to identify the subtype first.
	 *
	 * @var array<string, string>
	--->
	<cfset this.browsers = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.browsers["OPR"] = "Opera">
	<cfset this.browsers["Flock"] = "Flock">
	<cfset this.browsers["Edge"] = "Spartan">
	<cfset this.browsers["Edg"] = "Edge">
	<cfset this.browsers["Chrome"] = "Chrome">
	<!--- Opera 10+ always reports Opera/9.80 and appends Version/<real version> to the user agent string --->
	<cfset this.browsers["Opera.*?Version"] = "Opera">
	<cfset this.browsers["Opera"] = "Opera">
	<cfset this.browsers["MSIE"] = "Internet Explorer">
	<cfset this.browsers["Internet Explorer"] = "Internet Explorer">
	<cfset this.browsers["Trident.* rv"] = "Internet Explorer">
	<cfset this.browsers["Shiira"] = "Shiira">
	<cfset this.browsers["Firefox"] = "Firefox">
	<cfset this.browsers["Chimera"] = "Chimera">
	<cfset this.browsers["Phoenix"] = "Phoenix">
	<cfset this.browsers["Firebird"] = "Firebird">
	<cfset this.browsers["Camino"] = "Camino">
	<cfset this.browsers["Netscape"] = "Netscape">
	<cfset this.browsers["OmniWeb"] = "OmniWeb">
	<cfset this.browsers["Safari"] = "Safari">
	<cfset this.browsers["Mozilla"] = "Mozilla">
	<cfset this.browsers["Konqueror"] = "Konqueror">
	<cfset this.browsers["icab"] = "iCab">
	<cfset this.browsers["Lynx"] = "Lynx">
	<cfset this.browsers["Links"] = "Links">
	<cfset this.browsers["hotjava"] = "HotJava">
	<cfset this.browsers["amaya"] = "Amaya">
	<cfset this.browsers["IBrowse"] = "IBrowse">
	<cfset this.browsers["Maxthon"] = "Maxthon">
	<cfset this.browsers["Ubuntu"] = "Ubuntu Web Browser">
	<cfset this.browsers["Vivaldi"] = "Vivaldi">

	<!---
	 * -------------------------------------------------------------------
	 * Mobiles
	 * -------------------------------------------------------------------
	 *
	 * @var array<string, string>
	--->
	<cfset this.mobiles = CreateObject("java", "java.util.LinkedHashMap").init()>
	<!--- legacy array, old values commented out --->
	<cfset this.mobiles["mobileexplorer"] = "Mobile Explorer">
	<!--- 'openwave'             => 'Open Wave', --->
	<!--- 'opera mini'           => 'Opera Mini', --->
	<!--- 'operamini'            => 'Opera Mini', --->
	<!--- 'elaine'               => 'Palm', --->
	<cfset this.mobiles["palmsource"] = "Palm">
	<!--- 'digital paths'        => 'Palm', --->
	<!--- 'avantgo'              => 'Avantgo', --->
	<!--- 'xiino'                => 'Xiino', --->
	<cfset this.mobiles["palmscape"] = "Palmscape">
	<!--- 'nokia'                => 'Nokia', --->
	<!--- 'ericsson'             => 'Ericsson', --->
	<!--- 'blackberry'           => 'BlackBerry', --->
	<!--- 'motorola'             => 'Motorola' --->

	<!--- Phones and Manufacturers --->
	<cfset this.mobiles["motorola"] = "Motorola">
	<cfset this.mobiles["nokia"] = "Nokia">
	<cfset this.mobiles["palm"] = "Palm">
	<cfset this.mobiles["iphone"] = "Apple iPhone">
	<cfset this.mobiles["ipad"] = "iPad">
	<cfset this.mobiles["ipod"] = "Apple iPod Touch">
	<cfset this.mobiles["sony"] = "Sony Ericsson">
	<cfset this.mobiles["ericsson"] = "Sony Ericsson">
	<cfset this.mobiles["blackberry"] = "BlackBerry">
	<cfset this.mobiles["cocoon"] = "O2 Cocoon">
	<cfset this.mobiles["blazer"] = "Treo">
	<cfset this.mobiles["lg"] = "LG">
	<cfset this.mobiles["amoi"] = "Amoi">
	<cfset this.mobiles["xda"] = "XDA">
	<cfset this.mobiles["mda"] = "MDA">
	<cfset this.mobiles["vario"] = "Vario">
	<cfset this.mobiles["htc"] = "HTC">
	<cfset this.mobiles["samsung"] = "Samsung">
	<cfset this.mobiles["sharp"] = "Sharp">
	<cfset this.mobiles["sie-"] = "Siemens">
	<cfset this.mobiles["alcatel"] = "Alcatel">
	<cfset this.mobiles["benq"] = "BenQ">
	<cfset this.mobiles["ipaq"] = "HP iPaq">
	<cfset this.mobiles["mot-"] = "Motorola">
	<cfset this.mobiles["playstation portable"] = "PlayStation Portable">
	<cfset this.mobiles["playstation 3"] = "PlayStation 3">
	<cfset this.mobiles["playstation vita"] = "PlayStation Vita">
	<cfset this.mobiles["hiptop"] = "Danger Hiptop">
	<cfset this.mobiles["nec-"] = "NEC">
	<cfset this.mobiles["panasonic"] = "Panasonic">
	<cfset this.mobiles["philips"] = "Philips">
	<cfset this.mobiles["sagem"] = "Sagem">
	<cfset this.mobiles["sanyo"] = "Sanyo">
	<cfset this.mobiles["spv"] = "SPV">
	<cfset this.mobiles["zte"] = "ZTE">
	<cfset this.mobiles["sendo"] = "Sendo">
	<cfset this.mobiles["nintendo dsi"] = "Nintendo DSi">
	<cfset this.mobiles["nintendo ds"] = "Nintendo DS">
	<cfset this.mobiles["nintendo 3ds"] = "Nintendo 3DS">
	<cfset this.mobiles["wii"] = "Nintendo Wii">
	<cfset this.mobiles["open web"] = "Open Web">
	<cfset this.mobiles["openweb"] = "OpenWeb">

	<!--- Operating Systems --->
	<cfset this.mobiles["android"] = "Android">
	<cfset this.mobiles["symbian"] = "Symbian">
	<cfset this.mobiles["SymbianOS"] = "SymbianOS">
	<cfset this.mobiles["elaine"] = "Palm">
	<cfset this.mobiles["series60"] = "Symbian S60">
	<cfset this.mobiles["windows ce"] = "Windows CE">

	<!--- Browsers --->
	<cfset this.mobiles["obigo"] = "Obigo">
	<cfset this.mobiles["netfront"] = "Netfront Browser">
	<cfset this.mobiles["openwave"] = "Openwave Browser">
	<cfset this.mobiles["mobilexplorer"] = "Mobile Explorer">
	<cfset this.mobiles["operamini"] = "Opera Mini">
	<cfset this.mobiles["opera mini"] = "Opera Mini">
	<cfset this.mobiles["opera mobi"] = "Opera Mobile">
	<cfset this.mobiles["fennec"] = "Firefox Mobile">

	<!--- Other --->
	<cfset this.mobiles["digital paths"] = "Digital Paths">
	<cfset this.mobiles["avantgo"] = "AvantGo">
	<cfset this.mobiles["xiino"] = "Xiino">
	<cfset this.mobiles["novarra"] = "Novarra Transcoder">
	<cfset this.mobiles["vodafone"] = "Vodafone">
	<cfset this.mobiles["docomo"] = "NTT DoCoMo">
	<cfset this.mobiles["o2"] = "O2">

	<!--- Fallback --->
	<cfset this.mobiles["mobile"] = "Generic Mobile">
	<cfset this.mobiles["wireless"] = "Generic Mobile">
	<cfset this.mobiles["j2me"] = "Generic Mobile">
	<cfset this.mobiles["midp"] = "Generic Mobile">
	<cfset this.mobiles["cldc"] = "Generic Mobile">
	<cfset this.mobiles["up.link"] = "Generic Mobile">
	<cfset this.mobiles["up.browser"] = "Generic Mobile">
	<cfset this.mobiles["smartphone"] = "Generic Mobile">
	<cfset this.mobiles["cellphone"] = "Generic Mobile">

	<!---
	 * -------------------------------------------------------------------
	 * Robots
	 * -------------------------------------------------------------------
	 *
	 * There are hundred of bots but these are the most common.
	 *
	 * @var array<string, string>
	--->
	<cfset this.robots = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.robots["googlebot"] = "Googlebot">
	<cfset this.robots["google-pagerenderer"] = "Google Page Renderer">
	<cfset this.robots["google-read-aloud"] = "Google Read Aloud">
	<cfset this.robots["google-safety"] = "Google Safety Bot">
	<cfset this.robots["msnbot"] = "MSNBot">
	<cfset this.robots["baiduspider"] = "Baiduspider">
	<cfset this.robots["bingbot"] = "Bing">
	<cfset this.robots["bingpreview"] = "BingPreview">
	<cfset this.robots["slurp"] = "Inktomi Slurp">
	<cfset this.robots["yahoo"] = "Yahoo">
	<cfset this.robots["ask jeeves"] = "Ask Jeeves">
	<cfset this.robots["fastcrawler"] = "FastCrawler">
	<cfset this.robots["infoseek"] = "InfoSeek Robot 1.0">
	<cfset this.robots["lycos"] = "Lycos">
	<cfset this.robots["yandex"] = "YandexBot">
	<cfset this.robots["mediapartners-google"] = "MediaPartners Google">
	<cfset this.robots["CRAZYWEBCRAWLER"] = "Crazy Webcrawler">
	<cfset this.robots["adsbot-google"] = "AdsBot Google">
	<cfset this.robots["feedfetcher-google"] = "Feedfetcher Google">
	<cfset this.robots["curious george"] = "Curious George">
	<cfset this.robots["ia_archiver"] = "Alexa Crawler">
	<cfset this.robots["MJ12bot"] = "Majestic-12">
	<cfset this.robots["Uptimebot"] = "Uptimebot">
	<cfset this.robots["duckduckbot"] = "DuckDuckBot">
	<cfset this.robots["sogou"] = "Sogou Spider">
	<cfset this.robots["exabot"] = "Exabot">
	<cfset this.robots["bot"] = "Generic Bot">
	<cfset this.robots["crawler"] = "Generic Crawler">
	<cfset this.robots["spider"] = "Generic Spider">
</cfcomponent>
