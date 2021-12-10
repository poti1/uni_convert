#!/usr/bin/perl -CDAS

use v5.32;
use strict;
use warnings;
use utf8;
use Term::ANSIColor  qw/ colorstrip /; 
use Test::More;
use File::Basename   qw/ basename /;

sub run {
   my ($cmd)     = @_;
   state $script = basename($0) =~ s/\.\w+$/.pl/r;
   my @output    =
      grep { /\S/ }     # Skip blank lines
      colorstrip qx($script $cmd 2>&1);
   chomp @output;

   join "\n", @output;
}

sub define_snowflake_output {
   "❄ SNOWFLAKE U+2744 0x2744 10052";
}
sub define_abc_output {
   my $output =<<~"OUTPUT";
   A LATIN CAPITAL LETTER A U+41 0x41 65
   B LATIN CAPITAL LETTER B U+42 0x42 66
   C LATIN CAPITAL LETTER C U+43 0x43 67
   OUTPUT

   chomp $output;

   $output;
}

# Normal Usage.
my $snowflake_output = define_snowflake_output();
is run("SNOWFLAKE --name"),   $snowflake_output, "Name";
is run("❄ --string"),         $snowflake_output, "String";
is run("U+2744 --num"),       $snowflake_output, "Number - U+XXXX";
is run("0x2744 --num"),       $snowflake_output, "Number - 0xXXXX";
is run("10052 --num"),        $snowflake_output, "Number - Decimal";

# Multiple Strings.
my $abc_output = define_abc_output();
is run("ABC --string"),       $abc_output,         "Multiple strings";

# Errors.
is run("ABC --name"),         "Invalid name: 'ABC'",                    "Error - Invalid name";
is run("ABCDE --num"),        "Name cannot be determined from: ABCDE",  "Error - Invalid number";
is run("'' --string"),        "Invalid input: ''",                      "Error - Invalid string";

done_testing();
