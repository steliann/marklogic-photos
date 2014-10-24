xquery version "1.0-ml";

module namespace geo = "http://snastase.com/geo";

declare namespace search = "http://marklogic.com/appservices/search";

declare variable $geo:AFRICA as xs:string := "africa";
declare variable $geo:ANTARTICA as xs:string := "antartica";
declare variable $geo:ASIA as xs:string := "asia";
declare variable $geo:AUSTRALIA as xs:string := "australia";
declare variable $geo:EUROPE as xs:string := "europe";
declare variable $geo:NORTH_AMERICA as xs:string := "north_america";
declare variable $geo:SOUTH_AMERICA as xs:string := "south_america";

declare function geo:parse(
  $qtext as xs:string,
  $right as schema-element(cts:query) )
	as schema-element(cts:query)
{

element cts:element-attribute-pair-geospatial-query {
    	attribute qtextconst {fn:concat($qtext, fn:string($right//cts:text)) }, 
	  	element cts:annotation {"This is a custom constraint on continents" },
    	element cts:element { "city" },
    	element cts:latitude {"latitude"},
    	element cts:longitude {"longitude"},
    	element cts:region {
	    	attribute xsi:type { "cts:polygon" }, geo:get-range(fn:string($right//cts:text))},
	  	element cts:option { "coordinate-system=wgs84" } }
    
};

declare function geo:start-facet(
	$constraint as element(search:constraint), 
	$query as cts:query?,
	$facet-options as xs:string*, 
	$quality-weight as xs:double?,
  	$forests as xs:unsignedLong*)
as item()*
{
let $map := map:new()
let $_ := map:put($map, $geo:AFRICA, get-values($geo:AFRICA, $query))
let $_ := map:put($map, $geo:ANTARTICA, get-values($geo:ANTARTICA, $query))
let $_ := map:put($map, $geo:ASIA, get-values($geo:ASIA, $query))
let $_ := map:put($map, $geo:AUSTRALIA, get-values($geo:AUSTRALIA, $query))
let $_ := map:put($map, $geo:EUROPE, get-values($geo:EUROPE, $query))
let $_ := map:put($map, $geo:NORTH_AMERICA, get-values($geo:NORTH_AMERICA, $query))
let $_ := map:put($map, $geo:SOUTH_AMERICA, get-values($geo:SOUTH_AMERICA, $query))
  
return
	$map
};	

declare private function geo:get-values(
	$region as xs:string, 
	$query as cts:query?)
		as cts:point*
{

let $range := geo:get-range($region)

let $geo-query :=  cts:element-attribute-pair-geospatial-query(xs:QName("city"),
    xs:QName("latitude"), xs:QName("longitude"), $range)
    
let $and-query := cts:and-query(($query, $geo-query))    

return 
 cts:element-attribute-pair-geospatial-values(
    xs:QName("city"),
    xs:QName("latitude"), 
    xs:QName("longitude"),
    cts:point("-180,-90"),
    <options>
      <option>document</option>
    </options>,
    $and-query
  )	
};		
	
declare function geo:finish-facet(
	$start as item()*,
	$constraint as element(search:constraint), 
	$query as cts:query?,
	$facet-options as xs:string*, 
	$quality-weight as xs:double?,
	$forests as xs:unsignedLong*)
as element(search:facet)
{
	let $labels := $constraint/search:custom/search:annotation/search:regions
 
  	return
  		element search:facet {
  			attribute name {$constraint/@name},
    		for $key in map:keys($start)
    			return
    				element search:facet-value{
						attribute name {
							$labels/search:region[. eq fn:string($key)]/@label },
						attribute count {fn:sum(cts:frequency(map:get($start, $key)))}, 
						fn:string($key) 
					}
		}
};

declare private function geo:get-range (
    $rname as xs:string) 
		as cts:polygon
{
	let $kml := fn:doc(fn:concat("/kml/",$rname,".xml"))

	let $pairs := 
    	for $triple in fn:tokenize($kml//coordinates/text(), " ")
      		return
         		let $arr := fn:tokenize($triple,",")
          		return
            		cts:point(fn:number($arr[2]),fn:number($arr[1]))
          
  	let $count := fn:count($pairs)          
  	let $clean := fn:remove(fn:remove($pairs,$count),1)
          
  	return cts:polygon($clean) 
};

