# ref: https://github.com/zalando/postgres-operator/blob/v1.1.0/manifests/complete-postgres-manifest.yaml
apiVersion: __POSTGRES_API_VERSION__
kind: postgresql

metadata:
  name: __POSTGRES_CLUSTER_NAME__
  namespace: __POSTGRES_CLUSTER_NAMESPACE__
spec:
  init_containers:
  - name: date
    image: busybox
    command: [ "/bin/date" ]
  teamId: __POSTGRES_TEAMID__
  volume:
    size: __POSTGRES_VOLUME_SIZE__
  numberOfInstances: __POSTGRES_NUMBER_OF_INSTANCES__
  users: #Application/Robot users
    root:
    - __POSTGRES_APPLICATION_USERS_ROOT_ONE__
    - __POSTGRES_APPLICATION_USERS_ROOT_TWO__
  enableMasterLoadBalancer: __POSTGRES_ENABLE_MASTER_LOADBALANCER__
  enableReplicaLoadBalancer: __POSTGRES_ENABLE_REPLICA_LOADBALANCER__
  allowedSourceRanges: # load balancers' source ranges for both master and replica services
  #- 10.1.0.0/14      # AWS us-west-1 & us-west-2
  #- 172.30.0.0/15    # pritunl IP access
  #- 1.2.3.4/32 # devops-admin
  - __POSTGRES_ALLOWED_SOURCE_RANGE1__
  - __POSTGRES_ALLOWED_SOURCE_RANGE2__
  - __POSTGRES_ALLOWED_SOURCE_RANGE3__
  databases:
    __POSTGRES_DATABASES1_NAME__: __POSTGRES_DATABASES1_USER__
    __POSTGRES_DATABASES2_NAME__: __POSTGRES_DATABASES2_USER__
    __POSTGRES_DATABASES3_NAME__: __POSTGRES_DATABASES3_USER__
#Expert section
  enableShmVolume: __POSTGRES_ENABLE_SHM_VOLUME__
  postgresql:
    version: __POSTGRES_VERSION__
    parameters:
      shared_buffers: __POSTGRES_SHARED_BUFFERS__
      max_connections: __POSTGRES_MAX_CONNECTIONS__
      log_statement: __POSTGRES_LOG_STATEMENT__
      # refer to kube docs: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container
      #resources:
      #  requests:
      #    cpu: __POSTGRES_RESOURCES_REQUESTS_CPU__
      #    memory: __POSTGRES_RESOURCES_REQUESTS_MEMORY__
      #  limits:
      #    cpu: __POSTGRES_RESOURCES_LIMITS_CPU__
      #    memory: __POSTGRES_RESOURCES_LIMITS_MEMORY__
  patroni:
    initdb:
      encoding: "UTF8"
      locale: "en_US.C"
      data-checksums: "true"
    pg_hba:
    - __POSTGRES_PATRONI_PG_HBA_HOSTSSL__
    - __POSTGRES_PATRONI_PG_HBA_HOST__
    ttl: __POSTGRES_PATRONI_TTL__
    loop_wait: __POSTGRES_PATRONI_LOOP_WAIT__
    retry_timeout: __POSTGRES_PATRONI_RETRY_TIMEOUT__
    maximum_lag_on_failover: __POSTGRES_PATRONI_MAXIMUM_LAG_ON_FAILOVER__
  maintenanceWindows:
  - __POSTGRES_MAINT_WINDOWS__
