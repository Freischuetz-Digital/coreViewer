/*
 * global variables and objects
 */
vrvToolkit = new verovio.toolkit();
var svgns = "http://www.w3.org/2000/svg";
var externalEdiromBaseLink = 'http://rubin.upb.de:8092/exist/apps/EdiromOnline/?uri=xmldb:exist:///db/apps/contents/musicSources/';

var data = {};

/*
 * this function generates UUIDs
 */
Math.getUUID = function() {

    var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = Math.random()*16|0, v = c == 'x' ? r : (r&0x3|0x8);
        return v.toString(16);
    });
    
    return 'a' + uuid;
};

/*
 * 
 */
function getParameter(key) {
    
    var query = window.location.search.substring(1); 
    var pairs = query.split('&');
    
    for (var i = 0; i < pairs.length; i++) {
        var pair = pairs[i].split('=');
        if(pair[0] == key) {
            if(pair[1].length > 0)
                return pair[1];
        }  
    }
    
    return undefined;  
};

/*
 * this function renders the title of a source
 */
function renderSourceID(sourceID) {
    switch(sourceID) {
        case 'A': return '<span class="siglum">A</span>'; break;
        case 'KA1': return '<span class="siglum">K<sup>A</sup><sub>1</sub></span>'; break;
        case 'KA2': return '<span class="siglum">K<sup>A</sup><sub>2</sub></span>'; break;
        case 'KA9': return '<span class="siglum">K<sup>A</sup><sub>9</sub></span>'; break;
        case 'K13': return '<span class="siglum">K<sub>13</sub></span>'; break;
        case 'K15': return '<span class="siglum">K<sub>15</sub></span>'; break;
        case 'KA19': return '<span class="siglum">K<sup>A</sup><sub>19</sub></span>'; break;
        case 'K20': return '<span class="siglum">K<sub>20</sub></span>'; break;
        case 'KA26': return '<span class="siglum">K<sup>A</sup><sub>26</sub></span>'; break;
        case 'D1849': return '<span class="siglum">D<sub>1849</sub></span>'; break;
        default: return sourceID; break;
    }  
};

/*
 * this function renders an MEI file into SVG and inserts it in a given HTML element
 */
function renderMEI(mei, target, func) {
    var options = JSON.stringify({
      	inputFormat: 'mei',
      	border: 0,
      	scale: 50,
      	ignoreLayout: 0,
      	noLayout: 1
      });
    
	vrvToolkit.setOptions( options );
	vrvToolkit.loadData(mei + '\n');
    
    var svg = vrvToolkit.renderPage(1);
    
    $(target).html(svg);
    
    if(typeof func === 'function')
        func();
    
};

/*
 * this function retrieves the right MEI file to be rendered from the database
 */
function getMEI(staffID, rdgID, target) {

    new jQuery.ajax('./resources/xql/getMEIsnippet.xql',{
        method: 'get',
        data: {staffID: staffID,rdgID:rdgID},
        success: function(result) {
    	    
    	    var response = result || '';
            
            var mei = response;
            renderMEI(mei, target);    
            
            var rightRdg = $.grep(data.annot.rdgs, function(rdg, index) {
                return rdg.id === rdgID;
            })[0];
            
            for(var i = 0; i< rightRdg.eventIDs.length; i++) {
                $('#' + rightRdg.eventIDs[i]).attr('fill','#dd3333').attr('stroke','#dd3333');
            }
    	}
    });
};

/*
 * this function retrieves the right MEI file to be rendered from the database
 */
function getAnnotation(id) {

    $('#leftBox').html('');

    new jQuery.ajax('./resources/xql/annot_getAnnotation.xql',{
        method: 'get',
        data: {id: id},
        dataType: 'json',
        success: function(result) {
    	    
    	    data.annot = result;
            
    /**apps**/            
            if(data.annot.type === 'app') {
                
                var count = 0;
                
                //set up rdg boxes
                for(var i = 0; i < data.annot.rdgs.length; i++) {
                    var rdg = data.annot.rdgs[i];
                    var outerBox = '<div class="rdg" id="rdg_' + rdg.id + '"><ul class="nav nav-tabs" role="tablist"></ul><div class="tab-content"></div></div>';
                    
                    $('#leftBox').append(outerBox);
                    
                    var renderTab = '<li role="presentation" class="active"><a href="#rdg_' + rdg.id + '_verovio" aria-controls="rdg_' + rdg.id + '_verovio" role="tab" data-toggle="tab">Rendering</a></li>';
                    var renderContent = '<div role="tabpanel" class="tab-pane active verovioTab" id="rdg_' + rdg.id + '_verovio" aria-controls="rdg_' + rdg.id + '_verovio"></div>';
                    
                    $('#rdg_' + rdg.id + ' ul').append(renderTab);
                    $('#rdg_' + rdg.id + ' .tab-content').append(renderContent);
                    
                    for(var j = 0; j < rdg.sources.length; j++) {
                        var sourceRdg = rdg.sources[j];
                        
                        // generate snippet boxes
                        var tab = '<li role="presentation"><a href="#rdg_' + rdg.id + '_' + sourceRdg.source + '" aria-controls="rdg_' + rdg.id + '_' + sourceRdg.source + '" role="tab" data-toggle="tab">' + renderSourceID(sourceRdg.source) + '</a></li>';
                        var content = '<div role="tabpanel" class="tab-pane verovioTab" id="rdg_' + rdg.id + '_' + sourceRdg.source + '" aria-controls="rdg_' + rdg.id + '_' + sourceRdg.source + '" data-carouselN="' + count + '"><img src="' + sourceRdg.imageSrc + '"/></div>';
                        $('#rdg_' + rdg.id + ' ul').append(tab);
                        $('#rdg_' + rdg.id + ' .tab-content').append(content);
                        
                        $('#rdg_' + rdg.id + '_' + sourceRdg.source).on('click',function(e) {
                            var carouselN = $(e.currentTarget).attr('data-carouselN');
                            $('#fullPageModal').modal(); 
                            $('#full-page-carousel').carousel(parseInt(carouselN)).carousel('pause');
                        });
                        
                        // generate full pages for carousel
                        
                        var carouselLi = '<li data-target="#full-page-carousel" data-slide-to="' + count + '"' + (count === 0 ? ' class="active"' : '') + '></li>';
                        var carouselItem = '<div class="item' + (count=== 0 ? ' active' : '') + '" data-sourceID="' + sourceRdg.source + '" data-pageID="' + sourceRdg.pageID + '"><img src="' + sourceRdg.pageSrc + '"/><div class="carousel-caption"><h1>' + renderSourceID(sourceRdg.source) + '<span style="font-size: 80%">, page ' + sourceRdg.pageN + '</span></h1></div></div>';
                        
                        $('#fullPageModal ol.carousel-indicators').append(carouselLi);
                        $('#fullPageModal div.carousel-inner').append(carouselItem);
                        
                        $('#full-page-carousel').carousel('pause');
                        
                        count++;
                        
                        var link;
                        if(window === top) {
                        // die Seite läuft stand alone
                            link = ' href="' + externalEdiromBaseLink + 'freidi-musicSource_' + sourceRdg.source + '.xml#' + sourceRdg.source + '_' + data.annot.measureN + '" target="_blank"';
                        }else {
                        // die Seite läuft in einem iFrame
                            link = 'href="window.parent.loadLink("xmldb:exist:///db/apps/contents/musicSources/freidi-musicSource_' + sourceRdg.source + '.xml#' + sourceRdg.source + '_' + data.annot.measureN + '"';
                        }
                        
                        var wholeString = '<a' + link + '>' + renderSourceID(sourceRdg.source) + '</a>';
                        $('#annotSources').append(wholeString);
                        if(j < (rdg.sources.length - 1)) {
                            $('#annotSources').append('<span>, </span>');
                        }
                    }
                    
                    
                    $('#rdg_' + rdg.id + ' ul li.active a').tab('show');
                    getMEI(data.annot.staffID,rdg.id,'#rdg_' + rdg.id + '_verovio');
                    
                    if(i < (data.annot.rdgs.length - 1)) {
                        $('#annotSources').append('<span> &nbsp; | &nbsp; </span>');
                    }
                    
                }
                
                $('#openPageBtn').on('click',function() {
                    var pageID = $('#fullPageModal .carousel-inner .item.active').attr('data-pageID');
                    var sourceID = $('#fullPageModal .carousel-inner .item.active').attr('data-sourceID');
                    
                    window.parent.loadLink('xmldb:exist:///db/apps/contents/musicSources/freidi-musicSource_' + sourceID + '.xml#' + pageID);
                });
                
                //fill metadata section
                $('#annotPriority').html(data.annot.priority);
                $('#annotStaves').html(data.annot.staffLabel);
                $('#annotMeasures').html(data.annot.measureN);
                $('#annotResp').html('FreiDi (auto-generated from &lt;mei:app&gt;)');
                for(var i = 0; i < data.annot.otherAnnots.length; i++) {
                    var otherLink = '<a href="#" onclick="getAnnotation(' + data.annot.otherAnnots[i] + ')">' + data.annot.otherAnnots[i] + '</a>';
                    $('#otherAnnots').append(otherLink);
                    if( i < data.annot.otherAnnots.length - 1)
                        $('#otherAnnots').append('<span>, </span>');
                }
                if(data.annot.otherAnnots.length === 0)
                    $('#otherAnnots').append('<span>–</span>');
                $('#annotID').html(data.annot.id);
                //$('#annotSources').html(''); -> already filled above
                $('#annotCategories').html(data.annot.categories.join(', '));
                
                getAnnotText(data.annot.id);
    /**annots**/                
            } else if(data.annot.type === 'annot') {
                
                var count = 0;
                
                //set up staff tabs
                var pillBox = '<ul class="nav nav-pills" id="pillBox" role="tablist"></ul>';
                var tabBox = '<div class="tab-content" id="outerTabs"></div>';
                $('#annotStaves').append(pillBox);
                $('#leftBox').append(tabBox);
                
                for(var j = 0; j < data.annot.staves.length; j++) {
                    var staff = data.annot.staves[j];
                    
                    //set up pills
                    var pill = '<li role="presentation"><a href="#staffTab_' + staff.staffN + '" aria-controls="staffTab_' + staff.staffN + '" role="tab" data-toggle="tab">' + staff.staffLabel + '</a></li>';
                    var staffTab = '<div role="tabpanel" class="tab-pane" id="staffTab_' + staff.staffN + '"><ul class="nav nav-tabs" role="tablist"></ul><div class="tab-content"></div></div>';
                    
                    $('#pillBox').append(pill);
                    $('#outerTabs').append(staffTab);
                    
                    
                    
                    for(var n = 0; n < staff.sources.length; n++) {
                        var source = staff.sources[n];
                        
                        // generate snippet boxes
                        var tab = '<li role="presentation"><a href="#staff_' + staff.staffN + '_' + source.source + '" aria-controls="staff_' + staff.staffN + '_' + source.source + '" role="tab" data-toggle="tab">' + renderSourceID(source.source) + '</a></li>';
                        var content = '<div role="tabpanel" class="tab-pane" id="staff_' + staff.staffN + '_' + source.source + '" aria-controls="staff_' + staff.staffN + '_' + source.source + '" data-carouselN="' + n + '"><img src="' + source.imageSrc + '"/></div>';
                        $('#staffTab_' + staff.staffN + ' ul').append(tab);
                        $('#staffTab_' + staff.staffN + ' .tab-content').append(content);  
                        
                        
                        if( j === 0) {
                            
                            var carouselLi = '<li data-target="#full-page-carousel" data-slide-to="' + n + '"' + (n === 0 ? ' class="active"' : '') + '></li>';
                            var carouselItem = '<div class="item' + (n=== 0 ? ' active' : '') + '" data-sourceID="' + source.source + '" data-pageID="' + source.pageID + '"><img src="' + source.pageSrc + '"/><div class="carousel-caption"><h1>' + renderSourceID(source.source) + '<span style="font-size: 80%">, page ' + source.pageN + '</span></h1></div></div>';
                            
                            $('#fullPageModal ol.carousel-indicators').append(carouselLi);
                            $('#fullPageModal div.carousel-inner').append(carouselItem);
                            
                            $('#full-page-carousel').carousel('pause');
                        }
                        
                        $('#staff_' + staff.staffN + '_' + source.source).on('click',function(e) {
                            
                            var carouselN = $(e.currentTarget).attr('data-carouselN');
                            $('#fullPageModal').modal(); 
                            $('#full-page-carousel').carousel(parseInt(carouselN)).carousel('pause');
                        });
                        
                    }
                    
                    $('#staffTab_' + staff.staffN + ' ul li').first().addClass('active');
                    $('#staffTab_' + staff.staffN + ' .tab-content .tab-pane').first().addClass('active');
                    
                }
                
                $('#pillBox li').first().addClass('active');
                $('#outerTabs .tab-pane').first().addClass('active');
                
                //fill metadata section
                $('#annotPriority').html(data.annot.priority);
                //$('#annotStaves').html(data.annot.staffLabel);
                $('#annotMeasures').html(data.annot.allMeasures.join(', '));
                $('#annotResp').html('WeGA');
                for(var i = 0; i < data.annot.otherAnnots.length; i++) {
                    var otherLink = '<a href="#" onclick="getAnnotation(' + data.annot.otherAnnots[i] + ')">' + data.annot.otherAnnots[i] + '</a>';
                    $('#otherAnnots').append(otherLink);
                    if( i < data.annot.otherAnnots.length - 1)
                        $('#otherAnnots').append('<span>, </span>');
                }
                if(data.annot.otherAnnots.length === 0)
                    $('#otherAnnots').append('<span>–</span>');
                $('#annotID').html(data.annot.id);
                $('#annotSources').html(data.annot.sources.join(', '));
                $('#annotCategories').html(data.annot.categories.join(', '));
                
                getAnnotText(data.annot.id);
                
            }
    	}
    });
};

/*
 * this function gets the text of an annotation
 */
function getAnnotText(id) {

    $('#annotText').html('loading annotation…');
                    
    new jQuery.ajax('./resources/xql/getAnnotationText.xql',{
        method: 'get',
        data: {annotID: id},
        dataType: 'html',
        success: function(result) {
            
            $('#annotText').html(result);
            
        }
    });

    //$('#annotText').html('This is a text stub for annotation '+id);  
};

var annotParam = getParameter('annotID');
if(annotParam) {
    getAnnotation(annotParam);
    console.log(annotParam);
} else {
    getAnnotation('af7e7fe12-6668-427a-832f-4a9979a0aade');
}
// af7e7fe12-6668-427a-832f-4a9979a0aade -> Punktierung vs Note + Pause
// a3cbff2a7-688e-46b9-9746-77bedd60176e -> zwei Pausen vs. eine
// a645a7a03-6e27-4838-8d01-8cae100fa11b -> artic dot vs. none
// a63342691-67f7-417d-a4e9-0c81efe57cbd -> annot