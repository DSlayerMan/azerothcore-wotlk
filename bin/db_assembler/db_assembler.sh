#!/bin/bash

unamestr=`uname`
if [[ "$unamestr" == 'Darwin' ]]; then
   SRCPATH=$(greadlink -f "../../")
else
   SRCPATH=$(readlink -f "../../")
fi

source $SRCPATH"/bin/bash_shared/includes.sh"

if [ -f "./config.sh"  ]; then
    source "./config.sh" # should overwrite previous
fi

if [[ "$unamestr" == 'Darwin' ]]; then
    MD5_CMD="md5"
else
    MD5_CMD="md5sum"
fi

reg_file="$OUTPUT_FOLDER/__db_assembler_registry"

if [ -f "$reg_file" ]; then
    source "$reg_file"
fi

function assemble() {
    # to lowercase
    database=${1,,}
    start_sql=$2
    with_base=$3
    with_updates=$4
    with_custom=$5

    var_base="DB_"$1"_PATHS"
    base=${!var_base}

    var_updates="DB_"$1"_UPDATE_PATHS"
    updates=${!var_updates}

    var_custom="DB_"$1"_CUSTOM_PATHS"
    custom=${!var_custom}

    echo $updates


    suffix_base="_base"
    suffix_upd="_update"
    suffix_custom="_custom"

    curTime=`date +%Y_%m_%d_%H_%M_%S`

    if [ $with_base = true ]; then
        echo "" > $OUTPUT_FOLDER$database$suffix_base".sql"


        if [ ! ${#base[@]} -eq 0 ]; then
            echo "Generating $OUTPUT_FOLDER$database$suffix_base ..."

            for d in "${base[@]}"
            do
                echo "Searching on $d ..."
                if [ ! -z $d ]; then
                    for entry in "$d"/*.sql "$d"/**/*.sql
                    do
                        if [[ -e $entry ]]; then
                            cat "$entry" >> $OUTPUT_FOLDER$database$suffix_base".sql"
                        fi
                    done
                fi
            done
        fi
    fi

    if [ $with_updates = true ]; then
        updFile=$OUTPUT_FOLDER$database$suffix_upd"_"$curTime".sql"

        if [ ! ${#updates[@]} -eq 0 ]; then
            echo "Generating $OUTPUT_FOLDER$database$suffix_upd ..."

            for d in "${updates[@]}"
            do
                echo "Searching on $d ..."
                if [ ! -z $d ]; then
                    for entry in "$d"/*.sql "$d"/**/*.sql
                    do
                        if [[ ! -e $entry ]]; then
                            continue
                        fi

                        file=$(basename "$entry")
                        hash=$($MD5_CMD "$entry")
                        hash="${hash%% *}" #remove file path
                        n="registry__$hash"
                        if [[ -z ${!n} ]]; then
                            if [ ! -e $updFile ]; then
                                echo "" > $updFile
                            fi

                            printf -v "registry__${hash}" %s "$file"
                            echo "-- New update sql: "$file
                            cat "$entry" >> $updFile
                        fi
                    done
                fi
            done
        fi
    fi

    if [ $with_custom = true ]; then
        custFile=$OUTPUT_FOLDER$database$suffix_custom"_"$curTime".sql"

        if [ ! ${#custom[@]} -eq 0 ]; then
            echo "Generating $OUTPUT_FOLDER$database$suffix_custom ..."

            for d in "${custom[@]}"
            do
                echo "Searching on $d ..."
                if [ ! -z $d ]; then
                    for entry in "$d"/*.sql "$d"/**/*.sql
                    do
                        if [[ ! -e $entry ]]; then
                            continue
                        fi

                        file=$(basename "$entry")
                        hash=$($MD5_CMD "$entry")
                        hash="${hash%% *}" #remove file path
                        n="registry__$hash"
                        if [[ -z ${!n} ]]; then
                            if [ ! -e $custFile ]; then
                                echo "" > $custFile
                            fi

                            printf -v "registry__${hash}" %s "$file"
                            echo "-- New custom sql: "$file
                            cat "$entry" >> $custFile
                        fi
                    done
                fi
            done
        fi
    fi
}


echo "===== STARTING PROCESS ====="

    mkdir -p $OUTPUT_FOLDER

    for db in ${DATABASES[@]}
    do
        assemble "$db" $version".sql" true true true
    done

    echo "" > $reg_file

    for k in ${!registry__*}
    do
      n=$k
      echo "$k='${!n}';" >> "$reg_file"
    done

echo "===== DONE ====="
