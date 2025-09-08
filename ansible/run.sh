#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

ansible-galaxy collection install -r requirements.yml

ansible-playbook infra.yml

ansible-playbook -i ./.dynamic_web.ini configure.yml
ansible-playbook image.yml