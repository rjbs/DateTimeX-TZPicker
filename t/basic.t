use strict;
use warnings;

use DateTimeX::TZPicker;
use Test::More;

subtest "override for 'us'" => sub {
  my $tzpicker = DateTimeX::TZPicker->new({
    country_overrides => {
      us => [
        'Hawaiian Time'          => 'Pacific/Honolulu',
        'Alaskan Time'           => 'America/Anchorage',
        'Pacific Time'           => 'America/Los_Angeles',
        'Mountain Time (no DST)' => 'America/Phoenix',
        'Mountain Time'          => 'America/Denver',
        'Central Time'           => 'America/Chicago',
        'Eastern Time'           => 'America/New_York',
      ],
    }
  });

  my @zfc = $tzpicker->zones_for_country('us');

  is_deeply(
    [ map {; $_->virtual_name } @zfc ],
    [
      'Hawaiian Time',
      'Alaskan Time',
      'Pacific Time',
      'Mountain Time (no DST)',
      'Mountain Time',
      'Central Time',
      'Eastern Time',
    ],
    'the US time zones: nice and simple',
  );
};

subtest "no overrides" => sub {
  my $tzpicker = DateTimeX::TZPicker->new;

  my @zfc = $tzpicker->zones_for_country('us');

  # We don't test for an exact set match because it would be too fragile.  Once
  # Texas breaks away and declares its own time zone, our tests would fail with
  # the next DateTime::TimeZone release.  Instead, we'll just test for
  # something nice and simple. -- rjbs, 2011-09-19
  ok(
    (grep { $_->virtual_name eq 'America/Detroit' } @zfc)
    &&
    (grep { $_->virtual_name eq 'America/New_York' } @zfc),
    "without an override, 'us' contains both Detroit and NYC",
  )
};

done_testing;
