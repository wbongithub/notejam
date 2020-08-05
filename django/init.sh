#!/bin/sh

set -e

if [[ ! -z "${DJANGO_CONFIG}" ]]; then
    PSQL_USERNAME=$(echo $DJANGO_CONFIG | jq .db_username)
    PSQL_HOST=$(echo $DJANGO_CONFIG | jq .db_host)
    PSQL_PASSWORD=$(echo $DJANGO_CONFIG | jq .db_password)
    PSQL_DATABASE=$(echo $DJANGO_CONFIG | jq .db_dbname)

    DATABASE_URL=$(echo -n "psql://$PSQL_USERNAME:$PSQL_PASSWORD@$PSQL_HOST/$PSQL_DATABASE" | tr -d "\"")
    SECRET_KEY=$(echo $DJANGO_CONFIG | jq .django_secret_key)

    DJANGO_ADMIN_USERNAME=$(echo $DJANGO_CONFIG | jq .django_admin_user)
    DJANGO_ADMIN_MAIL=$(echo $DJANGO_CONFIG | jq .django_admin_mail)
    DJANGO_SUPERUSER_PASSWORD=$(echo $DJANGO_CONFIG | jq .django_admin_password)

    ELASTICACHE_HOST=$(echo $DJANGO_CONFIG | jq .cache_host)
    CACHE_URL=$(echo -n "pymemcache://$ELASTICACHE_HOST" | tr -d "\"")
fi

cd /usr/src/app
./manage.py syncdb --noinput

cat <<EOF | python manage.py shell
import os
from django.contrib.auth import get_user_model

admin_user = os.getenv('ADMIN', 'admin')
mail_addr = os.getenv('MAIL', 'foo@bar.com')
su =  os.getenv('DJANGO_SUPERUSER_PASSWORD', 'password')

User = get_user_model()  # get the currently active user model,

User.objects.filter(username=admin_user).exists() or \
    User.objects.create_superuser(admin_user, mail_addr, su)
EOF

./manage.py migrate

unset PSQL_USERNAME
unset PSQL_HOST
unset PSQL_PASSWORD
unset PSQL_DATABASE

unset DJANGO_CONFIG
unset DJANGO_ADMIN_USERNAME
unset DJANGO_ADMIN_MAIL
unset DJANGO_SUPERUSER_PASSWORD
unset ELASTICACHE_HOST

./manage.py runserver 0.0.0.0:8000
