#!/usr/bin/env bash

cpan -i JSON::Parse
cpan -i JSON::MaybeXS
cpan -i Encode
cpan -i LWP::UserAgent
cpan -i HTTP::Request
cpan -i IO::Prompter
cpan -i Config::Tiny
cpan -i Config::Std
cpan -i DateTime
cpan -i Date::Calc
cpan -i Crypt::Lite
cpan -i URL::Encode

echo "Modules installation done, you can now run the Script"
