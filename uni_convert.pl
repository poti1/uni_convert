#!/usr/bin/perl -CDAS

use v5.32;
use strict;
use warnings;
use utf8;
use charnames     qw/ :full /;
use Getopt::Long;
use List::Util    qw/ max /;


#-----------------------------------------------------------------------
#                              COLORS
#-----------------------------------------------------------------------

my $RED     = "\e[31m";
my $YELLOW  = "\e[33m";
my $TEAL    = "\e[35m";
my $BG_GREY = "\e[100m";
my $RESTORE = "\e[0m";

# TODO: use Term::ANSIColor instead.


#-----------------------------------------------------------------------
#                                SUBS
#-----------------------------------------------------------------------

sub define_spec {
   {
      "name"         => {
                           desc      => "Input is a name.",
                           exclusive => 1,
                        },
      "string"       => {
                           desc      => "Input is a string.",
                           exclusive => 1,
                        },
      "num"          => {
                           desc      => "Input is a number.",
                           exclusive => 1,
                        },
      "help"         => {
                           desc      => "Show this help section.",
                        },
      "debug"        => {
                           desc      => "Show debugging information.",
                        },
      "list_options" => {
                           desc      => "List available options.",
                        },
   }
}

sub build_spec_names {
   keys define_spec()->%*;
}

sub build_exclusive_options {
my $spec = define_spec();
   grep { $spec->{$_}{exclusive} } keys %$spec;
}

sub list_options {
   say for
   sort
   map {
      s/ (?=^\w{2,}) /--/x;   # Long options.
      s/ (?=^\w$)     /-/x;   # Short options.
      $_;
   }
   map {
      split /\|/, $_
   }
   keys define_spec()->%*;

   exit 1;
}

sub build_help_options {
   my $spec   = define_spec();
   my $indent = " " x 6;

   join "\n$indent", map {
      my $opt = join ", ",
      map {
         s/ (?=^\w{2,}) /--/x;   # Long options.
         s/ (?=^\w$)     /-/x;   # Short options.
         $_;
      }
      split /\|/, $_;

      sprintf "%-20s %s", $opt, $spec->{$_}{desc};
   } sort keys %$spec;
}

sub show_help {

   my $YELLOW  = "\e[33m";
   my $RESTORE = "\e[0m";
   my $self    = "${YELLOW}uni_convert$RESTORE";
   my $options = build_help_options();

   say <<~HERE;

      $self [options]

      Options:
         $options
   HERE

   exit 1;
}

sub r {
   require Data::Dumper;
   say Data::Dumper->new([@_])
         ->Terse(1)
         ->Indent(1)
         ->Sortkeys(1)
         ->Dump;
}

sub get_options {
   my $opts = {};

   GetOptions($opts, build_spec_names()) or die $!;

   r $opts if $opts->{debug}; 

   list_options() if $opts->{list_options};

   my @exclusive_opts = build_exclusive_options();

   show_help() if not keys %$opts
      or $opts->{help}
      or 1 != grep {defined} @$opts{ @exclusive_opts }
      or not @ARGV;

   $opts;
}

sub get_input {
   @ARGV;
}

sub get_name {
   my ($opts,$in) = @_;

   my $name = do {
      if(   $opts->{name})   {          uc $in  }
      elsif($opts->{string}) { string2name($in) }
      elsif($opts->{num})    {   code2name($in) }
      else{ show_help() }
   };

   unless ( defined $name ) {
      die "${YELLOW}Name cannot be determined from: $RED$in$RESTORE\n\n";
   }

   $name;
}

sub name_2_line {
   my ($name) = @_;
   my $string  = name2string($name) // die "${YELLOW}Invalid name: $RED$name$RESTORE\n\n";
   my $uni     = name2uni($name);
   my $hex     = name2hex($name);
   my $dec     = name2dec($name);

   # Make white space and escapes easier to see.
   $string =~ s/[\s\p{xPosixCntrl}]/ /g;

   [
      $string,
      $name,
      $uni,
      $hex,
      $dec,
   ];
}

sub get_max_length {
   my $last_row    = $#_;
   my $last_column = $_[0]->$#*;

   my @max = map {
      my $col = $_;
      max map {
         length $_[$_][$col];
      } 0 .. $last_row;
   } 0 .. $last_column;

   \@max;
}

sub define_raw_format {
   "$RED%%%ss $YELLOW%%-%ss$RESTORE $BG_GREY%%-%ss %%-%ss %%%ss$RESTORE\n";
}

sub render_lines {
   my $max    = get_max_length(@_);
   my $format = sprintf define_raw_format(), @$max;

   for ( @_ ) {
      printf $format, @$_;
   }
}

sub string2name{ charnames::viacode ord shift }          # ❄                      -> SNOWFLAKE
sub code2name  { charnames::viacode( shift )  }          # U+2744, 0x2744, 10052  -> SNOWFLAKE
sub name2string{ charnames::string_vianame( shift ) }    # SNOWFLAKE              -> ❄
sub name2uni   { sprintf "U+%x", name2dec( shift )  }    # SNOWFLAKE              -> U+2744
sub name2hex   { sprintf "%#x",  name2dec( shift )  }    # SNOWFLAKE              -> 0x2744
sub name2dec   { charnames::vianame( shift ) }           # SNOWFLAKE              -> 10052
               

#-----------------------------------------------------------------------
#                                MAIN
#-----------------------------------------------------------------------

my $opts    = get_options();
my ($input) = get_input();
my @process = $opts->{string} ? (split //, $input//"") : ($input);
my @lines;

say "";
for ( @process ) {
   my $name = get_name($opts,$_);   # Normalize to a name.
   push @lines, name_2_line($name); # Build other parts.
}
render_lines @lines;                # Format and render.
say "";

#-----------------------------------------------------------------------
#                                END
#-----------------------------------------------------------------------

