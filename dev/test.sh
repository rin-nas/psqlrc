# интерактивный режим с приглашением командной строки

psql -v pro=0 -q biha_db
psql -v pro=0 biha_db
psql -v pro=1 biha_db
psql -v pro=color biha_db

#-----------------------------------------------------------------------------------------------------------------------
# встраивание в bash скрипты

psql -v pro=0 -q -f ~/psqlrc/commands/W.psql biha_db | sed 's/[↵¤]/ /g'
psql -v pro=0 -q -f ~/psqlrc/commands/A.psql biha_db | sed 's/[↵¤]/ /g'
psql -v pro=0 -q -f ~/psqlrc/commands/T.psql biha_db | sed 's/[↵¤]/ /g'
psql -v pro=0 -q -f ~/psqlrc/commands/B.psql biha_db | sed 's/[↵¤]/ /g'
psql -v pro=0 -q -f ~/psqlrc/commands/BB.psql biha_db | sed 's/[↵¤]/ /g'
