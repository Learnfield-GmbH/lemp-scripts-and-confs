#!/bin/bash

isUbuntu() {
    dist=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`

    if [ "$dist" = "Ubuntu" ]; then
        return true
    fi

    return false
}

# Checks if a user belongs to a group
inGroup(){
   group="$1"
   user="${2:-$(whoami)}"
   ret=false
   for x in $(groups "$user" |sed "s/.*://g")
   do [[ "$x" == "$group" ]] && { ret=true ; break ; }
   done
   eval "${ret}"
}

# Prints a message and logs it
printAndLog() {
    echo "$1"
    echo "$1" >> /tmp/provision.log
    echo "$1" >> /tmp/provision_verbose.log
}

# Tries to execute a command and if it fails it waits for five seconds and retries is for max 100 times
function tryCommand() {
    printAndLog "Trying to $1"

    if [ -n "$2" ]; then
        TRIES=$2
    else
        TRIES=1
    fi

    if (( TRIES > 100 )); then
        printAndLog "Max tries reached aborting"
        exit 1
    fi

    eval "$1>>/tmp/provision_verbose.log"

    if [[ $? > 0 ]]; then
        printAndLog "Error while running $1, retrying in 5 seconds"

        ((++TRIES))

        sleep 5

        tryCommand "$1" "$TRIES"
    else
        printAndLog "Finished $1"
    fi
}

updateAptCacheAndUpgradePackages() {
    tryCommand "apt-get -y update"
    tryCommand "apt-get -y upgrade"

    printAndLog "Updated APT caches and upgraded packages"
}

installPackages() {
    tryCommand "apt-get install -y aptitude curl git sudo zip unzip python libssl-dev"

    printAndLog "Installed regular packages"
}

addSshKeyToUser() {
    if ( ! grep -Fxq "$1" $2); then
        echo "$1" >> $2
    fi
}
