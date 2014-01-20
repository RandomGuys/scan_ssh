#!/usr/bin/perl

use Term::ANSIColor qw(:constants);
use POSIX 'strftime';

my $start = time;

open (ADDR, $ARGV[0]);

unless ( -d "keys") {
	system "mkdir keys";
}

while (<ADDR>) {
        chomp;
				$duration = time - $start;
				($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime $duration;
				$hour = $hour - 1;
        print "[$hour:$min:$sec] Fetching $_...\n";
        system "rm -rf tmp.pub; ssh-keyscan -t rsa $_ | sed '/^#/d' | cut -d' ' -f2,3 > tmp.pub 2> /dev/null";
        if ($? != 0) {
                print RED, "Something wrong happened with $_\n",RESET;
                next;
        }
				if ( -z 'tmp.pub' ) {
					print RED, "No RSA key found...\n",RESET;
					next;
				}
        print "Storing key...\n";
        system "chmod 0600 tmp.pub; ssh-keygen -e -f tmp.pub -m PEM -P '' > keys/$_.pem";
        print GREEN,"$_ done!\n",RESET;
}

unless ( -e "tmp.pub" ) {
	system "rm tmp.pub";
}

close (ADDR);

