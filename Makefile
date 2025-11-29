.PHONY: build run-open run-hardened collect clean

build:
	@echo "Building image..."
	docker build -t project13:1.0.0 -f docker/Dockerfile .

run-open:
	./scripts/docker-run-open.sh

run-hardened:
	./scripts/docker-run-hardened.sh

collect:
	./scripts/collect-results.sh

clean:
	-docker rm -f project13_open project13_hardened || true
	-docker rmi project13:1.0.0 || true
	rm -rf reports/*
