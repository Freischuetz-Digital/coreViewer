xquery version "3.0";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";

declare option exist:serialize "method=xml media-type=text/plain omit-xml-declaration=yes indent=yes";

let $img.width := 600
let $img.height := 250
let $fullPage.width := 868

let $annot.id := request:get-parameter('id','')

let $config := doc('/db/apps/FreiDi_CoreViewer/config.xml')
let $data.basePath := $config//basePath/@url
let $digilib.basePath := $config//digilibPath/@url
let $xslPath := '../xslt/'      

let $abbr := collection(concat($data.basePath,'source_abbr'))
let $expan := collection(concat($data.basePath,'source_expan'))
let $raw := collection(concat($data.basePath,'source_raw'))
let $core := collection(concat($data.basePath,'core'))

let $sources := ('A','KA1','KA2','KA9','K13','K15','KA19','K20','KA26','D1849')

let $annotation := $core/id($annot.id)
let $annot.type := local-name($annotation)

let $mdiv := $annotation/ancestor::mei:mdiv
let $mdiv.n := $mdiv/@n
let $mdiv.id := $mdiv/@xml:id

let $result :=
    if(not($annotation))
    then()
(:FreiDi-Annotations:)      
    else if($annot.type = 'app')
    then(
        let $measure := $annotation/ancestor::mei:measure
        let $measure.id := $measure/@xml:id
        let $measure.n := $measure/@n
        let $categories := 
            for $cat in tokenize(replace($annotation/@decls,'#',''),' ')
            let $term := $core/id($cat)
            return '"' || $term/mei:name[@xml:lang = 'en']/text() || '"'
        let $staff.n := 
            if($annotation/ancestor::mei:staff) 
            then($annotation/ancestor::mei:staff/@n)
            else(($annotation//@staff)[1])
        let $staff.id := $measure/mei:staff[@n = $staff.n]/@xml:id
        let $staffDef := ($annotation/ancestor::mei:mdiv//mei:scoreDef)[1]//mei:staffDef[@n = $staff.n]
        let $staff.label := if($staffDef/@label) then($staffDef/@label)
            else if ($staffDef/parent::mei:staffGrp/@label) then($staffDef/parent::mei:staffGrp/@label || ' ' || (count($staffDef/preceding-sibling::mei:staffDef) +1))
            else if ($staffDef/child::mei:layerDef/@label) then(string-join($staffDef/child::mei:layerDef/@label,', '))
            else ('ERROR: Could not determine label for staff ' || $staff.n)
        let $otherAnnots :=
            for $other in $annotation/ancestor::mei:measure//mei:annot[(ancestor::mei:staff/@n = $staff.n or $staff.n = .//@staff) and @xml:id != $annot.id]
            return '"' || $other/@xml:id || '"'
        let $rdgs := 
            for $rdg in $annotation/mei:rdg
            let $rdg.id := $rdg/@xml:id
            let $sources := 
                for $source in tokenize($rdg/replace(@source,'#',''),' ')
                let $zone.id := $source || replace($staff.id,'core_','_zoneOf_')
                let $zone := $raw/id($zone.id)
                let $page.width := number($zone/ancestor::mei:surface/mei:graphic/@width)
                let $page.height := number($zone/ancestor::mei:surface/mei:graphic/@height)
                let $graphic.target := $zone/ancestor::mei:surface/mei:graphic/@target
                
                let $ulx := number($zone/@ulx)
                let $uly := number($zone/@uly)
                let $lrx := number($zone/@lrx)
                let $lry := number($zone/@lry)
                
                let $zone.width := $lrx - $ulx
                let $zone.height := $lry - $uly
                
                let $target.ratio := $img.width div $img.height
                let $zone.ratio := ($zone.width) div ($zone.height)
                
                let $wx.px := 
                    if($target.ratio lt $zone.ratio) (:needs padding above / below:)
                    then($ulx)
                    else($ulx - (($img.width - $zone.width) div 2))
                
                let $wy.px :=
                    if($target.ratio lt $zone.ratio) (:needs padding above / below:)
                    then($ulx - (($img.height - $zone.height) div 2))
                    else($uly)
                    
                let $ww.px := 
                    if($target.ratio lt $zone.ratio) (:needs padding above / below:)
                    then($zone.width)
                    else($img.width)
                
                let $wh.px :=
                    if($target.ratio lt $zone.ratio) (:needs padding above / below:)
                    then($img.height)
                    else($zone.height)
                
                let $dw := '?dw=' || string($img.width) (:destination image width (pixels). If omitted the image is scaled to fit dh.:)
                let $dh := '&#038;dh=' || string($img.height) (:destination image height (pixels). If omitted the image is scaled to fit dw.:)
                let $wx := '&#038;wx=' || string($wx.px div $page.width) (:relative x offset of the image area to be sent (0 <= wx <= 1):)
                let $wy := '&#038;wy=' || string($wy.px div $page.height) (:relative y offset of the image area to be sent (0 <= wy <= 1):)
                let $ww := '&#038;ww=' || string($ww.px div $page.width) (:relative width of the image area to be sent (0 <= ww <= 1):)
                let $wh := '&#038;wh=' || string($wh.px div $page.height) (:relative height of the image area to be sent (0 <= wh <= 1):)
                let $mode := '&#038;mo=fit'
                
                let $image.src := $digilib.basePath || $graphic.target || $dw || $dh || $wx || $wy || $ww || $wh || $mode
                
                let $page.src := $digilib.basePath || $graphic.target || '?dw=' || $fullPage.width || $mode
                
                order by index-of($sources,$source)
                
                return 
                    '{' ||
                        '"source":"' || $source || '",' ||
                        '"zoneID":"' || $zone/@xml:id || '",' ||
                        '"imageSrc":"' || $image.src || '",' ||
                        '"pageSrc":"' || $page.src || '",' ||
                        '"pageN":"' || $zone/ancestor::mei:surface/@n || '",' ||
                        '"pageID":"' || $zone/ancestor::mei:surface/@xml:id || '"' ||
                    '}'
            let $eventIDs := $rdg//mei:*/concat('"',@xml:id,'"')
            let $rdg.child.apps := exists($rdg//mei:app)
            return
                '{' ||
                    '"id":"' || $rdg.id || '",' ||
                    '"sources":[' || string-join($sources,',') || '],' ||
                    '"childApps":' || (if($rdg.child.apps) then('true') else('false')) || ',' ||
                    '"eventIDs":[' || string-join($eventIDs,',') || ']' ||
                '}'
        
        let $child.apps := exists($annotation//mei:app)
        let $tstamp.min := string(min($annotation//number(@tstamp)))
        let $tstamp.max := string(max($annotation//number(@tstamp)))
        
        return
            '{' ||
                '"id":"' || $annot.id || '",' ||
                '"type":"app",' ||
                '"priority":"2",' || (: hier später je nach Kategorie unterschiedliche Werte :)
                '"measureID":"' || $measure.id || '",' ||
                '"measureN":"' || $measure.n || '",' ||
                '"staffID":"' || $staff.id || '",' ||
                '"staffN":"' || $staff.n || '",' ||
                '"staffLabel":"' || $staff.label || '",' ||
                '"childApps":' || (if($child.apps) then('true') else('false')) || ',' || 
                '"tstampMin":"' || $tstamp.min || '",' ||
                '"tstampMax":"' || $tstamp.max || '",' ||
                '"rdgs":[' || string-join($rdgs,',') || '],' ||
                '"categories":[' || string-join($categories,',') || '],' ||
                '"otherAnnots":[' || string-join($otherAnnots,',') || ']' ||
            '}'
    )
    
(:WeGA-Annotations:)    
    else if($annot.type = 'annot' and $annotation/@type = 'editorialComment')
    then(
        let $measure := $annotation/ancestor::mei:measure
        let $measure.id := $measure/@xml:id
        let $measure.n := $measure/@n
        let $all.measure.n := 
            for $entry in tokenize($annotation/@plist,' ')
            return substring-after($entry,'_measure')
        
        let $categories := 
            for $cat in tokenize(replace($annotation/mei:ptr[@type = 'categories']/@target,'#',''),' ')
            let $term := $core/id($cat)
            return '"' || $term/mei:name[@xml:lang = 'en']/text() || '"'
            
        let $staves.n := tokenize($annotation/@staff,' ')
        let $following.measure.ids := tokenize($annotation/replace(@plist,'#',''),' ')[position() gt 1]
        
        let $sourceLabels := tokenize(replace($annotation/@source,'#',''),' ')
        
        let $staves := 
            for $staff.n in $staves.n
            let $staffDef := ($annotation/ancestor::mei:mdiv//mei:scoreDef)[1]//mei:staffDef[@n = $staff.n]
            let $staff.label :=
                if($staffDef/@label) then($staffDef/@label)
                else if ($staffDef/parent::mei:staffGrp/@label) then($staffDef/parent::mei:staffGrp/@label || ' ' || (count($staffDef/preceding-sibling::mei:staffDef) +1))
                else if ($staffDef/child::mei:layerDef/@label) then(string-join($staffDef/child::mei:layerDef/@label,', '))
                else ('ERROR: Could not determine label for staff ' || $staff.n)
        
            let $sources :=
                for $source in $sources
                let $zone.id := $source || replace($measure/mei:staff[@n = $staff.n]/@xml:id,'core_','_zoneOf_')
                let $zone := $raw/id($zone.id)
                let $page.width := number($zone/ancestor::mei:surface/mei:graphic/@width)
                let $page.height := number($zone/ancestor::mei:surface/mei:graphic/@height)
                let $graphic.target := $zone/ancestor::mei:surface/mei:graphic/@target
                
                let $ulx := number($zone/@ulx)
                let $uly := number($zone/@uly)
                let $lrx := number($zone/@lrx)
                let $lry := number($zone/@lry)
                
                let $zone.width := $lrx - $ulx
                let $zone.height := $lry - $uly
                
                let $target.ratio := $img.width div $img.height
                let $zone.ratio := ($zone.width) div ($zone.height)
                
                let $wx.px := 
                    if($target.ratio lt $zone.ratio) (:needs padding above / below:)
                    then($ulx)
                    else($ulx - (($img.width - $zone.width) div 2))
                
                let $wy.px :=
                    if($target.ratio lt $zone.ratio) (:needs padding above / below:)
                    then($ulx - (($img.height - $zone.height) div 2))
                    else($uly)
                    
                let $ww.px := 
                    if($target.ratio lt $zone.ratio) (:needs padding above / below:)
                    then($zone.width)
                    else($img.width)
                
                let $wh.px :=
                    if($target.ratio lt $zone.ratio) (:needs padding above / below:)
                    then($img.height)
                    else($zone.height)
                
                let $dw := '?dw=' || string($img.width) (:destination image width (pixels). If omitted the image is scaled to fit dh.:)
                let $dh := '&#038;dh=' || string($img.height) (:destination image height (pixels). If omitted the image is scaled to fit dw.:)
                let $wx := '&#038;wx=' || string($wx.px div $page.width) (:relative x offset of the image area to be sent (0 <= wx <= 1):)
                let $wy := '&#038;wy=' || string($wy.px div $page.height) (:relative y offset of the image area to be sent (0 <= wy <= 1):)
                let $ww := '&#038;ww=' || string($ww.px div $page.width) (:relative width of the image area to be sent (0 <= ww <= 1):)
                let $wh := '&#038;wh=' || string($wh.px div $page.height) (:relative height of the image area to be sent (0 <= wh <= 1):)
                let $mode := '&#038;mo=fit'
                
                let $image.src := $digilib.basePath || $graphic.target || $dw || $dh || $wx || $wy || $ww || $wh || $mode
                
                let $page.src := $digilib.basePath || $graphic.target || '?dw=' || $fullPage.width || $mode
                
                order by index-of($sources,$source)
                
                return 
                    '{' ||
                        '"source":"' || $source || '",' ||
                        '"zoneID":"' || $zone/@xml:id || '",' ||
                        '"imageSrc":"' || $image.src || '",' ||
                        '"pageSrc":"' || $page.src || '",' ||
                        '"pageN":"' || $zone/ancestor::mei:surface/@n || '",' ||
                        '"pageID":"' || $zone/ancestor::mei:surface/@xml:id || '"' ||
                    '}'                
        
            return
                '{' ||
                    '"staffN":"' || $staff.n || '",' ||
                    '"staffLabel":"' || $staff.label || '",' ||
                    '"sources":[' || string-join($sources,',') || ']' ||
                '}'
        
        
        
        let $otherAnnots :=
            for $id in $annotation/tokenize(replace(@plist,'#',''),' ')
            let $measure := $core/id($id)
            return $measure//mei:app[ancestor::mei:staff/@n = $staves.n or .//@staff = $staves.n]/concat('"',@xml:id,'"')
        
        let $tstamp.min := string(min($annotation//number(@tstamp)))
        let $tstamp.max := string(max($annotation//number(@tstamp)))
        
        return
            '{' ||
                '"id":"' || $annot.id || '",' ||
                '"type":"annot",' ||
                '"priority":"' || $annotation/mei:ptr[@type='priority']/substring-after(@target,'#ediromAnnotPrio') || '",' || (: hier später je nach Kategorie unterschiedliche Werte :)
                '"measureID":"' || $measure.id || '",' ||
                '"sources":["' || string-join($sourceLabels,'","') || '"],' ||
                '"allMeasures":["' || string-join($all.measure.n,'","') || '"],' ||
                '"staves":[' || string-join($staves,',') || '],' ||
                '"categories":[' || string-join($categories,',') || '],' ||
                '"otherAnnots":[' || string-join($otherAnnots,',') || ']' ||
            '}'
    ) 
    else()


(:let $annot.html := transform:transform($annotation,
                doc(concat($xslPath,'transformAnnotation.xsl')), 
            <parameters/>):)
    
return
    $result