vrvToolkit = new verovio.toolkit();

var defaultWidth;
var defaultHeight;

var svgns = "http://www.w3.org/2000/svg";

function getStaffList(target) {
    new jQuery.ajax('./resources/xql/getFeatures.xql',{
        dataType: 'json',
        method: 'get',
        data: {},
        success: function(result) {
    	    
    	    var staves = result || "";
    	    
    	    for(var i = 0; i<staves.length;i++) {
    	       var staff = staves[i];
    	       var tmp = '<div class="part"><input type="checkbox" checked="checked" value="' + staff.n + '"/> ' + staff.label + '</div>';
               
               $(target).append(tmp);
    	    }
    	    
    	    /*$.each(staves,function(index, staff) {
               var tmp = '<div class="part">' + staff.n + ': ' + staff.label + '</div>';
               
               $('#parts').append(tmp);
            });*/
    	    
    	}
    });
};

function getMEIfile(targetID,sourceID,mode,staves) {

    $('#loading').show();
    
    console.log('hallo?');
    var source = 'A';
    var mov = '3';
    var perspective = 'expan';
    
    new jQuery.ajax('./resources/xql/getMEI.xql',{
        method: 'get',
        data: {source: source,mov: mov, perspective: perspective},
        success: function(result) {
    	    
    	    var response = result || '';
            
            var mei = response;
            
            console.log('got mei');
            
            renderMEI(mei, targetID);
            
    	}
    });
    
    
    /*new jQuery.ajax('./resources/xql/getMEIfile.xql',{
        method: 'get',
        data: {sourceID:sourceID,mode: mode,staves: staves},
        success: function(result) {
    	    
    	    var response = result || "";
            mei = response;
            renderMEI(mei, targetID);
    	    
    	    //getAbbreviations(sourceID);
    	    
    	}
    });*/
};


function getAbbreviations(sourceID,svgContainer) {
    new jQuery.ajax('./resources/xql/getAbbreviations.xql',{
        dataType: 'json',
        method: 'get',
        data: {sourceID:sourceID,level: 'staff'},
        success: function(result) {
            
            var staves = result || "";
            
            if(sourceID === 'A') 
                removeHighlights(svgContainer);
            
            $.each(staves,function(index, staff) {
               highlightStaff(staff,svgContainer); 
            });
            
        }
    });  
};

function getApps() {
    new jQuery.ajax('./resources/xql/getApps.xql',{
        dataType: 'json',
        method: 'get',
        data: {},
        success: function(result) {
            
            var staves = result || "";
            
            removeHighlights();
            
            $.each(staves,function(index, staff) {
               highlightStaff(staff); 
            });
            
        }
    });  
};

function renderMEI(mei, targetID) {
    var options = JSON.stringify({
      	inputFormat: 'mei',
      	border: 0,
      	scale: 25,
      	ignoreLayout: 0,
      	noLayout: 1
      });
    
	vrvToolkit.setOptions( options );
	vrvToolkit.loadData(mei + '\n');
    
    var svg = vrvToolkit.renderPage(1);
    
    $(targetID).html(svg);
    
    defaultWidth = $(svg).width();
    defaultHeight = $(svg).height();
    
    addMeasureCount();
    adjustZoomlevel();
    
    $('#loading').hide();
    
};

function loadPage(n) {
    var svg = vrvToolkit.renderPage(n);
    $('#content').html(svg);
};

function addMeasureCount() {
    $('svg g.measure[id$="0"]').each(function(index) {
        var bbox = this.getBBox();
        bbox.width = $(this).children('g.staff').get(0).getBBox().width;
        
        var rect = document.createElementNS(svgns, 'rect');
        
        rect.setAttributeNS(null, 'x', bbox.x);
        rect.setAttributeNS(null, 'y', bbox.y);
        rect.setAttributeNS(null, 'height', bbox.height);
        rect.setAttributeNS(null, 'width', bbox.width);
        rect.setAttributeNS(null, 'class', 'measureCount');
        rect.setAttribute('title','Takt ' + ((index+1)*10));
        
        $(this).before(rect);
    });
};

function removeHighlights(svgContainer) {
    $('#' + svgContainer + ' svg rect.highlight').off();
    $('#' + svgContainer + ' svg rect.highlight').remove();
};

function highlightStaff(staff,svgContainer) {
    
    var svg;
    
    if(typeof svgContainer !== 'undefined') {
        svg = $('#' + svgContainer + ' svg g#' + staff.id).get(0);
    } else { 
        svg = $('svg g#' + staff.id).get(0);
    }
        
    if(typeof svg === 'undefined')
        return;
        
    var bbox = svg.getBBox();
    
    var rect = document.createElementNS(svgns, 'rect');
        
    rect.setAttributeNS(null, 'x', bbox.x);
    rect.setAttributeNS(null, 'y', bbox.y);
    rect.setAttributeNS(null, 'height', bbox.height);
    rect.setAttributeNS(null, 'width', bbox.width);
    rect.setAttributeNS(null, 'class', 'highlight');
    rect.setAttribute('title', 'Takt ' + staff.measureN + ', ' + staff.label + staff.desc);
    
    if(typeof staff.annotIDs !== 'undefined')
        rect.setAttribute('onclick','alert("Öffne Anmerkungen ' + staff.annotIDs + '");');
        
    $(svg).before(rect);

};

function addView() {
    
    console.log('addView');
    $('#loading').show();
    var tmp = $('#templates .viewBox').clone();
    
    var num = $('#content .viewBox').length;
    var outerid = 'viewBox' + num;
    var innerid = 'verovio' + num;
    
    $(tmp).attr('id',outerid);
    $(tmp).children('.verovio').attr('id',innerid);
    $('#content').append(tmp);
    
    getStaffList('#' + outerid + ' .staffDefs');
    getMEIfile('#' + innerid,'core','raw');
    
    /*set up listeners*/
    $('#' + outerid + ' .optionsBtn').on('click',function(e) {
        $('#' + outerid + ' .optionsBtn').toggleClass('active')
        $('#' + outerid + ' .scoreDef').toggle();
    });
    
    $('#' + outerid + ' .closeBtn').on('click',function(e) {
        $('#' + outerid + ' .optionsBtn').off();
        $('#' + outerid + ' .closeBtn').off();
        
        $('#' + outerid).remove();
    });
    
    $('#' + outerid + ' .abbrev_A').on('click',function(e) {
        getAbbreviations('A',innerid);
    });
    
    $('#' + outerid + ' .abbrev_KA2').on('click',function(e) {
        getAbbreviations('KA2',innerid);
    });

    
    $('#' + outerid + ' .refreshScoreDef').on('click',function(e){
        
        var checkedStaves = $('#' + outerid + ' .staffDefs input:checkbox:checked').map(function() {
            return this.value;
        }).get(); 
        
        getMEIfile('#' + innerid,'core','raw',checkedStaves.join('-'));
        
    });
    
};

function adjustZoomlevel() {
    var val = $('#scaleSlider').val();
    
    $('.verovio > svg').attr('width',(defaultWidth * val * 0.8) + 'px');
    $('.verovio > svg').attr('height',(defaultHeight * val * 0.8) + 'px');
    $('.verovio > svg').attr('transform','scale(' + val + ')');  
};

$('#scaleSlider').on('change',function(e) {
    adjustZoomlevel();
});

$('#addView').on('click',function() {
    addView();
});

$('#content').scroll(function(){
    $('.viewBox header').css({
        'left': $(this).scrollLeft() //Always stay left
    });
});

getMEIfile('#content','core','raw');


