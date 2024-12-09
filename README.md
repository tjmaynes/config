# config

> Ansible playbook for my workstations.

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

## Ubuntu users
To resize / extend the filesystem, run the following commands:
```bash
sudo lsblk /dev/vda

sudo cfdisk # select "Resize", set "New Size", hit "Write", and "Quit"

sudo lvextend -L+10G /dev/ubuntu-vg/ubuntu-lv

sudo resize2fs /dev/mapper/ubunut...

sudo df -h
```
