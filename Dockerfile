FROM alpine
RUN   sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g'  /etc/apk/repositories && apk update && apk add --no-cache ca-certificates
ADD ./certs /certs
ADD ./bin/repimage /repimage