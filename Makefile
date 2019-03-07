# Makefile to build and use a Ubuntu docker container

LINUX_DISTRO		= ubuntu
LINUX_DISTRO_TAG	= 16.04

LINUX_IMAGE		= $(LINUX_TAG)-image
LINUX_TAG		= $(LINUX_DISTRO)-$(LINUX_DISTRO_TAG)
LINUX_CONTAINER		= $(LINUX_TAG)-container
LINUX_HOME		?= $(shell pwd)
DOCKER_BIN		?= $(Q)/usr/bin/docker
USER_ID			= $(shell id -u -n)
HOSTNAME		= docker-$(LINUX_TAG)

################################################################

c.build-image: # Build Linux container image
	$(eval docker_gid=$(shell getent group docker | cut -d: -f3))
	$(DOCKER_BIN) build --pull -f Dockerfile.$(LINUX_IMAGE) \
		--build-arg IMAGENAME=$(LINUX_DISTRO):$(LINUX_DISTRO_TAG) \
		--build-arg LINUX_HOME=$(LINUX_HOME) \
		--build-arg DOCKER_GID=$(docker_gid) \
		--build-arg USER_ID=$(USER_ID) \
		-t $(LINUX_IMAGE) .

c.create: # Create the container
	$(DOCKER_BIN) create -P --name=$(LINUX_CONTAINER) \
		-v $(LINUX_HOME):$(LINUX_HOME) \
		-h $(HOSTNAME) \
		-i $(LINUX_IMAGE)

c.start: # Start the container
	$(DOCKER_BIN) start $(LINUX_CONTAINER)

c.shell: # Start a shell in the container with my user
	$(DOCKER_BIN) exec -u $(USER_ID) -it $(LINUX_CONTAINER) /bin/bash
	
c.rootshell: # Start a shell as root in the container
	$(DOCKER_BIN) exec -u root -it $(LINUX_CONTAINER) /bin/bash

c.stop: # Stop the container
	$(DOCKER_BIN) stop $(LINUX_CONTAINER)

c.rm: # Remove the container
	$(DOCKER_BIN) rm $(LINUX_CONTAINER)

c.rmi: # Remove the Linux image
	$(DOCKER_BIN) rmi $(LINUX_IMAGE)
