xquery version "1.0";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";

declare option exist:serialize "method=xml media-type=text/plain omit-xml-declaration=yes indent=no";


let $staff.id := request:get-parameter('staffID','')
let $rdg.id := request:get-parameter('rdgID','')

let $config := doc('/db/apps/FreiDi_CoreViewer/config.xml')
let $data.basePath := $config//basePath/@url
let $xslPath := '../xslt/'

let $core := collection(concat($data.basePath,'core'))
let $mei := $core/id($staff.id)/ancestor::mei:mei

let $file := transform:transform($mei,
                doc(concat($xslPath,'getMEIsnippet.xsl')), 
            <parameters>
                <param name="staff.id" value="{$staff.id}"/>
                <param name="rdg.id" value="{$rdg.id}"/>
            </parameters>)
        

return
    $file