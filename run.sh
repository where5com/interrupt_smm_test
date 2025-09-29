#!/usr/bin/env bash

filepath=$1
flag=$2

main="$(basename $filepath .asm)"
# logfile="$(date +%Y%m%d_%H%M%S).log"
logfile="$(date +%H%M%S).log"
main_src=$filepath
main_exe=out\\${main}.exe
main_lsm=out\\${main}.lsm
main_log_dir=log\\${main}
main_log=${main_log_dir}\\${logfile}

mkdir -p ${main_log_dir}

# echo "main		    = ${main}"
# echo "logfile		= ${logfile}"
# echo "main_src		= ${main_src}"
# echo "main_exe		= ${main_exe}"
# echo "main_lsm		= ${main_lsm}"
# echo "main_log_dir	= ${main_log_dir}"
# echo "main_log		= ${main_log}"

# exit


nasm -f bin ${main_src} -o ${main_exe} -l ${main_lsm}
# dosbox-x -c 'MOUNT C .' -c 'C:' -c ${main}
if [ -z "$flag" ]; then
    echo "debug mode flag: $flag"
    dosbox-x -c 'MOUNT C .' -c 'C:' -c "debugbox ${main_exe}"
elif [ "$flag" -eq 1 ]; then
    echo "run mode flag: $flag"
    dosbox-x -c 'MOUNT C .' -c 'C:' -c "${main_exe} > ${main_log}" -c "exit"
    cat ${main_log}
else
    echo "debug mode flag: $flag"
    dosbox-x -console -c 'MOUNT C .' -c 'C:' -c "debugbox ${main_exe}"
    cat ${main_log}

fi