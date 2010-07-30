#!/usr/bin/perl

use strict;
#use warnings;

use Test::More tests => 8;
use Test::NoWarnings;

use Data::Structure::FindPath qw(
  data_find_path
  data_find_path_eq
  data_find_path_num
);

my $target = {};

{
  my $ds = {
    foo => $target,
    bar => [
      1,
      2,
      3,
      {
        turnip => {
          wibble => $target,
        },
        alien => bless({
          bob => "zoom"
        },"zipzopzangzoodlezop"),
      },
      { fish => { fish => {} }},
      undef,  # to test no warnings
    ],
    "odd'\\" => $target,
    false => {},
  };

  is_deeply
    [data_find_path(sub { defined($_[0]) && $_[0] eq $target }, $ds)],
    ["{'bar'}[3]{'turnip'}{'wibble'}","{'foo'}","{'odd\\'\\\\'}"],
    "basic";
  
  # same thing using eq - note this tests that warnings are supressed
  is_deeply
    [data_find_path_eq($target, $ds)],
    ["{'bar'}[3]{'turnip'}{'wibble'}","{'foo'}","{'odd\\'\\\\'}"],
    "basic with _eq";
  
  # test looking inside objects
  is_deeply
    [data_find_path_eq("zoom", $ds)],
    [],
    "inside objs don't find";
  is_deeply
    [data_find_path_eq("zoom", $ds, inside_objects => 1)],
    ["{'bar'}[3]{'alien'}{'bob'}"],
    "inside objs do find when enabled";
  
  # test looking inside matches
  is_deeply
    [data_find_path(sub {
      ref($_[0]) eq "HASH" && exists $_[0]->{fish}
    }, $ds)],
    ["{'bar'}[4]"],
    "inside matches disabled";
  is_deeply
    [data_find_path(sub {
      ref($_[0]) eq "HASH" && exists $_[0]->{fish}
    }, $ds, inside_matches => 1)],
    ["{'bar'}[4]","{'bar'}[4]{'fish'}"],
    "inside matches enabled";
}

# testing recursive data structures

{
  my $foo = { bar => "zong" };
  $foo->{foo} = $foo;

  is_deeply
    [data_find_path_eq("zong", $foo)],
    ["{'bar'}"],
    "recursive";
}