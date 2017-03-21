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

    # Create new snapshot (rsnapshot style)
    if [ -e "./0" ]; then
        echo "Hard-linking ./0 to ./tmp"
        cp -rl "./0" "./tmp"
    else
        echo "Creating ./tmp"
        mkdir "./tmp"
    fi

    # Build a list of excludes
    EXCLUDES=""
    for i in $EXCLUDE; do
        EXCLUDES="$EXCLUDES --exclude $i"
    done

    # Rsync all remote files with "./tmp"
    echo "Syncing ./tmp with remote server"
    if time rsync -arx --delete $EXCLUDES --delete-excluded "rsync://$IP/$SOURCE" "tmp/"
    then
        echo "Done! (exit code: $?)"

        # Move old backups out of the way
        [ -e "$RETAIN" ] && rm -rf "$RETAIN"
        seq "$RETAIN" -1 0 | while read i; do
            if [ -e "$i" ]; then
                echo "Moving ./$i to ./$((i+1))"
                mv "$i" "$((i+1))"
            fi
        done
        mv "./tmp" "./0"

        # Run rsnapshot-diff to compare backups
        rsnapshot-diff -H "./0" "./1"
    else
        echo "Failed! (exit code: $?)"

        # Remove failed snapshot
        rm -rf "./tmp"
    fi

    # Return back
    cd ..
done
