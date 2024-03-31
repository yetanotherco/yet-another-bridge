.PHONE: deps run create_env create_python_venv start_db stop_db create_db

# Database variables
container = mm-bot
user = user
password = 123123123
database = mm-bot-db


# Application Commands
deps:
    @echo "Installing dependencies..."
    @. venv/bin/activate && pip install -r requirements.txt
    @echo "Dependencies installed successfully!"

run:
	@echo "Running application..."
	@. venv/bin/activate && python3 src/main.py

create_env:
	@echo "Creating environment variables files .env",
	@cp .env.example .env
	@echo "Environment variables files created successfully!"

create_python_venv:
	@echo "Creating virtual environment..."
	@python3 -m venv venv
	@echo "Virtual environment created successfully!"

# Database Commands
start_db:
	@if [ "$(container)" = "mm-bot" ]; then echo "Using default container name: mm-bot."; fi
	docker start $(container)

stop_db:
	@if [ "$(container)" = "mm-bot" ]; then echo "Using default container name: mm-bot."; fi
	docker stop $(container)

create_db:
	@if [ "$(container)" = "mm-bot" ]; then echo "Using default container name: 'mm-bot'."; fi
	@if [ "$(user)" = "user" ]; then echo "Using default user name: 'user'."; fi
	@if [ "$(password)" = "123123123" ]; then echo "Using default password: '123123123'."; fi
	@if [ "$(database)" = "mm-bot-db" ]; then echo "Using default database name: 'mm-bot-db'."; fi

	docker run --name $(container) -e POSTGRES_PASSWORD=$(password) -e POSTGRES_USER=$(user) -p 5432:5432 -d postgres
	sleep 5  # Wait for the PostgreSQL container to start (you can adjust this as needed)
	docker exec -it $(container) psql -U $(user) -c 'CREATE DATABASE "$(database)" WITH ENCODING "UTF-8";'
