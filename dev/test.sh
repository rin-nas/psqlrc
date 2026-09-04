# интерактивный режим с приглашением командной строки

sudo su - postgres

psql -v pro=0 -q biha_db
psql -v pro=0 biha_db
psql -v pro=1 biha_db
psql -v pro=color biha_db

#-----------------------------------------------------------------------------------------------------------------------
# встраивание в bash скрипты

psql -v pro=0 -q -f ~/psqlrc/commands/W.psql -U psqlrc_user biha_db | sed 's/[↵¤]/ /g'
psql -v pro=0 -q -f ~/psqlrc/commands/A.psql -U psqlrc_user biha_db | sed 's/[↵¤]/ /g'
psql -v pro=0 -q -f ~/psqlrc/commands/T.psql -U psqlrc_user biha_db | sed 's/[↵¤]/ /g'
psql -v pro=0 -q -f ~/psqlrc/commands/B.psql -U biha_replication_user biha_db | sed 's/[↵¤]/ /g'
psql -v pro=0 -q -f ~/psqlrc/commands/BB.psql -U biha_replication_user biha_db | sed 's/[↵¤]/ /g'
