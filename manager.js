;$( document ).ready(function() {
    var multi = true;
    var test = window.location.href.slice(window.location.href.indexOf('t=') + 2);
    //$('#t').val( test );
    var cache; // cached data

    function makeLogLine(str) {
	var now = Date(Date.now()).toString();
	$('#log').prepend( $('<div class="logItem">'  + str +
			     '<span class="logTime">' + now +
			     '</span></div>' ));
    }
    
    function SubmitSuccessHandler(data,action) {
	//console.log( data );
	if(data) {
	    makeLogLine( action + ' successful');
	    LoadQuestions();
	} else {
	    makeLogLine( action + ' failed');
	}
    }

    function SubmitErrorHandler(errString, err) {
	//console.log( errString, err );
	makeLogLine( errString + ' => ' + err);
    }
    
    function SubmitUpdate() {
	var url = 'manager.pl';
	var data = $('#managerForm').serialize();
	data += '&UPDATE=1';
	console.log( data );
	$.ajax({ type: 'POST',
		 url: url,
		 data: data,
		 success: function(d) { SubmitSuccessHandler(d,'Update') },
		 error: SubmitErrorHandler
	       });
    }

    function SubmitCreate() {
	var url = 'manager.pl';
	var data = $('#managerForm').serialize();
	data += '&CREATE=1';
	console.log( data );
	$.ajax({ type: 'POST',
		 url: url,
		 data: data,
		 success: function(d) { SubmitSuccessHandler(d,'Create') },
		 error: SubmitErrorHandler
	       });	
    }

    function SubmitDelete() {
	var url = 'manager.pl';
	var data = $('#managerForm').serialize();
	data += '&DELETE=1';
	console.log( data );
	$.ajax({ type: 'POST',
		 url: url,
		 data: data,
		 success: function(d) { SubmitSuccessHandler(d,'Delete') },
		 error: SubmitErrorHandler
	       });	
    }

    function ResetForm() {
	$('#t').val( test );
	$('#index').val( 0 );
	UnSetMulti();
	$('#multi').prop('checked', false);
	$('#submit').val('CREATE').unbind('click').click(SubmitCreate);
	$('#delete').hide();
    }
    
    function PopulateEditor(questionNumber) {
	var o = cache[ questionNumber];
	if(o.c.length > 1) {
	    SetMulti();
	    $('.crud-radio').prop('checked',false);
	    $('#multi').prop('checked', true);
	}
	else {
	    UnSetMulti();
	    $('#multi').prop('checked', false);
	}
	$('#index').val( 1+parseInt(questionNumber) );
	$('#q').val( o.q );
	$('#delete').show()
	$('#submit')
	    .val('UPDATE')
	    .unbind('click')
	    .click( SubmitUpdate );
	o.a.forEach(function(oo,i){
	    var id = i+1;
	    $(`#a${id}`).val( oo);
	    if(o.c.includes( id )) {
		$(`#c${id}`).prop( 'checked', true);
	    }
	});
	//o.c.forEach(function(o,i){ var id = i+1; $(`#c${id}`).prop( 'checked', true);	});
	//TODO: check if multi and run approprite function to update form display
    }
    
    function FilterList()
    {
	var indexFilter = parseInt($("#fix").val() || 0);
	var doIndexFilter = indexFilter > 0;
	var questionFilter = ($("#fq").val()).trim();
	var doQuestionFilter = questionFilter && questionFilter != "" ? true : false;
	var answerFilter = ($("#fa").val()||"").trim();
	var doAnswerFilter = answerFilter && answerFilter != "" ? true : false;
	var multiFilter = $("#fmulti").is(":checked") ? true : false;
	//console.log({iP:doIndexFilter,iF:indexFilter,qP:doQuestionFilter,qF:questionFilter,aP:doAnswerFilter,aF:answerFilter,m:multiFilter});
	$(".listl").each(function() {
	    var $this = $(this);
	    var hidden = false;
	    if(           doQuestionFilter && $this.find( `dt:contains(${questionFilter})` ).length == 0) { hidden = true; }
	    if(!hidden && doAnswerFilter   && $this.find( `dd:contains(${answerFilter})`   ).length == 0) { hidden = true; }
	    if(!hidden && multiFilter      && $this.find( 'dd'                             ).length != 5) { hidden = true; }
	    if(!hidden && doIndexFilter    && $this.attr('id') != `l${indexFilter}`                     ) { hidden = true; }
	    if(hidden) $this.hide();
	    else       $this.show();
	});
    }

    function FilterReset()
    {
	$( "#results > dl" ).show();
	$('#fq,#fa').val('');
	$('#fmulti').prop( 'checked', false);
    }
	
    function DrawList(data) {
	cache = data; // cache the data for loading the editor
	var $results = $("#results");
	//console.log($results);
	$results.empty();
	data.forEach(function(o,ix) {
	    var qid = 1+ix;
	    var $dl = $("<dl />",{id:'l'+qid,"class":"listl","data-index":ix});
	    var $dt = $("<dt />",{id:'q'+qid,"class":"listq","data-index":ix});
	    $dt.text( o.q );
	    $dl.append( $dt);
	    o.a.forEach(function(oo,iix) {
		var aid = 1 + iix;
		//var classes = o.c.includes(1+iix) ? "lista correctAnswer" : "lista correctAnswer";
		//var $dd = $("<dd />",{id:`q${qid}a${aid}`,"class":classes,"data-index":ix});
		var $dd = $("<dd />",{id:`q${qid}a${aid}`,"class":"lista","data-index":ix});
		$dd.html((o.c.includes(1+iix) ? '&#x2714;' : '&#10060;') + o.a[ iix ]);
		$dl.append( $dd);
	    });
	    $results.append( $dl);
	});
	var count = data.length;
	$('#listTab').text(`List (${count})`);
    }

    function LoadQuestions() {
	var url = "test.pl?t=" + test + "&list=1";
        //console.log("url: " + url);
        $.ajax({
            dataType: "json",
            url: url,
            success: function(data) {
                //console.log(data);
		DrawList(data);
            },
            error: function(xhr, textStatus, errorThrown) {
                console.log('AJAX ERROR: ' + textStatus + " : " + errorThrown);
            }
        });
    }
    
    function SetMulti() {
	if(multi) return;
	$("#fifth").show();
	//$("input:radio").attr('type','checkbox');
	$("input:radio").each(function(idx) {
            $this = $(this);
            if ($this.attr('name') != "multi" && $this.attr('name') != "fmulti") {
		var newName = $this.attr('name') + $this.attr('value');
		// $this.attr('name', newName);
		$this.attr('type', 'checkbox');
            }
	});
	multi = true;
    }

    function UnSetMulti() {
	if(!multi) return;
	$("#fifth").hide();
	$("input:checkbox").each(function(idx) {
            $this = $(this);
            if ($this.attr('name') != "multi" && $this.attr('name') != "fmulti") {
		// $this.attr('name', "c");
		$this.attr('type', 'radio');
            }
	});
	multi = false;
    }

    $('#reset').click(function() {
	ResetForm();
    });
    $('#delete').click(function() {
	SubmitDelete();
    });
    $("#multi").click(function() {
	if (multi) {
            UnSetMulti();
	} else {
            SetMulti();
	}
    });
    $('#listTab').click(function() {
	$( this ).addClass('selected');
	$('#crudTab').removeClass('selected');
	$('#list').show();
	$('#crud').hide();	
    }).click();
    $('#crudTab').click(function() {
	$( this ).addClass('selected');
	$('#listTab').removeClass('selected');
	$('#crud').show();
	$('#list').hide();	
    });
    $('#fclear').click(function(){FilterReset()});
    $('#fapply').click(function(){FilterList()});
    $('#results').on("click","dt,dd", function(){
	var $this = $( this );
	var ix = $this.attr('data-index');
	PopulateEditor( ix);
	$('#crudTab').click();
    });

    //UnSetMulti();
    ResetForm();
    LoadQuestions();
})
