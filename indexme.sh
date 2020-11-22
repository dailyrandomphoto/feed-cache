#!/usr/bin/env bash
# This is free and unencumbered software released into the public domain.
# 
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
# 
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <https://unlicense.org>


# makeitem <filepath>
# Prints to stdout HTML representing the item at <filepath> via  item. If it is
# a directory and I_RECURSIVE is set, then index the directory in a subshell.

makeitem () {
    local FULLPATH=$1
    local EXTN=""
    local LAST_MODIFIED=""
    local FILE_SIZE=""

# Get the extension/type of the item.
    if [ -d "$1" ]; then
        EXTN=dir
        FULLPATH="${1}/"
# Recurse if needed.
        if [ -n "$I_RECURSIVE" ] && [ "$1" != ".." ] && [ "$1" != "../" ]; then
            cd "$1" || exit 1
            (index) || exit 1
            cd ".." || exit 1
        fi
    else
        BASENAME=$(basename "$1")
        case $BASENAME in
            ?*.*)
                EXTN=${1##*.}
                ;;
            .*)
                EXTN=none
                ;;
            *)
                if [ -x "$1" ]; then
                    EXTN="bin"
                else
                    EXTN=none
                fi
                ;;
        esac
        FILE_SIZE=$(du -hc "$FULLPATH" |
                               tail -1 |
                         sed s/total// |
                      tr -d '[:space:]')
    fi

# The last-modified date.
    case $OSTYPE in
        *darwin*|*bsd*)
            LAST_MODIFIED=$(stat -f "%m" "$FULLPATH")
            LAST_MODIFIED=$(date -j -f "%s" "$LAST_MODIFIED" +"$I_DATE_FORMAT")
            ;;
        *linux*|*solaris*|*msys*)
            LAST_MODIFIED=$(date -r "$FULLPATH" +"$I_DATE_FORMAT" )
            ;;
    esac

# The size of the file in human notation

# Create an item.
    # item "$FULLPATH" "$EXTN" "$LAST_MODIFIED" "$FILE_SIZE"
    item "$FULLPATH" "$EXTN" "$LAST_MODIFIED"
}

# item <path> <extn> <date> <size>
# Generates the actual HTML for an item.  size  and  extn  are only defined for
# files, not for directories.

item () {
    echo "<li class=\"item $2\">"
    echo "  <a href=\"$1\">$1</a>"
    if [ -n "$4" ]; then
        echo "  <span class=\"size\">($4)</span>"
    fi
    echo "  <span class=\"date\">$3</span>"
    echo "</li>"
}

# header
# Prints to stdout the beginning of the HTML page for a listing.

header () {
    echo '<!DOCTYPE html>'
    echo "<!-- This file was generated automatically by indexme. -->"
    echo "<meta name=\"description\" content=\"Directory index for $I_TITLE\">"
    echo '<meta name="viewport" content="width=device-width, initial-scale=1">'
    echo '<meta charset="UTF-8">'
    # echo "<title>ls /$I_TITLE</title>"
    echo "<title>Index of $I_TITLE</title>"
    if [ -n "$I_CSS_URL" ]; then
        echo "<link rel=\"stylesheet\" type=\"text/css\" href=\"$I_CSS_URL\"/>"
    fi
    if [ -n "$I_JS_URL" ]; then
        echo "<script type=\"text/javascript\" src=\"$I_JS_URL\"></script>"
    fi
    if [ -n "$I_CSS_FILE" ]; then
        echo '<style type="text/css">'
        cat "$I_CSS_FILE"
        echo '</style>'
    fi
    if [ -n "$I_JS_FILE" ]; then
        echo '<script type="text/javascript">'
        cat "$I_JS_FILE"
        echo '</script>'
    fi
    if [ -n "$I_THEME" ]; then
        if [ -n "${!I_THEME}" ]; then
            echo "${!I_THEME}"
        else
            msg "[!] Warning: Theme $I_THEME not found."
        fi
    fi
    echo "<h1>Index of <strong>$I_TITLE</strong></h1>"
}

# body
# Prints to stdout the HTML body of a listing, iterating over each item in the
# directory via the  makeitem  command.

body () {
    echo "<ul>"
    if [ -z "$I_DOTDOT" ]; then
        makeitem ".."
    fi
    
    for FNAME in $(ls $I_LSFLAGS |
                 grep "$I_INCLUDE" |
                grep -v "$I_IGNORE"); do
        makeitem "$FNAME";
    done
    echo "</ul>"
}

# header
# Prints to stdout the end of the HTML page for a listing.

footer () {
    # echo "<p id=\"footer\">Generated automatically by indexme on"
    # echo "$(date +"%b %d &rsquo;%y at %l:%M:%S %p")."
    # echo "</p>"
    echo 
}

# page
# Prints to stdout a full HTML page for the current directory, via the  header,
# footer, and  body  commands.

page () {
    header
    body
    footer
}

# index
# Generates an index for the current directory, safely writing output to I_OUT.

index () {
    # I_TITLE="$(basename "$(pwd)")"
    
    I_TITLE="$(echo $(pwd) | sed -e "s|${I_BASE_DIR}||g")"
    if [ -z "${I_TITLE}" ]; then
      I_TITLE="/"
    fi
    if [ -e .indexme ]; then
        source .indexme
        # rm .indexme
        echo
    else
        # msg "[!] Creating .indexme in $(pwd)"
        # touch .indexme
        # if [ -e "$I_OUT" ]; then
        #     msg "[!] $I_OUT already exists: moving to $I_OUT.bak"
        #     mv "$I_OUT" "$I_OUT.bak"
        # fi
        echo
    fi
    if [ -e "$I_OUT.bak" ]; then
        rm "$I_OUT.bak"
        echo
    fi

    msg "[+] Indexing $(pwd)"
    page > "$I_OUT"
}

# usage
# Am I really supposed to document the documentation?

usage () {
    cat << EOF | sed "s/^    //"
    SYNOPSIS: $I_THIS_NAME [-qv] [-arczh] [dir ...]
      dir...
          directories to index; defaults to current working directory
      -q  Operate quietly (overrides -v).
      -v  Verbose mode (overrides -q).
      -r  Index directories recursively (obeys ignore/include directives).
      -a  Index all directories in ~ that contain a .indexme file, then exit.
      -c  Display a line for crontab and exit.
      -z  Launch a daemon that runs  $I_THIS_NAME -a  every 60 seconds.
      -h  Display this help message and exit.

    OVERVIEW

    indexme(1) is a simple utility to create directory indexes for the web, so
    that you can maintain easily-searchable directories of static content
    without thinking too hard about it. It provides the equivalent of Apache's
    mod_autoindex or nginx' autoindex functionality, but (a) doesn't require
    anything more than a static site server like Github Pages, and (b) tries to
    look somewhat prettier than raw ls(1) output.

    indexme produces HTML5 that is valid according to the W3C validator. A
    variety of flags and environment variables documented below allow a
    significant amount of customization. However, it comes with sane defaults:
    if you're short on time, simply run  indexme  in a directory to get a
    decent-looking index that includes file sizes and last-modification time
    (by the way, indexme won't clobber existing index.html files).

    indexme also comes with support for creating a cron job, and for running a
    background daemon that periodically updates the listings.

    INSTALLATION

    This file is the entire program. To install it, just copy this file to a
    directory in your PATH. The whole thing is written in bash, so it probably
    works on your system.

    ENVIRONMENT

    The following environment variables control the behavior of indexme.

      I_TITLE       Page title.
                    Currently: '$I_TITLE'.
      I_THEME       If set, the name of the variable containing inline CSS/JS.
                    Currently: '$I_THEME'.
      I_CSS_URL     URL of stylesheet
                    Currently: '$I_CSS_URL'
      I_JS_URL      URL of script.
                    Currently: '$I_JS_URL'
      I_CSS_FILE    Set to directly embed stylesheet
                    Currently: '$I_CSS_FILE'
      I_JS_FILE     Set to directly embed script
                    Currently: '$I_JS_FILE'
      I_LSFLAGS     Flags sent to ls(1) Ex: -c to sort by date.
                    Currently: '$I_LSFLAGS'
      I_DATE_FORMAT strftime-style format for dates
                    Currently: '$I_DATE_FORMAT'
      I_INCLUDE     Regex to whitelist entries
                    Currently: '$I_INCLUDE'
      I_IGNORE      Regex to blacklist entries, overrides I_INCLUDE
                    Currently: '$I_IGNORE'
      I_OUT         Output file; can set to '/dev/stdout' but only at top-level
                    Currently: '$I_OUT'
      I_QUIET       Set to suppress messages
                    Currently: '$I_QUIET'
      I_RECURSIVE   Set to index subdirectories (obeys include/ignore).
                    Currently: '$I_RECURSIVE'

    These variables are assigned in the following places before indexing each
    directory:
      1.  Defaults initialized
      2.  Command-line arguments     # customized per-invokation
      3.  source ~/.indexme_profile  # customized per-user
      3.5 (guess I_TITLE here)
      4.  source .indexme            # customized per-directory
    When recursing, variable assignments in subdirectories do not affect the
    indexing of their parent directories (as you would expect).

    For further customization, the functions  header,  footer, and
    item <path> <extn> <date> <size>  can all be overriden. They should print
    HTML to stdout.

    SEE ALSO

    If you need a quick testing server, consider the following command:

        python -m SimpleHTTPServer <port>


    $I_THIS_NAME(1)                                                 August 2017

EOF
}

# addcron
# Prints a line to add to crontab.

addcron () {
    I_CRONTAB="@hourly bash $I_THIS_LOC -a"
    echo "# Update directory listings where needed."
    echo "$I_CRONTAB"
}

# indexall
# Indexes every directory with a  .indexme  file in it via the  index  command.

indexall () {
    msg "[*] Searching for indexable directories..."
    for TGT in $(find ~ -name .indexme); do
        TGT_DIR=$(dirname "$TGT")
        cd "$TGT_DIR" || exit 1
        index
    done
}

# cleanlock, bgproc, launchbgproc
# Services to help start the background updating process.

cleanlock () {
    rm -f ~/.indexme.lock/pid
    rm -f ~/.indexme.lock/log
    rmdir ~/.indexme.lock
    exit 1
}

bgproc () {
    trap ":" SIGHUP
    msg "[*] Daemon started."
    trap cleanlock SIGTERM
    while true; do
        indexall
        for i in $(seq 1 60); do
            sleep 1
        done
    done
}

launchbgproc () {
    if mkdir ~/.indexme.lock 2> /dev/null; then # mkdir is atomic
        bgproc 2> ~/.indexme.lock/log &
        echo "$!" > ~/.indexme.lock/pid
        msg "[!] Acquired lock cleanly."
        msg "[*] Starting daemon, PID=$!."
        exit
    else
        I_OLD_DAEMON=$(cat ~/.indexme.lock/pid)
        kill -0 "$I_OLD_DAEMON" 2> /dev/null
        if [ "$?" = "0" ]; then
            msg "[?] Daemon is already running: $(cat ~/.indexme.lock/pid)"
            exit 1
        else
            bgproc 2> ~/.indexme.lock/log &
            echo "$!" > ~/.indexme.lock/pid
            msg "[!] Stole lock from dead process $I_OLD_DAEMON."
            msg "[*] Starting daemon, PID=$!"
            exit
        fi
    fi
}

msg () {
    if [ -z "$I_QUIET" ]; then
        echo "$1" >&2
    fi
}



# Initialize some sane defaults

# I_BASE_DIR="$(dirname "$(pwd)")"
I_BASE_DIR="$(pwd)"
I_TITLE=$(basename "$(pwd)")
I_THEME="I_THEME_DEFAULT"
I_CSS_URL=""
I_JS_URL=""
I_CSS_FILE=""
I_JS_FILE=""
I_LSFLAGS="-A"
I_INCLUDE=".*"
I_IGNORE='^index.html\|.indexme$'
I_OUT="index.html"
I_QUIET=""
I_RECURSIVE=""
I_DATE_FORMAT="%b %d &rsquo;%y"

# customized
I_RECURSIVE="yes"
I_IGNORE='^\(index.html\|.indexme\|.git\|.github\|\.gitignore\|package.*\.json\|.*\.sh\|.*\.js\|.*\.txt\|node_modules\)$'
I_LSFLAGS="-A --group-directories-first"

# Who am I?

I_THIS_DIR=$( cd "$(dirname "$0")" || exit 1 ; pwd -P )
I_THIS_NAME=$(basename "$0")
I_THIS_LOC="$I_THIS_DIR/$I_THIS_NAME"

I_THEME_DEFAULT=$(cat <<'EOF'
<style type="text/css">
body {
    /* max-width: 50em; */
    text-align: left;
    margin-left: auto;
    margin-right: auto;
    padding: 3em;
    color: black;
    background: white;
}

h1 {
    font-family: sans-serif;
    font-weight: 100;
}


p, ul {
    font-family: monospace;
    text-align: left;
}

.item {
    text-indent: -1em;
    padding-left: 2em;
    margin-right: 3em;
    margin-top: 1em;
    border-left: 0.5em solid gray;
    display: list-item;
}

.txt, .md, .tex { border-left-color: orange; }
.gif, .png, .jpg, .jpeg { border-left-color: #FF69B4; } /* pink */
.pdf, .svg { border-left-color: green; }
.mp3, .wav, .m4a { border-left-color: blue; }
.dir { border-left-color: black; }
.html { border-left-color: yellow; }
.py, .rb, .js, .json, .css, .sh, .hs, .c, .h, .cpp, .rs, .xml, .yml { border-left-color: red; }
.bin, .pyc, .o, .so, .dylib { border-left-color: limegreen; }

a {
    color: black;
}
a:hover {
    color: red;
}

p#footer {
    display: block;
    margin-top: 3em;
    font-style: italic;
}

.date {
    color: gray;
}

input[type=text] {
    display: block;
    margin-left: auto;
    margin-right: auto;
    font-family: monospace;
    font-size: 1.5em;
    border: none;
    padding: 0.3em;
    text-align: center;
    border-bottom: 1pt solid #eee;
    margin-bottom: 2em;
}

input:focus {
    outline: none;
}
</style>
EOF
)

# The main UI -- parse command-line options, and then take the remaining args
# and treat them as directories to index.

if [ -e ~/.indexme_profile ]; then
    source ~/.indexme_profile
fi
while getopts ":qvarczh" opt; do
    case $opt in
        q)
          I_QUIET="yes"
          ;;
        v)
          I_QUIET=""
          ;;
        a)
          indexall
          exit
          ;;
        r)
          I_RECURSIVE="yes"
          ;;
        c)
          addcron
          exit
          ;;
        z)
          launchbgproc
          exit
          ;;
        h|\?)
          usage >&2
          exit
          ;;
    esac
done
shift "$((OPTIND-1))"
if [ -z "$*" ]; then
    index
else
    HERE=$(pwd)
    for dir in "$@"; do
        cd "$HERE" || exit 1
        cd "$dir" || exit 1
        index
    done
fi