# WWW::HorizonsEphemerisSystem

Raku package for accessing 
[Jet Propulsion Laboratory](https://www.jpl.nasa.gov)'s 
[Horizons Ephemeris System](https://ssd.jpl.nasa.gov/horizons/) 
through the [HTTP API](https://ssd-api.jpl.nasa.gov/doc/horizons.html).

----

## Features

- Uses ["HTTP::Tiny"](https://raku.land/zef:jjatria/HTTP::Tiny), [JJp1], for all API requests.
- Percent-encodes query parameters for safe Horizons URL usage.
- Supports `json` and `text` output.
- Convenience methods for `OBSERVER`, `VECTORS`, `ELEMENTS`, `APPROACH`, and `SPK` requests.
- Raises typed exceptions for HTTP errors and API-level JSON errors.

----

### Basic Examples

Get the Cartesian position of Mars with default parameters:

```raku
use WWW::HorizonsEphemerisSystem;
horizons-ephemeris-data('state', '499', 'position');
```

Get the position of Mars for a specific date:

```raku
my $date = "{.year}-{.month.fmt('%02s')}-{.day.fmt('%02s')}" with DateTime.now(:12hours);
horizons-ephemeris-data(
  'state',
  ['499', { dates => $date }],
          
  'position'
);
```

Define a location on Earth (Moscow):

```raku
my $pos = (55.7505, 37.6175);
```

Get the azimuth and elevation of the Moon as seen from Moscow for the next 12 hours:

```raku
my @dates = do with DateTime.now { ($_, $_.later(:12hours), $_.later(minutes => 12*60 + 10))};
@dates = @dates.map({ "{.year}-{.month.fmt('%02s')}-{.day.fmt('%02s')}" });

horizons-ephemeris-data(
  'observer',
  {
      target => '301', 
      center => $pos, 
      :@dates
  },
  'all',
  :modifier<dataset>
);
```

Get the orbital elements of Saturn's moon Pandora for a specific list of date-times:

```raku
horizons-ephemeris-data(
  'orbital-elements',
  ['617', {
    center => '699',
    dates => [
      'Mon 10 Jan 2000 00:00:00',
      'Tue 11 Jan 2000 00:00:00'
    ]
  }],
  'all',
  :modifier<association>
);
```

----

## Client object

```raku
use WWW::HorizonsEphemerisSystem;

my $client = horizons-client();
```

----

## Client usage example

```raku
my $horizons = WWW::HorizonsEphemerisSystem::Client.new;

my $response = $horizons.observer-ephemeris(
    format      => 'json',
    COMMAND     => "'499'",
    OBJ_DATA    => 'YES',
    MAKE_EPHEM  => 'YES',
    CENTER      => "'500@399'",
    START_TIME  => "'2006-01-01'",
    STOP_TIME   => "'2006-01-20'",
    STEP_SIZE   => "'1 d'",
    QUANTITIES  => "'1,9,20,23,24,29'",
);

say $response.api-version;
say $response.result;
```

-----

## Implementation details

- The first version -- 0.0.1 -- was made using ChatGPT Codex with "gpt-5.3-codex" over the API spec [horizons.html](https://ssd-api.jpl.nasa.gov/doc/horizons.html).
  
  - See ["prompts.md"](./docs/prompts.md) for the development evolution by LLM prompts.
    - Some other interactive convincing was needed besides those prompts.

- The client object is fairly non-useful computations-wise -- it "only retrieves."

- The "top level" sub `horizons-ephemeris-data` aims to produce computation-ready outputs, that are Raku data structures.

- The overall functionalities design is very similar to the Wolfram Language [`HorizonsEphemerisData`](https://resources.wolframcloud.com/FunctionRepository/resources/HorizonsEphemerisData), [TTf1].
  - The [Raku spec](./resources/HorizonsEphemerisData-spec-Raku.md) given to ChatGPT was made from the Wolfram Language documentation of [TTf1].

----

## References

[JJp1] José Joaquín Atria,
[HTTP::Tiny, Raku package](https://gitlab.com/jjatria/http-tiny),
(2020-2025),
[GitLab/jjatria](https://gitlab.com/jjatria).

[TTf1] Truman Tapia,
[HorizonsEphemerisData, Wolfram Language Function](https://resources.wolframcloud.com/FunctionRepository/resources/HorizonsEphemerisData),
(2022),
[Wolfram Function Repository](https://resources.wolframcloud.com/FunctionRepository).

