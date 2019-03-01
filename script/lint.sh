# ------------------------------
function MAIN(){
  for i in `ls -A $(pwd)/lint/.[a-z]*`; do
    MKLINK $i
  done
}

# ------------------------------
function MKLINK(){
  f_link=~/`basename $1`
  f_file=$1

  if [ -L $f_link ]; then
    rm $f_link
  fi

  echo make $f_link
  ln -s $f_file $f_link

  unset f_link
  unset f_file
}

# ------------------------------
MAIN
unset MAIN
unset MKLINK
