xquery version "1.0";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";

declare option exist:serialize "method=xml media-type=text/plain omit-xml-declaration=yes indent=yes";


let $mov.n := request:get-parameter('mov','')
let $perspective := request:get-parameter('perspective','')
let $source := request:get-parameter('source','')
let $muted.staves := tokenize(request:get-parameter('muted',''),'-')
let $solo := request:get-parameter('solo','')

let $config := doc('/db/apps/FreiDi_CoreViewer/config.xml')
let $data.basePath := $config//basePath/@url
let $xslPath := '../xslt/'


let $file := if($perspective = 'abbr')
    then(
    
        if(not($solo = ('','-1')))
        then(
            transform:transform(doc(concat($data.basePath,'source_abbr/',$source,'/',$source,'_mov',$mov.n,'.xml')),
                doc(concat($xslPath,'getStaves.xsl')), 
            <parameters>
                <param name="solo" value="{$solo}"/>
            </parameters>)
        ) else if(count($muted.staves) gt 0) 
        then(
            transform:transform(doc(concat($data.basePath,'source_abbr/',$source,'/',$source,'_mov',$mov.n,'.xml')),
                doc(concat($xslPath,'getStaves.xsl')), 
                <parameters>
                    <param name="muted" value="{string-join($muted.staves,' ')}"/>
                </parameters>)
        ) else if(doc-available(concat($data.basePath,'source_abbr/',$source,'/',$source,'_mov',$mov.n,'.svg')))
        then (
            doc(concat($data.basePath,'source_abbr/',$source,'/',$source,'_mov',$mov.n,'.svg'))
        )
        else (
            doc(concat($data.basePath,'source_abbr/',$source,'/',$source,'_mov',$mov.n,'.xml'))
        )
        
    )
    else if($perspective = 'expan')
    then(
        if(not($solo = ('','-1')))
        then(
            transform:transform(doc(concat($data.basePath,'source_expan/',$source,'/',$source,'_mov',$mov.n,'.xml')),
                doc(concat($xslPath,'getStaves.xsl')), 
            <parameters>
                <param name="solo" value="{$solo}"/>
            </parameters>)
        ) else if(count($muted.staves) gt 0) 
        then(
            transform:transform(doc(concat($data.basePath,'source_expan/',$source,'/',$source,'_mov',$mov.n,'.xml')),
                doc(concat($xslPath,'getStaves.xsl')), 
                <parameters>
                    <param name="muted" value="{string-join($muted.staves,' ')}"/>
                </parameters>)
        ) else (
            doc(concat($data.basePath,'source_expan/',$source,'/',$source,'_mov',$mov.n,'.xml'))
        )
    ) else ()

return
    $file