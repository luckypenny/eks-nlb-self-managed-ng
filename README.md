# 0. Directory 및 전체 구조
### apps : python flask app code
### k8s : ingress controller, ingress, app deployment & service k8s code 
### terraform : vpc, eks, ecr terraform code

<img width="921" alt="eks-nlb-arch" src="https://user-images.githubusercontent.com/14371339/177030630-66e7537e-018e-41f7-8504-556bafa238ae.png">

# 1. Terraform으로 인프라 생성
테라폼을 사용하여 EKS, ECR, VPC, 자체 관리 노드 그룹 환경을 생성합니다. (공식 모듈 샘플을 참조)

컨트롤 플레인 로깅 기본값 적용 Default: [ "audit", "api", "authenticator" ]

클라우드 와치 로깅 리텐션은 기본값 90일 입니다.

셀프 매니지드 노드 그룹 (apps_node_group) 생성 되며 3대 기본 생성 합니다. 

ref) https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest

### Create AWS Componentes for EKS service
```
$ cd terraform
$ terraform init
$ terraform plan
$ terraform apply
```

### Create or update a kubeconfig file for your cluster.
```
$ aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name) --alias $(terraform output -raw cluster_name)
$ aws eks --region ap-northeast-2 update-kubeconfig --name eks-dev-cluster --alias eks-dev-cluster
```

# 2. Python-flask 앱 빌드 및 ECR 푸시
Basic Python Flask app in Docker which prints the hostname and IP of the container

아래 깃헙 소스를 참조 했고 용량을 줄이기 위해 도커 이미지를 작은것으로 수정 했습니다. 

ref) https://github.com/lvthillo/python-flask-docker.git

### Build application
Build the Docker image manually
```
$ cd ../apps
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

# 3. Create k8s Apps (Deployments, Service)
```
$ cd ../k8s
$ kubectl apply -f k8s-flask-app.yaml
$ kubectl get pod,svc
pod/flask-app-cddb57d58-6vvtg   1/1     Running   0          5s
pod/flask-app-cddb57d58-g7k9r   1/1     Running   0          5s
pod/flask-app-cddb57d58-n7hrp   1/1     Running   0          5s

NAME                        TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/flask-app-service   ClusterIP   172.20.227.209   <none>        8080/TCP   5s
service/kubernetes          ClusterIP   172.20.0.1       <none>        443/TCP    9m20s

```

# 4. Create Nginx-ingress controller, Ingress 생성 하기
공식 지원 사이트에서 nlb용 파일을 다운받아 사용했습니다.

ref) https://kubernetes.github.io/ingress-nginx/deploy/#local-testing
### nlb ingress controller
```commandline
$ #wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.2.1/deploy/static/provider/aws/deploy.yaml
$ #mv deploy nginx-ingress-nlb-deploy.yaml
$ kubectl apply -f nginx-ingress-nlb-deploy.yaml
$ kubectl -n ingress-nginx get pod
NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-s754d        0/1     Completed   0          32s
ingress-nginx-admission-patch-x8z7h         0/1     Completed   1          32s
ingress-nginx-controller-6648b5dbb8-zp46n   1/1     Running     0          32s
```

### Create Ingress 
```commandline
$ kubectl apply -f app-ingress.yaml
$ kubectl get ingress 
NAME          CLASS   HOSTS   ADDRESS                                                                              PORTS   AGE
app-ingress   nginx   *       aa1b3edf26f7a4d05bb14fc135d0f432-7c3594706ebfe73a.elb.ap-northeast-2.amazonaws.com   80      42s

# 생성된 NLB 상태 확인
$ aws elbv2 describe-load-balancers --load-balancer-arns arn:aws:elasticloadbalancing:ap-northeast-2:074017796595:loadbalancer/net/a39bc95f0b995480a9e613e9809f9427/57085e57e28f034c | grep -i state -A2
            "State": {
                "Code": "active"
            },
$ curl a39bc95f0b995480a9e613e9809f9427-57085e57e28f034c.elb.ap-northeast-2.amazonaws.com
```

# ToDo
- 환경 추가를 위해서 디렉토리 구조 변경
- 공동 작업을 위해서 테라폼 백앤드 사용하기
- 테라폼 중복된 코드 줄이기 ( terragrunt )
- k8s app 유연성 확보 위해 kustomze 사용
- External DNS 설정
- 인그레스 컨트롤러 헬름 차트로 변경