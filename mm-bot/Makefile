# Database variables
container = postgres
user = user
password = 123123123
database = mm-bot


# Application Commands
run:
	@echo "Running application..."
	@. venv/bin/activate && python3 main.py

create_env:
	@echo "Creating environment variables files .env",
	@cp .env.example .env
	@echo "Environment variables files created successfully!"

# Database Commands
start_db:
	@if [ "$(container)" = "postgres" ]; then echo "Using default container name: postgres."; fi
	docker start $(container)

stop_db:
	@if [ "$(container)" = "postgres" ]; then echo "Using default container name: postgres."; fi
	docker stop $(container)

create_db:
	@if [ "$(container)" = "postgres" ]; then echo "Using default container name: 'postgres'."; fi
	@if [ "$(user)" = "user" ]; then echo "Using default user name: 'user'."; fi
	@if [ "$(password)" = "123123123" ]; then echo "Using default password: '123123123'."; fi
	@if [ "$(database)" = "mm-bot" ]; then echo "Using default database name: 'yas-api'."; fi

	docker run --name $(container) -e POSTGRES_PASSWORD=$(password) -e POSTGRES_USER=$(user) -p 5432:5432 -d postgres
	sleep 5  # Wait for the PostgreSQL container to start (you can adjust this as needed)
	docker exec -it $(container) psql -U $(user) -c 'CREATE DATABASE "$(database)" WITH ENCODING "UTF-8";'