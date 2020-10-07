#!/usr/bin/env bash
#========== Define functions ===========
function usage {
    echo "DESCRIPTION:"
    echo "Generate the QR Code for specified WIFI credentials"
    echo
    echo
    echo "DEPENDENCIES:"
    echo "  - pwgen"
    echo "  - qrencode"
    echo "  - coreutils (GNU version)"
    echo "  - pdflatex (mactex on MacOS or latex on Linux)"
    echo
    echo "On MacOS install dependencies with Homebrew:"
    echo "Install LaTex:"
    echo "      'brew cask install mactex'"
    echo
    echo "Install coreutils:"
    echo "      'brew install coreutils qrencode pwgen'"
    echo "coreutils will be installed with g (for GNU) - prefix: gsed etc."
    echo
    echo
    echo "USAGE:"
    echo "      'wifiqr.sh { -h | -w | { -o <ESSID> <SEC> <PSK> } }'"
    echo
    echo "      -h                       - Show this message."
    echo "      -w                       - Wizard option. The one will be asked to specify all wifi details."
    echo "                                 If the Passphrase is left empty,"
    echo "                                 the secure 63 character password will be auto-generated"
    echo "      -o <ESSID> <SEC> [<PSK>] - One-liner option. Specify all wifi details through the command line."
    echo
    echo "         <ESSID>               - Wifi netork ESSID (Name)"
    echo "         <SEC>                 - Security/Encryption type (WEP/WPA/WPA2)"
    echo "         <PSK>                 - Wifi Pre-shared key (Passphrase). If left empty,"
    echo "                                 the secure 63 character password will be auto-generated"
    echo
    echo "EXAMPLES:"
    echo
    echo " ./wifiqr.sh -p My_Wifi WPA2 UnsecurePassword  # Creates folder with name 'My_Wifi' containing printable PDF"
    echo
}

function check_deps {
    # check if GNU Sed is installed depending on OS:
    command -v "${1}" >/dev/null 2>&1 || { echo >&2 "${1} is not installed.  Aborting."; exit 1; }
    # check other deps:
    command -v pwgen >/dev/null 2>&1 || { echo >&2 "pwgen is not installed.  Aborting."; exit 1; }
    command -v qrencode >/dev/null 2>&1 || { echo >&2 "qrencode is not installed.  Aborting."; exit 1; }
    command -v pdflatex >/dev/null 2>&1 || { echo >&2 "pdflatex is not installed.  Aborting."; exit 1; }
}

function wifidata {
    echo 'Specify Wifi ESSID:'
    read ESSID
    echo 'Specify Wifi Encryption type (WEP/WPA/WPA2):'
    read SEC
#    if [ "${SEC}" != 'WEP' ] && [ "${SEC}" != 'WPA' ] && [ "${SEC}" != 'WPA2' ]; then
#        echo "WiFi Encryption type is wrong. Should be [ WEP | WPA | WPA2 ]. Exiting..."
#        exit 1
#    fi
}

function checksec {
    if [ "${SEC}" != 'WEP' ] && [ "${SEC}" != 'WPA' ] && [ "${SEC}" != 'WPA2' ]; then
        echo "WiFi Encryption type is wrong. Should be [ WEP | WPA | WPA2 ]. Exiting..."
        exit 1
    fi
}

function genpass {
    if [[ "${SEC}" == 'WEP' ]]; then
        PASSLEN=13
    elif [[ "${SEC}" == 'WPA' ]] || [[ "${SEC}" == 'WPA2' ]]; then
        PASSLEN=63
    fi
    echo "Generating Secure Wifi Passphrase for ${SEC}-Encryption..."
    PSK=$(pwgen -1 -s "${PASSLEN}")
}

function genpdf {
    mkdir -p "./${1}"
    qrencode -o "./${1}/${1}.png" "WIFI:S:${1};T:${2};P:${3};;"

    # prepare wifiqr.tex self generated latex document:
    cat ./latex/wifiqr.template.tex | "${5}" -e "s/ESSID/${1}/g" \
    -e "s/SEC/${2}/g" \
    -e "s/PSK/${3}/g" > "${1}.tex"

    # Escape special characters properly:
    "${5}" -i -e '/fancyhead/ s/_/\\_/g' "${1}.tex"
    "${5}" -i -e '/centering{WiFi:/ s/_/\\char`_/g' "${1}.tex"

    # generate pdf and move it right place:
    pdflatex --shell-escape "${1}.tex" > /dev/null 2>&1
    mv ${1}.pdf ${1}

    # Cleanup:
    ${4} ${1}.log ${1}.tex ${1}.aux ${1}/${1}.png
    exit 0
}
#=======================================

#================ Main =================

# Detect OS
OS="$(uname | tr '[:upper:]' '[:lower:]')"

case ${OS} in
    'darwin')
        SECRM='rm -fP'
        SED='gsed'
        ;;
    'linux')
        SECRM='shred -v -n 0 -z -u'
        SED='sed'
        ;;
    *)
        echo "Unknown OS, Only MacOS and Linux are supported"
esac

# Check dependencies
check_deps "${SED}"

# Parse Arguments
while getopts ':hwo:' opt; do
    case "${opt}" in
        o)
            ESSID=$2  # The WiFi SSID
            SEC=$3    # WEP/WPA/WPA2
            PSK=$4    # The Pre-Shared Key (passwphrase)

            # If there are <3 or >4 arguments (including -p option):
            if [[ $# -lt 3 ]] || [[ $# -gt 4 ]]; then
                echo "Please specify -o with all necessary arguments. Try -h for help."
                exit 1
            # If only ESSID and Encryption type specified,
            # then generate secure passphrase and proceed:
            elif [[ $# -eq 3 ]]; then
                checksec
                genpass
            fi
            # Else, If ESSID, Encryption and Passphrase are specified,
            # then create QR code with specified passphrase:
            genpdf "${ESSID}" "${SEC}" "${PSK}" "${SECRM}" "${SED}"
            ;;
        w)
            wifidata
            checksec
            echo 'Specify Wifi Passphrase (leave empty and press Enter if you want to automatically generate one):'
            read PSK

            if [[ "${PSK}" == '' ]]; then
                genpass
            fi
            genpdf "${ESSID}" "${SEC}" "${PSK}" "${SECRM}" "${SED}"
            ;;
        h)
            usage
            exit 0
            ;;
        \?)
            echo "Invalid option -${OPTARG}. Try -h for help."
            exit 1
            ;;
        :)
            echo "Option -${OPTARG} requires arguments. Try -h for help."
            exit 1
            ;;
    esac
done

# Check if any options given:
if [[ $# -eq 0 ]]; then
    usage
    exit 0
fi
#=======================================
