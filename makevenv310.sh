#!/bin/bash

VENV=venv
REQS=./requirements.txt

TARGET_PY="3.10"
LOCAL_BIN=~/.local/bin

DIR0="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

MODE=$1
echo "MODE: $MODE - use something for parm1 to run this script manually."

ARRAY=()

find_python(){
    pythons=$1
    PYTHONS=$(whereis $pythons)
    for val in $PYTHONS; do
        if [[ $val == *"/usr/bin/"* ]]; then
            if [[ $val != *"-config"* ]]; then
                ARRAY+=($val)
            fi
        fi
    done
}

python310=$(which python$TARGET_PY)
echo "python310=$python310 -> python$TARGET_PY"

v=$($python310 -c 'import sys; i=sys.version_info; print("{}{}{}".format(i.major,i.minor,i.micro))')

if [[ -f $python310 ]]
then
    echo "7. Found $python310"
fi

if [[ $v != "3915" && $TARGET_PY == "3.9" ]]
then
    echo "8. $python310 ($v) is not $TARGET_PY"
    exit 1
    echo "8.1 Installing python3.9 latest."
    apt update -y
    apt install software-properties-common -y
    echo -ne '\n' | add-apt-repository ppa:deadsnakes/ppa
    apt install python3.9 -y
	apt install python3.9-distutils -y
    apt-get update -y && apt-get upgrade -y
    apt --fix-broken install -y
fi

if [[ $v != "3108" && $v != "3106" && $TARGET_PY == "3.10" ]]
then
    echo "9. $python310 ($v) is not $TARGET_PY"
    #exit 1
    echo "9.1 Installing python3.9 latest."
    apt update -y
    apt install software-properties-common -y
    echo -ne '\n' | add-apt-repository ppa:deadsnakes/ppa
    apt install python3.10 -y
	apt install python3.10-distutils -y
    apt-get update -y && apt-get upgrade -y
    apt --fix-broken install -y
fi

python310=$(which python$TARGET_PY)
pip3=$(which pip3)
setuptools="0"

if [[ -f $python310 ]]
then
    pip_local=$LOCAL_BIN/pip3
    if [[ -f $pip_local ]]
    then
        echo "8. Found $pip_local"
        export PATH=$LOCAL_BIN:$PATH
    else
        echo "Must install PIP?"
        if [[ -f $pip3 ]]
        then
            echo "9. $pip3 exists so not installing pip3, at this time."
        else
            echo "10. Installing pip3"
            GETPIP=$DIR0/get-pip.py

            if [[ ! -f $GETPIP ]]
            then
                echo "12. Downloading get-pip.py"
                curl https://bootstrap.pypa.io/get-pip.py -o $GETPIP
            fi

            if [[ -f $GETPIP ]]
            then
                $python310 $GETPIP
                export PATH=$LOCAL_BIN:$PATH
                pip3=$(which pip3)
                if [[ -f $pip3 ]]
                then
                    echo "11. Upgrading setuptools"
                    setuptools="1"
                    $pip3 install --upgrade setuptools > /dev/null 2>&1
                fi
            fi
        fi
    fi
fi

pip3=$(which pip3)
echo "12. pip3 is $pip3"

if [[ ! -f $pip3 ]]
then
    echo "13. Upgrading pip"
    $pip3 install --upgrade pip > /dev/null 2>&1
    if [[ "$setuptools." == "0." ]]
    then
        echo "14. Upgrading setuptools"
        $pip3 install --upgrade setuptools > /dev/null 2>&1
    fi
fi

virtualenv=$(which virtualenv)
echo "15. virtualenv is $virtualenv"

if [[ ! -f $virtualenv ]]
then
    echo "16. Installing virtualenv"
    $pip3 install virtualenv > /dev/null 2>&1
    $pip3 install --upgrade virtualenv > /dev/null 2>&1
fi

virtualenv=$(which virtualenv)
echo "16. virtualenv is $virtualenv"

if [[ ! -f $virtualenv ]]
then
    echo "17. Cannot find virtualenv ($virtualenv)"
    exit 1
fi

choice=$python310

if [[ "$MODE." != "." ]]
then
    find_python python

    v=$($python310 ./scripts/sort.py "${ARRAY[@]}")
    ARRAY=()
    ARRAY2=()
    for val in $v; do
        ARRAY+=($val)
        x=$($val -c 'import sys; i=sys.version_info; print("{}.{}.{}".format(i.major,i.minor,i.micro))')
        ARRAY2+=("$val $x")
    done

    PS3="Choose: "

    select option in "${ARRAY2[@]}";
    do
        echo "Selected number: $REPLY"
        choice=${ARRAY[$REPLY-1]}
        break
    done
fi

version=$($choice --version)
echo "Use this -> $choice --> $version"

v=$($choice -c 'import sys; i=sys.version_info; print("{}{}{}".format(i.major,i.minor,i.micro))')
vv=$($choice -c 'import sys; i=sys.version_info; print("{}.{}.{}".format(i.major,i.minor,i.micro))')
echo "Use this -> $choice --> $v -> $vv"

VENV=$VENV$v
echo "VENV -> $VENV"

if [[ -d $VENV ]]
then
    rm -R -f $VENV
fi

if [[ ! -d $VENV ]]
then
    echo "Making virtualenv for Python $choice -> $VENV"

    if [[ ! -f "$choice" ]]
    then
        echo "Cannot find python:$choice"
        exit 1
    fi
    $virtualenv --python $choice -v $VENV
fi

if [[ -d $VENV ]]
then
    . ./$VENV/bin/activate
    pip install --upgrade setuptools > /dev/null 2>&1
    pip install --upgrade pip > /dev/null 2>&1

    if [[ -f $REQS ]]
    then
        echo "Installing $REQS"
        pip install -r $REQS
    fi

fi
