#!/bin/sh

# This file is managed by Ansible.

exec docker inspect --format '{{json .State.Running}}' "$@"

exit $?
