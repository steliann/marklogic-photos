xquery version "1.0-ml";

import module namespace cpf = "http://marklogic.com/cpf" at "/MarkLogic/cpf/cpf.xqy";
import module namespace jam = "http://xqdev.com/jam" at "/jam/jam.xqy";
import module namespace mex = "http://marklogic.com/photos/metadata/extract" at "/metadata/extract-meta.xqy";
import module namespace cfg = "http://snastase.com/services/config" at "/config/services.xqy";

declare variable $cpf:document-uri as xs:string external; 
declare variable $cpf:transition as node() external;

if (cpf:check-transition($cpf:document-uri,$cpf:transition)) 
then try {
	
	let $meta-node := fn:doc($cpf:document-uri)

	let $city := fn:string-join(fn:tokenize($meta-node//city/text(), " "), "_")
	
	let $_ := jam:start($cfg:MLJAM_URL, $cfg:MLJAM_USR, $cfg:MLJAM_PWD)
	let $_ := jam:set("city", $city)
	
	let $res := jam:eval-get('{
      
  		import com.hp.hpl.jena.query.QueryExecution;
  		import com.hp.hpl.jena.query.QueryExecutionFactory;
  		import com.hp.hpl.jena.sparql.engine.http.QueryExceptionHTTP;
  		import com.hp.hpl.jena.query.ResultSet;
  		import com.hp.hpl.jena.query.QuerySolution; 


  		String service = "http://dbpedia.org/sparql";
  		String query = "PREFIX geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>" +
    		"SELECT ?lat ?long WHERE {" +
    		"<http://dbpedia.org/resource/" +city+"> geo:lat ?lat."+
    		"<http://dbpedia.org/resource/" +city+"> geo:long ?long.}";
    
    	String s = "";
    
    	QueryExecution qe = QueryExecutionFactory.sparqlService(service, query);
  
    	try {
      		ResultSet results = qe.execSelect();

      		for (; results.hasNext();) {
        		QuerySolution sol = (QuerySolution) results.next();
        		s = sol.getLiteral("lat").getLexicalForm() + " " + sol.get("long").getLexicalForm();
      	}
    	} catch (QueryExceptionHTTP e) {
            s = service + " is DOWN";
    	} finally {
            qe.close();
    	} 
        
    	return s;
        
	}')
	
	let $_ := jam:end()
	
	return
	if (fn:string-length($res) > 0)
	then	
		let $geo := fn:tokenize($res, " ")
	
		let $old_node := $meta-node//city
		let $new_node := mex:add-geo-attributes($old_node, $geo[1], $geo[2])
		let $_ := xdmp:node-replace($old_node, $new_node)
        let $_ := xdmp:log(fn:concat($cpf:document-uri, " geo metadata was updated"))
	
		return		
        	cpf:success( $cpf:document-uri, $cpf:transition, () )
     else
     	let $_ := xdmp:log(fn:concat($cpf:document-uri, " geo metadata not found"))
		return		
        	cpf:success( $cpf:document-uri, $cpf:transition, () )
     	   		
}
catch ($e) {
	cpf:failure( $cpf:document-uri, $cpf:transition, $e, () ) }
else ()