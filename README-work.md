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

## Client object

```raku
use WWW::HorizonsEphemerisSystem;

my $client = horizons-client();
```

----

## Example

```raku
my $horizons = WWW::HorizonsEphemerisSystem.new;

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

## Implementation

The first version -- 0.0.1 -- is made using ChatGPT Codex with "gpt-5.3-codex" over the API spec [horizons.html](https://ssd-api.jpl.nasa.gov/doc/horizons.html).
That first version is fairly non-useful computations-wise -- it "only retrieves."

A better, future version will provide computational outputs that are Raku data structures.
Very similar to the Wolfram Language [`HorizonsEphemerisData`](https://resources.wolframcloud.com/FunctionRepository/resources/HorizonsEphemerisData), [TTf1].

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

