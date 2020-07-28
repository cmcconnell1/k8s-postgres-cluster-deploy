# postgres-cluster-deploy

# PURPOSE: 
- CI/CD PostgreSQL clusters simple low-entry barrier allows non-kube folks to just modify vars file and run build script then deploy (optional auto with CI/CD)

# STATUS: 
- POC/Development--not for production use at this time--use at own risk-see below CONCERNS
- This is from work done early 2019.

# PREREQUISITE: 
- Ensure postgresql operator previously deployed and operations--this project deploys clusters that will be managed by the operator.


# CONCERNS: 
- Ensure you understand the limitations and issues with kubernetes and multi-az stateful gotchas--note persisent volumes dont span AZ's--this can be very painful--ensure you understand this.  consider creating AZ-specific storage classes, etc.
- I.e. this should *not* be used for production (without significant modifications).

### For any/all info on how the operator works--refer to official operator docs:
- <https://github.com/zalando/postgres-operator/tree/master/docs>

## Purpose / Overview 
- Gates PG configurtion and deployment of postgres-operator controlled DB applications/clusters.
- Deploys to requisite clusters and environments via commits to this project--see Jenkinsfile.

- For now commits to various branches will result in deployments via CI (dev) / and CD (stage/prod)--see Jenkinsfile.  
  - i.e.: postgres, postgres.
  - development: CI 
  - staging: CD
  - production: CD

### Prerequisites

### Postgres / Kubernetes Cluster Locations
| Postgres Cluster Name   | Kubernetes Cluster Name | Kubernetes Namespace |
| -------------           | -------------       | --------------
| postgres-cluster        | dev                 | postgres-operator 
| postgres-cluster        | prod          | postgres-operator


### DBA Workflow Overview
- Update/modify vars file as necessary for requisite environment:
   - dev:   __pg-dev.vars__
   - prod:  __pg-prod.vars__

- Run the requisite `build-postgres-$ENV-mainfest` script to build the requisite cluster's kubernetes manifest file.
  - dev: `./build-dev-postgres-cluster-manifest`
  - prod: `./build-prod-postgres-cluster-manifest`

- Validate dynamically generated kubernetes manifest files created in above script.
```sh
tree ./manifests/development/
./manifests/development/
├── postgres-cluster-cluster.yaml
└── postgres-cluster-namespace.yaml

0 directories, 2 files
```
- Follow __your__ specified gitworkflow for requisite branch commit/deploy.

### After your commit to requisite branch (and the CI/CD processes have executed) 
- Check the postgres-operator pod logs to ensure no errors.  
  - I.e. if you commit and don't see any postgres application pods there is a problem which you can track down in the operator pod logs.

  - What you should see in the operator pod logs
  ```sh
  time="2019-06-14T18:59:17Z" level=info msg="Creating the role binding zalando-postgres-operator in the namespace postgres-operator" pkg=controller
  time="2019-06-14T18:59:17Z" level=info msg="successfully deployed the role binding for the pod service account \"zalando-postgres-operator\" to the \"postgres-operator\" namespace" pkg=controller
  time="2019-06-14T18:59:17Z" level=info msg="creation of the cluster started" cluster-name=postgres-operator/pg-dev pkg=controller worker=0
  time="2019-06-14T18:59:17Z" level=warning msg="master is not running, generated master endpoint does not contain any addresses" cluster-name=postgres-operator/pg-dev pkg=cluster worker=0
  time="2019-06-14T18:59:17Z" level=info msg="endpoint \"postgres-operator/pg-dev\" has been successfully created" cluster-name=postgres-operator/pg-dev pkg=cluster worker=0
  ```

  - Examples of errors you will see in the postgres-operator pod logs
    - Note it tells you where the problem in its configuration is
    ```sh
    time="2019-06-14T18:48:55Z" level=info msg="no clusters running" pkg=controller
    time="2019-06-14T18:50:38Z" level=debug msg="skipping \"ADD\" event for the invalid cluster: name must match {TEAM}-{NAME} format" cluster-name=postgres-operator/postgres pkg=controller
    time="2019-06-14T18:53:55Z" level=info msg="there are no clusters running. 1 are in the failed state" pkg=controller
    time="2019-06-14T18:58:55Z" level=info msg="there are no clusters running. 1 are in the failed state" pkg=controller
    ```



# Working With my-company Application/PostgreSQL Clusters 
- These clusters/apps are deployed to the eks cluster in the postgres-$ENV namespace
  - For this example, we must have already committed to the `development` branch of this repo and the requisite CI kubernetes deploy was executed per the Jenkinsfile.


##### Dev Cluster (postgres) Example
- set kubernetes namespace (or you will have to use aliases or append '-n my-namespace' to every kubectl command)
```sh
kubens postgres-operator
Context "eks_eks-cluster" modified.
Active namespace is "postgres-operator".
```


##### Show everything in the namespace `postgres-operator`
- All of these are what make up a postgres cluster (and they depend on the requisite postgres-operator which runs in the `postgres-operator` namespace).
  - Two __pods__ (dynamic dev=2--configurable in the requisite `postgres.vars` file)
    - __postgres-0__
    - __postgres-1__
  - Two __services__
    - __postgres__      - aka: master
    - __postgres-repl__ - aka: replication
  - One __statefulset.app__ (required for stateful applications)
    - __postgres__
      - this manages the deployment and scaling of Pods and guarantees their ordering and uniqueness.
```sh
k get all -n postgres-operator
NAME           READY   STATUS    RESTARTS   AGE
pod/postgres-0   1/1     Running   0          16h
pod/postgres-1   1/1     Running   0          16h

NAME                  TYPE           CLUSTER-IP      EXTERNAL-IP                                                               PORT(S)          AGE
service/postgres        LoadBalancer   172.20.13.113   a9af2e92887f011e9aa3f0a9f985f63b-1960378799.us-west-2.elb.amazonaws.com   5432:30317/TCP   16h
service/postgres-repl   LoadBalancer   172.20.184.75   a9af5b38187f011e9aa3f0a9f985f63b-1228244778.us-west-2.elb.amazonaws.com   5432:31013/TCP   16h

NAME                      DESIRED   CURRENT   AGE
statefulset.apps/postgres   2         2         16h
```

#### Note for utility examples below, see the actual scripts for the code/logic for syntax, etc.

#### Get and export PG master and replication pod names
- Export pg master and replication pod names to current shell by sourcing utility script __WITH_REQUIRED_ARGS__
`export-master-repl-pod-names $KUBE_NAMESPACE $PG_CLUSTER_NAME`
- i.e.:
```sh
source ./bin/export-master-repl-pod-names postgres-operator postgres
# PGMASTER: postgres-0
# PGREPLICA: postgres-1
```

#### Export the pg-admin postgres (admin/super) password
- source get-pgadm-password utility script
```sh
source ./bin/export-pgadmin-password postgres-operator postgres
PGPASSWORD: XXXX-NOTACTUALPASSHERE-TS1p6R9OLTXSJ6NbFzhctFfJyG8FGTJ7tBdLNCyctPNUhJCHUcS 
```
- Note see the script for the code/logic which gets and decodes the secret password. 
  - Hint: Use the same process to get other passwords.


##### Export Master and Replication Service ELB IP
- Usage
```sh
source ./bin/export-master-and-replication-service $KUBE_NAMESPACE $PG_CLUSTER_NAME
```
- I.e.:
```sh
source ./bin/export-master-and-replication-service postgres-operator postgres
MASTER_SERVICE: a9af2e92887f011e9aa3f0a9f985f63b-1960378799.us-west-2.elb.amazonaws.com
REPL_SERVICE: a9af5b38187f011e9aa3f0a9f985f63b-1228244778.us-west-2.elb.amazonaws.com

echo $MASTER_SERVICE
a9af2e92887f011e9aa3f0a9f985f63b-1960378799.us-west-2.elb.amazonaws.com
echo $REPL_SERVICE
a9af5b38187f011e9aa3f0a9f985f63b-1228244778.us-west-2.elb.amazonaws.com
```
- OPS TODO: get PG resources into DNS


##### Connect to MASTER ELB / Service 
- Note: Requires requisite access in the allow CIDR access configuration--must allow 5432 from your IP (/32) or your CIDR range.
- Note you should already have the requisite PGPASSWORD exported in above 'Get postgres password' section.
```sh
export MY_POSTGRES_COMMAND="SELECT datname FROM pg_database;"
export PGHOST=$MASTER_SERVICE
export PGPORT=5432
psql -U postgres -c "${MY_POSTGRES_COMMAND}"
#  datname
#-----------
# postgres
# template1
# template0
#(3 rows)
```

##### Connect to REPLICATION ELB / Service 
- Note: Requires requisite access in the postgres security group rules--must allow 5432 from your IP (or your CIDR range).
- Note: Requires requisite access in the postgres security group rules--must allow 5432 from your IP (or your CIDR range).
- For READS or time insensitive queries.
- Note already have the requisite PGPASSWORD exported in above 'Get postgres password' section
```sh
export PGHOST=$REPL_SERVICE
export PGPORT=5432
psql -U postgres -c "SELECT pg_size_pretty( pg_database_size('my-app') );"
psql -U postgres -c "SELECT pg_size_pretty( pg_database_size('keycloak') );"
```

##### DANGER DONT DO UNLESS YOU KNOW WHAT YOU ARE DOING
- Delete Postgres clusters
  - Note that deleting the operator from the infrastructure project will NOT delete postgres clusters.
  - For this example note that we have already deleted the postgres-operator from the infrastructure project.

  - Note that we still have two clusters running
  ```sh
  export PGO="--namespace postgres-operator"
  k get all $PGO
  NAME                      READY   STATUS    RESTARTS   AGE
  pod/pg-dev-0              1/1     Running   0          21m
  pod/pg-dev-1              1/1     Running   0          21m
  pod/postgres-cluster-0    1/1     Running   0          4m25s
  pod/postgres-cluster-1    1/1     Running   0          4m4s
  ```

  - Deleting the cluster manifests from the __deploy project__ deletes the cluster(s) and their data
  ```sh
  cd $GIT_HOME/postgres-cluster-deploy 
  kubectl delete -n postgres-operator --recursive -f ./manifests/development
  postgresql.acid.zalan.do "postgres-cluster" deleted
  namespace "postgres-operator" deleted
  ```

  - Validate the pg clusters termination is now in progress
  ```sh
  k get all $PGO
  NAME                      READY   STATUS        RESTARTS   AGE
  pod/pg-dev-0              0/1     Terminating   0          23m
  pod/pg-dev-1              0/1     Terminating   0          23m
  pod/postgres-cluster-0    1/1     Terminating   0          6m25s
  pod/postgres-cluster-1    1/1     Terminating   0          6m4s
  ```
  - after some time validate they are gone
  ```sh
  k get all $PGO
  No resources found.
  ```
  - check for any lingering pv and pvcs--and there are none.
  ```sh
  kubectl get pv,pvc --all-namespaces | grep postgres

  ```

  - For reference you __should__ see something like this for pv and pvcs for postgres
  ```sh
  k get pv,pvc $ALL | grep postgres
  persistentvolume/pvc-1e5755b3-8edd-11e9-b9a8-02341bb52eb2   100Gi      RWO            Delete           Bound    postgres-operator/pgdata-postgres-cluster-0                    gp2                     46s
  persistentvolume/pvc-29fa4c97-8edd-11e9-b9a8-02341bb52eb2   100Gi      RWO            Delete           Bound    postgres-operator/pgdata-postgres-cluster-1                    gp2                     19s
  
  postgres-operator   persistentvolumeclaim/pgdata-postgres-cluster-0                              Bound    pvc-1e5755b3-8edd-11e9-b9a8-02341bb52eb2   100Gi      RWO            gp2            47s
  postgres-operator   persistentvolumeclaim/pgdata-postgres-cluster-1                              Bound    pvc-29fa4c97-8edd-11e9-b9a8-02341bb52eb2   100Gi      RWO            gp2            27s
  ```

  - TODO: More testing needed here.  By default we configure the clusters to NOT delete their volumes.
