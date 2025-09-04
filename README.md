#dotoip.sh

Resolve domain(s) to only IP addresses (IPv4/IPv6) using dnsx and save unique results to a file. This wrapper uses dnsx response-only mode to emit raw values and writes them to dotoip.txt by default.

Requirements
bash

dnsx installed and available in PATH

Optional: a file with one domain per line

Installation
Save the script below as dotoip.sh

Make it executable:

chmod +x dotoip.sh

Usage
Single domain:

./dotoip.sh example.com

Multiple domains from file:

./dotoip.sh -l domains.txt

Customize output file:

./dotoip.sh -l domains.txt -o myips.txt

IPv4 only:

./dotoip.sh -l domains.txt -4

IPv6 only:

./dotoip.sh -l domains.txt -6

Custom resolvers and higher concurrency:

./dotoip.sh -l domains.txt -r 1.1.1.1:53 -r 8.8.8.8:53 -T 400

Rate limit requests per second:

./dotoip.sh -l domains.txt -R 500

#buymeacoffee.com/gd_discov3r

#Join me : https://telegram.me/gd_discov3r

