xquery version "1.0-ml";

module namespace cfg = "http://snastase.com/services/config";

declare variable $cfg:MLJAM_URL as xs:string := "http://localhost:8580/mljam";
declare variable $cfg:MLJAM_USR as xs:string := "mljam";
declare variable $cfg:MLJAM_PWD as xs:string := "secret";

declare variable $cfg:CALAIS_URL as xs:string := "http://api.opencalais.com/tag/rs/enrich";
declare variable $cfg:CALAIS_KEY as xs:string := "rktqmhu4t6x7rs7ch8qfstwd";