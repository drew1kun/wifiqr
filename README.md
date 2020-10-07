# wifiqr
Generate the printable PDF with QR Code and PSK for specified WIFI credentials

[![BSD licensed][bsd-badge]][bsd-link]

## What does it do?
The tool takes the WiFi details (ESSID, Encryption type (WEP/WPA/WPA2) and the PSK) and generates the QR-code for easy
user authentication.
If the passprase is not being specified, this tool will automatically generate the 63 characters secure passphrase for
WPA/WPA2 encryption and 13 character passphrase for WEP encryption. It is generally advised against using WEP as it is
considered unsecure, so avoid it if possible.

## Dependencies
Depends on:

  - **pwgen**
  - **qrencode**
  - **coreutils** *(GNU version)*
  - **pdflatex** (mactex on MacOS or latex on Linux)

MacOS: install dependencies with [Homebrew][homebrew]:

Install mactex(pdflatex):

	brew cask install mactex

Install coreutils:

	brew install coreutils qrencode pwgen

## Usage

Do `./wifiqr.sh -h` or simply `./wifiqr.sh` for help

## License

[BSD][bsd-link]

## Author Information

Andrew Shagayev | [e-mail](mailto:drewshg@gmail.com)

[bsd-badge]: https://img.shields.io/badge/license-BSD-blue.svg
[bsd-link]: https://raw.githubusercontent.com/drew-kun/gpgbackup/master/LICENSE
[homebrew]: http://brew.sh/
