#!/bin/bash
export LANG=C
export LC_CTYPE=C
export EPASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
export ECOLLECTION=OTUS_$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 4 | head -n 1)
kubectl create namespace otus-mongodb --dry-run=client -o yaml | kubectl apply -f -
helm repo add bitnami https://charts.bitnami.com/bitnami
envsubst <  my_values.yaml | helm  install --wait  --timeout 120s --create-namespace otus-mongodb bitnami/mongodb -f -
echo
echo "created user test-user with password $EPASS"
echo "created collection $ECOLLECTION"
echo
echo
#NODE_IP=$(kubectl get node -o wide | tail -1 | awk '{print $6}')
#NODE_PORT=$(kubectl -n otus-mongodb get svc  otus-mongodb-metrics -o json | jq -r '.spec.ports[0].nodePort')
#echo "curl $NODE_IP:$NODE_PORT/metrics"
#curl $NODE_IP:$NODE_PORT/metrics  2>&1 | grep health
echo
echo
kubectl run --namespace otus-mongodb otus-mongodb-client --rm --tty -i \
--restart='Never' --image docker.io/bitnami/mongodb:4.4.0-debian-10-r0 \
--command -- mongo test-database \
--host "otus-mongodb-0.otus-mongodb-headless.otus-mongodb.svc.cluster.local,otus-mongodb-1.otus-mongodb-headless.otus-mongodb.svc.cluster.local,otus-mongodb-2.otus-mongodb-headless.otus-mongodb.svc.cluster.local," \
--authenticationDatabase test-database -u test-user -p $EPASS --eval 'db.getCollectionNames()'
