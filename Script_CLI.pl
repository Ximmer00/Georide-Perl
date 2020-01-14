#!/usr/bin/env perl
# Written by Loïc BONNARD, under the course of Mr Darold, in LPRO MI ASSR.
use strict;
use warnings;
use Data::Dumper;    #Debug Purpose

#List of all modules to use.
use JSON::Parse 'parse_json';
use JSON::MaybeXS qw(encode_json);
use Encode qw(encode_utf8);
use LWP::UserAgent;
use HTTP::Request;
use 5.010;           #use for "say" command

#Init variables
my $URL       = 'https://api.georide.fr';
my $HEADER    = [ 'Content-Type' => 'application/json; charset=UTF-8' ];

################################################################################
################################################################################
#########################   Functions for remote requests ######################

sub request_to_api {
    ##say "request_to_api sub";

    #this function is used to sending any request to the API.
    my ( $sub_url, $method, $head, $encoded_data ) = @_;    #Parameters
    my $ua = LWP::UserAgent->new();
    my $r;
    if ($encoded_data) {
        $r =
          HTTP::Request->new( $method, $URL . $sub_url, $head, $encoded_data )
          ;    #Creating the the http request
    }
    else {
        $r =
          HTTP::Request->new( $method, $URL . $sub_url, $head )
          ;    #Creating the the http request
    }
    my $res = $ua->request($r);    #sending the http request
    if ( $res->is_success ) {
        return $res->decoded_content;    #returning the response decoded
    }
    elsif ( $res->status_line =~ /429/ ) {
        system("sleep 1");
        $res = $ua->request($r);         #sending the http request
    }
    else {
        die $res->status_line;           #Stopping programm with the error
    }
}

sub get_auth_header {

    #say "get_auth_header sub";

    #simple function to return a auth header (taking token)
    my $token = shift;
    return [ 'Authorization' => 'Bearer ' . $token ];
}

sub get_token {

    #say "get_token sub";

    #function to getting the account token (available 30 days)
    my ( $email, $password ) = @_;    #we need data to pass to POST http request
    my $data = {
        email    => $email,
        password => $password
    };                                #creating data for email and password
    my $auth_data =
      encode_utf8( encode_json($data) );  #tranforming to be use in http request
    my $response =
      request_to_api( '/user/login', 'POST', $HEADER, $auth_data )
      ;    #request to API to get back the auth Token
    my $content = parse_json($response);    #transforming reponse in hash
    return $content->{'authToken'};         #giving back the token
}

sub get_trackers {    #This sub needs improvement about listing of trackers
    my $auth_header = shift;
    my $content     = request_to_api( '/user/trackers', 'GET', $auth_header );
    my $response    = parse_json($content);
    # print Dumper($response);
    if ( $response->[0]->{'canLock'} ) {

        # print("Can lock ", $response->[0]->{'trackerName'}."\n");
        return $response->[0];
    }
    else {
        print( "Cannot lock ", $response->[0]->{'trackerName'}, "\n" );
    }
}

sub toggle_tracker {
    my ( $tracker_id, $bearer_header ) = @_;
    request_to_api( '/tracker/' . $tracker_id . '/toggleLock',
        'POST', $bearer_header );
}

sub lock_tracker {
    my ( $tracker_id, $bearer_header ) = @_;
    request_to_api( '/tracker/' . $tracker_id . '/lock',
        'POST', $bearer_header );
}

sub unlock_tracker {
    my ( $tracker_id, $bearer_header ) = @_;
    request_to_api( '/tracker/' . $tracker_id . '/unlock',
        'POST', $bearer_header );
}

sub generate_token {

    #say "generate_token sub";
    my ( $email, $password ) = @_;
    my $encrypted_token = read_conf($email)->{token};
    my $token           = decrypt_string( $encrypted_token, $password );
    my $auth_header     = get_auth_header($token);
    my $response = request_to_api( '/user/new-token', 'GET', $auth_header );
    my $newToken = parse_json($response);
    my $new_encrypted_token =
      encrypt_string( $newToken->{'authToken'}, $password );
    update_conf( $email, 'token', $new_encrypted_token );
}

sub get_pos {
    my $bearer_header = shift;
    my $tracker       = get_trackers($bearer_header);
    return ( $tracker->{'latitude'}, $tracker->{'longitude'} );
}

################################################################################
################################################################################
####################  Functions for this script (local) ########################

sub show_loc {
    my ( $lat, $lon ) = @_;
    my $url = "https://www.google.com/maps/search/?api=1&query=$lat,$lon";
    say "Well, this are the coordinates of your the tracker : \nLatitude = $lat,\t longitude = $lon";
    say "Url to access with google : $url";
}


sub printing_state {
    #say "printing_state sub";
    my ( $tracker_state, $tracker_name ) = @_;
    my $state;
    $tracker_state == 1 ? ( $state = "lock" ) : ( $state = "unlock" );
    print "$tracker_name is $state\n";
}

sub show_status {
    my $auth_header  = shift;
    my $tracker      = get_trackers($auth_header);
    my $tracker_name = $tracker->{'trackerName'};
    my $kilometers   = $tracker->{'odometer'} / 1000;
    if ( $tracker->{'isLocked'} ) {
        printing_state( 1, $tracker_name );
    }
    else {
        printing_state( 0, $tracker_name );
    }
    my $rounded = int($kilometers);
    my $final   = commify($rounded);
    print "$tracker_name has $final km\n\n";
}

sub commify {
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1 /g;
    return scalar reverse $text;
}

sub config_main {

    #say "config_main sub";
    #Entering main !!
    my $email_main = $ARGV[0];
    if ($email_main !~  m/^[\w_\.]+@[a-zA-Z_]+?\.[a-zA-Z]{2,8}$/i){
      say "Email is not an correct, exiting ..";
      exit 1;
    }
    my $password_main = $ARGV[1];
    return ( $email_main, $password_main );
}

sub command_treat {
    my ( $command, $auth_header, $tracker_id ) = @_;
    if ( $command eq "lock" ) {
        lock_tracker( $tracker_id, $auth_header );
        say "Locked !";
    }
    elsif ( $command eq "unlock" ) {
        unlock_tracker( $tracker_id, $auth_header );
        say "Unlocked !";
    }
    elsif ( $command eq "status" ) {
        show_status($auth_header);
    }
    elsif ( $command eq "locate" ) {
        show_loc(get_pos($auth_header));
    }
}

sub Main {
    my ( $mail, $pass, $exists ) = config_main();
    my ( $tracker_name, $tracker_id );
    my $header = get_auth_header( get_token( $mail, $pass ) );
    my $tracker_raw = get_trackers($header);
    $tracker_name = $tracker_raw->{'trackerName'};
    $tracker_id   = $tracker_raw->{'trackerId'};
    my $command = $ARGV[2];
    command_treat( $command, $header, $tracker_id );
}


Main();
