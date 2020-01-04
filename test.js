;
$(document).ready(function() {
    var isRunning = false;
    var totalQuestions = 90;
    var remainingQuestions = totalQuestions;
    var answeredQuestions = 0;
    var remainingTime = 900000;
    var questionList = new Array();
    var answerList = new Array();
    //var test = 'A1';
    var test = window.location.href.slice(window.location.href.indexOf('t=') + 2);
    var currentQuestion;

    var testNames = { a1: "A+ (1001)",
		      a2: "A+ (1002)",
		      n:  "N+ (N10-007)",
		      s:  "S+ (SY0-501)" };
    
    function drawReport() {
	$('input:button').hide();
        var target = $("#reportDiv");
        answerList.forEach(function(o, ix) {
	    var dlID = "a" + ix;
            var dl = $("<dl />", {
                id: dlID,
                "class": "reportDl"
            });
	    var dt = $("<dt />", {
		id: dlID + "q",
		"class": "reportDt"
	    });
	    dt.text( o.question.data.q );
	    o.question.data.a.forEach(function(oo,ixx) {
		var dd = $("<dd />", {
                    id: dlID + 'a' + (1+ixx),
                    "class": "reportDd"
		});
		dd.text( oo );
		if(o.chosen.includes( ixx + 1 ))
		    dd.addClass('reportChosen');
		if(o.question.data.c.includes( ixx + 1))
		    dd.addClass('reportCorrect');
		dt.append( dd );
	    });
	    dl.append( dt );
	    target.append( dl );
        });
	target.show();
    }
    
    function drawResults() {

        //console.log(answerList);

        if (!isRunning) return;
        isRunning = false;
        $('#time').trigger('pause');
        $('#current').hide();
        var $btn = $('input:button');
        $btn.hide();
        var $r = $("#results");
        var incorrect = answerList.length;
        if (answeredQuestions < totalQuestions)
            incorrect += totalQuestions - answeredQuestions;
        var correct = totalQuestions - incorrect;
        var pct = Math.round((100 * correct) / totalQuestions);
	var percentageClass = pct < 60 ? 'fiftyNinePercent' : (pct < 80 ? 'seventyNinePercent' : 'eightyPercent');
        var result = correct + '/' + totalQuestions + ' = <span id="resultPercentage" class="' + percentageClass +'">' + pct + '</span>%';
        $r.html(result);
        $r.show();

        $btn.unbind('click');
        $btn.click(function() {
	    drawReport();
        });
	if(incorrect > 0) {
            $btn.val('View Errors');
	    $btn.show();
	}
    }

    function scoreQuestion() {
        var chosen = new Array();
        $('.chosen').each(function() {
            var x = $(this).prop("id").match(/\d+/);
            chosen.push(parseInt(x[0]));
        });
        //console.log(chosen);
        //console.log(currentQuestion.data.c);
        var a = JSON.stringify(chosen);
        var b = JSON.stringify(currentQuestion.data.c);
        console.log(a + ' == ' + b + ' => ' + (a == b).toString());
        if (a == b) {
            // correct answer!
        } else {
            // incorrect, add answerList
            answerList.push({
                chosen: chosen,
                question: currentQuestion
            });
        }
        ++answeredQuestions;
    }

    function nextQuestion() {
        $('#current').fadeOut('fast');
        scoreQuestion();
        if (--remainingQuestions > 0) getQuestion();
        else drawResults();
    }

    function start() {
        $btn = $('input:button');
        $btn.unbind('click');
        $btn.click(function() {
            nextQuestion()
        });
        $btn.val('Submit Answer');
	$('#progress').show();
        getQuestion();
    }

    function toggleSelected(el) {
        var $this = $(el);
        if ($this.hasClass('chosen'))
            $this.removeClass('chosen');
        else
            $this.addClass('chosen');
    }

    function getQuestion() {
        var url = "test.pl?t=" + test + "&history=" + questionList.join(',');
        console.log("url: " + url);
        $('dd').removeClass();
        $.ajax({
            dataType: "json",
            url: url,
            success: function(data) {
                currentQuestion = data;
                //console.log(data);
                console.log(data.data.c);
                questionList.push(data.index);
                drawQuestion(data.data);
            },
            error: function(xhr, textStatus, errorThrown) {
                console.log('AJAX ERROR: ' + textStatus + " : " + errorThrown);
            }
        });
    }

    function drawQuestion(question) {
        $('#q').text(question.q);
        var qcount = question.a.length;
        for (var i = 0; i < qcount; ++i) {
            var field = i + 1;
            $('#a' + field).text(question.a[i]);
        }
        if (qcount > 4)
            $('#a5').show();
        else
            $('#a5').hide();
        $('#current').fadeIn('fast');
        if (!isRunning) {
            isRunning = true;
            $('#time').startTimer({
                onComplete: function(ele) {
		    $('dd.chosen').each(function(){ $(this).removeClass('chosen')});
		    scoreQuestion();
                    drawResults();
                }
            });
        }
        $('#count').text((answeredQuestions + 1).toString() + "/" + totalQuestions);
        return false;
    }

    $('dd.currentAnswer').click(function() {
        toggleSelected(this);
    });
    $('input').click(start);

    $('#testName').text( testNames[ test.toLowerCase() ]);
});

/*

	url,
	   function( data) {
	       // result is the next question
	       currentQuestion = data;	
	       // add this one to question list
	       questionList.push( data.index );
	       // UPDATE DISPLAY
	       // TODO
	   });
*/
