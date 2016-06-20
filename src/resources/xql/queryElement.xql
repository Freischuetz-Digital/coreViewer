xquery version "3.0";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";

declare option exist:serialize "method=xml media-type=text/plain omit-xml-declaration=yes indent=yes";

let $svg.id := request:get-parameter('id','')

let $file := '../../contents/Op.111/Op.111_A/Op.111_A.xml'
let $xslPath := '../xslt/'
let $doc := doc($file)


let $result := transform:transform($doc,
               doc(concat($xslPath,'queryElement.xsl')), <parameters><param name="svg.id" value="{$svg.id}"/></parameters>)

return
    $result