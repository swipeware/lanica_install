#!/bin/bash
#------------------------------------------------------------------------------
# lanica_install.command
#
# Simple installer for Lanica modules.
#
# NOTE: This file is of type .command to make it friendly for OSX Finder.
# Double-clicking on a .command file in Finder will automatically
# open the Terminal app to display the output.
#
#
# MIT License (MIT)
#
# Copyright (c) 2014 Ingemar Bergmark
# Email: ingemar@swipeware.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#------------------------------------------------------------------------------

INSTALLDEST="~/Library/Application Support/Titanium"
LOGFILE="/tmp/lanica_install.log"
LANICA_ZIP="co.lanica*.zip"

folderExists()
{
    local folder="$INSTALLDEST/${1%/}"

    if [ -d "`eval echo $folder`" ]; then
        echo "OK"
    else
        echo ""
    fi
}

installFiles()
{
    local src="$TMPDEST/$1"
    local dest=`eval echo "$INSTALLDEST/$1"`

    # delete old destination. we want to replace it completely
    if [ -d "$dest" ]; then
        rm -rf "$dest"
    fi
    
    cp -pR "$src" "$dest"
}

getListing()
{
    # list only folders
    for listing in `ls -d $1*/`; do
        if [ $MODULELEVEL == 1 ]; then
            VERSIONLEVEL=1
        elif [[ `eval basename $listing` == co.lanica.* ]]; then
            # make sure listing has a valid Titanium module path
            if [[ $listing == modules/* ]]; then
                echo "Processing ${listing%/}"
                MODULELEVEL=1
            fi
        fi

        result=$(folderExists $listing)

        # installation folder doesn't exist?
        if [ -z "$result" ]; then
            if [ $VERSIONLEVEL == 1 ]; then
                echo "Adding version: `eval basename '$listing'`"
                installFiles $listing
            elif [ $MODULELEVEL == 1 ]; then
                echo "Adding module: `eval basename '$listing'`"
                installFiles $listing
            else
                echo "Error processing $zipfile"
                break
            fi 
        else
            if [ $VERSIONLEVEL == 1 ]; then
                echo "Updating version: `eval basename '$listing'`"
                installFiles $listing
                break

            elif [ $MODULELEVEL == 1 ]; then
                if [ $REPLACEMODULE == 1 ]; then
                    echo "Updating module: `eval basename '$listing'`"
                    installFiles $listing
                    break
                fi
            fi

            getListing $listing
        fi
    done
}

usage()
{
cat << EOF

    usage: `basename $0` [-h] [-r]

    Install Lanica modules. 

    This script will find all Lanica zip files in the current folder
    and update or add them to your Titanium modules folder.
    The default behavior will keep older versions of the module intact.
    You can override this behavior with the -r flag.

    OPTIONS:
       -h      Show this message
       -r      Replace modules and delete old versions

EOF
}

doFilesExist()
{
    ls $zipdir$LANICA_ZIP 1>/dev/null 2>&1
}

REPLACEMODULE=0

while getopts "hr" OPTION; do
    case $OPTION in
        h)
            usage
            exit 1
            ;;
        r)
            REPLACEMODULE=1
            ;;
        ?)
            usage
            exit
            ;;
    esac
done

#execute in subshell and capture output to log
(
echo "=========================================================="
echo "Lanica installation START"
echo -e "`date`\n"

zipdir=

# are there any zips in the current folder?
doFilesExist

if [ $? == 1 ]; then #nope, try looking in script folder
    zipdir=$(dirname $0)/
fi

doFilesExist

if [ $? == 1 ]; then #nope, bail
    echo -e "No Lanica zip files found.\n"
else
    for zipfile in `ls $zipdir$LANICA_ZIP`; do
        MODULELEVEL=0
        VERSIONLEVEL=0

        #create tmp folder
        TMPBASE=`basename $0`
        TMPDEST=`mktemp -d /tmp/${TMPBASE}.XXXXXX` || (echo "Cannot create tmp folder" && exit 1)

        unzip -d "$TMPDEST" $zipfile 1>/dev/null

        pushd $TMPDEST 1>/dev/null

        getListing

        popd 1>/dev/null

        #remove tmp folder
        rm -rf "$TMPDEST"

        echo ""
    done
fi

echo "Lanica installation END"
echo "`date`"
echo -e "\nOutput saved to $LOGFILE "
echo -e "==========================================================\n"
) 2>&1 | tee -a $LOGFILE
