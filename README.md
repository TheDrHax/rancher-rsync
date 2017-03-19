# Rancher automatic rsync service [![](https://images.microbadger.com/badges/image/thedrhax/rancher-rsync.svg)](https://hub.docker.com/r/thedrhax/rancher-rsync)

This service collects files from all rsync daemons running in a specific stack (`$STACK`) and service (`$SERVICE`). It uses Rancher Metadata (`$METADATA`) service to discover running rsync daemons automatically. So you can simply replicate rsync daemon to all your hosts and backup `/var/lib/docker/volumes` automatically :)

Also this service uses rsnapshot-like backup management (hard links) to save disk space.

## Getting started

1. Create a service that will start rsync daemons on all necessary hosts (I use [zhongpei/rsyncd](https://hub.docker.com/r/zhongpei/rsyncd/) at the moment). You can start as many rsync daemons as you want. Also mount all your backup sources to `/data`.

2. Create a service with this container and point it to the previous service by setting `$STACK` and `$SERVICE` variables. You should set `Auto Restart` to `Never` and run this service when you want to do a new backup. Also mount a volume to `/backup` to be sure that backups are being saved when container is destroyed.

## Starting by Cron

1. Install `Rancher Container Cron` from Rancher Catalog

2. Add new label to rsync service: cron.schedule="your cron rule here"

