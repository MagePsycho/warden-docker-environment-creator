#!/bin/bash

#
# Script to speed up the application (Magento & Symfony) environment creation for warden based development
#
# @author   Raj KB <magepsycho@gmail.com>
# @website  https://www.magepsycho.com
# @version  1.0.0

# UnComment it if bash is lower than 4.x version
shopt -s extglob

################################################################################
# CORE FUNCTIONS - Do not edit
################################################################################
#
# VARIABLES
#
_bold=$(tput bold)
_underline=$(tput sgr 0 1)
_reset=$(tput sgr0)

_purple=$(tput setaf 171)
_red=$(tput setaf 1)
_green=$(tput setaf 76)
_tan=$(tput setaf 3)
_blue=$(tput setaf 38)

#
# HEADERS & LOGGING
#
function _debug()
{
    if [[ "$DEBUG" = 1 ]]; then
        "$@"
    fi
}

function _header()
{
    printf '\n%s%s==========  %s  ==========%s\n' "$_bold" "$_purple" "$@" "$_reset"
}

function _arrow()
{
    printf '➜ %s\n' "$@"
}

function _success()
{
    printf '%s✔ %s%s\n' "$_green" "$@" "$_reset"
}

function _error() {
    printf '%s✖ %s%s\n' "$_red" "$@" "$_reset"
}

function _warning()
{
    printf '%s➜ %s%s\n' "$_tan" "$@" "$_reset"
}

function _underline()
{
    printf '%s%s%s%s\n' "$_underline" "$_bold" "$@" "$_reset"
}

function _bold()
{
    printf '%s%s%s\n' "$_bold" "$@" "$_reset"
}

function _note()
{
    printf '%s%s%sNote:%s %s%s%s\n' "$_underline" "$_bold" "$_blue" "$_reset" "$_blue" "$@" "$_reset"
}

function _die()
{
    _error "$@"
    exit 1
}

function _safeExit()
{
    exit 0
}

#
# UTILITY HELPER
#
function _seekConfirmation()
{
  printf '\n%s%s%s' "$_bold" "$@" "$_reset"
  read -p " (y/n) " -n 1
  printf '\n'
}

# Test whether the result of an 'ask' is a confirmation
function _isConfirmed()
{
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        return 0
    fi
    return 1
}


function _typeExists()
{
    if type "$1" >/dev/null; then
        return 0
    fi
    return 1
}

function _isOs()
{
    if [[ "${OSTYPE}" == $1* ]]; then
      return 0
    fi
    return 1
}

function _isOsDebian()
{
    if [[ -f /etc/debian_version ]]; then
        return 0
    else
        return 1
    fi
}

function _checkRootUser()
{
    #if [ "$(id -u)" != "0" ]; then
    if [ "$(whoami)" != 'root' ]; then
        echo "You have no permission to run $0 as non-root user. Use sudo"
        exit 1;
    fi
}

function _selfUpdate()
{
    TMP_FILE=$(mktemp -p "" "XXXXX.sh")
    curl -s -L "$SCRIPT_URL" > "$TMP_FILE"
    NEW_VER=$(grep "^VERSION" "$TMP_FILE" | awk -F'[="]' '{print $3}')
    if [[ "$VERSION" < "$NEW_VER" ]]; then
        printf "Updating script \e[31;1m%s\e[0m -> \e[32;1m%s\e[0m\n" "$VERSION" "$NEW_VER"
        printf "(Run command: $(basename "$0") --version to check the version)"
        cp -f "$TMP_FILE" "$ABS_SCRIPT_PATH" || _die "Unable to update the script"
    else
         _arrow "Already the latest version."
    fi
    exit 1
}

function _printPoweredBy()
{
    local mp_ascii
    mp_ascii='
   __  ___              ___               __
  /  |/  /__ ____ ____ / _ \___ __ ______/ /  ___
 / /|_/ / _ `/ _ `/ -_) ___(_-</ // / __/ _ \/ _ \
/_/  /_/\_,_/\_, /\__/_/  /___/\_, /\__/_//_/\___/
            /___/             /___/
'
    cat <<EOF
${_green}
Powered By:
$mp_ascii

 >> Store: ${_reset}${_underline}${_blue}https://www.magepsycho.com${_reset}${_reset}${_green}
 >> Blog:  ${_reset}${_underline}${_blue}https://blog.magepsycho.com${_reset}${_reset}${_green}

################################################################
${_reset}
EOF
}

################################################################################
# SCRIPT FUNCTIONS
################################################################################
function _printVersion()
{
    echo "Version $VERSION"
}

function _printUsage()
{
    echo -n "$(basename "$0") [OPTION]...

Script to speed up the application (Magento & Symfony) environment creation for warden based development
Version $VERSION

    Options:
        -p,     --project          Project Name
        -t,     --type             Type (magento2|symfony), Default: magento2
        -h,     --help             Display this help and exit
        -d,     --debug            Display this help and exit
        -v,     --version          Output version information and exit
        -u,     --update           Self-update the script from Git repository
                --self-update      Self-update the script from Git repository

    Examples:
        $(basename "$0") --project --type [--debug] [--version]  [--help]

"
    _printPoweredBy
    exit 1
}

function checkCmdDependencies()
{
    local _dependencies=(
      warden
      sed
      wget
      curl
      awk
    )

    for cmd in "${_dependencies[@]}"
    do
        hash "${cmd}" &>/dev/null || _die "'${cmd}' command not found."
    done;
}

function processArgs()
{
    # Parse Arguments
    for arg in "$@"
    do
        case $arg in
            -p|--project=*)
                APP_PROJECT="${arg#*=}"
                APP_DOMAIN="app.${APP_PROJECT}.test"
            ;;
            -t|--type=*)
                APP_TYPE="${arg#*=}"
            ;;
            --debug)
                DEBUG=1
                set -o xtrace
            ;;
            -v|--version)
                _printVersion
            ;;
            -h|--help)
                _printUsage
            ;;
            -u|--update|--self-update)
                _selfUpdate
            ;;
            *)
                #_printUsage
            ;;
        esac
    done

    validateArgs
}

function initDefaultArgs()
{
    INSTALL_DIR=$(pwd)
    APP_TYPE="magento2"
}

function validateArgs()
{
    ERROR_COUNT=0

     if [[ -z "$APP_PROJECT" ]]; then
        _error "Project name (--project=...) cannot be empty"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi

     if [[ ! -z "$APP_TYPE" && "$APP_TYPE" != @(magento2|symfony) ]]; then
        _error "Please enter valid application name for --type=... parameter(magento2|symfony)."
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi

    #echo "$ERROR_COUNT"
    [[ "$ERROR_COUNT" -gt 0 ]] && exit 1
}

function createEtcHostEntry()
{
    local _etcHostLine="127.0.0.1  ${APP_DOMAIN}"
    if grep -Eq "127.0.0.1[[:space:]]+${APP_DOMAIN}" /etc/hosts; then
        _warning "Entry ${_etcHostLine} already exists in host file"
    else
        echo "127.0.0.1 ${APP_DOMAIN}" | sudo tee -a /etc/hosts || _die "Unable to write host to /etc/hosts"
    fi
}

function createWardenEnv()
{
    _arrow "Warden env creation started..."

    warden env-init "$APP_PROJECT" "$APP_TYPE"
    warden sign-certificate "${APP_PROJECT}.test"

    _success "Done"

    _arrow "Configuring the environment variables..."
    local _webRoot=$(grep WARDEN_WEB_ROOT "${INSTALL_DIR}/.env" | cut -d '=' -f2)
    if [[ "$_webRoot" != "/web" ]]; then
      sed -i 's/WARDEN_WEB_ROOT=\//WARDEN_WEB_ROOT=\/web/g' "${INSTALL_DIR}/.env"
    fi
    if [[ ! -d "${INSTALL_DIR}/web" ]]; then
      mkdir web
    fi
    _success "Done"

    warden env up

    # Not sure why /etc/hosts needs to configured manually for Ubuntu
    if _isOsDebian ; then
       _arrow "Creating an entry to /etc/hosts file..."
       createEtcHostEntry
       _success "Done"
    fi
}

function printSuccessMessage()
{
    _success "Warden environment has been created for the application"

    echo "################################################################"
    echo ""
    echo " >> App Type        : ${APP_TYPE}"
    echo " >> App Domain      : ${APP_DOMAIN}"
    echo " >> App Dir         : ${INSTALL_DIR}"
    echo " (Now you can login to the shell for further processing: warden shell)"
    echo "################################################################"
    _printPoweredBy
}

################################################################################
# Main
################################################################################
export LC_CTYPE=C
export LANG=C

DEBUG=0
_debug set -x
VERSION="1.0.0"
SCRIPT_URL='https://raw.githubusercontent.com/MagePsycho/warden-docker-environment-creator/main/src/wenv-creator.sh'
SCRIPT_LOCATION="${BASH_SOURCE[@]}"
ABS_SCRIPT_PATH=$(readlink -f "$SCRIPT_LOCATION")

INSTALL_DIR=
APP_PROJECT=
APP_TYPE=
APP_DOMAIN=

function main()
{
    #_checkRootUser
    checkCmdDependencies

    [[ $# -lt 1 ]] && _printUsage

    initDefaultArgs
    processArgs "$@"

    createWardenEnv

    printSuccessMessage

    exit 0
}

main "$@"

_debug set +x
