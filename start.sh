#!/bin/bash
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

set -e

# The _log function is used for everything this script wants to log. It will
# always log errors and warnings, but can be silenced for other messages
# by setting JUPYTER_DOCKER_STACKS_QUIET environment variable.
_log () {
    if [[ "$*" == "ERROR:"* ]] || [[ "$*" == "WARNING:"* ]] || [[ "${JUPYTER_DOCKER_STACKS_QUIET}" == "" ]]; then
        echo "$@"
    fi
}
_log "Entered start.sh with args:" "$@"

# A helper function to unset env vars listed in the value of the env var
# JUPYTER_ENV_VARS_TO_UNSET.
unset_explicit_env_vars () {
    if [ -n "${JUPYTER_ENV_VARS_TO_UNSET}" ]; then
        for env_var_to_unset in $(echo "${JUPYTER_ENV_VARS_TO_UNSET}" | tr ',' ' '); do
            _log "Unset ${env_var_to_unset} due to JUPYTER_ENV_VARS_TO_UNSET"
            unset "${env_var_to_unset}"
        done
        unset JUPYTER_ENV_VARS_TO_UNSET
    fi
}


# Default to starting bash if no command was specified
if [ $# -eq 0 ]; then
    cmd=( "bash" )
else
    cmd=( "$@" )
fi

# NOTE: This hook will run as the user the container was started with!
# shellcheck disable=SC1091
source /usr/local/bin/run-hooks.sh /usr/local/bin/start-notebook.d
