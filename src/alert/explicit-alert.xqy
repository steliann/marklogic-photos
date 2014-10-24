xquery version "1.0-ml";

declare namespace alert = "http://marklogic.com/xdmp/alert";

declare variable $alert:config-uri as xs:string external;
declare variable $alert:doc as node() external;
declare variable $alert:rule as element(alert:rule) external;
declare variable $alert:action as element(alert:action) external;


if (fn:compare($alert:rule/alert:name/text(),"explicit-rule") = 0)
then try {
	let $_ := xdmp:log(fn:concat("alert processing for ","uri"))
	return
  		if ($alert:doc/photo/explicit)
  		then ()
  		else
      		xdmp:node-insert-child($alert:doc/photo, <explicit>true</explicit>),
      		xdmp:log(fn:concat(fn:document-uri($alert:doc), " was flagged as explicit")) }
catch ($e) {
  fn:concat("Problem trying to flag document ", fn:document-uri($alert:doc), " as explicit"), $e 
}
else ()