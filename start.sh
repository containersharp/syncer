#!/bin/sh 

_term() { 
  echo "SIGTERM signal received: Shuting down..." 
  kill -TERM "$child" 2>/dev/null
}
trap _term SIGTERM


/app/SharpCR.Registry > /var/registry.log &
child=$! 

/app/sync.sh
wait "$child"