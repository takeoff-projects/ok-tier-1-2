FROM golang:alpine

ENV GOOGLE_CLOUD_PROJECT=roi-takeoff-user61 \
CGO_ENABLED=0 \
GO111MODULE="on"

# Download dependenices
WORKDIR /app
COPY go.mod .
RUN go mod download all

#Copy all files
COPY . .

RUN go build -o main .

EXPOSE 8080

CMD ["/app/main"]