# Makefile to build and use a Ubuntu docker container

LINUX_DISTRO		= ubuntu
LINUX_DISTRO_TAG	= 18.04

LINUX_IMAGE		= $(LINUX_TAG)-image
LINUX_TAG		= $(LINUX_DISTRO)-$(LINUX_DISTRO_TAG)
LINUX_CONTAINER_NAME	= wrl-mirror-updater
MIRROR_PATH		= /home/beni/hdd1
PODMAN_BIN		= $(shell which podman)
USER_ID			= $(shell id -u -n)
HOSTNAME		= podman-$(LINUX_CONTAINER_NAME)

################################################################

c.build-image: # Build container image from Dockerfile (this is done once per machine/repo)
	$(PODMAN_BIN) build --pull -f Dockerfile.$(LINUX_IMAGE) \
		--build-arg IMAGENAME=$(LINUX_DISTRO):$(LINUX_DISTRO_TAG) \
		--build-arg MIRROR_PATH=$(MIRROR_PATH) \
		--build-arg USER_ID=$(USER_ID) \
		--build-arg WR_PWD=$(WR_PWD) \
		-t $(LINUX_IMAGE) .

c.create: # Create the container from image
	$(PODMAN_BIN) create -P --name=$(LINUX_CONTAINER_NAME) \
		-v $(MIRROR_PATH):$(MIRROR_PATH) \
		-h $(HOSTNAME) \
		-i $(LINUX_IMAGE)

c.start: # Start the container
	$(PODMAN_BIN) start $(LINUX_CONTAINER_NAME)

c.shell: # Start a shell in the container with my user
	$(PODMAN_BIN) exec -u $(USER_ID) -it $(LINUX_CONTAINER_NAME) /bin/bash
	
c.rootshell: # Start a shell as root in the container
	$(PODMAN_BIN) exec -u root -it $(LINUX_CONTAINER_NAME) /bin/bash

c.stop: # Stop the container
	$(PODMAN_BIN) stop $(LINUX_CONTAINER_NAME)

c.rm: # Remove the container
	$(PODMAN_BIN) rm $(LINUX_CONTAINER_NAME)

c.rmi: # Remove the Linux image
	$(PODMAN_BIN) rmi $(LINUX_IMAGE_NAME)
