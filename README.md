# B&W Garden
B&W Garden is a web site where the most fascinating black and white photos are presented. 
Photographers collections are shown together with text description for every photo.

At this stage the application is able to browse through preloaded photos. The user can 
search for photos using their description or other metadata and is also able to filter them
(facet filtering) on metdata as well as n the geospatial location of the place where the 
picture was taken. 

The user can generate a PDF with photo and its description and downloaded

The user can add tags to the photo or can use OpenCalais service to generate these tags.

## Requirements
To be able to run this application the following are needed:

* MarkLogic
* Jetty
* MLJAM
* OpenCalais (free account)
* DBPedia (free access)

### MarkLogic
MarkLogic must have geospatial and semantic license.
The configuration and code required are maintain with the Roxy framework

Deployment in MarkLogic has the following steps:
* `ml local bootstrap`
* `ml local init cpf`
* `ml local deploy modules`
* `ml local deploy cpf`
* `ml local deploy_alerting`
* `ml local deploy content`

At the last step, the cpf starts to execute the steps and data is enriched with geospatial 
information (the latitude and longitude of the city where the photo was taken)

### Jetty
Jetty is required to be able to deploy the web application written. The port used by the 
XQuery modules from MarkLogic to connect the MLJAM running under jetty is 8580

The SpringMVC application is deployed as well under jetty (photos.war) and will be available 
at http://localhost:8580/photos/search/

### MLJAM
The standard distribution for MLJAM is required together with extra libraries to support 
PDF creation (PDFBox) as well as connecting to DBpedia (Jena)

### OpenCalais
OpenCalais is required for enrichment of the document describing the photo. A fre account 
is required (one is already set inside the xquery code)

OpenCalais is used for document enrichment (tagging). Due to the limitation of the free 
service, auto-tagging is done on user request from the web interface (is actually a rest 
service which can be called by any client)

## Alerting
Server side alerting is set-up in combination with CPF with the single role of detecting 
if any photo has explicit content. The detection is done on a list of few words. The alerting 
set up has two rules, one around violent images and the other one around sexual explicit 
images. Upon detection, the documents are flagged as "explicit" 

## CPF
CPF is used in combination with alerting as well as for extrating EXIF (if any) information 
from the JPEG data. 

For geospatial "tagging", a  pipeline has been developed to gather latitude and 
longitude from DBPedia. The information is saved in the document and used for the geospatial 
faceting (continent).

## Autotagging
The information from the photo description element is sent to OpenCalais for analysis and 
the answer (RDF/XML) is saved in the database and as such made available for semantic queries.

At this point only social tags are returned and these are used for tagging the photos. 

## PDF 
MLJAM together with PDF box are used for creating PDF pages. There are a simple proposal now 
and only demonstrates the possibility to run JAVA code (remotely!!)

## JavaAPI
The web application is build with SpringMVC and uses MarkLogic JavaAPI for the connection 
to MarkLogic sever.

Two extension where built (for PDF document manager and auto-tagging service) ato of two 
MarkLogic REST API extensions.

## REST API
Two extensions were build using Roxy as a start point. These extension supports the PDF
creation service and the the auto-tagging service

## Facets
A custom facet for geospatial location has been built. For these cts:polygons are used built 
with data extracted in KML format from Google Earth (be aware that the polygons contain 
only few point to prove that works) 