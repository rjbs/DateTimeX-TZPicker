package DateTimeX::TZPicker;
use Moose;

use namespace::autoclean;

use DateTime ();
use DateTime::TimeZone ();
use IP::Country::Fast;
use Locale::Country ();

# This is constant, and will not change unless Locale::Country or
# DateTime::TimeZone are reloaded, reinstalled, or otherwise mucked-with in
# ways that it's okay to require a terp restart for. -- rjbs, 2011-09-16
has _countries => (
  is   => 'ro',
  isa  => 'HashRef',
  lazy => 1,
  init_arg => undef,
  traits   => [ 'Hash' ],
  handles  => {
    _country_names => 'keys',
  },
  default  => sub {
    my ($self) = @_;
    return {
      # "UK" should really be "GB" for the ISO code.  Since DateTime knows both,
      # let's skip the one that Locale::Country doesn't know.
      # -- rjbs, 2011-09-16
      map  {; $_ => Locale::Country::code2country($_) }
      grep { $_ ne 'uk' }
      DateTime::TimeZone->countries
    };
  },
);

has _zone_lookup => (
  is   => 'ro',
  isa  => 'HashRef[ HashRef ]',
  init_arg => undef,
  builder  => '_build_zone_lookup',
  # traits   => [ 'Hash' ],
  # handles  => { _all_zones => 'keys' },
);

sub _build_zone_lookup {
  my ($self) = @_;

  my $now = DateTime->now;

  my %zone;
  for my $tz (
    map {; DateTime::TimeZone->new(name => $_) } DateTime::TimeZone->all_names
  ) {
    my $offset = $tz->offset_for_datetime($now);
    my $offset_str = sprintf '%+03d:%02u',
      int($offset / 3600),
      int($offset % 3600 / 60);

    $zone{ $tz->name } = {
      name         => $tz->name,
      offset_str   => $offset_str,
      offset       => $offset,
    };
  }

  return \%zone;
}

# Eastern Time => America/New_York
has country_overrides => (
  is  => 'ro',
  isa => 'HashRef[ HashRef ]',
  default => sub {  {}  },
  traits  => [ 'Hash' ],
  handles => {
    country_override_for => 'get',
  },
);

sub zones_for_country {
  my ($self, $cc) = @_;
  $cc = lc $cc;

  my %zone;

  if (my $override = $self->country_override_for($cc)) {
    %zone = %$override;
  } else {
    my $zfc = $self->_zones_for_country->{ $cc };
    %zone  = map { $_ => $_ } @$zfc;
  }

  return
    map {; +{ %{ $self->_zone_lookup->{ $zone{$_} } }, display_name => $_ } }
    keys %zone;
}

has _zones_for_country => (
  is   => 'ro',
  isa  => 'HashRef[ ArrayRef ]',
  lazy => 1,
  init_arg => undef,
  builder  => '_build_zones_for_country',
  traits   => [ 'Hash' ],
  handles  => { _country_codes => 'keys' },
);

sub _build_zones_for_country {
  my ($self) = @_;

  my $zone = $self->_zone_lookup;

  my %zones_for_country;
  for my $country ($self->_country_names) {
    $zones_for_country{$country} = [
      sort { $zone->{$a}{name} cmp $zone->{$b}{name} }
      grep {; exists $zone->{$_} }
      DateTime::TimeZone->names_in_country($country)
    ];
  }

  return \%zones_for_country;
}

has _all_zones => (
  is   => 'ro',
  isa  => 'ArrayRef',
  lazy => 1,
  init_arg => undef,
  default  => sub {
    my ($self) = @_;

    my $zone = $self->_zone_lookup;
    return [ sort { $zone->{$a}{name} cmp $zone->{$b}{name} } keys %$zone ];
  },
);

has constructed_at => (
  is   => 'ro',
  isa  => 'DateTime',
  init_arg => undef,
  default  => sub { DateTime->now },
);

my %RECENT;
sub recent_instance {
  my ($class, $timeout) = @_;
  $timeout = 3600 unless defined $timeout;

  if (my $recent = $RECENT{ $class }) {
    return $recent
      if $timeout < DateTime->new->epoch - $recent->constructed_at->epoch;
  }

  $RECENT{ $class } = $class->new;
}

sub BUILD {
  my ($self) = @_;
  $self->_zones_for_country;
  $self->_all_zones;
}

__PACKAGE__->meta->make_immutable;
1;
