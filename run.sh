#!/bin/bash

METADATA=${METADATA:-169.254.169.250}

STACK=${STACK:-Backup}
SERVICE=${SERVICE:-rsyncd}

SOURCE=${SOURCE:-volume}
RETAIN=${RETAIN:-7}

# Count all rsyncd containers
CONTAINERS_URL="http://$METADATA/2015-12-19/stacks/$STACK/services/$SERVICE/containers"
curl -s "$CONTAINERS_URL" | sed 's/=.*$/ /g' | while read container; do
    # Get name of the host with this container
    UUID=$(curl -s "$CONTAINERS_URL/$container/host_uuid")
    NAME=$(curl -s "http://$METADATA/2015-12-19/hosts/$UUID/name")

    # Get IP of the container
    IP=$(curl -s "$CONTAINERS_URL/$container/primary_ip")

    echo "Starting backup of $NAME (IP of $SERVICE container for this host: $IP)"

    # Prepare directories
    [ ! -e "$NAME" ] && mkdir "$NAME"
    cd "$NAME"

    # Move old backups out of the way (rsnapshot style)
    [ -e "$RETAIN" ] && rm -rf "$RETAIN"
    seq "$RETAIN" -1 0 | while read i; do
        if [ -e "$i" ]; then
            echo "Moving ./$i to ./$((i+1))"
            mv "$i" "$((i+1))"
        fi
    done

    if [ -e "1" ]; then
        echo "Hard-linking ./1 to ./0"
        cp -rl "1" "0"
    else
        echo "Creating ./0"
        mkdir "0"
    fi

    # Build a list of excludes
    EXCLUDES=""
    for i in $EXCLUDE; do
        EXCLUDES="$EXCLUDES --exclude $i"
    done

    # Rsync all remote files with "0"
    echo "Syncing ./0 with remote server"
    time rsync -avrhx --delete $EXCLUDES --delete-excluded "rsync://$IP/$SOURCE" "0/"
    echo "Done! (exit code: $?)"

    # Return back
    cd ..
done
