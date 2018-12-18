#!/bin/sh
### BEGIN INIT INFO
# Provides:          upload_rpicam_file
# Required-Start:    $local_fs $syslog $network
# Required-Stop:     $local_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Something
# Description:       Something else
### END INIT INFO

# CONFIGURATION
DIR="/etc/opt/kerberosio/capture"
EVENTS="close_write"
FIFO="/tmp/inotify2.fifo"

# FUNCTIONS
on_exit() {
    kill $INOTIFY_PID
    rm $FIFO
    exit
}

on_event() {
    local date=$1
    local time=$2
    local dir=$3
    local file=$4

    sleep 5

    echo "$date $time Fichier créé: $file dans $dir" >> /etc/opt/kerberosio/log.log

    /etc/opt/kerberosio/uploader.py /etc/opt/kerberosio/uploader.cfg $dir/$file
}

# MAIN
if [ ! -e "$FIFO" ]
then
    mkfifo "$FIFO"
fi

inotifywait -m -e "$EVENTS" --timefmt '%Y-%m-%d %H:%M:%S' --format '%T %w %f' "$DIR" > "$FIFO" &
INOTIFY_PID=$!

trap "on_exit" 2 3 15

while read date time dir file
do
    on_event $date $time $dir $file &
done < "$FIFO"

on_exit
