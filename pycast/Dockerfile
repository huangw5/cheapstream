FROM python:rc-alpine

RUN apk update && \
    apk add --no-cache gcc linux-headers libc-dev && \
    pip install pychromecast && \
    apk del gcc linux-headers libc-dev

WORKDIR /pycast
COPY cast.py /pycast/
CMD ["sh", "-c", "python /pycast/cast.py ${URL} \"${DEVICE}\" ${TYPE}"]
