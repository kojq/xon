<div align="center">

  # xon

  <p>Implementation of xdg-open in Nim.</p>
</div>

## Overview

xon is a lightweight xdg-open replacement written in Nim. It inspects the MIME type of the file/URI provided and matches it against user-defined patterns from a configuration file. Based on the matching criteria and enabled contexts, xon runs the associated command.

## Usage

### Command-Line Usage

You can invoke xon directly from the command line. It requires two arguments:
- The path to the configuration file (in JSON format).
- The file or URI to be opened.

Example:
```bash
./xon config.json /path/to/file.txt
```

If the file exists, xon determines its MIME type (using the configured mime_query), matches it against defined patterns in the configuration, and executes the associated command for the first enabled context.

## Desktop Environment Integration

Many desktop environments use `xdg-open` to open files with their default applications. To use `xon` as a replacement, adjust your desktop environment's file association settings or create a wrapper script that points to `xon`.

For systems using `.desktop` files, you can change the `Exec` line. For example:

```ini
[Desktop Entry]
Type=Application
Name=xon
Exec=/path/to/xon /path/to/config.json %u
MimeType=...
```

Alternatively, you can symlink xon to xdg-open to tell your desktop environment to call xon whenever a file is opened via xdg-open:
```bash
sudo ln -s /path/to/xon /usr/local/bin/xdg-open
```

xon uses a JSON configuration file.

- **placeholder**: A string used in commands as a placeholder for the file/URI.
- **mime_query**: A command used to detect the file's MIME type if the file exists.
- **contexts**: A set of options that allow you to enable or disable specific association contexts.
- **targets**: A list of target objects; each object specifies:
  - **patterns**: An array of regex patterns to match MIME types or URIs.
  - **associations**: A mapping of context names to shell commands. The command should include the placeholder where the file path needs to be substituted.

## Build

To build xon, make sure you have the Nim compiler installed, and run the following commands in your terminal:
```bash
nim c -d:release xon.nim
```

To install xon system-wide:
```bash
sudo cp xon /usr/local/bin/
```
