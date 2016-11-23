# only for iTerm2
# http://www.iterm2.com/#/section/documentation/escape_codes
function setBackground() {
  echo -e "\033]Ph${1}\033\\"
}
alias setBlackBackground='setBackground 000000'

function ssh() {
  if [[ -n "$EC2_SSH_PRIVATE_KEY" ]]
  then
    /usr/bin/ssh -i "$EC2_SSH_PRIVATE_KEY" $@
  else
    /usr/bin/ssh $@
  fi
}

function ec2ssh() {
  INSTANCE="$1"
  shift
  if [[ -z "$INSTANCE" ]]
  then
    echo 'use: ec2ssh $INSTANCE' >&2
    return 2
  fi
  DESCRIBE=$(aws ec2 describe-instances --output json --instance-ids "$INSTANCE")
  ADDRESS=$(echo "$DESCRIBE" | jq -r '.Reservations[].Instances[].PublicDnsName')
  ENVIRONMENT=$(echo "$DESCRIBE" | jq -r '.Reservations[].Instances[].Tags[] | "\(.Key)=\(.Value)"')
  if [[ -n "$ADDRESS" ]]
  then
    if [[ `echo "$ENVIRONMENT" | grep "Environment=production"` ]]
    then
      setBackground 250000
    fi
    if [[ `echo "$ENVIRONMENT" | grep "Environment=sandbox"` ]]
    then
      setBackground 000025
    fi
    if [[ -n "$EC2_SSH_PRIVATE_KEY" ]]
    then
      ssh -i "$EC2_SSH_PRIVATE_KEY" -t "$ADDRESS" $@
    else
      ssh -t "$ADDRESS" $@
    fi
    STATUS=$?
    setBackground 000000
    return $STATUS
  else
    return 1
  fi
}

function ec2log() {
  INSTANCE="$1"
  if [[ -z "$INSTANCE" ]]
  then
    echo "Use: $0 instance [logfile]" >&2
    return 1
  fi
  LOGFILE="${2:-/var/log/bootstrap.log}"
  ec2ssh "$INSTANCE" "tail -f '$LOGFILE'"
}

# renames the current tab on iTerm2 (OS X only)
function tabname() {
  echo -ne "\033]0;"$@"\007";
}

# Create a data URL from an image (works for other file types too, if you tweak the Content-Type afterwards)
dataurl() {
  echo "data:image/${1##*.};base64,$(openssl base64 -in "$1")" | tr -d '\n'
}

# Get gzipped file size
function gz() {
  echo "orig size (bytes): "
  cat "$1" | wc -c
  echo "gzipped size (bytes): "
  gzip -c "$1" | wc -c
}

# Test if HTTP compression (RFC 2616 + SDCH) is enabled for a given URL.
# Send a fake UA string for sites that sniff it instead of using the Accept-Encoding header. (Looking at you, ajax.googleapis.com!)
function httpcompression() {
  encoding="$(curl -LIs -H 'User-Agent: Mozilla/5 Gecko' -H 'Accept-Encoding: gzip,deflate,compress,sdch' "$1" | grep '^Content-Encoding:')" && echo "$1 is encoded using ${encoding#* }" || echo "$1 is not using any encoding"
}

# Gzip-enabled `curl`
function gurl() {
  curl -sH "Accept-Encoding: gzip" "$@" | gunzip
}

# Syntax-highlight JSON strings or files
function json() {
  if [ -p /dev/stdin ]; then
    # piping, e.g. `echo '{"foo":42}' | json`
    python -mjson.tool | pygmentize -l javascript
  else
    # e.g. `json '{"foo":42}'`
    python -mjson.tool <<< "$*" | pygmentize -l javascript
  fi
}

# All the dig info
function digga() {
  dig +nocmd "$1" any +multiline +noall +answer
}

# Escape UTF-8 characters into their 3-byte format
function escape() {
  printf "\\\x%s" $(printf "$@" | xxd -p -c1 -u)
  echo # newline
}

# Decode \x{ABCD}-style Unicode escape sequences
function unidecode() {
  perl -e "binmode(STDOUT, ':utf8'); print \"$@\""
  echo # newline
}

# Get a character’s Unicode code point
function codepoint() {
  perl -e "use utf8; print sprintf('U+%04X', ord(\"$@\"))"
  echo # newline
}

# reload source
reload() {
  source ~/.bash_profile;
}

# Open a new SSH tunnel.
#
#   $ tunnel                    # Open dynamic proxy for my own domain
#   $ tunnel example.com 2812   # Redirect localhost:2812 to example.com:2812, without exposing service/port.
#   $ tunnel -h                 # Show help
#
tunnel() {
  if [[ $# = 0 ]]; then
    echo "Opening dynamic tunnel to simplesideias..."
    sudo ssh -vND localhost:666 fnando@simplesideias.com.br
  elif [[ $# = 2 ]]; then
    echo "Forwarding port $2 to $1..."
    ssh -L $2:localhost:$2 $1
  else
    echo "Usage:"
    echo "  tunnel                         # Use simplesideias as proxy server"
    echo "  tunnel example.com 2345        # Redirect port from localhost:2345 to example.com"
    echo ""
    echo "Common ports:"
    echo "  2812: Monit"
    echo "  5984: CouchDB"
  fi
}

# Check if given url is giving gzipped content
#
#   $ gzipped http://simplesideias.com.br
#
gzipped() {
  local r=`curl -L --write-out "%{size_download}" --output /dev/null --silent $1`
  local g=`curl -L -H "Accept-Encoding: gzip,deflate" --write-out "%{size_download}" --output /dev/null --silent $1`
  local message

  local rs=`expr ${r} / 1024`
  local gs=`expr ${g} / 1024`

  if [[ "$r" =  "$g" ]]; then
    message="Regular: ${rs}KB\n\033[31m → Gzip: ${gs}KB\033[0m"
  else
    message="Regular: ${rs}KB\n\033[32m → Gzip: ${gs}KB\033[0m"
  fi

  echo -e $message
  return 0
}

# Schedule alarm. Will display growl
# notification and beep.
#
#   $ alarm "now + 2 hours" "Your time has finished"
#
# Quotes required, sorry!
#
alarm() {
  echo "afplay /System/Library/Sounds/Basso.aiff && /usr/local/bin/growlnotify -t Alarm -s -d alarm -a /Applications/iCal.app -m '$2'" | at $1
}

# Truncates all files ending in .log on the current folder.
clear_logs() {
  find . -name '*.log' -type f -exec cp /dev/null {} \;
}

# Runs rspec for all files with content matching the supplied expression
function rspec_for () {
  grep -lir $1 spec/**/*_spec.rb | xargs bundle exec rspec
}

# Runs all specs, one kind at a time
myfinance_all_tests () {
  echo '**********************************************************'
  echo 'Executando migração de dados'
  bundle exec rake db:migrate db:test:prepare
  dirs=($(find spec -type d -depth 1 ! -name factories ! -name support ! -name fixtures ! -name javascripts ! -name tmp))
  for dirname in $dirs
  do
    echo '**********************************************************'
    echo "Executando os testes de $dirname"
    RAILS_ENV=test IGNORE_GC_PERFORMANCE_FILE=true bundle exec rspec $dirname
  done
  echo '**********************************************************'
  echo 'Executando os testes de javascript'
  RAILS_ENV=test IGNORE_GC_PERFORMANCE_FILE=true bundle exec rake spec:javascript
  echo '**********************************************************'
  echo 'Executando os testes de integração'
  RAILS_ENV=test IGNORE_GC_PERFORMANCE_FILE=true bundle exec rspec features/*_spec.rb
  echo
}

# via: http://blog.tinogomes.com/2014/03/21/dica-criando-branches-no-git/
# fix-branch some bugfix with long name
function fix-branch() {
  local new_branch_name=$(echo "$*" | tr " " _)
  git checkout master
  # git checkout -b fix/$new_branch_name
  grb create fix/$new_branch_name
}

# feature-branch some new feature with long name
function feature-branch() {
  local new_branch_name=$(echo "$*" | tr " " _)
  git checkout master
  # git checkout -b feature/$new_branch_name
  grb create feature/$new_branch_name
}

# topic-branch some new unplanned feature with long name
function topic-branch() {
  local new_branch_name=$(echo "$*" | tr " " _)
  git checkout master
  # git checkout -b feature/$new_branch_name
  grb create topic/$new_branch_name
}
