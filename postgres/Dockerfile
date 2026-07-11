FROM postgres:15-alpine
RUN apk add --no-cache aws-cli jq bash
COPY init-secrets.sh /usr/local/bin/init-secrets.sh
RUN chmod +x /usr/local/bin/init-secrets.sh
ENTRYPOINT ["/usr/local/bin/init-secrets.sh"]

