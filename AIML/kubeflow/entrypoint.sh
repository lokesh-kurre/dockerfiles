#! /bin/bash -e

NB_PREFIX=${NB_PREFIX%%/} # Removing leading slash
NB_PREFIX=${NB_PREFIX##/} # Removing trailing slash
if [[ -n "${NB_PREFIX}" ]]; then
    NB_PREFIX="${NB_PREFIX}/"
fi
if [ -d "/home/jovyan" ]; then
    SERVE_DIR="/home/jovyan"
else
    SERVE_DIR=${SERVE_DIR:-"/"}
fi
export SERVE_DIR NB_PREFIX
export LD_LIBRARY_PATH="${SERVE_DIR}/lib:${LD_LIBRARY_PATH}"

export PATH="${VENV_DIR}/${VENV_NAME}/bin:${CONDA_DIR}/condabin:${PATH}"

conda init bash

cat << 'FILE' | envsubst '$NB_PREFIX $SERVE_DIR' > /etc/default/environ
#! /bin/bash
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
export OPENCV_IO_ENABLE_JASPER=1
export CUDA_VISIBLE_DEVICES=""
export NB_PREFIX="${NB_PREFIX}"
export SERVE_DIR="${SERVE_DIR}"

FILE

cat << 'FILE' | envsubst '$NB_PREFIX' > /etc/nginx/nginx.conf
user  root;
worker_processes  1;

include /etc/nginx/modules-enabled/*.conf;

error_log  /proc/1/fd/2 notice;
pid        /run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    map $http_upgrade $connection_upgrade {
      default upgrade;
      '' close;
    }
  
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '[$time_local] - $remote_addr - $status '
                      ' "$request" "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /proc/1/fd/1  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
}

FILE

echo $NB_PREFIX

cat  << 'FILE' | envsubst '$NB_PREFIX' > /etc/nginx/conf.d/default.conf
server {
    listen       8888;
    server_name  localhost;

    access_log  /proc/1/fd/1  main;
    error_log  /proc/1/fd/2 notice;

    proxy_buffering off;

    location /${NB_PREFIX}vscode/ {
        proxy_pass http://127.0.0.1:8889/;
        # proxy_pass http://unix:/run/code-server.sock;
	
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Accept-Encoding gzip;

        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /${NB_PREFIX} {
        proxy_pass http://unix:/run/jupyter.sock;
	
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Accept-Encoding gzip;

        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

FILE

mkdir -p ${HOME}/.config/code-server/
cat << 'FILE' > ${HOME}/.config/code-server/config.yaml
bind-addr: 0.0.0.0:8889
# socket: /run/code-server.sock
auth: none
password: 8360c51ec82d456940d7fb51
cert: false

disable-telemetry:
disable-update-check:
ignore-last-opened:

app-name: vscode-code-server-development

FILE

mkdir -p ${HOME}/.local/share/code-server/User/
cat << 'FILE' > ${HOME}/.local/share/code-server/User/settings.json
{
    "workbench.colorTheme": "Default Dark Modern",
    "editor.fontSize": 18,
    "editor.wordWrap": "on",
    "editor.formatOnSave": true,
    "files.insertFinalNewline": true,
    "extensions.autoCheckUpdates": false,
    "extensions.autoUpdate": false,
    "terminal.integrated.copyOnSelection": true,
    "telemetry.telemetryLevel": "off",
    "update.mode": "none"
}

FILE

cat << 'FILE' | envsubst '$NB_PREFIX' > /etc/init.d/code-server
#!/bin/sh

### BEGIN INIT INFO
# Provides:          code-server
# Required-Start:    $local_fs $remote_fs $network $syslog $named
# Required-Stop:     $local_fs $remote_fs $network $syslog $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the code server
# Description:       starts code server using start-stop-daemon
### END INIT INFO

DAEMON=/usr/bin/code-server
NAME=code-server
DESC="A vscode server for developer"

# Include default environment variables if available
if [ -r /etc/default/environ ]; then
    . /etc/default/environ
fi


# Include code-server defaults if available
if [ -r /etc/default/code-server ]; then
    . /etc/default/code-server
fi

STOP_SCHEDULE="${STOP_SCHEDULE:-QUIT/5/TERM/5/KILL/5}"

test -x $DAEMON || exit 0

. /lib/init/vars.sh
. /lib/lsb/init-functions


PID=/run/code-server.pid


if [ -n "$ULIMIT" ]; then
    # Set ulimit if it is set in /etc/default/code-server
    ulimit $ULIMIT
fi

start_code_server() {
    # Start the daemon/service
    #
    # Returns:
    #   0 if daemon has been started
    #   1 if daemon was already running
    #   2 if daemon could not be started
    start-stop-daemon --test --start --quiet --pidfile $PID --startas /bin/bash -- \
                -c "exec $DAEMON $DAEMON_OPTS 1> /proc/1/fd/1 2>/proc/1/fd/2" > /dev/null \
            || return 1
    start-stop-daemon --start --quiet --make-pidfile --background --pidfile $PID --startas /bin/bash -- \
                -c "exec $DAEMON $DAEMON_OPTS 1> /proc/1/fd/1 2>/proc/1/fd/2" > /dev/null \
            || return 2
}

stop_code_server() {
    # Stops the daemon/service
    #
    # Return
    #   0 if daemon has been stopped
    #   1 if daemon was already stopped
    #   2 if daemon could not be stopped
    #   other if a failure occurred
    start-stop-daemon --stop --quiet --remove-pidfile --retry=$STOP_SCHEDULE --pidfile $PID --startas /bin/bash -- \
                -c "exec $DAEMON $DAEMON_OPTS 1> /proc/1/fd/1 2>/proc/1/fd/2"
    RETVAL="$?"
    sleep 1
    return "$RETVAL"
}

case "$1" in
    start)
        log_daemon_msg "Starting $DESC" "$NAME"
        start_code_server
        case "$?" in
                0|1) log_end_msg 0 ;;
                2)   log_end_msg 1 ;;
        esac
        ;;
    stop)
        log_daemon_msg "Stopping $DESC" "$NAME"
        stop_code_server
        case "$?" in
                0|1) log_end_msg 0 ;;
                2)   log_end_msg 1 ;;
        esac
        ;;
    restart)
        log_daemon_msg "Restarting $DESC" "$NAME"

        stop_code_server
        case "$?" in
            0|1)
                start_code_server
                case "$?" in
                    0) log_end_msg 0 ;;
                    1) log_end_msg 1 ;; # Old process is still running
                    *) log_end_msg 1 ;; # Failed to start
                esac
                ;;
            *)
                # Failed to stop
                log_end_msg 1
                ;;
        esac
        ;;

    status)
        status_of_proc -p $PID "$DAEMON" "$NAME" && exit 0 || exit $?
        ;;

    *)
        echo "Usage: $NAME {start|stop|restart|status}" >&2
        exit 3
        ;;
esac

FILE

cat << 'FILE' | envsubst '$NB_PREFIX $SERVE_DIR' >  /etc/init.d/jupyter
#!/bin/sh

### BEGIN INIT INFO
# Provides:          jupyter
# Required-Start:    $local_fs $remote_fs $network $syslog $named
# Required-Stop:     $local_fs $remote_fs $network $syslog $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the jupyter server
# Description:       starts jupyter server using start-stop-daemon
### END INIT INFO

DAEMON=$(which jupyter)
NAME=jupyter
DESC="A jupyter server for developer"

# Include default environment variables if available
if [ -r /etc/default/environ ]; then
    . /etc/default/environ
fi

OPTS="notebook --allow-root \
    --no-browser \
    --ServerApp.sock="/run/jupyter.sock" \
    --ServerApp.base_url=/${NB_PREFIX} \
    --ServerApp.root_dir=${SERVE_DIR} \
    --ServerApp.allow_origin='*' \
    --ServerApp.allow_remote_access=true \
    --ServerApp.token='' \
    --ServerApp.password=''"


# Include jupyter defaults if available
if [ -r /etc/default/jupyter ]; then
    . /etc/default/jupyter
fi

STOP_SCHEDULE="${STOP_SCHEDULE:-QUIT/5/TERM/5/KILL/5}"

test -x $DAEMON || exit 0

. /lib/init/vars.sh
. /lib/lsb/init-functions


PID=/run/jupyter.pid


if [ -n "$ULIMIT" ]; then
    # Set ulimit if it is set in /etc/default/jupyter
    ulimit $ULIMIT
fi

start_code_server() {
    # Start the daemon/service
    #
    # Returns:
    #   0 if daemon has been started
    #   1 if daemon was already running
    #   2 if daemon could not be started
    start-stop-daemon --test --start --quiet --pidfile $PID --startas /bin/bash -- \
                -c "exec $DAEMON $OPTS 1> /proc/1/fd/1 2>/proc/1/fd/2" > /dev/null \
            || return 1
    start-stop-daemon --start --quiet --make-pidfile --background --pidfile $PID --startas /bin/bash -- \
                -c "exec $DAEMON $OPTS 1> /proc/1/fd/1 2>/proc/1/fd/2" > /dev/null \
            || return 2
}

stop_code_server() {
    # Stops the daemon/service
    #
    # Return
    #   0 if daemon has been stopped
    #   1 if daemon was already stopped
    #   2 if daemon could not be stopped
    #   other if a failure occurred
    start-stop-daemon --stop --quiet --remove-pidfile --retry=$STOP_SCHEDULE --pidfile $PID --startas /bin/bash -- \
                -c "exec $DAEMON $OPTS 1> /proc/1/fd/1 2>/proc/1/fd/2"
    RETVAL="$?"
    sleep 1
    return "$RETVAL"
}

case "$1" in
        start)
                log_daemon_msg "Starting $DESC" "$NAME"
                start_code_server
                case "$?" in
                        0|1) log_end_msg 0 ;;
                        2)   log_end_msg 1 ;;
                esac
                ;;
        stop)
                log_daemon_msg "Stopping $DESC" "$NAME"
                stop_code_server
                case "$?" in
                        0|1) log_end_msg 0 ;;
                        2)   log_end_msg 1 ;;
                esac
                ;;
        restart)
                log_daemon_msg "Restarting $DESC" "$NAME"

                stop_code_server
                case "$?" in
                        0|1)
                                start_code_server
                                case "$?" in
                                        0) log_end_msg 0 ;;
                                        1) log_end_msg 1 ;; # Old process is still running
                                        *) log_end_msg 1 ;; # Failed to start
                                esac
                                ;;
                        *)
                                # Failed to stop
                                log_end_msg 1
                                ;;
                esac
                ;;

        status)
                status_of_proc -p $PID "$DAEMON" "$NAME" && exit 0 || exit $?
                ;;

        *)
                echo "Usage: $NAME {start|stop|restart|status}" >&2
                exit 3
                ;;
esac

FILE

chmod 755 /etc/init.d/jupyter /etc/init.d/code-server

if [[ -z "$@" ]]; then
    service jupyter start
    sleep 5
    service code-server start 
    sleep 5
    exec nginx -g 'daemon off;'
else
    exec "$@"
fi