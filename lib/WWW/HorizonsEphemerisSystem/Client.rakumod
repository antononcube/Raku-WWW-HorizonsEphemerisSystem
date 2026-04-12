use v6.d;

unit module WWW::HorizonsEphemerisSystem::Client;

use HTTP::Tiny;
use JSON::Fast;

constant $DEFAULT-API-URL     = 'https://ssd.jpl.nasa.gov/api/horizons.api';
constant $DEFAULT-API-VERSION = '1.3';
constant $DEFAULT-USER-AGENT  = 'WWW::HorizonsEphemerisSystem/0.1 (Raku; HTTP::Tiny)';

my constant %EPHEM-TYPES = set <OBSERVER VECTORS ELEMENTS SPK APPROACH>;

class X::WWW::HorizonsEphemerisSystem is Exception {
    has Str $.message is required;
    method gist { $!message }
}

class X::WWW::HorizonsEphemerisSystem::HTTP
    is X::WWW::HorizonsEphemerisSystem {
    has Int $.status is required;
    has Str $.reason = '';

    method gist {
        "HTTP request to Horizons API failed with status $!status" ~
        ($!reason.chars ?? " ($!reason)" !! '')
    }
}

class X::WWW::HorizonsEphemerisSystem::API
    is X::WWW::HorizonsEphemerisSystem {
    has Str $.request-url;

    method gist {
        "Horizons API reported an error" ~
        ($!request-url.defined ?? " for {$!request-url}" !! '') ~
        ": {self.message}"
    }
}

class HorizonsResponse {
    has Bool $.success;
    has Int $.status;
    has Str $.reason = '';
    has Str $.request-url;
    has Hash $.headers = {};
    has Str $.body = '';
    has Str $.format = 'json';
    has $.json;

    method is-json(--> Bool) {
        $!format.lc eq 'json'
    }

    method api-version(--> Str) {
        return '' unless $!json.defined && $!json ~~ Associative;
        return $!json<signature><version> // '';
    }

    method api-error(--> Str) {
        return '' unless $!json.defined && $!json ~~ Associative;
        return $!json<error> // '';
    }

    method result(--> Str) {
        return '' unless $!json.defined && $!json ~~ Associative;
        return $!json<result> // '';
    }

    method spk(--> Str) {
        return '' unless $!json.defined && $!json ~~ Associative;
        return $!json<spk> // '';
    }

    method spk-file-id(--> Str) {
        return '' unless $!json.defined && $!json ~~ Associative;
        return $!json<spk_file_id> // '';
    }

    method gist {
        "HorizonsResponse(success={$!success}, status={$!status}, format={$!format})"
    }
}

class WWW::HorizonsEphemerisSystem::Client {
    has Str $.api-url = $DEFAULT-API-URL;
    has Str $.expected-api-version = $DEFAULT-API-VERSION;
    has Bool $.strict-version-check = False;
    has $!http-client;

    submethod BUILD(
        Str :$!api-url = $DEFAULT-API-URL,
        Str :$!expected-api-version = $DEFAULT-API-VERSION,
        Bool :$!strict-version-check = False,
        Str :$user-agent = $DEFAULT-USER-AGENT,
        :$http-client
    ) {
        $!http-client = $http-client // HTTP::Tiny.new(:agent($user-agent));
    }

    method percent-encode(Str:D $text --> Str:D) {
        my $blob = $text.encode('utf8');

        return $blob.map(-> $byte {
            my $char = chr($byte);
            if $char ~~ /<[A..Za..z0..9\-\._~]>/ {
                $char
            }
            else {
                '%' ~ $byte.base(16).uc.fmt('%02s')
            }
        }).join;
    }

    method build-query(*%params --> Str:D) {
        my @pairs;

        for %params.kv -> $key, $value {
            next unless $value.defined;

            if $value ~~ Positional && $value !~~ Str {
                for $value.list -> $entry {
                    next unless $entry.defined;
                    @pairs.push: self.percent-encode($key.Str)
                        ~ '='
                        ~ self.percent-encode($entry.Str);
                }
            }
            else {
                @pairs.push: self.percent-encode($key.Str)
                    ~ '='
                    ~ self.percent-encode($value.Str);
            }
        }

        @pairs.join('&');
    }

    method build-url(*%params --> Str:D) {
        my $query = self.build-query(|%params);
        $query.chars ?? "$!api-url?$query" !! $!api-url;
    }

    method query(*%params, Str :$format = 'json', Bool :$throw = True --> HorizonsResponse:D) {
        my %call-params = %params;
        %call-params<throw>:delete;
        %call-params<format> //= $format;

        my $request-url = self.build-url(|%call-params);
        my %http = $!http-client.get($request-url);
        my $body = %http<content>.defined ?? %http<content>.decode('utf8') !! '';

        my %json;
        my $effective-format = (%call-params<format> // '').lc;
        if $effective-format eq 'json' && $body.chars {
            try {
                %json = from-json($body);
                CATCH {
                    when X::AdHoc {
                        if $throw {
                            die X::WWW::HorizonsEphemerisSystem.new(
                                message => "Failed to decode JSON payload: {.message}"
                            );
                        }
                        %json = ();
                    }
                }
            }
        }

        my $response = HorizonsResponse.new(
            success     => so (%http<success> // False),
            status      => (%http<status> // 0).Int,
            reason      => (%http<reason> // '').Str,
            request-url => $request-url,
            headers     => (%http<headers> // {}).Hash,
            body        => $body,
            format      => $effective-format,
            json        => (%json.elems ?? %json !! Any),
        );

        if $throw {
            unless $response.success {
                die X::WWW::HorizonsEphemerisSystem::HTTP.new(
                    status  => $response.status,
                    reason  => $response.reason,
                    message => 'HTTP error'
                );
            }

            if $response.is-json {
                my $api-error = $response.api-error;
                if $api-error.chars {
                    die X::WWW::HorizonsEphemerisSystem::API.new(
                        message     => $api-error,
                        request-url => $request-url
                    );
                }

                my $version = $response.api-version;
                if $!strict-version-check
                    && $version.chars
                    && $version ne $!expected-api-version {
                    die X::WWW::HorizonsEphemerisSystem::API.new(
                        message     => "Unexpected API version '$version' (expected '{$!expected-api-version}')",
                        request-url => $request-url
                    );
                }
            }
        }

        $response;
    }

    method observer-ephemeris(Bool :$throw = True, *%params --> HorizonsResponse:D) {
        self!query-for('OBSERVER', :$throw, |%params)
    }

    method vectors-ephemeris(Bool :$throw = True, *%params --> HorizonsResponse:D) {
        self!query-for('VECTORS', :$throw, |%params)
    }

    method elements-ephemeris(Bool :$throw = True, *%params --> HorizonsResponse:D) {
        self!query-for('ELEMENTS', :$throw, |%params)
    }

    method approach-table(Bool :$throw = True, *%params --> HorizonsResponse:D) {
        self!query-for('APPROACH', :$throw, |%params)
    }

    method spk-file(Bool :$throw = True, *%params --> HorizonsResponse:D) {
        self!query-for('SPK', :$throw, |%params)
    }

    method extract-table(Str:D $text --> Str:D) {
        my $start = $text.index('$$SOE');
        my $end   = $text.index('$$EOE');

        return '' if $start == -1 || $end == -1 || $end <= $start;

        my $table-start = $start + '$$SOE'.chars;
        my $table = $text.substr($table-start, $end - $table-start);

        $table.trim;
    }

    method !query-for(Str:D $ephem-type, Bool :$throw = True, *%params --> HorizonsResponse:D) {
        die X::WWW::HorizonsEphemerisSystem.new(
            message => "Unsupported EPHEM_TYPE '$ephem-type'"
        ) unless %EPHEM-TYPES{$ephem-type};

        my %call-params = %params;
        %call-params<throw>:delete;
        %call-params<EPHEM_TYPE> = $ephem-type;

        self.query(|%call-params, :$throw);
    }
}
