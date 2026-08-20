chown -R postgres: ~/psqlrc
chmod -R 600 ~/psqlrc
chmod 700 ~/psqlrc

psql -v pro=0 -q -f ~/psqlrc/command_INSTALL.psql biha_db
psql -v pro=0 -q -f ~/psqlrc/command_REINSTALL.psql biha_db
psql -v pro=0 -q -f ~/psqlrc/command_UNINSTALL.psql biha_db

psql -v pro=0 -q -f ~/psqlrc/command_W.psql biha_db
psql -v pro=0 -q -f ~/psqlrc/command_A.psql biha_db
psql -v pro=0 -q -f ~/psqlrc/command_B.psql biha_db
psql -v pro=0 -q -f ~/psqlrc/command_BB.psql biha_db

#-----------------------------------------------------------------------------------------------------------------------

psql -v pro=0 -q biha_db
psql -v pro=0 biha_db
psql -v pro=1 biha_db
psql -v pro=color biha_db