plan:
	./tf-plan.sh

deploy:
	./tf-apply.sh
	./sls-deploy.sh

destroy:
	./tf-destroy.sh
	./sls-remove.sh