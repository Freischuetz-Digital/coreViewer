xquery version "3.0";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";

declare option exist:serialize "method=xml media-type=text/html omit-xml-declaration=yes indent=yes";

let $annot.id := request:get-parameter('annotID','')

let $config := doc('/db/apps/FreiDi_CoreViewer/config.xml')
let $data.basePath := $config//basePath/@url
let $xslPath := '../xslt/'      

let $core := collection(concat($data.basePath,'core'))

let $sources := ('A','KA1','KA2','KA9','K13','K15','KA19','K20','KA26','D1849')
let $annotation := $core//id($annot.id)

let $annot.html := transform:transform($annotation,
                doc(concat($xslPath,'transformAnnotation.xsl')), 
            <parameters/>)
    
return
    $annot.html