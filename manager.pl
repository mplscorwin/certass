#!/usr/bin/perl

use strict;
use warnings;

use CGI;
use CGI::Carp qw[fatalsToBrowser];
use JSON qw[encode_json]; #to ensures JSON is valid
use Tie::File;  #for line-number based file manipulation

our ($DATAFOLDER) = q(./appdata/);

# sub replace_line($$;$) {
#     my($filename,$idx,$json) = @_;
#     open my$FH, $filename or die qq(failed to open "$filename"; $!);
#     my @lines = <$FH>;
#     close $FH;
#     open $FH, '>', $filename or die qq(cannot write "$filename"; $!);
#     for(my$i=0;$i<@lines;++$i) {
# 	warn qq(checking line $i vs $idx; content $lines[$i]);
# 	unless($i == $idx) {
# 	    print $FH ( $lines[ $i] ); #  . "\n" 
# 	    next;
# 	}
# 	warn qq(skipping line $i with content $lines[$i]);
# 	if($json) {
# 	    print $FH "$json"; # \n
# 	}
#     }
# }

# builds the name of the datafile for a test
# accepts testID (string), returns testfile (string)
sub testfile($) { $DATAFOLDER . (shift) . '.json' }

# create JSON response for ADD/UPDATE/DELETE actions
# accepts CGI object, causes graceful program exit
sub return_ok($) {
  my $q = shift || die qq(CGI instance required);
  print $q->header(q(application/json)), q(true);
  exit;
}

# create a JSON string from the submitted for data
# used for add and edit actions
sub process_form($) { # accepts CGI object, returns JSON text
  my $q = shift || die qq(CGI instance required);
  my($question, $correct, @answers);

  $question = $q->param('q');
  die qq(question is required) unless $question and $question =~ /\S/;

  my $number_of_answers = $q->param('multi') ? 5 : 4;
  $correct = [ map { 0+$_ } $q->multi_param( 'c')];
  die qq(correct answer(s) must be selected) unless @$correct;

  for( my $i=1; $i < 1+$number_of_answers; ++$i ) {
    my $answer = $q->param( "a$i" );
    push @answers, $answer if $answer and $answer =~ /\S/;
  }
  die qq(all answers are required) unless @answers == $number_of_answers;

  return encode_json({q => $question, c => $correct, a => \@answers})."\n";
}

# adds a new question to the end of the file for the given test
# die upon failure
sub add_question($$) { # accepts CGI object and testID (string);
  my($q,$test) = @_;
  my $testfile = testfile($test);
  my $json = process_form( $q );
  my $OUTPUT_FILE;
  open $OUTPUT_FILE, q( >> ), $testfile or die qq(cannot open "$testfile"; $!);
  print $OUTPUT_FILE $json or die qq(cannot write to "$testfile"; $!);
  close $OUTPUT_FILE;
  return_ok($q);
}

# removes a question given the 1 based index
# accepts CGI object and testID (string);
# die upon failure
sub remove_question($$) {
  my($q,$test) = @_;
  my $testfile = testfile($test);

  my $target_index = do {
    use warnings FATAL => qw[all];
    0+$q->param('index')
  };

  if($target_index) { 
      tie my@questions, q(Tie::File), $testfile
	  or die qq(cannot open "$testfile");
      splice( @questions, $target_index-1, 1);
      untie @questions;
#      replace_line( $testfile, $target_index-1 );
      return_ok($q);
  }
}

# updates a question given the 1 based index
# accepts CGI object and testID (string);
# die upon failure
sub update_question($$) {
  my($q,$test) = @_;
  my $testfile = testfile($test);

  my $target_index = do {
    use warnings FATAL => qw[all];
    0+$q->param('index')
  };

  if( $target_index) {
      tie my@questions, q(Tie::File), $testfile or die qq(cannot open "$testfile");
      $questions[ $target_index-1 ] = process_form( $q);
      untie @questions;
      return_ok($q);
  }
}

MAIN: {
  my $q = new CGI();
  my $test = $q->param('t');
  die "test (t=) is required" unless $test;
  die qq(unknown test "$test") unless $test =~ /^(A[12]|[NS])$/;
  if($q->param('CREATE'))       { add_question( $q, $test); }
  elsif($q->param('UPDATE')) { update_question( $q, $test); }
  elsif($q->param('DELETE')) { remove_question( $q, $test); }
  print $q->header('application/json'), "false";
  exit;
}

__END__

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






=pod
  my $OUTPUT_FILE;
  open $OUTPUT_FILE, q( +> ), $testfile or die qq(cannot open "$testfile"; $!);

  my$line_count = 0;
  while(my $json = <$OUTPUT_FILE>) {
    next unless ++line_count == $target_index;
  }
  print $OUTPUT_FILE $json or die qq(cannot write to "$testfile"; $!)
=cut

