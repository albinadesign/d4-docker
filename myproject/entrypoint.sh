#!/bin/bash

# Wait for PostgreSQL to start
echo "Waiting for PostgreSQL to start..."
while ! nc -z db 5432; do
  sleep 0.1
done
echo "PostgreSQL started"

# Apply database migrations
echo "Applying database migrations..."
python manage.py migrate

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --no-input --clear
chmod -R 755 /app/staticfiles
chown -R nginx:nginx /app/staticfiles
cat /app/logs/nginx-error.log


# Create a superuser if one does not exist
echo "Creating superuser..."
python manage.py shell -c "
from django.contrib.auth import get_user_model;
User = get_user_model();
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin')
"

# Start Gunicorn
echo "Starting Gunicorn..."
exec gunicorn myproject.wsgi:application --bind 0.0.0.0:8000 --workers 3
