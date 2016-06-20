xquery version "3.0";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
(:declare default element namespace "http://www.music-encoding.org/ns/mei";:)

declare option exist:serialize "method=xml media-type=text/plain omit-xml-declaration=yes indent=yes";

let $source.id := request:get-parameter('sourceID','')
let $mdiv.n := request:get-parameter('movN','')
let $xpath.raw := request:get-parameter('xpath','')

let $xpath.prep1 := replace($xpath.raw,'(update|collection\(|document-uri\(|doc\()','')
let $xpath := replace($xpath.prep1,'^/*','//')

let $config := doc('/db/apps/FreiDi_CoreViewer/config.xml')
let $data.basePath := $config//basePath/@url
let $xslPath := '../xslt/'     

let $source := doc(concat($data.basePath,'source_raw/',$source.id,'/',$source.id,'_mov',$mdiv.n,'.xml'))//mei:mei
let $core := doc(concat($data.basePath,'core/core_mov',$mdiv.n,'.xml'))//mei:mei
let $scoreDef := $source//mei:score/mei:scoreDef[1]

let $query.source := concat('$source',$xpath)
let $query.core := concat('$core',$xpath)

let $source.results := util:eval($query.source)
let $core.results := util:eval($query.core)

let $source.elems := 
    for $elem in $source.results[. instance of element() and ancestor::mei:staff]
    let $measure.id := $elem/ancestor::mei:measure/@xml:id
    let $measure.n := number($elem/ancestor::mei:measure/@n)
    let $staff.id := $elem/ancestor::mei:staff/@xml:id
    let $staff.n := $elem/ancestor::mei:staff/@n
    let $elem.id := $elem/@xml:id
    let $query := $xpath
    order by $measure.n, $staff.n
    return
        '{' ||
            '"measureID":"' || $measure.id || '",' ||
            '"measureN":"' || $measure.n || '",' ||
            '"staffID":"' || $staff.id || '",' ||
            '"staffN":"' || $staff.n || '",' ||
            '"elemID":"' || $elem.id || '",' ||
            '"desc":"' || $query || '"' ||
        '}'

let $core.elems := 
    for $elem in $core.results[. instance of element() and ancestor::mei:staff]
    let $measure.id := $elem/ancestor::mei:measure/@xml:id
    let $measure.n := number($elem/ancestor::mei:measure/@n)
    let $staff.id := $elem/ancestor::mei:staff/@xml:id
    let $staff.n := $elem/ancestor::mei:staff/@n
    let $elem.id := $elem/@xml:id
    let $query := $xpath
    order by $measure.n, $staff.n
    return
        '{' ||
            '"measureID":"' || $measure.id || '",' ||
            '"measureN":"' || $measure.n || '",' ||
            '"staffID":"' || $staff.id || '",' ||
            '"staffN":"' || $staff.n || '",' ||
            '"elemID":"' || $elem.id || '",' ||
            '"desc":"' || $query || '"' ||
        '}'

return
    '{' ||
        '"source":[' || string-join($source.elems,',') || '],' ||
        '"core":[' || string-join($core.elems,',') || '],' ||
        '"xpath":"' || $xpath || '"' ||
    '}'
    
    