use v6.d;

use HTTP::Tiny;
use JSON::Fast;

constant $HORIZONS-DEFAULT-API-URL     = 'https://ssd.jpl.nasa.gov/api/horizons.api';
constant $HORIZONS-DEFAULT-FILE-API-URL = 'https://ssd.jpl.nasa.gov/api/horizons_file.api';
constant $HORIZONS-DEFAULT-API-VERSION = '1.3';
constant $HORIZONS-DEFAULT-FILE-API-VERSION = '1.0';
constant $HORIZONS-DEFAULT-USER-AGENT  = 'WWW::HorizonsEphemerisSystem/0.1 (Raku; HTTP::Tiny)';

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

class WWW::HorizonsEphemerisSystem::Response {
    has Bool $.success;
    has Int $.status;
    has Str $.reason = '';
    has Str $.request-url;
    has Str $.request-method = 'GET';
    has Str $.request-summary = '';
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
    has Str $.api-url = $HORIZONS-DEFAULT-API-URL;
    has Str $.file-api-url = $HORIZONS-DEFAULT-FILE-API-URL;
    has Int $.url-length-limit = 1800;
    has Str $.expected-api-version = $HORIZONS-DEFAULT-API-VERSION;
    has Str $.expected-file-api-version = $HORIZONS-DEFAULT-FILE-API-VERSION;
    has Bool $.strict-version-check = False;
    has $!http-client;

    submethod BUILD(
        Str :$!api-url = $HORIZONS-DEFAULT-API-URL,
        Str :$!file-api-url = $HORIZONS-DEFAULT-FILE-API-URL,
        Int :$!url-length-limit = 1800,
        Str :$!expected-api-version = $HORIZONS-DEFAULT-API-VERSION,
        Str :$!expected-file-api-version = $HORIZONS-DEFAULT-FILE-API-VERSION,
        Bool :$!strict-version-check = False,
        Str :$user-agent = $HORIZONS-DEFAULT-USER-AGENT,
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

    # The regular API receives query parameters, whereas the file API receives
    # Horizons batch syntax in a multipart `input` part.  Keep that difference
    # here, at the transport boundary; callers only deal in API parameters.
    method query(
        *%params,
        Str :$format = 'json',
        Str :$transport = 'auto',
        Bool :$throw = True
        --> WWW::HorizonsEphemerisSystem::Response:D
    ) {
        my %call-params = %params;
        %call-params<throw>:delete;
        %call-params<transport>:delete;
        %call-params<format> //= $format;

        my $request-url = self.build-url(|%call-params);
        my $selected = $transport.lc;
        die X::WWW::HorizonsEphemerisSystem.new(
            message => "Unsupported transport '$transport'. Expected get, file, or auto"
        ) unless $selected eq any(<get file auto>);

        $selected = $request-url.chars > $!url-length-limit ?? 'file' !! 'get'
            if $selected eq 'auto';

        my %http;
        my $response-url;
        my $request-method;
        my $request-summary;
        if $selected eq 'get' {
            %http = $!http-client.get($request-url);
            $response-url = $request-url;
            $request-method = 'GET';
            $request-summary = $request-url;
        }
        else {
            my $input = self.batch-input(|%call-params);
            my %multipart = self!multipart-body(
                format => (%call-params<format> // 'json').Str,
                input  => $input,
            );
            %http = $!http-client.post(
                $!file-api-url,
                :content(%multipart<body>.encode('utf8')),
                headers => {
                    'content-type' => "multipart/form-data; boundary={%multipart<boundary>}",
                },
            );
            $response-url = $!file-api-url;
            $request-method = 'POST';
            # Avoid placing potentially huge TLIST values in error messages.
            $request-summary = "POST $!file-api-url ({$input.lines.elems - 1} batch settings)";
        }
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

        my $response = WWW::HorizonsEphemerisSystem::Response.new(
            success     => so (%http<success> // False),
            status      => (%http<status> // 0).Int,
            reason      => (%http<reason> // '').Str,
            request-url => $response-url,
            request-method => $request-method,
            request-summary => $request-summary,
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
                        request-url => $response-url
                    );
                }

                my $version = $response.api-version;
                my $expected-version = $request-method eq 'POST'
                    ?? $!expected-file-api-version
                    !! $!expected-api-version;
                if $!strict-version-check
                    && $version.chars
                    && $version ne $expected-version {
                    die X::WWW::HorizonsEphemerisSystem::API.new(
                        message     => "Unexpected API version '$version' (expected '$expected-version')",
                        request-url => $response-url
                    );
                }
            }
        }

        $response;
    }

    method batch-input(*%params --> Str:D) {
        my %batch = %params;
        %batch<format>:delete;
        if %batch<EPHEM_TYPE>:exists {
            %batch<TABLE_TYPE> = %batch<EPHEM_TYPE>;
            %batch<EPHEM_TYPE>:delete;
        }

        my @lines = '!$$SOF';
        for %batch.keys.sort -> $key {
            my $value = %batch{$key};
            die X::WWW::HorizonsEphemerisSystem.new(
                message => "Batch value for '$key' cannot contain a newline"
            ) if $value.Str.contains("\n") || $value.Str.contains("\r");
            @lines.push: "$key=$value";
        }
        @lines.join("\n") ~ "\n";
    }

    method !multipart-body(Str:D :$format!, Str:D :$input! --> Hash:D) {
        my $boundary = '----RakuHorizons' ~ now.Int ~ '-' ~ (1000000..9999999).pick;
        my $crlf = "\r\n";
        my $body = "--$boundary$crlf"
            ~ "Content-Disposition: form-data; name=\"format\"$crlf$crlf"
            ~ "$format$crlf"
            ~ "--$boundary$crlf"
            ~ "Content-Disposition: form-data; name=\"input\"; filename=\"horizons.in\"$crlf"
            ~ "Content-Type: text/plain; charset=utf-8$crlf$crlf"
            ~ $input ~ $crlf
            ~ "--$boundary--$crlf";
        { :$boundary, :$body };
    }

    method observer-ephemeris(Bool :$throw = True, *%params --> WWW::HorizonsEphemerisSystem::Response:D) {
        self!query-for('OBSERVER', :$throw, |%params)
    }

    method vectors-ephemeris(Bool :$throw = True, *%params --> WWW::HorizonsEphemerisSystem::Response:D) {
        self!query-for('VECTORS', :$throw, |%params)
    }

    method elements-ephemeris(Bool :$throw = True, *%params --> WWW::HorizonsEphemerisSystem::Response:D) {
        self!query-for('ELEMENTS', :$throw, |%params)
    }

    method approach-table(Bool :$throw = True, *%params --> WWW::HorizonsEphemerisSystem::Response:D) {
        self!query-for('APPROACH', :$throw, |%params)
    }

    method spk-file(Bool :$throw = True, *%params --> WWW::HorizonsEphemerisSystem::Response:D) {
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

    method !query-for(Str:D $ephem-type, Bool :$throw = True, *%params --> WWW::HorizonsEphemerisSystem::Response:D) {
        die X::WWW::HorizonsEphemerisSystem.new(
            message => "Unsupported EPHEM_TYPE '$ephem-type'"
        ) unless %EPHEM-TYPES{$ephem-type};

        my %call-params = %params;
        %call-params<throw>:delete;
        %call-params<EPHEM_TYPE> = $ephem-type;

        self.query(|%call-params, :$throw);
    }
}
