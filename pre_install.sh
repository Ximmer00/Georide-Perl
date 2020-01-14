#!/usr/bin/env bash

cpan -i JSON::Parse
cpan -i JSON::MaybeXS
cpan -i Encode
cpan -i LWP::UserAgent
cpan -i HTTP::Request
cpan -i URL::Encode

echo "Modules installation done, you can now run the Script"
