#!/bin/bash
export LANG=C
export LC_CTYPE=C
export EPASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
export ECOLLECTION=wb_$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 4 | head -n 1)
kubectl create namespace wb-mongodb --dry-run=client -o yaml | kubectl apply -f -
#helm repo add bitnami https://charts.bitnami.com/bitnami
envsubst <  my_values.yaml | helm  install --wait  --timeout 120s --create-namespace wb-mongodb oci://registry-1.docker.io/bitnamicharts/mongodb -f -
echo
echo "created user test-user with password $EPASS"
echo "created collection $ECOLLECTION"
echo
echo
#NODE_IP=$(kubectl get node -o wide | tail -1 | awk '{print $6}')
#NODE_PORT=$(kubectl -n wb-mongodb get svc  wb-mongodb-metrics -o json | jq -r '.spec.ports[0].nodePort')
#echo "curl $NODE_IP:$NODE_PORT/metrics"
#curl $NODE_IP:$NODE_PORT/metrics  2>&1 | grep health
echo
echo
kubectl run --namespace wb-mongodb wb-mongodb-client --rm --tty -i \
--restart='Never' --image docker.io/bitnami/mongodb:8.0.13-debian-12-r0 \
--command -- mongosh test-database \
--host "wb-mongodb-0.wb-mongodb-headless.wb-mongodb.svc.cluster.local,wb-mongodb-1.wb-mongodb-headless.wb-mongodb.svc.cluster.local,wb-mongodb-2.wb-mongodb-headless.wb-mongodb.svc.cluster.local," \
--authenticationDatabase test-database -u test-user -p $EPASS --eval 'db.getCollectionNames()'
