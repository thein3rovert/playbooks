-Creating a namespace
Kubectl create namespace <namespace-name>

- When using yaml or deploying through yaml
  kubectl apply -f <namespacefile-name.yaml>

- Deleting a namespace
  kubectl delete namespace <namespace-name>
  kubectl delete -f <namespace-name.yaml>
