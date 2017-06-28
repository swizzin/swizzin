EDITOR=nano; export EDITOR=nano
USER=`whoami`
TMPDIR=$HOME/.tmp/
HOSTNAME=`hostname -s`
IDUSER=`id -u`
PROMPT_COMMAND='echo -ne "\033]0;${USER}(${IDUSER})@${HOSTNAME}: ${PWD}\007"'
export LS_COLORS='rs=0:di=01;33:ln=00;36:mh=00:pi=40;33:so=00;35:do=00;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=01;05;37;41:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.log=02;34:*.torrent=02;37:*.conf=02;34:*.sh=00;32:*.tar=00;31:*.tgz=00;31:*.arj=00;31:*.taz=00;31:*.lzh=00;31:*.lzma=00;31:*.tlz=00;31:*.txz=00;31:*.zip=00;31:*.z=00;31:*.Z=00;31:*.dz=00;31:*.gz=00;31:*.lz=00;31:*.xz=00;31:*.bz2=00;31:*.tbz=00;31:*.tbz2=00;31:*.bz=00;31:*.tz=00;31:*.tcl=00;31:*.deb=00;31:*.rpm=00;31:*.jar=00;31:*.rar=00;31:*.ace=00;31:*.zoo=00;31:*.cpio=00;31:*.7z=00;31:*.rz=00;31:*.jpg=00;35:*.jpeg=00;35:*.gif=00;35:*.bmp=00;35:*.pbm=00;35:*.pgm=00;35:*.ppm=00;35:*.tga=00;35:*.xbm=00;35:*.xpm=00;35:*.tif=00;35:*.tiff=00;35:*.png=00;35:*.svg=00;35:*.svgz=00;35:*.mng=00;35:*.pcx=00;35:*.mov=00;35:*.mpg=00;35:*.mpeg=00;35:*.m2v=00;35:*.mkv=00;35:*.ogm=00;35:*.mp4=00;35:*.m4v=00;35:*.mp4v=00;35:*.vob=00;35:*.qt=00;35:*.nuv=00;35:*.wmv=00;35:*.asf=00;35:*.rm=00;35:*.rmvb=00;35:*.flc=00;35:*.avi=00;35:*.fli=00;35:*.flv=00;35:*.gl=00;35:*.dl=00;35:*.xcf=00;35:*.xwd=00;35:*.yuv=00;35:*.cgm=00;35:*.emf=00;35:*.axv=00;35:*.anx=00;35:*.ogv=00;35:*.ogx=00;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.axa=00;36:*.oga=00;36:*.spx=00;36:*.xspf=00;36:'
export TERM=xterm;TERM=xterm
TPUT=`which tput`
BC=`which bc`
if [ ! -e $TPUT ]; then echo "tput is missing, please install it (yum install tput/apt-get install tput)";fi
if [ ! -e $BC ]; then echo "bc is missing, please install it (yum install bc/apt-get install bc)";fi
COLDBLUE="\e[0;38;5;33m"
SCOLDBLUE="\[\e[0;38;5;33m\]"
DFSCRIPT="${HOME}/.du.sh"
if [ ! -e $DFSCRIPT ]; then
cat >"$DFSCRIPT"<< 'EOF'
#!/bin/bash
let TotalBytes=0
for Bytes in $(ls -l | grep "^-" | awk '{ print $5 }')
do
    let TotalBytes=$TotalBytes+$Bytes
done
if [ $TotalBytes -lt 1024 ]; then
           TotalSize=$(echo -e "scale=1 \n$TotalBytes \nquit$(tput sgr0)" | bc)
           suffix="b"
	elif [ $TotalBytes -lt 1048576 ]; then
           TotalSize=$(echo -e "scale=1 \n$TotalBytes/1024 \nquit$(tput sgr0)" | bc)
           suffix="kb"
        elif [ $TotalBytes -lt 1073741824 ]; then
           TotalSize=$(echo -e "scale=1 \n$TotalBytes/1048576 \nquit$(tput sgr0)" | bc)
           suffix="Mb"
else
           TotalSize=$(echo -e "scale=1 \n$TotalBytes/1073741824 \nquit$(tput sgr0)" | bc)
           suffix="Gb"
fi
echo -en "${TotalSize}${suffix}"
EOF
chmod u+x $DFSCRIPT
fi

alias ls='ls --color=auto'
alias dir='ls --color=auto'
alias vdir='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

function normal {
if [ $(id -u) == 0 ] ; then
	DG="$(tput bold ; tput setaf 1)";LG="$(tput bold;tput setaf 4)";NC="$(tput sgr0)"
	export PS1='[\[$LG\]\u\[$NC\]@\[$LG\]\h\[$NC\]]:(\[$LG\]\[$BN\]$($DFSCRIPT)\[$NC\])\w\$ '
else
	DG="$(tput bold;tput setaf 0)";LG="$(tput setaf 4)";DS="$(tput setaf 2)";NC="$(tput sgr0)"
	export PS1='[\[$LG\]\u\[$NC\]@\[$LG\]\h\[$NC\]]:(\[$LG\]\[$BN\]\[$DS\]$($DFSCRIPT)\[$NC\])\w\$ '
fi
}

case $TERM in
	rxvt*|screen*|cygwin)
		export PS1='\u\@\h\w'
	;;
	xterm*|linux*|*vt100*|cons25)
		normal
	;;
	*)
		normal
        ;;
esac

function rarit() { rar a -m5 -v25m $1 $1; }
function haste() { url="http://p.rewt.pl";key="$(curl --silent --insecure --data-binary @/dev/fd/0  $url/documents | cut -d "\"" -f 4)";echo $url"/"$key; }
function paste() { $* | curl -F 'sprunge=<-' http://sprunge.us ; }
function disktest() { dd if=/dev/zero of=test bs=64k count=16k conv=fdatasync;rm -rf test ; }
function newpass() { perl -le 'print map {(a..z,A..Z,0..9)[rand 62] } 0..pop' 15 ; }
function fixhome() { chmod -R u=rwX,g=rwX,o= "$HOME" ;}

function swap() {
local TMPFILE=tmp.$$
    [ $# -ne 2 ] && echo "swap: 2 arguments needed" && return 1
    [ ! -e $1 ] && echo "swap: $1 does not exist" && return 1
    [ ! -e $2 ] && echo "swap: $2 does not exist" && return 1
    mv "$1" $TMPFILE; mv "$2" "$1"; mv $TMPFILE "$2"
}

if [ -e /etc/bash_completion ] && ! shopt -oq posix; then source /etc/bash_completion; fi
if [ -e ~/.custom ]; then source ~/.custom; fi
