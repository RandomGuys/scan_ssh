#!/usr/bin/perl

use Term::ANSIColor qw(:constants);
use POSIX 'strftime';
use threads;
use Thread::Semaphore;

open (ADDR, $ARGV[0])
        or die "Usage : perl ssh_collector.pl adresses\n";

unless ( -d "keys") {
        system "mkdir keys";
}
unless ( -d "bannieres") {
        system "mkdir bannieres";
}

my $start               = time;
my $semaphore_no        = 5;
my $sema                = Thread::Semaphore->new($semaphore_no);
my $info_rep            = "bannieres";
my $keys_rep            = "keys";

# SUBROUTINES
sub getKey {
        $sema->down();
        # Get the thread id. Allows each thread to be identified.
        my ($IP) = @_;
        $id = threads->tid();

        # [DEBUG]
        # print "Thread $id : Fetching $IP ...\n";
        system "rm -rf tmp_$IP.pub; ssh-keyscan -t rsa $IP 2> $info_rep/$IP.info | sed '/^#/d' | cut -d' ' -f2,3 > tmp_$IP.pub 2> /dev/null";

        if ($? != 0) {
                print RED, "Something wrong happened with $IP\n",RESET;
                system "rm -rf $info_rep/$IP.info";
                $sema->up();
                return;
        };

        # Get size of file
        $size_of_file = `ls -sh tmp_$IP.pub | cut -d' ' -f1 2> /dev/null`;

        # Check if file is empty
        if ( $size_of_file == 0 ) {
                print RED, "$IP : No RSA key found...\n",RESET;
                system "rm -rf $info_rep/$IP.info";
                system "rm -rf tmp_$IP.pub";
                $sema->up();
        } else {

                print "$IP : Storing key...\n";
                system "chmod 0600 tmp_$IP.pub; ssh-keygen -e -f tmp_$IP.pub -m PEM -P '' > $keys_rep/$IP.pem";
                system "rm -rf tmp_$IP.pub";
                print GREEN,"$IP : done!\n",RESET;

                # [DEBUG]
                # print "Thread $id done!\n";
                $sema->up();
        };
}

while (<ADDR>) {
        chomp;

        my $duration = time - $start;
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime $duration;
        my $hour = $hour - 1;

        $line = $_;

        # Starting
        print "[$hour:$min:$sec] Fetching $line...\n";

        # Create threads wirth IP
        $th = threads->create(\&getKey, $line);
}

# Join remaining Threads before closing
foreach my $thr (threads->list()){
        $id = $thr->tid();
        # [DEBUG]
        # print "joining : thread $id\n";
        $thr->join();
}

print "Cleaning...\n";
system "rm -rf tmp*";

close (ADDR)
        or die "impossible de fermer le fichier : $!\n";
