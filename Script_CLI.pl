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
use IO::Prompter;
use Config::Std;
use DateTime;
use Date::Calc qw(:all);
use Crypt::Lite;

#Init variables
my $URL       = 'https://api.georide.fr';
my $HEADER    = [ 'Content-Type' => 'application/json; charset=UTF-8' ];
my $CONF_FILE = 'file.conf';

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
    print "Toggling ...\n";
    request_to_api( '/tracker/' . $tracker_id . '/toggleLock',
        'POST', $bearer_header );
    print "Toggled\n";
}

sub lock_tracker {
    my ( $tracker_id, $bearer_header ) = @_;
    print "Toggling ...\n";
    request_to_api( '/tracker/' . $tracker_id . '/lock',
        'POST', $bearer_header );
    print "Toggled\n";
}

sub unlock_tracker {
    my ( $tracker_id, $bearer_header ) = @_;
    print "Toggling ...\n";
    request_to_api( '/tracker/' . $tracker_id . '/unlock',
        'POST', $bearer_header );
    print "Toggled\n";
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
########################  Functions for this script (local) ####################

sub token_age {

    #say "token_age sub";
    my $email = shift;
    my $td    = DateTime->now;
    my $date1 = read_conf($email)->{date};
    my $date2 = $td->dmy;
    my ( $jour1, $mois1, $annee1 ) = split( '-', $date1 );
    my ( $jour2, $mois2, $annee2 ) = split( '-', $date2 );
    my $NombreJoursEntreDate =
      Delta_Days( ( $annee1, $mois1, $jour1 ), ( $annee2, $mois2, $jour2 ) );
    return $NombreJoursEntreDate;
}

sub printing_state {

    #say "printing_state sub";
    my ( $tracker_state, $tracker_name ) = @_;
    my $state;
    $tracker_state == 1 ? ( $state = "lock" ) : ( $state = "unlock" );
    print "$tracker_name is $state\n";
}

sub read_conf {

    #say "read_conf sub";
    my $email = shift;
    $email =~ /(^[\w_\.]+)@[a-zA-Z_]+?\.[a-zA-Z]{2,5}$/;
    my $user = $1;
    read_config $CONF_FILE => my %config;
    return $config{$user};    #returning hash for user from config file
}

sub update_conf {

    #say "update_conf sub";
    my ( $email, $key, $value ) = @_;
    $email =~ /(^[\w_\.]+)@[a-zA-Z_]+?\.[a-zA-Z]{2,5}$/;
    my $user = $1;
    read_config $CONF_FILE => my %config;
    $config{$user}{$key} = $value;    #Updating information
    write_config %config;             #writing in file
}

sub exists_in_conf {

    #say "exists_in_conf sub";
    my $email = shift;
    if ( !-e $CONF_FILE ) {
        return 0;
    }
    $email =~ /(^[\w_\.]+)@[a-zA-Z_]+?\.[a-zA-Z]{2,5}$/;
    my $user = $1;
    read_config $CONF_FILE => my %config;
    return 1 if $config{$user};
    return 0;
}

sub create_config {

    #say "create_config sub";
    say "Getting information from server, please wait ...";
    my ( $email, $password ) = @_;
    my %config;
    $email =~ /(^[\w_\.]+)@[a-zA-Z_]+?\.[a-zA-Z]{2,5}$/;
    my $user      = $1;
    my $td        = DateTime->now;
    my $authToken = get_token( $email, $password );    #getting back token
    my $encrypted_token = encrypt_string( $authToken, $password );
    $config{$user} = {
        email => $email,                               # Add a section
        token => $encrypted_token,
        date  => $td->dmy
    };    # Add a section
    write_config( %config => $CONF_FILE );    #write in config file
}

sub encrypt_string {

    #say "encrypt_string sub";
    my ( $clear_token, $pass ) = @_;
    my $crypt   = Crypt::Lite->new( encoding => 'utf8' );
    my $crypted = $crypt->encrypt( $clear_token, $pass );
    return $crypted;
}

sub decrypt_string {

    #say "decrypt_string sub";
    my ( $encrypted_token, $pass ) = @_;
    my $crypt     = Crypt::Lite->new( encoding => 'utf8' );
    my $decrypted = $crypt->decrypt( $encrypted_token, $pass );
    if ($decrypted) {
        return $decrypted;
    }
    else {
        die "Wrong password !";
    }
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

sub open_browser {
    my ( $lat, $lon ) = @_;
    my $continue = prompt( "Do you want to open your browser ?", -y1t10 );
    if ($continue) {
        my $url = "https://www.google.com/maps/search/?api=1&query=$lat,$lon";

        # say $url;
        open_default_browser($url);
    }
    else {
        say
"Well, this are the coordinates of your the tracker : \nLatitude = $lat,\t longitude = $lon";
    }
}

sub open_default_browser {
    my $url      = shift;
    my $platform = $^O;
    my $cmd;
    if ( $platform eq 'darwin' ) { $cmd = "open \"$url\""; }    # Mac OS X
    elsif ( $platform eq 'linux' ) { $cmd = "x-www-browser \"$url\""; }  # Linux
    elsif ( $platform eq 'MSWin32' ) { $cmd = "start $url"; }    # Win95..Win7
    if ( defined $cmd ) {
        system("$cmd 2>/dev/null");
    }
    else {
        die "Can't locate default browser";
    }
}

sub config_main {

    #say "config_main sub";
    #Entering main !!
    system("clear");
    my $email_main = prompt(
        "Enter your georide email : ",
        -must => {
            'It must be a valid email :' =>
              qr/^[\w_\.]+@[a-zA-Z_]+?\.[a-zA-Z]{2,5}$/i
        },
        -v
    );    #Just gathering email from user input
    my $password_main = prompt(
        "Enter your account password : ",
        -echo => '*',
        -v
    );    #gathering password
    my $exists =
      exists_in_conf($email_main);    #checking if email exists in conf file
    return ( $email_main, $password_main, $exists );
}

sub command_treat {
    my ( $command, $auth_header, $tracker_id ) = @_;
    if ( $command eq "Lock" ) {
        lock_tracker( $tracker_id, $auth_header );
        system("clear");
        say "Locked !";
    }
    elsif ( $command eq "Unlock" ) {
        unlock_tracker( $tracker_id, $auth_header );
        system("clear");
        say "Unlocked !";
    }
    elsif ( $command eq "Status" ) {
        system("clear");
        show_status($auth_header);
    }
    elsif ( $command eq "Locate" ) {
        system("clear");
        open_browser( get_pos($auth_header) );
    }
    else {
        system("clear");
        say "Wrong command";
    }
}

sub command_choice {
    my $choices = [qw<Lock Unlock Status Locate>];
    my $command = prompt( "What do you want to do ?", -1, -menu => $choices );
    return $command;
}

sub Main {

    #say "Main sub";
    my ( $mail, $pass, $exists ) = config_main();
    my $temp = 0;
    my $header;
    my ( $tracker_name, $tracker_id );
    if ( $exists == 0 ) {
        say "Email does not exists.";
        if ( prompt( "Do you want to add it in base ? ", -y1t10 ) ) {
            create_config( $mail, $pass );
            $header =
              get_auth_header(
                decrypt_string( read_conf($mail)->{token}, $pass ) );
            my $tracker_raw = get_trackers($header);
            $tracker_name = $tracker_raw->{'trackerName'};
            $tracker_id   = $tracker_raw->{'trackerId'};
            update_conf( $mail, 'trackerName', $tracker_name );
            update_conf( $mail, 'trackerId',
                encrypt_string( $tracker_id, $pass ) );
        }
        else {
            say "Running temporary !";
            my $tracker_raw = get_trackers($header);
            $temp   = 1;
            $header = get_auth_header( get_token( $mail, $pass ) );
        }
    }
    else {
        $header =
          get_auth_header( decrypt_string( read_conf($mail)->{token}, $pass ) );
        $tracker_name = read_conf($mail)->{trackerName};
        $tracker_id =
          decrypt_string( read_conf($mail)->{trackerId}, $pass );
    }

    if ( $temp == 0 && token_age($mail) > 28 )
    {    #generating new token and writes it
        say "Generating new token ...";
        generate_token( $mail, $pass );
    }

#Here will enter command, but each time of the loop, we'll display tracker lock state
    while (1) {
        my $command = command_choice();
        command_treat( $command, $header, $tracker_id );
    }
}

Main();
