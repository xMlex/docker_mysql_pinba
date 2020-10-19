# MySQL 5.6.45 Docker with pinba_engine plugin v1.2

see: https://github.com/tony2001/pinba_engine

## Build image:
```
docker build -t xmlex/pinba-v1 .
```

## Run:
```
docker run -d -p 30002:30002/udp -p 3306:3306/tcp -e "MYSQL_ROOT_PASSWORD=123456" --name pinbav1 --restart always -v pinbav1_data:/opt/mysql/data xmlex/pinba-v1
```
