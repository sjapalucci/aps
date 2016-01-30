#! /usr/bin/perl
#################################################################################
# Copyright (C) Steven M. Japalucci - All Rights Reserved
# Unauthorized copying of this file, via any medium is strictly prohibited
# Proprietary and confidential
# Written by Steven M Japalucci RHCE RHCT <steve.japalucci@gmail.com>, August 2013
#################################################################################

use Net::Dropbox::API;

my $folder = $ARGV[0] or die("Usage: $0 dirname\n");
use WebService::Dropbox;

my $dropbox = WebService::Dropbox->new({
    key => '6wyh2z3q52uqp5w', # App Key
    secret => 'm54s1kapdewdtq1' # App Secret
});

# get access token
if (!$access_token or !$access_secret) {
    my $url = $dropbox->login or die $dropbox->error;
    warn "Please Access URL and press Enter: $url";
    <STDIN>;
    $dropbox->auth or die $dropbox->error;
    warn "access_token: " . $dropbox->access_token;
    warn "access_secret: " . $dropbox->access_secret;
    } else {
    $dropbox->access_token($access_token);
    $dropbox->access_secret($access_secret);
}

my $info = $dropbox->account_info or die $dropbox->error;

# filelist(metadata)
# https://www.dropbox.com/developers/reference/api#metadata
my $data = $dropbox->metadata('Steve');
print($data);
