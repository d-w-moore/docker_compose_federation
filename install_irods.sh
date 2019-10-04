service postgresql start
while ! sudo su - postgres -c 'psql -c "\l" >/dev/null 2>&1'
do
   echo "waiting for database..." ; sleep 1
done
sudo su - postgres -c 'psql -f /tmp/db_commands.txt'
python /var/lib/irods/scripts/setup_irods.py </localhost_setup_postgres.input
#
#---------------------------
#while : ; do sleep 30; done
