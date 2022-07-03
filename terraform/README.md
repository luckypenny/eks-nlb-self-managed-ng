# EKS (Self Managed Node Gorup, ECR, VPC) with Terraform
테라폼을 사용하여 EKS, ECR, VPC, 비관리 노드 그룹 환경을 생성합니다.

### Create AWS Componentes for EKS service
```
$ terraform init
$ terraform plan
$ terraform apply
```

### Create or update a kubeconfig file for your cluster.
```
$ aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name) --alias $(terraform output -raw cluster_name)
$ aws eks --region ap-northeast-2 update-kubeconfig --name eks-dev-cluster --alias eks-dev-cluster
```

# Python-flask-docker
Basic Python Flask app in Docker which prints the hostname and IP of the container
ref) https://github.com/lvthillo/python-flask-docker.git

### Build application
Build the Docker image manually
```
$ docker build -t flask-app .
```

### Run the container
Create a container from the image.
```
$ docker run -p 8080:8080 flask-app
```

Now visit http://localhost:8080
```
 The hostname of the container is 6095273a4e9b and its IP is 172.17.0.2. 
```

### Push Docker Images to ECR
Set up image tags and deploy to ECR.
```
$ aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin 074017796595.dkr.ecr.ap-northeast-2.amazonaws.com
$ docker tag flask-app:latest 074017796595.dkr.ecr.ap-northeast-2.amazonaws.com/flask-app:latest
$ docker push 074017796595.dkr.ecr.ap-northeast-2.amazonaws.com/flask-app:latest
```

### Create Apps (Deployments, Service)
```
$ kubectl apply -f k8s-flask-app.yaml
```

### Create Nginx-ingress controller
공식 지원 사이트에서 nlb용 파일을 다운받아 사용했습니다.
```commandline
$ wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.2.1/deploy/static/provider/aws/deploy.yaml
$ mv deploy nginx-ingress-nlb-deploy.yaml
$ kubectl apply -f nginx-ingress-nlb-deploy.yaml
```

### Create Ingress 
```commandline
$ kubectl apply -f app-ingress.yaml
$ kubectl get ingress 
NAME          CLASS   HOSTS   ADDRESS                                                                              PORTS   AGE
app-ingress   nginx   *       aa1b3edf26f7a4d05bb14fc135d0f432-7c3594706ebfe73a.elb.ap-northeast-2.amazonaws.com   80      42s
```