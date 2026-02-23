# config
> Ansible playbook for my developer workstations.

## Requirements

- [GNU Make](https://www.gnu.org/software/make/)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

## Usage

To bootstrap machine, run the following command:
```bash
make bootstrap
```

To install project dependencies, run the following command:
```bash
make install
```

To set up machine, run the following command:
```bash
make setup
```

To teardown machine, run the following command:
```bash
make teardown
```
