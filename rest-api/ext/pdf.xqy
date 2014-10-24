xquery version "1.0-ml";

module namespace app = "http://marklogic.com/rest-api/resource/pdf";

import module namespace jam = "http://xqdev.com/jam" at "/jam/jam.xqy";
import module namespace cfg = "http://snastase.com/services/config" at "/config/services.xqy";

declare namespace roxy = "http://marklogic.com/roxy";
declare namespace rapi = "http://marklogic.com/rest-api";

(:
 : This function returns back the PDF created from the photo metadata document.
 : It use MLJAM t build the PDF in Java and passes back to the requester the byte array with 
 : the document  
 :)
declare 
%roxy:params("uri=xs:string")
function app:get(
  $context as map:map,
  $params  as map:map
) as document-node()*
{
  	map:put($context, "output-types", "application/pdf"),
  	map:put($context, "output-headers", map:new(
  		map:entry("Content-Disposition", 'attachment; filename=fn:concat(id, ".pdf")'))),
  	map:put($context, "output-status", (200, "OK")),
    document {
    	try {
    		let $id := fn:substring-before(fn:substring-after(map:get($params,"uri"),"/pdf/"),".") 
			
			let $meta-uri := fn:concat("/metadata/", $id, ".xml")
			let $jpeg-uri := fn:concat("/image/", $id, ".jpg")
			
            let $_ := jam:start($cfg:MLJAM_URL, $cfg:MLJAM_USR, $cfg:MLJAM_PWD)
            
			let $_ := jam:set("title", doc($meta-uri)/photo/title/text())
			let $_ := jam:set("author", doc($meta-uri)/photo/photo-meta/author/text())
			let $_ := jam:set("text", doc($meta-uri)/photo/description/text())
			let $_ := jam:set("jpeg", doc($jpeg-uri))
			let $_ := jam:set("space", " ")
			let $_ := jam:set("empty", "")
	
			let $pdf := jam:eval-get('{
			  			
  				import java.awt.Color;
  				import java.io.ByteArrayInputStream;
  				import java.io.InputStream;
  				import java.util.ArrayList;
  				import java.util.List;

  				import org.apache.pdfbox.pdmodel.PDDocument;
  				import org.apache.pdfbox.pdmodel.PDPage;
  				import org.apache.pdfbox.pdmodel.common.PDRectangle;
  				import org.apache.pdfbox.pdmodel.edit.PDPageContentStream;
  				import org.apache.pdfbox.pdmodel.font.PDFont;
  				import org.apache.pdfbox.pdmodel.font.PDType1Font;
  				import org.apache.pdfbox.pdmodel.graphics.xobject.PDJpeg;
  				import org.apache.pdfbox.pdmodel.graphics.xobject.PDPixelMap;
  				import org.apache.pdfbox.pdmodel.graphics.xobject.PDXObjectImage;


  				PDDocument document = new PDDocument();
  				PDPage page = new PDPage(PDPage.PAGE_SIZE_A4);
  				
  				PDRectangle rect = page.getMediaBox();
    			float margin = 72;
    			float width = rect.getWidth() - 2*margin;
   				float startX = rect.getLowerLeftX() + margin;
    			float startY = rect.getUpperRightY() - margin;
  
  				document.addPage(page);

        		PDFont fontBold = PDType1Font.HELVETICA_BOLD;
    			float fontTitleSize = 18;
    			float fontAuthorSize = 14;
        		
        		PDFont fontItalic = PDType1Font.HELVETICA_OBLIQUE;
    			float fontItalicSize = 14;
    			float leading = 1.5f * fontItalicSize;

        		// Start a new content stream which will "hold" the to be created content
        		PDPageContentStream cos = new PDPageContentStream(document, page);
        		int line = 1;

        		cos.beginText();
        		cos.setFont(fontBold, fontTitleSize);
        		cos.moveTextPositionByAmount(100, rect.getHeight() - 50*(++line));
        		cos.drawString(title);
        		cos.endText();
        		
        		cos.beginText();
        		cos.setFont(fontBold, fontAuthorSize);
        		cos.moveTextPositionByAmount(100, rect.getHeight() - 50*(++line));
        		cos.drawString(author);
        		cos.endText();
        		
        		List lines = new ArrayList();
    			int lastSpace = -1;
    			while (text.length() > 0){
        			int spaceIndex = text.indexOf(space, lastSpace + 1);
        			if (spaceIndex < 0){
            			lines.add(text);
            			text = empty;
        			}
        			else{
            			String subString = text.substring(0, spaceIndex);
            			float size = fontItalicSize * fontItalic.getStringWidth(subString) / 1000;
            			if (size > width){
                			if (lastSpace < 0) 
                    			lastSpace = spaceIndex;
                			subString = text.substring(0, lastSpace);
                			lines.add(subString);
                			text = text.substring(lastSpace).trim();
                			lastSpace = -1;
            			}
            			else{
                			lastSpace = spaceIndex;
            			}
        			}
    			}
    			
    			
          		cos.beginText();
    			cos.setFont(fontItalic, fontItalicSize);
    			cos.moveTextPositionByAmount(100, rect.getHeight() - 50*(++line));            
    			for (String line: lines){
        			cos.drawString(line);
        			cos.moveTextPositionByAmount(0, -leading);
    			}
    			cos.endText(); 
        		
        		InputStream bais = new ByteArrayInputStream(jpeg);
        
        		PDXObjectImage ximage = new PDJpeg(document, bais);
        		cos.drawXObject( ximage, 100, rect.getHeight() - 45*(2 + lines.size()) - 280, 400,280 );

        		// Make sure that the content stream is closed:
        		cos.close();

  				// Save the newly created document
  				ByteArrayOutputStream baos = new ByteArrayOutputStream(10240);
  				document.save(baos);

  				// finally make sure that the document is properly closed.
  				document.close();
  
  				baos.toByteArray(); 
			}') 

			let $_ := jam:end()  
    
			return $pdf
        }
        catch ($e) {
            element error { $e/error:message }
        }
    }
};
