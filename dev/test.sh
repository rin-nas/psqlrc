psql -v pro=0 -q -f ~/psqlrc/command_INSTALL.psql biha_db
psql -v pro=0 -q -f ~/psqlrc/command_REINSTALL.psql biha_db
psql -v pro=0 -q -f ~/psqlrc/command_UNINSTALL.psql biha_db

psql -v pro=0 -q -c '\echo :W :A' | psql -v pro=0 -q biha_db
psql -v pro=0 -q -c '\echo :T' | psql -v pro=0 -q biha_db
psql -v pro=0 -q -c '\echo :B :BB' biha_db | psql -v pro=0 -q biha_db

#-----------------------------------------------------------------------------------------------------------------------

psql -v pro=0 -q biha_db
psql -v pro=0 biha_db
psql -v pro=1 biha_db
psql -v pro=color biha_db