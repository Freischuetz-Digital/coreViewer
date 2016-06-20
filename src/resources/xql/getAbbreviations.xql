xquery version "3.0";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";

declare option exist:serialize "method=xml media-type=text/plain omit-xml-declaration=yes indent=yes";

let $source.id := request:get-parameter('sourceID','')
let $mdiv.n := request:get-parameter('movN','')

let $config := doc('/db/apps/FreiDi_CoreViewer/config.xml')
let $data.basePath := $config//basePath/@url
let $xslPath := '../xslt/'     

let $file := doc(concat($data.basePath,'source_raw/',$source.id,'/',$source.id,'_mov',$mdiv.n,'.xml'))//mei:mei
let $scoreDef := $file//mei:score/mei:scoreDef[1]

let $abbrs := 
    for $abbr in $file//mei:abbr[not(@type = 'collaParte')]
    let $measure.id := $abbr/ancestor::mei:measure/@xml:id
    let $measure.n := number($abbr/ancestor::mei:measure/@n)
    let $staff.id := $abbr/ancestor::mei:staff/@xml:id
    let $staff.n := number($abbr/ancestor::mei:staff/@n)
    let $tstamp.min := min($abbr/following-sibling::mei:expan//number(@tstamp))
    let $tstamp.max := max($abbr/following-sibling::mei:expan//number(@tstamp))
    let $abbrContent := $abbr//@xml:id
    let $expanContent := $abbr/following-sibling::mei:expan//@xml:id
    order by $measure.n, $staff.n
    return
        '{' ||
            '"measureID":"' || $measure.id || '",' ||
            '"measureN":"' || $measure.n || '",' ||
            '"staffID":"' || $staff.id || '",' ||
            '"staffN":"' || $staff.n || '",' ||
            '"tstampMin":"' || $tstamp.min || '",' ||
            '"tstampMax":"' || $tstamp.max || '",' ||
            '"type":"' || $abbr/@type || '",' ||
            '"abbrContent":[' || (if(count($abbrContent) gt 0) then('"' || string-join($abbrContent,'","') || '"') else('')) || '],' ||
            '"expanContent":[' || (if(count($expanContent) gt 0) then('"' || string-join($expanContent,'","') || '"') else('')) || '],' ||
            '"desc":"abbreviation in bar ' || $measure.n || ', staff ' || $staff.n || '"' ||
        '}'

let $collaPartes := 
    for $cp in $file//mei:abbr[@type = 'collaParte']
    let $measure.id := $cp/ancestor::mei:measure/@xml:id
    let $measure.n := number($cp/ancestor::mei:measure/@n)
    let $staff.id := $cp/ancestor::mei:staff/@xml:id
    let $staff.n := number($cp/ancestor::mei:staff/@n)
    
    let $staff.label := 
        if($scoreDef//mei:staffDef[@n = $staff.n]/@label) 
        then($scoreDef//mei:staffDef[@n = $staff.n]/@label)
        else if($scoreDef//mei:staffDef[@n = $staff.n]/parent::mei:staffGrp/@label)
        then($scoreDef//mei:staffDef[@n = $staff.n]/parent::mei:staffGrp/@label)
        else(string-join($scoreDef//mei:staffDef[@n = $staff.n]/child::mei:layerDef/@label,', '))
    
    let $cpMark.id := $cp/following-sibling::mei:expan/@evidence
    let $cpMark := $file/id($cpMark.id)
    let $ref.staff := $cpMark/@ref.staff
    let $ref.staff.label := 
        if($scoreDef//mei:staffDef[@n = $ref.staff]/@label) 
        then($scoreDef//mei:staffDef[@n = $ref.staff]/@label)
        else if($scoreDef//mei:staffDef[@n = $ref.staff]/parent::mei:staffGrp/@label)
        then($scoreDef//mei:staffDef[@n = $ref.staff]/parent::mei:staffGrp/@label)
        else(string-join($scoreDef//mei:staffDef[@n = $ref.staff]/child::mei:layerDef/@label,', '))
    let $first.measure := $cpMark/ancestor::mei:measure/@n
    let $measure.count := substring-before($cpMark/@tstamp2,'m+')
    let $abbrContent := $cp//@xml:id
    let $expanContent := $cp/following-sibling::mei:expan//@xml:id
    
    order by $measure.n, $staff.n
    return
        '{' ||
            '"measureID":"' || $measure.id || '",' ||
            '"measureN":"' || $measure.n || '",' ||
            '"staffID":"' || $staff.id || '",' ||
            '"staffN":"' || $staff.n || '",' ||
            '"cpmarkID":"' || $cpMark.id || '",' ||
            '"refStaff":"' || $ref.staff || '",' ||
            '"firstMeasure":"' || $first.measure || '",' ||
            '"measureCount":"' || $measure.count || '",' ||
            '"abbrContent":[' || (if(count($abbrContent) gt 0) then('"' || string-join($abbrContent,'","') || '"') else('')) || '],' ||
            '"expanContent":[' || (if(count($expanContent) gt 0) then('"' || string-join($expanContent,'","') || '"') else('')) || '],' ||
            '"desc":"colla parte with ' || $ref.staff.label || ', beginning in bar ' || $measure.n || ' for '  || string(number($measure.count) + 1) || ' bar' || (if(number($measure.count) gt 0) then('s') else('')) || '"' ||
        '}'

let $trems := 
    for $trem in $file//(mei:bTrem | mei:fTrem)
    let $measure.id := $trem/ancestor::mei:measure/@xml:id
    let $measure.n := number($trem/ancestor::mei:measure/@n)
    let $staff.id := $trem/ancestor::mei:staff/@xml:id
    let $staff.n := number($trem/ancestor::mei:staff/@n)
    let $abbrContent := $trem//@xml:id
    let $expanContent := $trem/following-sibling::mei:expan//@xml:id
    order by $measure.n, $staff.n
    return
        '{' ||
            '"measureID":"' || $measure.id || '",' ||
            '"measureN":"' || $measure.n || '",' ||
            '"staffID":"' || $staff.id || '",' ||
            '"staffN":"' || $staff.n || '",' ||
            '"abbrContent":[' || (if(count($abbrContent) gt 0) then('"' || string-join($abbrContent,'","') || '"') else('')) || '],' ||
            '"expanContent":[' || (if(count($expanContent) gt 0) then('"' || string-join($expanContent,'","') || '"') else('')) || '],' ||
            '"type":"' || local-name($trem) || '",' ||
            '"desc":"tremolo"' ||
        '}'

return
    '{' ||
        '"abbrs":[' || string-join($abbrs,',') || '],' ||
        '"collaPartes":[' || string-join($collaPartes,',') || '],' ||
        '"trems":[' || string-join($trems,',') || ']' ||
    '}'