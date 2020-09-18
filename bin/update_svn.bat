@echo off
pushd %~dp0

set s_dt=%date:/=%_%time: =0%
set s_dt=%s_dt::=%
set s_dt=%s_dt:~0,13%
set f_log=..\log\svn_update_%s_dt%.log
set s_dt=

type nul > %f_log%

for %%d in (%*) do (
  echo update %%d
  svn update "%%d" >>%f_log%
)

start notepad %f_log%
set f_log=
popd
rem pause
