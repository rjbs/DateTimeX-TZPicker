use strict;
use warnings;

use DateTimeX::TZPicker;
use Test::More;

my $tzpicker = DateTimeX::TZPicker->new({
  country_overrides => {
    us => {
      'Eastern Time'  => 'America/New_York',
      'Pacific Time'  => 'America/Los_Angeles',
      'Central Time'  => 'America/Chicago',
      'Mountain Time' => 'America/Denver',
      'Alaskan Time'  => 'America/Anchorage',
      'Hawaiian Time' => 'Pacific/Honolulu',
    },
  }
});

my @zfc = $tzpicker->zones_for_country('us');

note explain \@zfc;

done_testing;
