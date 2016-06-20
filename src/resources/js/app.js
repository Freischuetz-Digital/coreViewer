/*
 * global variables and objects
 */
vrvToolkit = new verovio.toolkit();
var svgns = "http://www.w3.org/2000/svg";
var externalEdiromBaseLink = 'http://rubin.upb.de:8092/exist/apps/EdiromOnline/?uri=xmldb:exist:///db/apps/contents/musicSources/';
var data = {};
var views = {};

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
function getMEI(view, func) {

    var source = view.source;
    var mov = view.mdiv.n;
    var perspective = view.perspective;
    var target = view.renderTarget;
    var muted = view.muted.join('-');
    var solo = view.solo;

    new jQuery.ajax('./resources/xql/getMEI.xql',{
        method: 'get',
        data: {source: source,mov: mov, perspective: perspective, muted: muted, solo: solo},
        success: function(result) {
    	    
    	    var response = result || '';
            
            if($(response).get(0).localName === 'mei') {
                var mei = response;
                renderMEI(mei, target, func);    
            } else if($(response).get(0).localName === 'svg') {
                var svg = response;
                $(target).html(svg);
                
                if(typeof func === 'function')
                    func();
            }
            
            prepareSVG(view);
            
            changeScale(view);
            renderHighlights(view);
    	}
    });
};

/*
 * This function gets all available movements and sources, 
 * populates the modal that allows to open them, and adds 
 * the required listeners to open a view using function addView  
 */
function getFeatures() {

    new jQuery.ajax('./resources/xql/getFeatures.xql',{
        method: 'get',
        data: {},
        dataType: 'json',
        success: function(result) {
    	    
    	    data.mdivs = result.mdivs;
            data.sources = result.sources;
            data.annotCategories = result.annotCategories;
            
            //getApps();
            $('#loading').hide();
            
            for(var i = 0;i < data.sources.length;i++) {
                var td = '<td>' + renderSourceID(data.sources[i]) + '</td>';
                $('table#movementOverview thead tr').append(td);
            };
            
            for(var i = 0;i < data.mdivs.length;i++) {
                var mdiv = data.mdivs[i];
                
                //var option = '<option value="' + mdiv.id + '">' + mdiv.label + '</option>'; 
                //$('#movementSelect').append(option);
                
                var tr = '<tr data-mov.n="' + mdiv.n + '"><td class="mvivLabel">' + mdiv.label + '</td></tr>';
                $('table#movementOverview tbody').append(tr);
                
                for(var j = 0;j < data.sources.length;j++) {
                    var source = data.sources[j];
                    if(mdiv.sources.indexOf(source) === -1) {
                        $('table#movementOverview tbody tr:last-child').append('<td data-source="' + source + '" class="empty"></td>');
                    } else {
                        $('table#movementOverview tbody tr:last-child').append('<td data-source="' + source + '"><button type="button" data-source="' + source + '" data-mdiv-n="' + mdiv.n + '" class="btn btn-success btn-xs newViewBtn">Öffnen</button></td>');
                    }
                };
                
            }
            
            $('.newViewBtn').on('click',function(e) {
                var btn = e.target;
                var source = $(btn).attr('data-source');
                var mdivN = $(btn).attr('data-mdiv-n');
                
                function combinationWorks(mdiv, index, array) {
                    return (mdiv.n === mdivN && mdiv.sources.indexOf(source) !== -1);
                }
                
                if(data.mdivs.some(combinationWorks)) {
                    addView(source,mdivN);
                    $('#openViewModal').modal('hide');
                } else {
                    return false;
                }
                
                
            });
            
    	}
    });
    
};

/*
 * This function opens a new view
 */
function addView(source,movN) {
    
    $('#loading').show();
    
    function mdivsByN(mdiv) {
        return mdiv.n === movN;
    }
    
    var mdivs = data.mdivs.filter(mdivsByN);
    
    //check if there exactly one correct movement
    if(mdivs.length !== 1) {
        console.log('ERROR: cannot open view for mov ' + movN + ' from source ' + source);
        return false;
    }   
    
    //get right data object
    var mdiv = mdivs[0];
    
    //append template for this box
    $('#views').append($('#templates .viewBox').clone());
    
    //get unique id
    var boxID = Math.getUUID();
    $('#views .viewBox:last-child').attr('id',boxID);
    
    //create view object
    var view = {};
    view.perspective = 'abbr';
    view.source = source;
    view.mdiv = mdiv;
    view.id = boxID;
    view.muted = [];
    view.solo = -1;
    view.highlights = {};
    view.otherSources = {};
    view.renderTarget = '#verovio_' + boxID;
    view.categories = {};
    
    for(var i = 0; i < data.annotCategories.length; i++) {
        var category = data.annotCategories[i];
        view.categories[category.id] = true;
    }
    
    views[boxID] = view;
    
    //add source title
    $('#' + boxID + ' .sourceSiglum').html(source + ': <small>' + mdiv.label + '</small>');
    
    //add listener for closing view
    $('#' + boxID + ' .closeBtn').on('click',function(e) {
        closeView(view);
    });
    
    //setup scale slider
    $('#' + boxID + ' .scale input').attr('id','scale_' + boxID);
    $('#' + boxID + ' .scale input').attr('data-slider-id','slider_' + boxID);
    view.scale = $('#scale_' + boxID).slider();
    view.scale.on('change',function(){
        changeScale(view);
    });
    
    //add listener for rendering the abbreviated text
    $('#' + boxID + ' .showShortcutsBtn').on('click',function(e) {
        if(view.perspective === 'expan') {
            view.perspective = 'abbr';
            getMEI(view);
        }   
    });
    
    //add listener for rendering the expanded text
    $('#' + boxID + ' .resolveShortcutsBtn').on('click',function(e) {
        if(view.perspective === 'abbr') {
            view.perspective = 'expan';
            getMEI(view);
        }
    });
    
    //prepare coloration adjustments
    $('#' + boxID + ' .adjustColorationBtn').on('click', function() {
        $('#colorationModal').modal();
        
        $('#colorationModal button').off();
        
        view.highlights.trem ? $('#colorationModal .tremBtn').addClass('active').addClass('btn-success').attr('aria-pressed','true') : $('#colorationModal .tremBtn').removeClass('active').removeClass('btn-success').attr('aria-pressed','false');
        view.highlights.collaParte ? $('#colorationModal .collaParteBtn').addClass('active').addClass('btn-success').attr('aria-pressed','true') : $('#colorationModal .collaParteBtn').removeClass('active').removeClass('btn-success').attr('aria-pressed','false');
        view.highlights.abbr ? $('#colorationModal .abbrBtn').addClass('active').addClass('btn-success').attr('aria-pressed','true') : $('#colorationModal .abbrBtn').removeClass('active').removeClass('btn-success').attr('aria-pressed','false');
        
        $('#colorationModal .tremBtn').on('click',function(e) {
            $(e.target).toggleClass('btn-success');
            if($(e.target).hasClass('btn-success')) {
                 
                highlightFeatures(view,'trem');
                 
            } else {
                removeHighlights(view,'trem');
            }
        });
        $('#colorationModal .cpBtn').on('click',function(e) {
             $(e.target).toggleClass('btn-success');
             if($(e.target).hasClass('btn-success')) {
                 
                highlightFeatures(view,'collaParte');
                 
            } else {
                removeHighlights(view,'collaParte');
            }
        });
        $('#colorationModal .rptBtn').on('click',function(e) {
             $(e.target).toggleClass('btn-success');
             if($(e.target).hasClass('btn-success')) {
                 
                highlightFeatures(view,'abbr');
                 
            } else {
                removeHighlights(view,'abbr');
            }
        });
    
        $('#colorationModal .xpathBtn').on('click',function(e) {
            var xpath = $('#xpathInput').val();
            
            $(e.target).toggleClass('btn-success');
            if($(e.target).hasClass('btn-success')) {
                
                postXPath(view,xpath);
                
            } else {
                removeHighlights(view,'xpath');
            }
            
        });
        
    })
    
    //prepare scoreDef adjustments
    $('#' + boxID + ' .adjustScoreDefBtn').on('click', function() {
        $('#scoreDefList *').off();
        $('#scoreDefList li').remove();
        
        var tempMuted = view.muted.slice();
        var tempSolo = view.solo;
        
        //fill perfMedium
        for(var i = 0; i < mdiv.staves.length; i++) {
            var staff = mdiv.staves[i];
            
            //create list entry
            var li = '<li class="staff list-group-item' + ((tempSolo !== -1 && tempSolo !== staff.n) ? ' disabled' : '') + '" data-staff-n="' + staff.n + '" data-staff-label="' + staff.label + '">' + 
                '<span class="staffLabel">' + staff.n + ': ' + staff.label + '</span>' + 
                '<button class="solo btn btn-default btn-xs pull-right ' + (tempSolo === staff.n ? 'btn-warning' : 'btn-info') + '" data-toggle="button" aria-pressed="false">Solo</button>' +
                '<button class="mute btn btn-default btn-xs pull-right ' + (tempMuted.indexOf(staff.n) === -1 ? ' btn-success' : ' btn-danger') + (tempMuted.indexOf(staff.n) === -1 ? ' active' : '') + (tempSolo !== -1 ? ' disabled' : '') + '" data-toggle="button" aria-pressed="' + (tempMuted.indexOf(staff.n) !== -1 ? 'true' : 'false') + '">Show</button>' + 
            '</li>';
            $('#scoreDefList').append(li);
            
            //register listener for mute buttons
            $('#scoreDefList li[data-staff-n="' + staff.n + '"] .mute').on('click', function(e) {
                
                var label = $(e.target).parents('li').attr('data-staff-label');
                var n = $(e.target).parents('li').attr('data-staff-n');
                
                $(e.target).toggleClass('btn-success').toggleClass('btn-danger');
                if($(e.target).hasClass('btn-success')) {
                    var index = tempMuted.indexOf(n);
                    tempMuted.splice(index,1);
                } else {
                    tempMuted.push(n);
                }
            });
            
            //register listener for solo buttons
            $('#scoreDefList li[data-staff-n="' + staff.n + '"] .solo').on('click', function(e) {

                var label = $(e.target).parents('li').attr('data-staff-label');
                var n = $(e.target).parents('li').attr('data-staff-n');
                
                $(e.target).toggleClass('btn-info').toggleClass('btn-warning');
                
                if($(e.target).hasClass('btn-warning')) {
                    $('#scoreDefList li').addClass('disabled');
                    
                    if(tempSolo !== -1) 
                        $('#scoreDefList li[data-staff-n="' + tempSolo + '"] .solo').removeClass('btn-warning').addClass('btn-info');
                    
                    tempSolo = n;
                    $('#scoreDefList li[data-staff-n="' + n + '"]').removeClass('disabled');
                    $('#scoreDefList .mute').addClass('disabled');
                } else {
                    $('#scoreDefList li').removeClass('disabled');
                    $('#scoreDefList .mute').removeClass('disabled');
                    tempSolo = -1;
                }
            });
            
        }
        
        $('#adjustScoreDefBtn').on('click', function() {
            
            view.muted = tempMuted.slice();
            view.solo = tempSolo;
            
            getMEI(view);
            $('#scoreDefModal').modal('hide');
        });
        
        $('#scoreDefModal').modal();
        
    });
    
    //prepare overlays
    //currently disabled
    if(mdiv.sources.length === 1) {
        $('#' + boxID + ' .adjustOverlays').addClass('disabled');
    } else {
        //TODO
    }
    
    //prepare annotations
    if(mdiv.annotations.length === 0) {
        $('#' + boxID + ' .adjustAnnotations').addClass('disabled');
    } else {
        
        $('#' + boxID + ' .adjustAnnotations').on('click', function() {
            
            $('#annotationSources *').off();
            $('#annotationSources *').remove();
            
            //list of sources
            for(var i = 0; i < data.sources.length; i++) {
                
                var current = data.sources[i];
                var available = mdiv.sources.indexOf(current) !== -1;
                
                if(available && typeof view.otherSources[current] === 'undefined' && current !== view.source)
                    view.otherSources[current] = true;
                else if(typeof view.otherSources[current] === 'undefined')
                    view.otherSources[current] = false;
                    
                var content = '<label class="checkbox-inline sourceCheck"><input type="checkbox" id="annotSource_' + current + '" value="' + current + '"' + ((current === view.source) ? ' checked="checked"' : '') + ((!available || current === view.source) ? ' disabled="disabled"' : '') + '/> ' + renderSourceID(current) + ' </label>';
                $('#annotationSources').append(content);
                
                if(available && view.otherSources[current] === true) {
                    //console.log('I should check '+ current + ' --- ' + view.otherSources[current]);
                    $('#annotSource_' + current).attr('checked','checked');
                } else {
                    //console.log('I should uncheck '+current + ' --- ' + view.otherSources[current]);
                    $('#annotSource_' + current).removeAttr('checked');
                }    
                if(available && current !== view.source) {
                    $('#annotSource_' + current).on('click',function(e) {
                        view.otherSources[e.target.value] = !view.otherSources[e.target.value];
                    });
                }    
            }
            
            $('#annotationsModal .catRow *').off();
            
            for(var i = 0; i < data.annotCategories.length; i++) {
                
                var category = data.annotCategories[i];
                var active = view.categories[category.id];
                
                if(active === true)
                    $('#annotationsModal #' + category.id).get(0).checked = true;
                else    
                    $('#annotationsModal #' + category.id).get(0).checked = false;
                    
                $('#annotationsModal #' + category.id).on('change',function(e) {
                    view.categories[e.currentTarget.value] = !view.categories[e.currentTarget.value];                    
                });
                
            }
            
            
            //remove listeners from other views
            $('#annotationsModal button').off();
            
            //set up button for apps according to current view
            if(view.highlights['apps'] === true)
                $('#annotationsModal .diffSourceBtn').addClass('btn-success').addClass('active').attr('aria-pressed','true');
            else    
                $('#annotationsModal .diffSourceBtn').removeClass('btn-success').removeClass('active').attr('aria-pressed','false');
                
            $('#annotationsModal .diffSourceBtn').on('click',function(e) {
                $(e.target).toggleClass('btn-success');
                if($(e.target).hasClass('btn-success')) {
                    highlightFeatures(view,'apps');
                } else {
                    removeHighlights(view,'apps');
                }
            });
            
            //set up button for annotation priority 1 according to current view
            if(view.highlights['annotPrio1'] === true)
                $('#annotationsModal .annotPrio1Btn').addClass('btn-success').addClass('active').attr('aria-pressed','true');
            else    
                $('#annotationsModal .annotPrio1Btn').removeClass('btn-success').removeClass('active').attr('aria-pressed','false');
                
            $('#annotationsModal .annotPrio1Btn').on('click', function(e) {
                $(e.target).toggleClass('btn-success');
                if($(e.target).hasClass('btn-success')) {
                    showAnnotations(view,'1');
                } else {
                    removeAnnotations(view,'1');
                }
            });
            
            //set up button for annotation priority 2 according to current view
            if(view.highlights['annotPrio2'] === true)
                $('#annotationsModal .annotPrio2Btn').addClass('btn-success').addClass('active').attr('aria-pressed','true');
            else    
                $('#annotationsModal .annotPrio2Btn').removeClass('btn-success').removeClass('active').attr('aria-pressed','false');
                
            $('#annotationsModal .annotPrio2Btn').on('click', function(e) {
                $(e.target).toggleClass('btn-success');
                if($(e.target).hasClass('btn-success')) {
                    showAnnotations(view,'2');
                } else {
                    removeAnnotations(view,'2');
                }
            });
            
            //set up button for annotation priority 3 according to current view
            if(view.highlights['annotPrio3'] === true)
                $('#annotationsModal .annotPrio3Btn').addClass('btn-success').addClass('active').attr('aria-pressed','true');
            else    
                $('#annotationsModal .annotPrio3Btn').removeClass('btn-success').removeClass('active').attr('aria-pressed','false');
            
            $('#annotationsModal .annotPrio3Btn').on('click', function(e) {
                $(e.target).toggleClass('btn-success');
                if($(e.target).hasClass('btn-success')) {
                    showAnnotations(view,'3');
                } else {
                    removeAnnotations(view,'3');
                }
            });
            
            $('#annotationsModal').modal();    
        });
        
    }
    
    //set up renderBox
    $('#' + boxID + ' .renderBox').append('<div class="verovio" id="' + view.renderTarget.substring(1) + '"></div>');
    
    $('#' + boxID).show();
    
    $('#loading').hide();
    
    getMEI(view);
    getAbbreviations(view.source,view.mdiv.n);
};

/*
 * this function adds circles for annotations
 */
function showAnnotations(view,prio) {
    var annots = $.grep(view.mdiv.annotations, function(annot,i) {
        return annot.priority === prio;
    });
    
    view.highlights['annotPrio' + prio] = true;
    
    for(var i = 0; i<annots.length;i++) {
        var annot = annots[i];
        
        var activeCategories = [];
        var showMe = false;
        
        //get array of active categories
        $.each( view.categories, function(category, bool) {
            if(bool)
                activeCategories.push(category);
        });
        
        //iterate until first active category is found
        for (var n = 0; n < annot.categories.length; n++) {
            if(activeCategories.indexOf(annot.categories[n]) !== -1) {
                showMe = true;
                break;
            }
        }
        
        //when no active category is contained, move on to next annotation
        if(!showMe)
            continue;
        
        for(var m = 0; m < annot.measures.length; m++) {
            for(var s = 0; s < annot.staves.length;s++) {
                var id = 'overlay_' + view.source + '_' + annot.measures[m] + '_s' + annot.staves[s];
                var g = $(view.renderTarget + ' #' + id);
                
                if(g.length === 0) {
                    console.log('ERROR: Unable to retrieve ' + view.renderTarget + ' #' + id);
                    continue;
                }
                
                var rect = $(view.renderTarget + ' #' + id + ' rect.staffRect').get(0);
                //var rect = $(g).filter('rect.staffRect').get(0);
                
                var bbox = rect.getBBox();
                
                var circle = document.createElementNS(svgns,'circle');
                circle.setAttributeNS(null,'id','marker_' + annot.id + '_' + id);
                circle.setAttributeNS(null,'cx',bbox.x + bbox.width/2 - 500 + prio * 300);
                circle.setAttributeNS(null,'cy',bbox.y + bbox.height/2 - 200);
                circle.setAttributeNS(null,'r',400);
                circle.setAttributeNS(null,'stroke','none');
                circle.setAttributeNS(null,'class','annotMarker annotPrio' + prio);
                circle.setAttributeNS(null,'title',annot.categories.join(', '));
                
                $(g).append(circle);
                
                $(view.renderTarget + ' #marker_' + annot.id + '_' + id).on('click', function() {
                    
                    loadAnnotation(annot.id);
                    
                });
                
            }
        }
    }
};

/*
 * this function removes annotations
 */
 function removeAnnotations(view,prio) {
     $(view.renderTarget + ' .annotMarker.annotPrio' + prio).off().remove();
     view.highlights['annotPrio' + prio] = false;
 }

/*
 * this function removes colorations from a view
 */
function removeHighlights(view,type) {
    $(view.renderTarget + ' svg .highlight.' + type).off().remove();
    
    $(view.renderTarget + ' .' + type + 'Item').off();
    $(view.renderTarget + ' .' + type + 'Item').each(function(index) {
        this.classList.remove(type + 'Item'); 
    });
    
    if(type === 'xpath')
        view.xpathResults = {};
    
    view.highlights[type] = false;
};


/*
 * this function decides which parts need to be highlighted and calls the respective functions
 */
 function renderHighlights(view) {
    if(view.highlights.trem === true)
        highlightFeatures(view,'trem');
        
    if(view.highlights.abbr === true)
        highlightFeatures(view,'abbr');
        
    if(view.highlights.collaParte === true)
        highlightFeatures(view,'collaParte');
        
    if(view.highlights.xpath === true)
        highlightFeatures(view,'xpath');

    if(view.highlights.apps === true)
        highlightFeatures(view,'apps');
 };

/*
 * this function sends an xpath expression to the database and 
 * executes a success function afterwards
 */
function postXPath(view,xpath) {
    
    $('#loading').show();
    
    xpath = xpath.replace(/</g,' lt ');
    xpath = xpath.replace(/>/g,' gt ');
    xpath = xpath.replace(/"/g,"'");
    xpath = xpath.replace(/(document-uri\(|doc\(|collection\(|&|\\|\||\&)/g,'');
    
    jQuery.ajax('./resources/xql/processXPath.xql',{
        method: 'get',
        data: {xpath:xpath,sourceID: view.source,movN: view.mdiv.n},
        dataType: 'json',
        success: function(result) {
    	   
    	   $('#loading').hide();
    	   
    	   view.xpathResults = result;
    	   highlightFeatures(view,'xpath');
    	   
        }
    });

};

/*
 * this function highlights abbreviations in a view
 */
function highlightFeatures(view,type) {
    
    //decide if an abbreviation is to be rendered
    if(['trem','abbr','collaParte'].indexOf(type) !== -1) {
        
        var shortcuts = data.shortcuts[view.source][view.mdiv.n];
        
        for(var i = 0;i < shortcuts[type + 's'].length;i++) {
            var shortcut = shortcuts[type + 's'][i];
            highlightStaff(view,type, shortcut.staffID,shortcut.desc);
            
            for(var j = 0;j < shortcut.abbrContent.length; j++) {
                if(typeof $(view.renderTarget + ' #' + shortcut.abbrContent[j]).get(0) !== 'undefined') {
                    $(view.renderTarget + ' #' + shortcut.abbrContent[j]).get(0).classList.add(type + 'Item');
                }
            }
            
            for(var j = 0;j < shortcut.expanContent.length; j++) {
                if(typeof $(view.renderTarget + ' #' + shortcut.expanContent[j]).get(0) !== 'undefined') {
                    $(view.renderTarget + ' #' + shortcut.expanContent[j]).get(0).classList.add(type + 'Item');
                }
            }
            
        }
    
    }
    
    if(type === 'xpath') {
        
        for(var i = 0;i < view.xpathResults.source.length;i++) {
            var elem = view.xpathResults.source[i];
            highlightStaff(view,type, elem.staffID,elem.desc);
            
            if(typeof $(view.renderTarget + ' #' + elem.elemID).get(0) !== 'undefined') {
                $(view.renderTarget + ' #' + elem.elemID).get(0).classList.add(type + 'Item');
            }
        
        }
    }
    
    if(type === 'apps') {
        
        //todo: identify which sources are active and highlight only them
        //get apps from 
        
        getApps(view);
        
    }
    
    view.highlights[type] = true;
    
};


/*
 * this function loads all apps for a given view
 */
function getApps(view) {
    
    $('#loading').show();
    
    var otherSources = [];
    
    $.each( view.otherSources, function( source, bool ) {
        if(bool)
            otherSources.push(source);
    });
    
    var categories = [];
    $.each( view.categories, function(category, bool) {
        if(bool)
            categories.push(category);
    });

    new jQuery.ajax('./resources/xql/getApps.xql',{
        method: 'get',
        dataType: 'json',
        data: {source: view.source,otherSources: otherSources.join('_'),categories: categories.join('___'),mdivN: view.mdiv.n},
        success: function(result) {
    	    
    	    var response = result || '';
            
            $('#loading').hide();
            
            for(var i = 0;i < response.length;i++) {
                var app = response[i];
                highlightStaff(view,'app', app.staffID,app.desc);
                
                $(view.renderTarget + ' svg g#' + app.staffID + ' rect.app').on('click',function() {
                    loadAnnotation(app.id);    
                });
                
                for(var j = 0; j < app.appContent.length; j++) {
                    if(typeof $(view.renderTarget + ' #' + app.appContent[j]).get(0) !== 'undefined') {
                        $(view.renderTarget + ' #' + app.appContent[j]).get(0).classList.add('appItem');
                    }   
                }
            }
    	}
    });
};



/*
 * this function closes a view
 */
function closeView(view) {
    $('#' + view.id + ' .closeBtn, #' + view.id + ' button').off();
    removeHighlights(view);
    delete views[view.id];
    $('#' + view.id).remove();
};

/*
 * this function changes the scaling of a given view
 */
function changeScale(view) {

    var height = $($(view.renderTarget + ' svg').get(0)).height();
    var width = $($(view.renderTarget + ' svg').get(0)).width();
	var value = view.scale.val();
	
	var minv = Math.log(0.02);
	var maxv = Math.log(0.95);
	var scale = (maxv-minv) / (1 - 0.01);
	
	var output = Math.exp(minv + scale *(value - 0.01));
	
	var factor;
	var vfactor;
	var hfactor;
	
	if(output > 0.3) {
	    factor = output;
	    hfactor = output;
	    vfactor = output;
	} else {
	    factor =  (Math.pow((2 * output + 0.4),4) * output) + ',' + output;
	    hfactor = (Math.pow((2 * output + 0.4),4) * output);
	    vfactor =  output;
	}
	
	
	
	$($(view.renderTarget + ' svg').get(0)).attr('transform','scale(' + factor + ')');
	$($(view.renderTarget).parent().get(0)).height(height * vfactor + 10);
	$($(view.renderTarget).get(0)).width(width * hfactor + 10);
	$($(view.renderTarget).get(0)).height(height * vfactor - 10);
	
	//following code not used yet
	if(output > 0.3) {
        $(view.renderTarget).addClass('scaleNotes');
        $(view.renderTarget).removeClass('scaleRects');
	} else {
	    $(view.renderTarget).removeClass('scaleNotes');
	    $(view.renderTarget).addClass('scaleRects');
	}
	
};

function logslider(position) {
  // position will be between 0 and 100
  var minp = 30;
  var maxp = 100;

  // The result should be between 100 an 10000000
  var minv = Math.log(100);
  var maxv = Math.log(10000000);

  // calculate adjustment factor
  var scale = (maxv-minv) / (maxp-minp);

  return Math.exp(minv + scale*(position-minp));
}

/*
 * this function gets the staves containing abbreviations for a specific source
 * and stores / caches this information is the global data object. If a success 
 * function is provided, it is executed after loading (or accessing) the data.
 */
function getAbbreviations(sourceID,movN,func) {
    
    $('#loading').show();
    
    if(typeof data.shortcuts === 'undefined' ||
        typeof data.shortcuts[sourceID] === 'undefined' ||
        typeof data.shortcuts[sourceID][movN] === 'undefined') {
        
            new jQuery.ajax('./resources/xql/getAbbreviations.xql',{
            dataType: 'json',
            method: 'get',
            data: {sourceID:sourceID,movN: movN},
            success: function(result) {
                
                $('#loading').hide();
                
                if(typeof data.shortcuts === 'undefined')
                    data.shortcuts = {};
            
                if(typeof data.shortcuts[sourceID] === 'undefined')
                    data.shortcuts[sourceID] = {};
                    
                var tmp = data.shortcuts[sourceID];
                
                if(typeof tmp[movN] === 'undefined')
                    tmp[movN] = {};
                    
                tmp[movN].abbrs = result.abbrs;
                tmp[movN].collaPartes = result.collaPartes;
                tmp[movN].trems = result.trems;
                
                if(typeof func === 'function')
                    func();
            }
        });  
        
    } else if(typeof func === 'function') {
        func();
    } 
    
};

/*
 * this function lays out an interaction layer on top of all staves
 */
function prepareSVG(view) {
    $(view.renderTarget + ' svg g.staff').each(function(index) {
        var staff = this;
        var staffID = $(staff).attr('id');
        
        var parts = staffID.split('_');
        var measureN = parts[2].substring(7);
        var staffN = parts[3].substring(1);
        
        var staffLabel = view.mdiv.staves[staffN - 1].label;
        
        var bbox = staff.getBBox();
        
        var g = document.createElementNS(svgns,'g');
        g.setAttributeNS(null,'id','overlay_' + staffID);
        $(staff).before(g);
        
        var rect = document.createElementNS(svgns, 'rect');
        var desc = 'Bar ' + measureN + ', ' + staffLabel;
        
        rect.setAttributeNS(null, 'x', bbox.x);
        rect.setAttributeNS(null, 'y', bbox.y);
        rect.setAttributeNS(null, 'height', bbox.height);
        rect.setAttributeNS(null, 'width', bbox.width);
        rect.setAttributeNS(null, 'class', 'staffRect');
        rect.setAttribute('title', desc);
        $(g).append(rect);
        
        
        var header = {header: desc}
        var link;
        
        if(window === top) {
        // die Seite läuft stand alone
            link = { text: 'Open Facsimile', href: externalEdiromBaseLink + 'freidi-musicSource_' + view.source + '.xml#' + view.source + '_zoneOf_mov' + view.mdiv.n + '_measure' + measureN + '_s' + staffN, target: '_blank' };
        }else {
        // die Seite läuft in einem iFrame
            link = { text: 'Open Facsimile', 
                    action: function(e){
                   	    e.preventDefault();
                        window.parent.loadLink("xmldb:exist:///db/apps/contents/musicSources/freidi-musicSource_' + view.source + '.xml#' + view.source + '_zoneOf_mov' + view.mdiv.n + '_measure' + measureN + '_s' + staffN'", {useExisting:true});
                    }
            };
        }
        
        $(rect).on('mouseover',function() {
            context.attach('.staffRect', [header,link]);
        });
        
    });
};

/*
 * this function colors a given staff
 */
function highlightStaff(view,type,staffID,desc) {
    
    var svg = $(view.renderTarget + ' svg g#' + staffID).get(0);
        
    if(typeof svg === 'undefined')
        return;
        
    var bbox = svg.getBBox();
    
    var rect = document.createElementNS(svgns, 'rect');
        
    rect.setAttributeNS(null, 'x', bbox.x);
    rect.setAttributeNS(null, 'y', bbox.y);
    rect.setAttributeNS(null, 'height', bbox.height);
    rect.setAttributeNS(null, 'width', bbox.width);
    rect.setAttributeNS(null, 'class', 'highlight ' + type);
    rect.setAttribute('title', desc);
    
    /*if(typeof staff.annotIDs !== 'undefined')
        rect.setAttribute('onclick','alert("Öffne Anmerkungen ' + staff.annotIDs + '");');
    */    
    $(svg).prepend(rect);

};


/*
 * This function registers the listener to open the viewModal
 */
$('#openViewModalBtn').on('click',function() {
    if(typeof data.mdivs === 'undefined' || data.mdivs.length === 0)
        return false;
    
    $('#openViewModal').modal();
    
});

$('#movementSelect').on('change',function() {
    alert('selected source has changed'); 
});

function loadAnnotation(id) {
    //TODO: 
    console.log('INFO: loading annotation ' + id);
};

function renderSourceID(sourceID) {
    switch(sourceID) {
        case 'A': return 'A'; break;
        case 'KA1': return 'K<sup>A</sup><sub>1</sub>'; break;
        case 'KA2': return 'K<sup>A</sup><sub>2</sub>'; break;
        case 'KA9': return 'K<sup>A</sup><sub>9</sub>'; break;
        case 'K13': return 'K<sub>13</sub>'; break;
        case 'K15': return 'K<sub>15</sub>'; break;
        case 'KA19': return 'K<sup>A</sup><sub>19</sub>'; break;
        case 'K20': return 'K<sub>20</sub>'; break;
        case 'KA26': return 'K<sup>A</sup><sub>26</sub>'; break;
        case 'D1849': return 'D<sub>1849</sub>'; break;
        default: return sourceID; break;
    }  
};

context.init({
    fadeSpeed: 100,
    filter: function ($obj){},
    above: 'auto',
    preventDoubleContext: true,
    compress: false
});

/*
 * start of processing
 */
getFeatures();

//getMEI(source,mov,perspective);
