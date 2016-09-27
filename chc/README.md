## Synopsis

The **chc** is a check-script framework for LINUX environments written in Perl. It helps to identifying problems and repair them manually or automatically. The script uses a csv file to get the components, which should be checked and how they should be checked.   

    chc.pl [OPTION]... [FILE]...

    OPTIONS:
    -h | -help | --help
      display this help page.
    -f <FILENAME>
      select a custom csv-file to execute checks (default is chc.csv).
    -o <FILENAME>
      select the html output file (default is /tmp/chc.html).
    -r
      auto-repair: try to repair failed checks atomatically if the repair-command is defined in chc.csv
    -s
      silent-mode: don't display results (writes check-results only in the log if it is activated).

    FILES AND DIRECTORIES
    -chc.pl
      the main executable script to perform checks.
    -chc/lib/chc.conf
      config-file for customizing the output and the logging.
    -chc/lib/chc.csv
      this file contains the services or components (one per row), which should be checked. The file is written in CSV, the field-separator is semicolon.
      Format: 
        -SERVER;CHECK_TYPE(PS/CMD/LOG);DESC;CHECK_CMD;COUNT_MIN;COUNT_MAX;OK_MSG;ERR_MSG;START_CMD;INST_MSG;
          -SERVER: servername or IP. If it is the localhost, then set the value to "LOCALHOST"
          -CHECK_TYPE: PS  - process count check
                       CMD - execute a command or another script
                       LOG - search for specified string in the log
          -DESC: short description of the checked item
          -CHECK_CMD: check command
          -COUNT_MIN: minimum count of the result
          -COUNT_MAX: maximum count of the result
          -OK_MSG: check result if OK
          -ERR_MSG: check result if NOK
          -REPAIR_CMD: command to resolve the error (e.g. if the process is stopped(PS-check))
          -INST_MSG: instruction ID, to find instructions in the file chc_instructions.txt
      Examples:
        -LOCALHOST;PS;Apache-HTTP;sudo systemctl status httpd|grep 'active (running)'|wc -l;1;1;RUNNING;STOPPED;sudo /etc/init.d/httpd start;INST_APACHE;
        -192.168.1.100;PS;Website check;curl -s example.com|egrep 'Password|Username'|wc -l;2;2;OK;NOT REACHABLE;;;
    -chc/lib/chc.instructions
      for any error you can define an instruction, when the error occurs the selected instruction will displayed.
    -chc/modules/
      here are the custom Perl-modules stored.

## Code Examples

    Execute the check-script with autorepair option:
      -./chc.pl -r
    Wrinting the results in a html-file, without auto-repair
      -./chc.pl -o /var/www/html/chc.html

