xquery version "1.0-ml";

module namespace mex = "http://marklogic.com/photos/metadata/extract";

declare function mex:map_metadata($meta-html as item()) {
	let $image-meta :=
    	<image-meta>
    		<size>{fn:string($meta-html//*[@name="size"]/@content)}</size>
    	</image-meta>
  
  return $image-meta
};


declare function mex:add-geo-attributes(
	$element as element(), 
	$latitude as xs:anyAtomicType?, 
	$longitude as xs:anyAtomicType?)
{
	element { node-name($element) } {
		attribute latitude { $latitude },
		attribute longitude { $longitude },
		(:$element/@*,:)
		$element/node()
	}
};

