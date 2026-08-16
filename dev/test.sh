echo > ~/.psqlrc && nano ~/.psqlrc

psql -v pro=install -c '' biha_db

psql -v pro=0 -q -c '\echo :T :B :BB' biha_db | psql -v pro=0 -q biha_db

#-----------------------------------------------------------------------------------------------------------------------

psql -v pro=0 -q

psql -v pro=0

psql -v pro=1

psql -v pro=color