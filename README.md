# FACEIT challenge

## Architecture

For this challenge the technologies used are `AWS` as a cloud provider and `EKS` as a platform to deploy all required services.

The diagram that follows is a 10000 foot view of what is/meant to be used.

![architecture](./img/faceit_assignment.png)

The challenge focuses on a few areas which will be briefly touched in this section but they will be explained in detail below:

There are 3 components in play AWS, Kubernets (EKS) and Github.

### AWS

On the AWS side we have an `S3` bucket that will contain the terraform state file for the rest of the infrastructure. For the purposes of this challenge, we assume that this bucket is created via Cloudformation. The terraform code will create an `EKS` cluster which will be our platform to run the `test-app` service, an `postgres RDS` database that will be used by `test-app` as a target. `SSM Parameter Store` will be used to store the secrets (endpoint, dbname, username, password) of the `RDS` so we can securely pass them into `test-app`.

### Kubernetes

On the Kubernetes side we have a few that are required to properly run the cluster. Starting with the basic services `aws-node` will take care of the networking in the cluster. `coredns` is the DNS service for the cluster and `kube-proxy` to take care of the network rules. We also have the `metrics-server` that we use to retrieve metrics for our services.

Moving on to our monitoring stack, we have `prometheus` and `alertmanager` to scrape metrics and alert for imminent problems and `grafana` to visualise our metrics.

`cluster-autoscaler` is used to autoscale the node groups based on the load of the cluster. The service needs to speak to the AWS API and for that purpose I have implemented IRSA in the cluster, which can directly assign AWS IAM roles with Kubernetes pods, giving permissions to use AWS service like EC2 for the autoscaling groups. These permissions can only be used by the pod itself without even the node, on which `cluster-autoscaler` is running, being able to speak to the EC2 API. IRSA tigthens security on nodes and pods so even if a node is compromised, the attacker will be limited to what they can do.

As with `cluster-autoscaler` , every service that needs to speak with the AWS API is integrated with `IRSA`.

`external-dns` is a service that will continuously watch over `Ingress/Service` creation and will create the appropriate route53 records if the resources are of type `LoadBalancer`. (external-dns is not included in the code)

On the topic of load balancers, we also install `aws-loadbalancer-controller`. This service will watch over `Ingress` objects and create a correspoinding load balancer in AWS when the `Ingress type` is of `LoadBalancer`.

`flux` is a GitOps solution that makes it easy to deploy Kubernetes objects in the cluster. It's the tool that we use to deploy new versions of the `test-app` service.

`external-secrets-operator` or `ESO` is the service that we use to fetch the `RDS` information from `Parameter Store`. It can be integrated with the most popular secret management solutions from the major cloud providers, plus `hashicorp Vault`.

Last but not least, we have the `test-app` service which holds the code of our application.

### Github

On the Github side we have 3 repositories and each repository serves one function.

The `infrastructure` repository is where our terraform code exists. Ideally we would also have a `github action` to implement `CI/CD`.

The `application` repository is where the `test-app` code exists. There is also a `github action` to create the container image.

The `kubernetes-manifest` repository is where we keep our kubernetes manifests. The `deployment` object for `test-app` and the `ExternalSecrets` that are fetching the `RDS` secrets from `Parameter Store`.

We also make use of the `Github` container registry to save the container image. `application` repository's `github action` pushes the newly created image in the registry.


## Infrastructure creation

The infrastructure creation is pretty straight forward. `terraform` is used to create the infrastructure for  `VPC` and `subnets`,` EKS`, `RDS` and `Parameter Store` secrets. `IAM roles` will also be created so our services can have access to the `AWS API`. We also have an `S3` that stores the terraform state file. The `S3` as mentioned above is assumed to be created by Cloudformation.

![infrastructure_creation](./img/faceit_infrastructure_creation.png)

## Autoscaling and high availability

This section focuses on two distinct case that keeps a service up and running.

![autoscaling](./img/faceit_autoscaling_and_high_availability.png)

The first case has to do with `autoscaling`. `test-app` has a `HorizontalPodAutoscaler` or `HPA`, that monitors the `CPU` utilization of the existing pods. If the utilization goes over the threshold, a deployment will scale up to more pods to account for the increased load. If the load starts decreasing, and the number of Pods is above the configured minimum, a scale down will begin. If more nodes exist and the affinities are set appropriately, the new `test-app` pods will be scheduled in the available nodes.

In the event that there are no more nodes available but `test-app` still wants to scale up, `cluster-autoscaler` will figure out that there are pods that are waiting to be scheduled and it will scale up the node group to get more nodes. This might take some time until the nodes are `Ready` to accept pods, so to mitigate this problem, we can make use of the `overprovision` service which will always keep extra capacity of nodes of, in case of a sudden spike in traffic. `overprovision` is not included in the challenge but it's worth to mention it as a mitigation solution.

The second case has to do with `high availability` and it has to do with user-initiated disruption of service, `draining` for example. Draining of the nodes might be initiated for various reasons by the cluster administrator, two notables are `cluster upgrades` and `node rotations` to cover newly found CVEs. The way that the `PDB` is setup is that the maximum unavailable instances of a service should be 1 at any given time. If there is already one pod that is `not ready` to recieve traffic, Kubernetes will respect the `PDB` and will pause the draining. This way we guarantee that `test-app` will be running at all times even during a cluster upgrade.

This case assumes that `test-app` is able to run multiple pods at the same time. If the service does not support multiple pods at the same time and only one pod needs to be running, the service will definitely have an outage during drainings.

## DB secret injection

`test-app` requires information so it can connect to `postgres` and ping the database. These information **must** not be hardcoded in the code for obvious reasons. It also prohibited to be in any kind of configuration file. For this reason we have the `ESO` in the cluster.

![secret_injection](./img/faceit_db_secret_injection.png)

`ESO` is in charge of speaking with the `Parameter Store` API and securely retrieving the information needed to connect to the `RDS`.

`ESO` has two resources, `SecretStore` which is used to communicate with the secret management solution, `Parameter Store` in our case, which is done through `IRSA` - again, no credentials are visible in any configuration file - and `ExternalSecret` which uses `SecretStore` as a connection point, retrieves the secrets from `Parameter Store` and creates `Kubernetes Secrets` with the values from `Parameter Store`. These secrets are read as an environment variable in the `test-app deployement` and the pod can eventually reach the `RDS`.

## CI/CD and zero downtime service update

We want out application to have a robust deployment mechanism, so that we can push changes frequenlty but on the same time we dont want to have any downtime in order to push a new version of `test-app`.

There are two repositories that make this work and on Kubernetes `flux` is the service that guarantees us continuous deployment.

![ci_cd](./img/faceit_ci_cd_and_zero_downtime_service_update.png)

On Github we have the repository on which `test-app` is being developed. This repository also has integrated CI with `github actions`, who will run the suite for our application and make sure that nothing broke in the latest release. Once the CI is successful, the code has been merged into the `main` branch, the github action will cut a release and tag it with a version. A second github action sees the new release and creates a container image and sends the image into the Github container regitstry. We now have a fresh new version of our application ready to be used in our cluster.

The last step is to update the Kubernetes manifest for the deployment with the new version of `test-app`. Once this is in the `main` branch, `flux` will pull it and apply it in the cluster to compelete the CD.

On important thing to note here, is that the `test-app`'s deployment has a strategy of `rollingUpdate`. Kubebernetes will first spin up a new replica set with the new version of the application, make sure that it is ready to receive traffic and then scale down the old replica set, thus making sure that traffic has been served at all times.

## Endpoint creation

For easier and production grade access to the `test-app` pods need a common endpoint so a user can reach the service without the need to remember IPs and ports. For that reason we have a combination of a `Service` and an `Ingress` object. The `Service` sit atop all the `test-app` pods while the `Ingress` which is of type `LoadBalancer` points to `Service`.

![endpoint_creation](./img/faceit_endpoint_creation.png)

When the `Ingress` object is created, two services pick up this event. The `aws-loadbalancer-controller` checks if the `Ingress` object is a `LoadBalancer` and if it is, it will create an `application load balancer in AWS` that will eventually redirect traffic to `test-app` pods.

`external-dns` will also pick up the `Ingress` creation and if it is a `LoadBalancer`, it will create a Route53 record based on the `external-dns.alpha.kubernetes.io/hostname` annotation value (if and only if the annotation exists). It will also pass the load balancer's hostname to the newly created record.

So now the `test-app` application is assigned an endpoint and can be reached from the internet, if you wish to make it public.


## Miscellany

Not all services mentioned in this README have been implmented in the solution for the sake of brevity. Below I have a list with services that made it into the challenge

#### AWS

:white_check_mark: VPC/subnets

:white_check_mark: IAM roles

:white_check_mark: EKS

:white_check_mark: RDS

:x: S3

:x: Route53


#### Kubernetes


:white_check_mark: amazon-vpc-cni (aws-node)

:white_check_mark: coredns

:white_check_mark: kube-proxy

:white_check_mark: external secrets operator

:white_check_mark: flux2

:white_check_mark: cluster-autoscaler

:white_check_mark: metrics-server

:warning: prometheus stack (prometheus + alertmanager + grafana) - implemented but not configured

:x: external-dns

:x: overprovision

#### Github

:white_check_mark: Infrastructure repo

:white_check_mark: Kubernetes manifest repo

:white_check_mark: Application repo with a Dockerfile

:white_check_mark: Github action to create the container image and send it to `ghcr.io`

:x: Github action to run terraform

:x: Github action for testing and cutting releases

#### Diagram link

You can find all diagrams here => [excalidraw.io](https://excalidraw.com/#json=TLw4K9WUw51Noo9xItJAi,dm9_ZAcOEkd8wBiOO7JHew)
