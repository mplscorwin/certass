#!/usr/bin/perl

use strict;
use warnings;

use CGI;
use CGI::Carp qw[fatalsToBrowser];
use List::MoreUtils qw[uniq any];
#use JSON;

our ($datafolder) = q(./appdata/);

my $q = new CGI();

sub mydie (@) {
  print $q->header;
  print @_;
  exit;
}

{ my $test; # = $q->param('t');
  sub test {
    $test ||= do {
      my $t = $q->param('t');
      mydie( "<h1>test (t=) is required</h1>" ) unless $t;
      mydie qq(unknown test "$t") unless $t =~ /^(A[12]|[NS])$/;
      $t;
    }
  }
}

my $t = test();
my @history = uniq( grep defined, map { split /,/ } $q->multi_param('history'));
#die "ok: " . $t . " history: " . join ' - ' , @history;
#print $q->header('application/json');print q({"index":10});

my $testfile = $datafolder . $t . '.json';
die qq(cannot find test-file for "$t") unless -r $testfile;
my @lines;
{
  open my$FH, '<' ,$testfile
    or die qq(cannot open test-file "$testfile"; $!);
  @lines = map { chomp; $_ } <$FH>;
}

if($q->param('list')) {
  print $q->header('application/json');
  print '[';
  print join q(,), @lines;
  print ']';
  exit();
}

#sanity check
mydie("too much history") unless @lines > @history;

#lather, rince, ...
while(1) {
  my $i = int( rand( @lines)); # get a random index
  my $x = $i + 1; #history uses 1 (not zero) based index
  next if any { $_ == $x } @history;  # avoid repeat questions
  #next if grep $x == $i, @history; # avoid repeat questions
  print $q->header('application/json');
  print qq<{ "index": $x, "data": $lines[$i] }>;
  exit;
}

__END__
s
MAIN: {
  if($q->param('q')) { # TODO: more form validation!
    my $testfile = $datafolder . $test . '.json';

    my($question, $answer, $correct, @answers);
    my $number_of_answers = 4;
    #use Data::Dumper; warn Dumper ({ $q->param() });
    #use Data::Dumper qw( Dumper ); my %f = map { $_ => $q->param( $_ ) } $q->param(); warn Dumper( \%f );

    $question = $q->param('q');
    die qq(question is required) unless $question and $question =~ /\S/;

    my $multi = $q->param('multi') ? 1 : 0;
    if($multi) {
      $number_of_answers = 5;
      $correct = '['.(join ',', $q->multi_param('c')).']';
      #my @c;
      #for( my $i=1; $i< 6; ++$i ) {
      #push @c, $i if $q->param( qq(c$i) );
      #}
      #die qq[at least one answer must be selected as correct] unless @c;
      #{ local $"=','; $correct = qq([@c]); }
    } else {
      $correct = $q->param('c');
    }
    die qq(correct answer(s) must be selected) unless $correct;

    for( my $i=1; $i < 1+$number_of_answers; ++$i ) {
      my $answer = $q->param( "a$i" );
      push @answers, $answer if $answer and $answer =~ /\S/;
    }
    die qq(all answers are required) unless @answers == $number_of_answers;

    my $OUTPUT_FILE;
    local $" = q(",");
    open $OUTPUT_FILE, q( >> ), $testfile or die qq(cannot write to "$testfile"; $!);
    print $OUTPUT_FILE qq({"q":"$question", "c":$correct, "a":["@answers"] }\n);
  }
}

my $SCRIPT = <<'END_OF_JS';
$( document ).ready(function() {
var multi = false;

function SetMulti() {
    $("#fifth").show();
    //$("input:radio").attr('type','checkbox');
    $("input:radio").each(function(idx) {
        $this = $(this);
        if ($this.attr('name') != "multi") {
            var newName = $this.attr('name') + $this.attr('value');
            // $this.attr('name', newName);
            $this.attr('type', 'checkbox');
        }
    });
    multi = true;
}

  function UnSetMulti() {
    $("#fifth").hide();
    $("input:checkbox").each(function(idx) {
        $this = $(this);
        if ($this.attr('name') != "multi") {
            // $this.attr('name', "c");
            $this.attr('type', 'radio');
        }
    });
    multi = false;
  }
$("#multi").click(function() {
    if (multi) {
        UnSetMulti();
    } else {
        SetMulti();
    }
});
  UnSetMulti();
//$("#fifth").hide();
})
END_OF_JS

# TODO: IMPORTANT!!!  test select should be sticky!
# TODO: client side validation?
DISPLAY_FORM: {
  local $" = q(</option><option>);
  print $q->header(), <<"  END_OF_HTML";
<html>
<head>
  <title>Cert Assessment - Test Manager</title>
  <script src="jquery-3.4.1.min.js"></script>
  <script language="javascript">
$SCRIPT
  </script>
</head>
<body><form method="POST"><input type="hidden" name="t" value="$test" />
  <h1>Cert Assessment - Test Manager</h1>
  <h2>Select a test and enter a question and four answers.  Don't forget to mark the correct one!</h2>
  <label>Question</label><textarea rows="5" cols="40" name="q"></textarea><br />
  <label>A1</label><input type="radio" value="1" name="c"><textarea rows="2" cols="40" name="a1"></textarea><br />
  <label>A2</label><input type="radio" value="2" name="c"><textarea rows="2" cols="40" name="a2"></textarea><br />
  <label>A3</label><input type="radio" value="3" name="c"><textarea rows="2" cols="40" name="a3"></textarea><br />
  <label>A4</label><input type="radio" value="4" name="c"><textarea rows="2" cols="40" name="a4"></textarea><br />
  <span id="fifth"><label>A5</label><input type="radio" value="5" name="c"><textarea rows="2" cols="40" name="a5"></textarea><br /></span>
  <label>Allow Multiple Correct Answers</label><input type="checkbox" id="multi" name="multi" value="1" />
  <input type="SUBMIT" name="SUBMIT" value="SUBMIT" />
</form></body>
</html>
  END_OF_HTML
}


sub dumpform {
  my $cgi = CGI->new();
  my %form;
  for my $param ($cgi->param()) {
    $form{$param} = [ $cgi->param($param) ];
  }
  #print($cgi->header('text/plain'));
  local $Data::Dumper::Indent   = 1;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Useqq    = 1;
  eval { use Data::Dumper qw[Dumper]; };
  warn(Dumper(\%form));
}

__END__

our @tests = qw[ A+1
                 A+2
	         N+
	         S+ ];
  <label>Test</label><select name="t"><option>@tests</option></select><br />




