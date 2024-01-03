#!/bin/bash

# Ustawienia
PROJECT_NAME="my_ansible_project"
ROLE_NAME="my_webserver_role"
PLAYBOOK_NAME="webserver_playbook"
NGINX_CONF_J2="nginx.conf.j2"
HANDLERS_MAIN="main.yml"
TASKS_MAIN="main.yml"
TEMPLATES_DIR="templates"
HANDLERS_DIR="handlers"
INVENTORY_FILE="inventory.ini"
INDEX_HTML_J2="index.html.j2"
ROLE_VERSION="1.0.0"

# Tworzenie katalogu projektu
mkdir -p $PROJECT_NAME/roles/$ROLE_NAME/{tasks,meta,$TEMPLATES_DIR,$HANDLERS_DIR}
touch $PROJECT_NAME/roles/$ROLE_NAME/tasks/$TASKS_MAIN
touch $PROJECT_NAME/roles/$ROLE_NAME/$TEMPLATES_DIR/$NGINX_CONF_J2
touch $PROJECT_NAME/roles/$ROLE_NAME/$TEMPLATES_DIR/$INDEX_HTML_J2
touch $PROJECT_NAME/roles/$ROLE_NAME/$HANDLERS_DIR/$HANDLERS_MAIN

# Dodanie pliku index.html do roli
cat <<EOF > $PROJECT_NAME/roles/$ROLE_NAME/$TEMPLATES_DIR/$INDEX_HTML_J2
{{ INDEX_HTML_CONTENT | default("Example Index Content") }}
EOF

# Wstawianie zawartości do plików (tasks)
cat <<EOF > $PROJECT_NAME/roles/$ROLE_NAME/tasks/$TASKS_MAIN
---
- name: Install nginx
  package:
    name: nginx
    state: present
  become: true

- name: Copy nginx configuration file
  template:
    src: $NGINX_CONF_J2
    dest: /etc/nginx/nginx.conf
  notify: Restart nginx

- name: Copy index html file
  template:
    src: $INDEX_HTML_J2
    dest: /usr/share/nginx/html/index.html
  notify: Restart nginx
EOF

# Wstawianie zawartości do plików (templates)
cat <<EOF > $PROJECT_NAME/roles/$ROLE_NAME/$TEMPLATES_DIR/$NGINX_CONF_J2
# templates/nginx.conf.j2

{{ ansible_managed | comment }}

user {{ nginx_user | default('www-data') }};
worker_processes {{ nginx_worker_processes | default('auto') }};
error_log {{ nginx_error_log | default('/var/log/nginx/error.log') }};
pid {{ nginx_pid | default('/run/nginx.pid') }};

events {
    worker_connections {{ nginx_worker_connections | default(768) }};
}

http {
    sendfile {{ nginx_sendfile | default('on') }};
    tcp_nopush {{ nginx_tcp_nopush | default('on') }};
    tcp_nodelay {{ nginx_tcp_nodelay | default('on') }};
    keepalive_timeout {{ nginx_keepalive_timeout | default(65) }};
    types_hash_max_size {{ nginx_types_hash_max_size | default(2048) }};

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen {{ nginx_listen_port | default(8080) }};
        server_name {{ nginx_server_name | default('localhost') }};

        location / {
            root /usr/share/nginx/html;
            index index.html index.htm;
        }
    }
}
EOF

# Tworzenie pliku metadata roli
cat <<EOF > $PROJECT_NAME/roles/$ROLE_NAME/meta/main.yml
galaxy_info:
  author: Kamil
  description: Your role description
  license:  MIT
  min_ansible_version: 2.10
  platforms:
    - name: EL
      versions:
        - all
    - name: Debian
      versions:
        - stretch
  galaxy_tags:
    - web
    - nginx
  company: Pytlik
  license_file: LICENSE
  min_ansible_version: 2.9
  role_name: $ROLE_NAME
  version: $ROLE_VERSION  # Ustaw odpowiednią wersję roli
EOF

# Wstawianie zawartości do plików (handlers)
cat <<EOF > $PROJECT_NAME/roles/$ROLE_NAME/$HANDLERS_DIR/$HANDLERS_MAIN
---
# handlers file for $ROLE_NAME

- name: Restart nginx
  service:
    name: nginx
    state: restarted
  become: true
EOF

# Tworzenie pliku inventory
cat <<EOF > $PROJECT_NAME/$INVENTORY_FILE
[localhost]
127.0.0.1 ansible_connection=local
EOF

# Tworzenie playbooka nadrzędnego
cat <<EOF > $PROJECT_NAME/$PLAYBOOK_NAME.yml
---
- name: Configure and deploy web server
  hosts: localhost
  become: true
  vars:
    nginx_user: "www-data"
    nginx_worker_processes: "auto"
    nginx_error_log: "/var/log/nginx/error.log"
    nginx_pid: "/run/nginx.pid"
    nginx_worker_connections: 768
    nginx_sendfile: "on"
    nginx_tcp_nopush: "on"
    nginx_tcp_nodelay: "on"
    nginx_keepalive_timeout: 65
    nginx_types_hash_max_size: 2048
    nginx_listen_port: 8080
    nginx_server_name: "localhost"
    INDEX_HTML_CONTENT: "Hallo World"
  roles:
    - $ROLE_NAME

EOF

echo "Struktura katalogów, pliki, zawartość i plik inventory zostały utworzone w katalogu $PROJECT_NAME."
