xquery version "1.0-ml";

module namespace app = "http://marklogic.com/rest-api/resource/tag";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";
import module namespace cfg = "http://snastase.com/services/config" at "/config/services.xqy";

declare namespace roxy = "http://marklogic.com/roxy";
declare namespace srs  = "http://www.w3.org/2005/sparql-results#";

(:
 :)
declare 
%roxy:params("uri=xs:string")
function app:put(
    $context as map:map,
    $params  as map:map,
    $input   as document-node()*
) as document-node()?
{
  map:put($context, "input-types", "application/xml"),
  map:put($context, "output-types", "application/xml"),
  map:put($context, "output-status", (202, "Accepted")),
  document { 
  	let $duri := map:get($params,"uri")
  	let $ddoc := doc($duri)   
  	(:
  	 : Deletes the previous triples file
  	 :) 
  	let $turi :=
  		cts:search(/sem:triples,
         cts:and-query((
           cts:collection-query("http://marklogic.com/semantics/photos/"),
           cts:word-query($duri, "exact")
         )))
           
	let $_ := xdmp:document-delete(fn:base-uri($turi)) 
  	
  	(:
  	 : Gets the triples from OpenCalais and saves them
  	 :) 
	let $data := $ddoc/photo/description/text()

	let $rdf := xdmp:http-post($cfg:CALAIS_URL,
     <options xmlns="xdmp:http">
       <data>{$data}</data>
       <headers>
         <x-calais-licenseID>{$cfg:CALAIS_KEY}</x-calais-licenseID>
         <content-type>text/xml; charset=UTF-8</content-type>
         <accept>xml/rdf</accept>
         <externalID>{$duri}</externalID>
         <reltagBaseURL>http://snastase.com/tag</reltagBaseURL>
         <enableMetadataType>GenericRelations,SocialTags</enableMetadataType>
       </headers>
     </options>)/rdf:RDF
     
    let $_ := xdmp:log(fn:concat("OpenCalais returned ", fn:count($rdf//rdf:Description), " triples"))
     
    let $_ := xdmp:invoke-function( function(){
      	let $tri := sem:rdf-insert(sem:rdf-parse($rdf,"rdfxml"),"override-graph=http://marklogic.com/semantics/photos/")
      	let $_ := xdmp:log(fn:concat(fn:count($rdf//rdf:Description), " triples stored in ", $tri))
      	return
      		xdmp:commit()
      },
      <options xmlns="xdmp:eval">
        <transaction-mode>update</transaction-mode>
        <isolation>different-transaction</isolation>
      </options>
    )
    
	let $_ := xdmp:sleep(500)
	
	let $_ := xdmp:log("Going to extract the tags from the triples")

	(:
	 : Extract tags from the triples
	 :) 
	let $bindings := map:new(map:entry("uri", $duri))
 
	let $tags := sem:query-results-serialize(
    	sem:sparql('
      		SELECT ?tag
      		FROM <http://marklogic.com/semantics/photos/>
      		WHERE { 
        		?did <http://s.opencalais.com/1/pred/externalID> $uri.
        		?tid <http://s.opencalais.com/1/pred/name> ?tag.
        		FILTER regex(?tid, ?did)
      		}
    	', $bindings
    ))//srs:literal/text()
    
    (:
     : Replaces the tags in the original document
     :)   	
    let $_ := xdmp:log(fn:concat(fn:count($tags), " tags extracted")) 
    let $_ := xdmp:node-delete($ddoc//tags)

	let $mtag := <tags>{
                  for $tag in $tags
                    return
                      <tag>{$tag}</tag>
                 }</tags> 

	let $_ := xdmp:node-insert-child($ddoc/photo,$mtag)
						
	return
		xdmp:log(fn:concat($duri, " has been processed")),
		"Automatic tag generation called" 
  }
};
