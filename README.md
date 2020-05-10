# `local-cf`: A simple script for deploying quickly Cloud Foundry in a local machine

This project contains a couple of files:
- `run.sh`: This script downloads [`bucc`] and execute it. By running it, you get a local installation of Bosh, UAA, Credhub and Concourse on top of a VirtualBox VM. You can configure VM resources by modifying this script. When everything is ready, it sets a pipeline in Concourse. This pipeline will deploy [`cf`]
- `ci/cf-deploy`: a simple Concourse pipeline for deploying [`cf`]

This can be useful for:
- Playing in local with Cloud Fondry
- Develop in local things like [nozzles] or [service brokers]

## Dependencies

This script is using:
- `git`, for cloning [`bucc`] and [`cf`] repos from Github
- [`yq`], for modifying [`bucc`] config
- [VirtualBox], [`bucc`] uses it for deploying Bosh, UAA, Credhub and Concourse inside a VM. I've run this succesfully using version `5.2.0` on top of Debian 9.12.

## Usage
1. Clone this project `git clone https://github.com/diefida/local-cf`
1. Go inside the folder and execute `./run.sh`. It takes a while.
1. When it finish, go to your [local Concourse] and login with the credentials given in `run.sh` output.
1. You will see a pipeline named `cf` running.
1. When this pipeline finish, you will have a working CF deployment in local!

## Further tips
- For tearing down this environment, go inside bucc dir (`cd bucc`) and run `bucc down`.
- This CF deployment is using bosh-lite.com as system domain. This domain is registered on the internet as an A Record to 10.244.0.34. This private IP is the internal one for the gorouters. For being able to reach it, you need to add some routes to your OS routing table:
```

if [ "$(uname)" = "Darwin" ]; then
  sudo route add -net 10.244.0.0/16 192.168.50.6
elif [ "$(uname)" = "Linux" ]; then
  if type ip > /dev/null 2>&1; then
    sudo ip route add 10.244.0.0/16 via 192.168.50.6
  elif type route > /dev/null 2>&1; then
    sudo route add -net 10.244.0.0/16 gw 192.168.50.6
  else
    echo "ERROR adding route"
    exit 1
  fi
fi
```

You should be able to run `curl api.bosh-lite.com` and receive a JSON like this:
```json
{
  "links": {
    "self": {
      "href": "https://api.bosh-lite.com"
    },
    "bits_service": null,
    "cloud_controller_v2": {
      "href": "https://api.bosh-lite.com/v2",
      "meta": {
        "version": "2.148.0"
      }
    },
    "cloud_controller_v3": {
      "href": "https://api.bosh-lite.com/v3",
      "meta": {
        "version": "3.83.0"
      }
    },
    "network_policy_v0": {
      "href": "https://api.bosh-lite.com/networking/v0/external"
    },
    "network_policy_v1": {
      "href": "https://api.bosh-lite.com/networking/v1/external"
    },
    "login": {
      "href": "https://login.bosh-lite.com"
    },
    "uaa": {
      "href": "https://uaa.bosh-lite.com"
    },
    "credhub": null,
    "routing": {
      "href": "https://api.bosh-lite.com/routing"
    },
    "logging": {
      "href": "wss://doppler.bosh-lite.com:443"
    },
    "log_cache": {
      "href": "https://log-cache.bosh-lite.com"
    },
    "log_stream": {
      "href": "https://log-stream.bosh-lite.com"
    },
    "app_ssh": {
      "href": "ssh.bosh-lite.com:2222",
      "meta": {
        "host_key_fingerprint": "Kr/1hFleWFFTURXex7OS4NfjMEcmijO/vwMpBKBVoFw",
        "oauth_client": "ssh-proxy"
      }
    }
  }
}
```

[`bucc`]: https://github.com/starkandwayne/bucc
[`cf`]: https://github.com/cloudfoundry/cf-deployment
[`yq`]: https://github.com/mikefarah/yq
[VirtualBox]: https://www.virtualbox.org/. 
[nozzles]: 'https://docs.cloudfoundry.org/loggregator/log-ops-guide.html#scaling-nozzles'
[service brokers]: 'https://docs.cloudfoundry.org/services/overview.html'
[local Concourse]: https://192.168.50.6:4443