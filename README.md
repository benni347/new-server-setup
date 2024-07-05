# new server setup
## Requirements

- macOS or Linux (or Windows with WSL2)
- [Ansible](https://www.ansible.com/)
- [Ansible Lint](https://ansible-lint.readthedocs.io/en/latest/)

## Usage

- Install [Ansible](https://www.ansible.com/)
  - macOS: `brew install ansible`; or: `python -m pip install --user ansible`
  - Ubuntu: `sudo sh -c 'apt-get update; apt-get install -y software-properties-common; add-apt-repository --yes --update ppa:ansible/ansible; apt-get install -y ansible'`
  - Windows is NOT supported! Use macOS or Linux instead. WSL2 on
    Windows works.
- Ansible will login to the to be configured systems using SSH as user
  `shradmin` (see `ansible.cfg`). Public key authentication is used. The
  required SSH key is stored in _.ssh/id_rsa_ . Or search for
  **id_rsa**
  - Store the private key on your system at
    `~/.ssh/id_rsa`
  - The file must not be group or world readable; run: `chmod u=rw,go= ~/.ssh/id_rsa`
  - If the bastion host is not available and cannot be resetup, make
    sure to grant access to the required systems by manually modifying
    the rule(s) in the affected network security group(s).
  - This is also required when "bootstrapping", ie. when setting up a
    bastion host with no other bastion host being available.
- On the target systems, a set of default users will be setup. See
  `group_vars/all.yml` -> `users` for the definitive list.
- To (re-)configure all hosts, run: `ansible-playbook main.yml`
  - See `ansible-playbook --help` for ways to limit which tasks are
    executed where. Example:
    - `ansible-playbook l bastion --start-at-task 'Install pip'`

## cloud-config

Ensure you are buying a server where you can use a cloud-init script.
This cloud init script creates the correct user, under the **assumption** that you have your public ssh key in /root/.ssh/authorized_keys.
```
#cloud-config

# Create the shradmin user
users:
  - name: shradmin
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    groups: sudo
    lock_passwd: true

# Copy SSH key from root user to shradmin
runcmd:
  - mkdir -p /home/shradmin/.ssh
  - cp /root/.ssh/authorized_keys /home/shradmin/.ssh/authorized_keys
  - chown -R shradmin:shradmin /home/shradmin/.ssh
  - chmod 700 /home/shradmin/.ssh
  - chmod 600 /home/shradmin/.ssh/authorized_keys
```
