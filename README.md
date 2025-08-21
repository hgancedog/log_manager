# Log Analyzer Script

## Description

This is a comprehensive Bash script designed to parse, analyze, and generate a professional report from syslog-formatted log files. It decodes syslog priority (PRI) values into human-readable severity and facility names, providing clear statistics and a detailed breakdown of log entries.

The script offers a user-friendly, color-coded report in the terminal and generates a clean, non-colored log file for further analysis with other tools.

---

## Features ✨

* **Log Parsing**: Analyzes each line of a log file, validating it against the RFC 5424 standard.
* **PRI Decoding**: Automatically translates syslog numerical priority values into severity (`emerg`, `alert`, etc.) and facility names. Note that only facilities from 0 to 15 (kern to reserved) are supported; all other values will be displayed as `[Unknown]`.
* **Detailed Reporting**: Generates a final report with the following sections:
    * List of all parsed log messages with decoded values.
    * Counts of logs by severity.
    * Counts of logs by facility.
    * A table showing the breakdown of logs by both severity and facility.
* **Error Handling**: Identifies and reports log entries with an invalid format, listing the line numbers for easy reference.
* **File Output**: Creates a `log_parsed.txt` file containing all valid log messages in a simplified format for easy filtering and searching.
* **Robustness**: Includes argument validation and graceful exit handlers to prevent unexpected behavior.

---

## Getting Started

### Prerequisites

The script requires a Unix-like environment with the following command-line tools installed:

* **Bash** (version 4.0 or higher)
* **`grep`** (with PCRE support, enabled by the `-P` flag)
* **`awk`**
* **`column`**
* **`tr`**

### Usage

1.  Make the script executable:
    ```bash
    chmod +x script_name.sh
    ```
2.  Run the script, providing the path to your log file as an argument:
    ```bash
    ./script_name.sh your_log_file.log
    ```

If the file is not provided, the script will display a clear usage message and exit.

---

## Log File Configuration

This script is designed to analyze logs that conform to the **RFC 5424** standard, which is the modern syslog protocol. Log entries that do not match this format will be counted as invalid.

To ensure your system's logs are generated in the correct format, you need to configure your `rsyslog` daemon.

1.  **Create a dedicated configuration file:**
    Create a new file in the `/etc/rsyslog.d/` directory. For example, `my_config.conf`. This is the recommended practice to avoid modifying the main `rsyslog.conf` file.

    ```bash
    sudo vim /etc/rsyslog.d/my_config.conf
    ```

2.  **Add the RFC 5424 template:**
    Add the following line to the newly created file. This will instruct `rsyslog` to save all log messages in the required format to a file named `syslog5424.log`.

    ```bash
    *.* /var/log/syslog5424.log;RSYSLOG_SyslogProtocol23Format
    ```

3.  **Ensure `rsyslog` receives messages from `journald`:**
    Modern systems often use `journald` as the primary logging service. To ensure these messages are forwarded to `rsyslog` (and thus saved to your `syslog5424.log` file), you must enable one of the following methods:

    * **Method A: Using the `imjournal` module (Recommended)**
        This module allows `rsyslog` to pull logs directly from the journal. Ensure the following line is uncommented in your `rsyslog.conf` file:

        ```bash
        # /etc/rsyslog.conf
        module(load="imjournal" StateFile="imjournal.state")
        ```

    * **Method B: Forwarding via socket**
        Alternatively, you can configure `journald` to forward logs to `rsyslog`'s socket. Edit the `journald` configuration file:

        ```bash
        sudo vim /etc/systemd/journald.conf
        ```
        Uncomment or add the following line:

        ```bash
        ForwardToSyslog=yes
        ```

4.  **Restart `rsyslog`:**
    After making the changes, restart the `rsyslog` service to apply the new configuration.

    ```bash
    sudo systemctl restart rsyslog
    ```

After these steps, your `syslog5424.log` file will contain logs in the correct format for this script to analyze.

---

## Example Report

The script generates a clear, color-coded report in the terminal. Below is an example of the "Facility/Severity Breakdown" table, which provides a quick overview of system activity.

```text
---------------    TABLE FACILITY/SEVERITY BREAKDOWN    ---------------

  Facility →
Severity↓ |    kern    user    auth    syslog    lpr     mail     daemon
----------+-----------------------------------------------------------
 emerg    |     10       2       0        0       0       0         0
 alert    |      0       0       3        5       0       0         0
 crit     |      1       0       0        0       0       0         0
 err      |     25      15       7        0       0       0         0
 warn     |     10       5       1        0       0       0         0
 notice   |      0       0       0       12       0       0         0
 info     |      0      12       0       18       1       1         1
 debug    |      0      20       0        0       0       0         0
