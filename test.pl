#!/usr/bin/perl

use strict;
use warnings;

use CGI;
use CGI::Carp qw[fatalsToBrowser];
use List::MoreUtils qw[uniq any];
#use JSON;

# Hofmator: https://www.perlmonks.org/?node_id=340636
use Tie::File;

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
my $testfile = $datafolder . $t . '.json';
my $index = $q->param('i') or die qq(no idea\n);

my @lines;
TRY: {
  next unless $index =~ /^[1-9][0-9]{0,4}$/;
  next unless -r $testfile;

  next unless tie @lines, 'Tie::File', $testfile;
  next unless $index <= @lines;
  last;
} continue {
  die "nope\n"
}

print $q->header('application/json');

if ( $q->param(q(count))) {
  print scalar @lines;
}
else {
  printf q<{ "index": %d, "data": %s }>=> $index, $lines[$index-1];
}

exit();

__END__
