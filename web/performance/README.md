## Overview

Benchmark scripts to test the response and rendering speed of a given
website URL.

Utilizes the Linux packages:

* Uzbl Browser
* Apache Benchmark
* Gnuplot

These scripts are published without warranty.

## Setup

Make the cgi script in the servercgi folder publicly available,
defaults are:  www.domain.tld/cgi-bin/stat.cgi

The domain is extracted from the target URL given at the command
prompt.
If your CGI script path differs from the server defaults, change the
path within the benchmark scripts.

## Run

Execute the script you like to run in an empty folder.
The script will create a data collection and report folder next to it,
where you will find the results, rendered as diagrams with Gnuplot.

## Questions & Remarks

I'm always open for suggestions and improvements.
Please report anything through Github's facilities.

