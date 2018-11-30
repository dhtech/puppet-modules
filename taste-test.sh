#!/bin/bash

if [ "$1" = "" ]
then
  echo "Usage: taste-test.sh HOSTNAME"
  exit
fi

HOSTNAME=$1
DATE=`date +%s`
SESSID="`echo "canary_${USER}_${HOSTNAME/-/_}" | cut -f1 -d"."`_$DATE"

set -e
ssh $HOSTNAME << EOF 
    wall \$USER is running puppet canary on this host.
    echo "[PREFLIGHT] Testing host access..."
EOF 
ssh puppet.tech.dreamhack.se echo "[PREFLIGHT] Testing puppet access..."
set +e

read -p "Do you want to canary on $HOSTNAME? [Y/n]" -n 1 -r
if [[ $REPLY =~ ^[Nn]$ ]]
then
    echo "Canary aborted!"
else
    echo "Putting host $HOSTNAME in canary mode..."
    ssh -q -o LogLevel=error $HOSTNAME sudo systemctl stop puppet 2>/dev/null
    while true; do 
        read -p "Push current state and run puppet on $HOSTNAME? [Y/n]" -n 1 -r
        if [[ $REPLY =~ ^[Nn]$ ]]
        then
            echo "Aborting canary!"
            break
        else
            if [[ $(git diff --shortstat 2> /dev/null | tail -n1) != "" ]]
            then 
                echo "Using dirty branch when running canary..."
            fi
            echo "Pusing current state to puppet.."
            rsync -ruvz --exclude=".*" . puppet.tech.dreamhack.se:/etc/puppetlabs/puppet/environments/$SESSID 2>/dev/null
            echo "Running puppet on host..."
            ssh -q -o LogLevel=error $HOSTNAME "
                sudo puppet agent -t --environment $SESSID 2>&1 | tee \$HOME/puppet-canary.log
            "
        fi
    done
fi

echo "Restoring host and puppet server..."
ssh -q -o LogLevel=error puppet.tech.dreamhack.se "
    sudo rm -r /etc/puppetlabs/puppet/environments/$SESSID
" 2>/dev/null
ssh -q -o LogLevel=error $HOSTNAME "
    wall \$USER is done running puppet canary on this host, going back to production.
    sudo systemctl start puppet
" 2>/dev/null

echo "Cleanup done! Dont forget to merge changes on GitHub or they will be overridden on next puppet run."