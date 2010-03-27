use strict;
use warnings;

use Test::More tests => 42;

use_ok('Term::Sk');

{
    my $ctr = Term::Sk->new('%2d Elapsed: %8t %21b %4p %2d (%8c of %11m) %P', { test => 1 } );
    ok(defined($ctr), 'standard counter works ok');
}

{
    my $ctr = eval{ Term::Sk->new('%', { test => 1 } )};
    ok($@, 'invalid id aborts ok');
    like($@, qr{\AError-0*100}, '... with errorcode 100');
    like($@, qr{Can't parse}, '... and error message Can\'t parse');
}

{
    my $ctr = eval{ Term::Sk->new('%z', { test => 1 } )};
    ok($@, 'unknown id aborts ok');
    like($@, qr{\AError-0*110}, '... with errorcode 110');
    like($@, qr{invalid display-code}, '... and error message invalid display-code');
}

{
    my $ctr = Term::Sk->new('Test %d', { test => 1 } );
    ok(defined($ctr), '%d works ok');
    is(content($ctr->get_line), 'Test -',  '... first displays -');
    $ctr->up;
    is(content($ctr->get_line), 'Test \\', '... then  displays \\');
    $ctr->up;
    is(content($ctr->get_line), 'Test |',  '... then  displays |');
    $ctr->up;
    is(content($ctr->get_line), 'Test /',  '... then  displays /');
}

{
    my $ctr = Term::Sk->new('Elapsed %8t', { test => 1 } );
    ok(defined($ctr), '%t works ok');
    like(content($ctr->get_line), qr{^Elapsed \d{2}:\d{2}:\d{2}$},  '... and displays the time elapsed');
}

{
    my $ctr = Term::Sk->new('Bar %10b', { test => 1, target => 20, pdisp => '!' } );
    ok(defined($ctr), '%b works ok');
    $ctr->up for 1..11;
    is(content($ctr->get_line), 'Bar ######____',  '... always use hash for progress bar');
}

{
    my $ctr = Term::Sk->new('Percent %4p', { test => 1, target => 20 } );
    ok(defined($ctr), '%p works ok');
    $ctr->up for 1..5;
    is(content($ctr->get_line), 'Percent  25%',  '... and displays 25% after a quarter of it\'s way');
}

{
    my $ctr = Term::Sk->new('%P', { test => 1 } );
    ok(defined($ctr), '%P (in captital letters) works ok');
    is(content($ctr->get_line), '%',  '... and displays a percent symbol');
}

{
    my $ctr = Term::Sk->new('Ctr %5c', { test => 1, base => 1000 } );
    ok(defined($ctr), '%c works ok');
    $ctr->up for 1..8;
    is(content($ctr->get_line), 'Ctr 1_008',  '... and displays the correct counter value');
}

{
    my $ctr = Term::Sk->new('Tgt %5m', { test => 1, target => 9876 } );
    ok(defined($ctr), '%m works ok');
    is(content($ctr->get_line), 'Tgt 9_876',  '... and displays the correct target value');
}

{
    my $ctr = Term::Sk->new('Test', { test => 1 } );
    ok(defined($ctr), 'Simple fixed text works ok');
    $ctr->whisper('abc');
    is(content($ctr->get_line), 'abcTest',  '... and whisper() works as expected');
}

{
    my $ctr = Term::Sk->new('Dummy', { test => 1 } );
    ok(defined($ctr), 'Simple fixed text works ok');
    $ctr->close;
    is(content($ctr->get_line), '',  '... and close() works as expected');
}

{
    my $ctr = Term::Sk->new('Dummy', { test => 1 } );
    ok(defined($ctr), '%c works ok');
    $ctr->up for 1..27;
    is($ctr->ticks, 27,  '... number of ticks are correct');
}

{
  my $flatfile = "Test hijabc\010\010\010xyzklm";

  Term::Sk::rem_backspace(\$flatfile);

  is($flatfile, 'Test hijxyzklm',  '... backspaces have been removed');
  is(Term::Sk::log_info(), '[I=20,B=3]', '... log_info() for backspaces');
}

{
  my $flatfile = "z\010\010\010";

  Term::Sk::rem_backspace(\$flatfile);

  like($flatfile, qr{\[\*\* \s Buffer \s underflow \s \*\*\]}xms,  '... provoked underflow');
  is(Term::Sk::log_info(), '[I=4,B=3]', '... log_info() for provoked underflow');
}

{
  my $flatfile = "ab\nc\010\010\010";

  Term::Sk::rem_backspace(\$flatfile);

  like($flatfile, qr{\[\*\* \s Ctlchar:}xms,  '... provoked shortline');
  is(Term::Sk::log_info(), '[I=7,B=3]', '... log_info() for provoked shortline');
}


{
  my $flatfile = ('abcde' x 37).("\010" x 28).'fghij';

  Term::Sk::set_chunk_size(200);
  Term::Sk::set_bkup_size(15);

  Term::Sk::rem_backspace(\$flatfile);

  is(length($flatfile), 162,  '... length abcde (200,15)');
  is(Term::Sk::log_info(), '[I=200,B=15][I=18,B=13]', '... log_info() for abcde (200,15)');
  is(substr($flatfile, -10), 'cdeabfghij', '... trailing characters for abcde (200,15)');
}

{
  my $flatfile = ('abcde' x 37).("\010" x 28).'fghij';

  Term::Sk::set_chunk_size(180);
  Term::Sk::set_bkup_size(15);

  Term::Sk::rem_backspace(\$flatfile);

  is(Term::Sk::log_info(), '[I=180,B=0][I=38,B=28]', '... log_info() for abcde (180,15) is different');
  like($flatfile, qr{\[\*\* \s Buffer \s underflow \s \*\*\]}xms,  '... abcde (180,15) provoked underflow');
}

sub content {
    my ($text) = @_;

    $text =~ s{^ \010+ \s+ \010+}{}xms;
    return $text;
}
