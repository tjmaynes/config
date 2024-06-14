# developer-workstation
> Ansible playbook for my developer workstation.

## Requirements

- [GNU Make](https://www.gnu.org/software/make/)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

## Usage
To bootstrap `dev` machine, run the following command:
```bash
make bootstrap
```

To install project dependencies, run the following command:
```bash
make install
```

To setup `dev` machine, run the following command:
```bash
make setup
```

To teardown `dev` machine, run the following command:
```bash
make teardown
```
