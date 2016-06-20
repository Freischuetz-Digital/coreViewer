xquery version "3.0";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";

declare option exist:serialize "method=xml media-type=text/plain omit-xml-declaration=yes indent=yes";

let $config := doc('/db/apps/FreiDi_CoreViewer/config.xml')
let $data.basePath := $config//basePath/@url
let $xslPath := '../xslt/'      

let $abbr := collection(concat($data.basePath,'source_abbr'))
let $expan := collection(concat($data.basePath,'source_expan'))
let $raw := collection(concat($data.basePath,'source_raw'))
let $core := collection(concat($data.basePath,'core'))

let $sources := ('A','KA1','KA2','KA9','K13','K15','KA19','K20','KA26','D1849')
let $annotCategories := ($core//mei:termList[@classcode = '#ediromCategory'])[1]//mei:term[@classcode = '#ediromCategory']/concat('{"id":"',@xml:id,'","label":"',child::mei:name[@xml:lang = 'en']/text(),'"}')

let $mdivs := 
    for $mdiv in $core//mei:mdiv
    let $id := $mdiv/@xml:id
    let $label := $mdiv/@label
    let $mdiv.n := $mdiv/substring-after(@xml:id,'_mov')
    let $mdiv.sources := $raw//mei:mdiv[ends-with(@xml:id,concat('_mov',$mdiv.n))]/ancestor::mei:mei/@xml:id
    let $annotations := 
        for $annot in $mdiv//mei:annot[@type = 'editorialComment']
        let $affected.measures := for $measure.id in $annot/tokenize(replace(@plist,'#core_',''),' ') return concat('"',$measure.id,'"')
        let $affected.sources := for $source.id in $annot/tokenize(replace(@source,'#',''),' ') return concat('"',$source.id,'"')
        let $categories := for $category in $annot/mei:ptr[@type = 'categories']/tokenize(replace(@target,'#',''),' ') return concat('"',$category,'"')
        let $priority := $annot/mei:ptr[@type = 'priority']/substring-after(@target,'#ediromAnnotPrio')
        let $annot.id := $annot/@xml:id
        let $staves := for $staff in $annot/tokenize(@staff,' ') return concat('"',$staff,'"')
        return
            '{' ||
                '"id":"' || $annot.id || '",' ||
                '"priority":"' || $priority || '",' ||
                '"categories":[' || string-join($categories,',') || '],' ||
                '"measures":[' || string-join($affected.measures,',') || '],' ||
                '"sources":[' || string-join($affected.sources,',') || '],' ||
                '"staves":[' || string-join($staves,',') || ']' ||
            '}'
    let $staves := 
        for $staffDef in ($mdiv//mei:scoreDef)[1]//mei:staffDef
        let $staff.n := $staffDef/@n
        let $label := if($staffDef/@label) then($staffDef/@label)
            else if ($staffDef/parent::mei:staffGrp/@label) then($staffDef/parent::mei:staffGrp/@label || ' ' || (count($staffDef/preceding-sibling::mei:staffDef) +1))
            else if ($staffDef/child::mei:layerDef/@label) then(string-join($staffDef/child::mei:layerDef/@label,', '))
            else ('ERROR: Could not determine label for staff ' || $staff.n)
        let $label.abbr := if($staffDef/@label.abbr) then($staffDef/@label.abbr)
            else if ($staffDef/parent::mei:staffGrp/@label.abbr) then($staffDef/parent::mei:staffGrp/@label.abbr || (count($staffDef/preceding-sibling::mei:staffDef) +1))
            else if ($staffDef/child::mei:layerDef/@label.abbr) then(string-join($staffDef/child::mei:layerDef/@label.abbr,', '))
            else ($label)
        order by number($staff.n)
        return
            '{' ||
                '"n":"' || $staff.n || '",' ||
                '"label":"' || $label || '",' ||
                '"abbr":"' || $label.abbr || '"' ||
            '}'
    order by number($mdiv.n)
    return 
        '{' ||
            '"id":"' || $id || '",' ||
            '"label":"' || $label || '",' ||
            '"n":"' || $mdiv.n || '",' ||
            '"sources":[' || (if(count($mdiv.sources) gt 0) then('"' || string-join($mdiv.sources,'","') || '"') else()) || '],' ||
            '"staves":[' || string-join($staves,',') || '],' ||
            '"annotations":[' || string-join($annotations,',') || ']' ||
        '}'
    
return
    '{' ||
        '"sources":[' || (if(count($sources) gt 0) then('"' || string-join($sources,'","') || '"') else()) || '],' ||
        '"mdivs":[' || string-join($mdivs,',') || '],' ||
        '"annotCategories":[' || string-join($annotCategories,',') || ']' ||
    '}'
    