#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'HTML::SocialMedia' ) || print "Bail out!
";
}

diag( "Testing HTML::SocialMedia $HTML::SocialMedia::VERSION, Perl $], $^X" );
