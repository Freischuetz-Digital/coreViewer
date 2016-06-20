xquery version "3.0";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";

declare option exist:serialize "method=xml media-type=text/plain omit-xml-declaration=yes indent=yes";

let $source.id := request:get-parameter('source','')
let $other.sources := tokenize(request:get-parameter('otherSources',''),'_')
let $categories := tokenize(request:get-parameter('categories',''),'___')
let $mdiv.n := request:get-parameter('mdivN','')

let $config := doc('/db/apps/FreiDi_CoreViewer/config.xml')
let $data.basePath := $config//basePath/@url
let $xslPath := '../xslt/'      

let $source.file := doc(concat($data.basePath,'source_raw/',$source.id,'/',$source.id,'_mov',$mdiv.n,'.xml'))
let $core.file := doc(concat($data.basePath,'core/core_mov',$mdiv.n,'.xml'))

let $sources := ('A','KA1','KA2','KA9','K13','K15','KA19','K20','KA26','D1849')

(:type-specific annotations:)
(:let $apps := $core.file//mei:staff//mei:app[mei:rdg['dot' = .//@artic] and mei:rdg[not('dot' = .//@artic)]]:)

let $apps := 
    for $rdg in $core.file//mei:staff//mei:rdg[$source.id = tokenize(replace(@source,'#',''),' ') and 
        (some $cat in ./parent::mei:app/tokenize(replace(@decls,'#',''),' ') satisfies ($cat = $categories)) and 
        (preceding-sibling::mei:rdg[some $source in tokenize(replace(@source,'#',''),' ') satisfies $source = $other.sources] or following-sibling::mei:rdg[some $source in tokenize(replace(@source,'#',''),' ') satisfies $source = $other.sources])]
    let $app := $rdg/parent::mei:app
    let $app.id := $app/@xml:id
    let $staff.id := if($app/ancestor::mei:staff) then($app/ancestor::mei:staff/@xml:id) else(concat($app/ancestor::mei:measure/@xml:id,'_s',($app//@staff)[1]))
    let $staff.n := substring-after($staff.id,'_s')
    let $measure := $app/ancestor::mei:measure
    let $measure.id := $measure/@xml:id
    let $measure.n := $measure/@n
    let $this.rdg.id := $rdg/@xml:id
    let $this.rdg.sources := tokenize(replace($rdg/@source,'#',''),' ')
    let $this.rdg.core.elem.ids := $rdg/descendant::mei:*/concat('#',@xml:id)
    let $this.rdg.source.elem.ids := 
        for $id in $this.rdg.core.elem.ids
        return
            $source.file//mei:*[@sameas = $id]/@xml:id
    let $content := $this.rdg.source.elem.ids[string-length(.) gt 0]
    
    let $siblings := ($rdg/preceding-sibling::mei:rdg,$rdg/following-sibling::mei:rdg)
    
    let $other.rdgs :=
        for $other.rdg in $siblings
        let $other.rdg.id := $other.rdg/@xml:id
        let $other.rdg.sources := tokenize(replace($other.rdg/@source,'#',''),' ')
        return 
            '{' ||
                '"id":"' || $other.rdg.id || '",' ||
                '"sources":[' || (if(count($other.rdg.sources) gt 0) then('"') else()) || string-join($other.rdg.sources,'","') || (if(count($other.rdg.sources) gt 0) then('"') else()) || ']' || 
            '}'
    return
        '{' ||
            '"id":"' || $app.id || '",' ||
            '"measureID":"' || replace($measure.id,'core_mov',concat($source.id,'_mov')) || '",' ||
            '"measureN":"' || $measure.n || '",' ||
            '"staffID":"' || replace($staff.id,'core_mov',concat($source.id,'_mov')) || '",' ||
            '"staffN":"' || $staff.n || '",' ||
            '"rdgID":"' || $this.rdg.id || '",' ||
            '"sources":[' || (if(count($this.rdg.sources) gt 0) then('"') else()) || string-join($this.rdg.sources,'","') || (if(count($this.rdg.sources) gt 0) then('"') else()) || '],' ||
            '"otherRdgs":[' || string-join($other.rdgs,',') || '],' ||
            '"appContent":[' || (if(count($content) gt 0) then('"') else()) || string-join($content,'","') || (if(count($content) gt 0) then('"') else()) || '],' ||
            '"desc":"different reading in source' || (if(count(distinct-values($siblings/tokenize(replace(@source,'#',''),' '))) gt 1) then('s') else('')) || ' ' || string-join(distinct-values($siblings/tokenize(replace(@source,'#',''),' ')),', ') || '"' ||
        '}'
 
return
    '[' ||
        string-join($apps,',') || 
    ']'
    