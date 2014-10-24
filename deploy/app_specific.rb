#
# Put your custom functions in this class in order to keep the files under lib untainted
#
# This class has access to all of the stuff in deploy/lib/server_config.rb
#
class ServerConfig
  def deploy_alerting()
    r = execute_query %Q{
    
    import module namespace alert = "http://marklogic.com/xdmp/alert" at "/MarkLogic/alert.xqy";
    if (alert:config-get("http://snastase.com/alert/photo")) then 
    	alert:config-insert(
  			alert:config-set-cpf-domain-names(
    			alert:config-get("http://snastase.com/alert/photo"),()))
    else();		
    
    import module namespace alert = "http://marklogic.com/xdmp/alert" at "/MarkLogic/alert.xqy";
    if (alert:config-get("http://snastase.com/alert/photo")) then 
  		alert:config-delete("http://snastase.com/alert/photo")
  	else();
    
    import module namespace alert = "http://marklogic.com/xdmp/alert" at "/MarkLogic/alert.xqy";
    if (alert:config-get("http://snastase.com/alert/photo")) then ()
    else
      let $config :=
        alert:make-config(
          "http://snastase.com/alert/photo",
          "Alert Explicit Content",
          "Alerting config for explicit content tagging application",
          <alert:options/>)
      return
        alert:config-insert($config);
        
    import module namespace alert = "http://marklogic.com/xdmp/alert" at "/MarkLogic/alert.xqy";
	let $action := alert:make-action(
    	"explicit-alert", 
    	"Flags the metadata document",
    	xdmp:modules-database(),
    	"/", 
    	"/alert/explicit-alert.xqy",
    	<alert:options />)
	return
		alert:action-insert("http://snastase.com/alert/photo", $action);
		
	import module namespace alert = "http://marklogic.com/xdmp/alert" at "/MarkLogic/alert.xqy";
	let $rule := alert:make-rule(
    	"explicit-rule", 
    	"Rule for detecting explicit content",
    	0, 
    	cts:or-query((
          cts:word-query("sex"),
          cts:word-query("die"),
          cts:word-query("death"),
          cts:word-query("violent"),
          cts:word-query("assault")
    	)),
    	"explicit-alert",
    	<alert:options/> )
	return
		alert:rule-insert("http://snastase.com/alert/photo", $rule);
		
	import module namespace alert = "http://marklogic.com/xdmp/alert" at "/MarkLogic/alert.xqy";
	alert:config-insert(
  		alert:config-set-cpf-domain-names(
    		alert:config-get("http://snastase.com/alert/photo"),("Photos Metadata")));
        

  },
  { :app_name => @properties["ml.app-name"] }
  end
  
  def clean_alerting()
    r = execute_query %Q{
    
    import module namespace alert = "http://marklogic.com/xdmp/alert" at "/MarkLogic/alert.xqy";
    if (alert:config-get("http://snastase.com/alert/photo")) then 
    	alert:config-insert(
  			alert:config-set-cpf-domain-names(
    			alert:config-get("http://snastase.com/alert/photo"),()))
    else();		
    
    import module namespace alert = "http://marklogic.com/xdmp/alert" at "/MarkLogic/alert.xqy";
    if (alert:config-get("http://snastase.com/alert/photo")) then 
  		alert:config-delete("http://snastase.com/alert/photo")
  	else();
    
  },
  { :app_name => @properties["ml.app-name"] }
  end
end