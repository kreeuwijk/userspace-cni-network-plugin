FROM ligato/vpp-base:23.02 as builder
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
COPY . /root/userspace-cni-network-plugin
WORKDIR /root/userspace-cni-network-plugin
RUN apt-get update -y 
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y binutils wget make git
RUN wget -qO- https://golang.org/dl/go1.20.1.linux-amd64.tar.gz | tar -C /usr/local -xz
ENV PATH="${PATH}:/usr/local/go/bin"
RUN go mod download
RUN go get go.fd.io/govpp/binapigen/vppapi@v0.7.0
RUN make generate
RUN go mod tidy
RUN make generate-bin
#End of builder container

# Copy build userspace cni bin to a small deployer container
FROM alpine:3.18
RUN mkdir -p /root/userspace-cni-network-plugin/userspace
COPY --from=builder /root/userspace-cni-network-plugin/userspace/userspace /root/userspace-cni-network-plugin/userspace/userspace
CMD ["cp", "-rf", "/root/userspace-cni-network-plugin/userspace/userspace", "/opt/cni/bin"]
