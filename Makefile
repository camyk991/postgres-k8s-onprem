.PHONY: all

all:
	./backup-storage/setup.sh
	set -a && . backup-storage/.env && set +a && \
	kubectl create namespace database --dry-run=client -o yaml | kubectl apply -f - && \
	kubectl create secret generic garage-s3 -n database \
	  --from-literal=ACCESS_KEY_ID=$$GARAGE_DEFAULT_ACCESS_KEY \
	  --from-literal=ACCESS_SECRET_KEY=$$GARAGE_DEFAULT_SECRET_KEY \
	  --from-literal=REGION=garage \
	  --dry-run=client -o yaml | kubectl apply -f -
	kubectl get secret pg-backup-user -n database >/dev/null 2>&1 || \
	kubectl create secret generic pg-backup-user -n database \
	  --type=kubernetes.io/basic-auth \
	  --from-literal=username=backup \
	  --from-literal=password=$$(openssl rand -hex 16)
	helmfile apply --skip-diff-on-install 
