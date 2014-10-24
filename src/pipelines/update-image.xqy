xquery version "1.0-ml";

import module namespace cpf = "http://marklogic.com/cpf" at "/MarkLogic/cpf/cpf.xqy";
import module namespace mex = "http://marklogic.com/photos/metadata/extract" at "/metadata/extract-meta.xqy";

declare variable $cpf:document-uri as xs:string external; 
declare variable $cpf:transition as node() external;

if (cpf:check-transition($cpf:document-uri,$cpf:transition)) 
then try {

	let $jpg := fn:doc($cpf:document-uri)
	let $meta := xdmp:document-filter($jpg)

	let $meta-img := mex:map_metadata($meta)
	let $photo-uri := fn:concat(
						"/metadata/",
						fn:substring-before(
							fn:substring-after($cpf:document-uri,"/image/"),
							"."),
						".xml"
					 )
					 
	let $meta-node := fn:doc($photo-uri)
	
	return
		if($meta-node) then (
			  if (xdmp:path($meta-node/photo/image-meta)) then
			      	xdmp:node-replace(
						$meta-node/photo/image-meta,
						$meta-img
			      	)     
		      else  
            		xdmp:node-insert-child(
              			$meta-node/photo,
              			$meta-img
            		) , 		
        	  xdmp:log(fn:concat($photo-uri, " metadata was updated")),		
              cpf:success( $cpf:document-uri, $cpf:transition, () )		
        )  
        else (    
        	xdmp:log(fn:concat($photo-uri, " metadata was not updated because is missing")),
			cpf:success( $cpf:document-uri, $cpf:transition, () )
		)
}
catch ($e) {
	cpf:failure( $cpf:document-uri, $cpf:transition, $e, () ) }
else ()