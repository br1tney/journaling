# build vue frontend
FROM node:18-alpine3.19 as build-vue
WORKDIR /app
ENV PATH /app/node_modules/.bin:$PATH
COPY ./client/package*.json ./client/.npmrc ./
RUN npm config set update-notifier false && \
    npm update -g npm && npm ci --no-audit --maxsockets 1
COPY ./client .
# Add AWS SDK for frontend AWS integration
RUN npm install aws-amplify @aws-amplify/ui-react
RUN npm run build

# python packages with AWS SDK
FROM python:3-alpine as builder
WORKDIR /app
RUN apk update && apk add --no-cache python3 && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
    rm -r /root/.cache
COPY ./server/requirements.txt ./
# Add AWS SDK to requirements or install here
RUN echo "boto3==1.34.84" >> requirements.txt && \
    echo "botocore==1.34.84" >> requirements.txt
RUN apk update && apk add --no-cache gcc musl-dev libressl-dev libffi-dev python3-dev && \
    pip install --user -r requirements.txt && \
    pip install --user gunicorn

# production
FROM python:3-alpine as production
WORKDIR /app
COPY --from=build-vue /app/dist /usr/share/nginx/html
RUN apk update && apk add --no-cache nginx && \
    addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

# Copy nginx configs (we'll modify these)
COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf
COPY ./nginx/nginx.conf /etc/nginx/nginx.conf

COPY --from=builder /root/.local/ /root/.local/
ENV PATH=/root/.local/bin:$PATH
COPY ./server .

# Create health check endpoint in nginx config
RUN echo 'location /health { access_log off; return 200 "healthy\n"; add_header Content-Type text/plain; }' >> /etc/nginx/conf.d/default.conf

# Fixed port for ALB (no dynamic PORT substitution)
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Modified startup command for ECS
CMD gunicorn -b 127.0.0.1:5000 'dailytxt.application:create_app()' --daemon && \
    nginx -g 'daemon off;'
