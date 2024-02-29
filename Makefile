BUILDTIME ?= $(shell date +%Y-%m-%d_%I:%M:%S)
GITCOMMIT ?= $(shell git rev-parse -q HEAD)
VERSION ?= $(shell git describe --tags --always  --dirty)
TAG ?= $(shell date +%Y%m%d-%H%M%S)
REGISTRY ?= registry.cn-beijing.aliyuncs.com
NAMESPACE ?= laoq
BINARYNAME ?= repimage

LDFLAGS = -extldflags \
		  -static \
		  -X "main.Version=$(VERSION)" \
		  -X "main.BuildTime=$(BUILDTIME)" \
		  -X "main.GitCommit=$(GITCOMMIT)" \
		  -X "main.BuildNumber=$(BUILDNUMER)"
export GO111MODULE=on
export GOPROXY=https://goproxy.cn

clean:
	rm -rf bin/
build:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0  go build -ldflags '${LDFLAGS}' -o bin/$(BINARYNAME)
docker-image :
	docker build -t $(REGISTRY)/$(NAMESPACE)/$(BINARYNAME):$(TAG) .
push:
	docker build -t  $(REGISTRY)/$(NAMESPACE)/$(BINARYNAME):$(TAG) .
	docker push $(REGISTRY)/$(NAMESPACE)/$(BINARYNAME):$(TAG)
containerd-image:
	nerdctl build -t $(BINARYNAME):$(TAG) .
	nerdctl tag $(BINARYNAME):$(TAG) $(REGISTRY)/$(NAMESPACE)/$(BINARYNAME):$(TAG)
	nerdctl push $(REGISTRY)/$(NAMESPACE)/$(BINARYNAME):$(TAG)
