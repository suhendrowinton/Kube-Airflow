echo 'Setting up minikube ...'
sudo minikube start --vm-driver=none
echo '------- Running kubectl apply -f airflow-secrets.yaml -------'
sudo kubectl apply -f rbac_rule.yaml
sudo kubectl apply -f airflow-secret.yaml
sleep 5
echo '------- Running kubectl get secret airflow-secrets -------'
sudo kubectl describe secret airflow-secrets
sudo kubectl apply -f volumes.yaml
echo '------- Running kubectl get pv -------'
sudo kubectl get pv
echo '------- Running kubectl get pvc -------'
sudo kubectl get pvc
sudo kubectl apply -f postgres-deployment.yaml
sudo kubectl apply -f webserver-deployment.yaml
sudo kubectl apply -f scheduler-deployment.yaml
# wait for up to 10 minutes for everything to be deployed
PODS_ARE_READY=0
for i in {1..150}
do
  echo "------- Running kubectl get pods -------"
  PODS=$(sudo kubectl get pods | awk 'NR>1 {print $0}')
  echo "$PODS"
  NUM_AIRFLOW_WEBSERVER_READY=$(echo $PODS | grep airflow-webserver | awk '{print $2}' | grep -E '([0-9])\/(\1)' | wc -l | xargs)
  NUM_AIRFLOW_SCHEDULER_READY=$(echo $PODS | grep airflow-scheduler | awk '{print $2}' | grep -E '([0-9])\/(\1)' | wc -l | xargs)
  NUM_POSTGRES_READY=$(echo $PODS | grep postgres | awk '{print $2}' | grep -E '([0-9])\/(\1)' | wc -l | xargs)
  if [ "$NUM_AIRFLOW_WEBSERVER_READY" == "1" ] && [ "$NUM_AIRFLOW_SCHEDULER_READY" == "1" ] && [ "$NUM_POSTGRES_READY" == "1" ]; then
    PODS_ARE_READY=1
    break
  fi
  sleep 4
done
POD=$(sudo kubectl get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep airflow | head -1)

if [[ "$PODS_ARE_READY" == 1 ]]; then
  echo "PODS are ready."
else
  echo "PODS are not ready after waiting for a long time. Exiting..."
  exit 1
fi
webserver=$(sudo kubectl get pods -l=name=airflow-webserver | tail -1 | cut -d ' ' -f 1)
sudo kubectl cp k8s_executor_example.py default/$webserver:/usr/local/airflow/dags