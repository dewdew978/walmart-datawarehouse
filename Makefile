.PHONY: up down down-v restart ps dbt-debug dbt-run dbt-test dbt-docs dbt-serve

up:
	docker compose up -d

down:
	docker compose down

down-v:
	docker compose down -v

restart:
	docker compose restart

ps:
	docker compose ps

dbt-debug:
	docker exec -it wmt_dbt bash -c "cd walmart_dw && dbt debug"

dbt-run:
	docker exec -it wmt_dbt bash -c "cd walmart_dw && dbt run"

dbt-test:
	docker exec -it wmt_dbt bash -c "cd walmart_dw && dbt test"

dbt-docs:
	docker exec -it wmt_dbt bash -c "cd walmart_dw && dbt docs generate"

dbt-serve:
	docker exec -it wmt_dbt bash -c "cd walmart_dw && dbt docs serve --port 8080"
