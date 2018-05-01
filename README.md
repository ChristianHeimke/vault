# config vault

This is a small (de)crypt helper for handling env configuration with secrets.

If you want to use it, you have to create a `.secret` file or pass the password via command line option.
You also need a basic plain text vault (see example below) to encrypt (seal) or decrypt (unseal).


## usage

To run vault, you need ruby in version 2.5 or higher. The easiest way is rvm[1] to manage it.

```
gem install https://github.com/dockerist/vault.git
```

If you want to see the option you have, just use the help:

```
bash-3.2$ vault -h
usage: vault [command] [options] ...

Command:
    seal               seal the vault
    unseal             unseal the vault

Options:
    -e, --environment  Set the environment you want to (un)seal
    -d, --directory    Set the directory where to find the fault, default current directory
    -p, --password     Set the password of the vault
    -f, --secret       Set the secret file name inside the directory
```

## example vault

```
---
files:
- name: compose.env
  env:
  - name: ENV
    encrypt: true
    value: some-value
  - name: DEBUG
    value: 'false'
  - name: DISABLE_OAUTH
    value: 'false'
- name: foo.pub
  value_only: true
  env:
  - value: ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAp...
- name: database.json
  template: database.json.erb
  env:
  - name: DB_USER
    value: some-user
  - name: DB_PASSWORD
    encrypt: true
    value: password
  - name: DB_NAME
    encrypt: true
    value: database_name
  - name: DB_HOST
    value: postgres

```

| files | array of files you want to manage |                                |                                                           |
|-------|-----------------------------------|--------------------------------|-----------------------------------------------------------|
|       | env                               | array of environment variables |                                                           |
|       | name                              | path and name of the file      |                                                           |
|-------|-----------------------------------|--------------------------------|-----------------------------------------------------------|
|       |                                   | encrypt                        | true or false (default) if you want to encrypt the string |
|       |                                   | name                           | name of the environment variable                          |
|       |                                   | template                       | an erb template file                                      |
|       |                                   | value                          | the value                                                 |
|       |                                   | value_only                     | write only the  value without key                         |


## output

if you don't set an template file, it will generate a simple docker-compose like env-file with key-value lines:

```
ENV=some-value
DEBUG=false
DISABLE_OAUTH=false
```

if you set a template file, it will render the values:

template:
```
{
  "database": {
    "host": "<%= db_host %>",
    "name": "<%= db_name %>",
    "password": "<%= db_password %>",
    "user": "<%= db_user %>"
  }
}
```

rendered file:

```
{
  "database": {
    "host": "postgres",
    "name": "database_name",
    "password": "password",
    "user": "some-user"
  }
}
```

The keys inside the template needs to be lower case - if the vault has upper case, it will transform them automatically.