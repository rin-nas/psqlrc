# интерактивный режим с приглашением командной строки

psql -v pro=0 -q biha_db
psql -v pro=0 biha_db
psql -v pro=1 biha_db
psql -v pro=color biha_db

#-----------------------------------------------------------------------------------------------------------------------
# встраивание в bash скрипты

psql -v pro=0 -q -f ~/psqlrc/command_W.psql biha_db | sed 's/[↵¤]/ /g'
psql -v pro=0 -q -f ~/psqlrc/command_A.psql biha_db | sed 's/[↵¤]/ /g'
psql -v pro=0 -q -f ~/psqlrc/command_T.psql biha_db | sed 's/[↵¤]/ /g'
psql -v pro=0 -q -f ~/psqlrc/command_B.psql biha_db | sed 's/[↵¤]/ /g'
psql -v pro=0 -q -f ~/psqlrc/command_BB.psql biha_db | sed 's/[↵¤]/ /g'
