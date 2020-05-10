#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BUCC_DIR="$THIS_SCRIPT_DIR/bucc"
CF_DEPLOYMENT_DIR="$THIS_SCRIPT_DIR/cf-deployment"

VBOX_VM_CORES=4
VBOX_VM_RAM=16384
VBOX_VM_DISK=100_000
# I needed to change Concourse port for being able to expose CF API
CONCOURSE_PORT=4443


function update_repo {
    local repo_dir=$1
    local repo_url=$2

    if [[ -d "$repo_dir" ]]; then
        pushd "$repo_dir"
            git pull
        popd   
    else
        git clone "$repo_url" "$repo_dir"
    fi
}

function modify_bucc_config {
    yq w "$BUCC_DIR/ops/cpis/virtualbox/vars.tmpl" vm_cpus "$VBOX_VM_CORES" -i
    yq w "$BUCC_DIR/ops/cpis/virtualbox/vars.tmpl" vm_memory "$VBOX_VM_RAM" -i
    yq w "$BUCC_DIR/ops/cpis/virtualbox/vars.tmpl" vm_ephemeral_disk "$VBOX_VM_DISK" -i
    yq w "$BUCC_DIR/ops/3-concourse.yml" '[0].value.properties.external_url' 'https://((internal_ip)):'"$CONCOURSE_PORT" -i
    yq w "$BUCC_DIR/ops/3-concourse.yml" '[0].value.properties.tls_bind_port' "$CONCOURSE_PORT" -i
}

function run_inside_bucc_dir {
    local cmd=$1; shift
    local args=( "$@" )

    pushd "$BUCC_DIR"
        source .envrc
        $cmd "${args[@]}"
        return_code=$?
    popd
    return $return_code
}

function bucc_up {
   run_inside_bucc_dir bucc up --lite
}

function update_runtime_config {
    run_inside_bucc_dir bosh --non-interactive update-runtime-config src/bosh-deployment/runtime-configs/dns.yml --name dns
}

function set_and_trigger_pipeline {
    pushd "$BUCC_DIR"
        source .envrc
        bucc fly
        fly -t bucc set-pipeline -p cf -c "$THIS_SCRIPT_DIR/ci/cf-deploy.yml" \
            -v stemcell_type=$(bosh int "$CF_DEPLOYMENT_DIR/cf-deployment.yml" --path /stemcells/alias=default/os) \
            -v stemcell_version=$(bosh int "$CF_DEPLOYMENT_DIR/cf-deployment.yml" --path /stemcells/alias=default/version) \
            --non-interactive
        fly -t bucc unpause-pipeline -p cf
        fly -t bucc trigger-job -j cf/deploy-cf
    popd
}

function show_concourse_info {
    run_inside_bucc_dir bucc info
}


function main {
    update_repo "$BUCC_DIR" "https://github.com/starkandwayne/bucc" && \
    update_repo "$CF_DEPLOYMENT_DIR" "https://github.com/cloudfoundry/cf-deployment" && \
    modify_bucc_config && \
    bucc_up && \
    update_runtime_config && \
    set_and_trigger_pipeline && \
    show_concourse_info
}

main