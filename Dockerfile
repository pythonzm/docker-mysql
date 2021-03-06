FROM centos:7
ENV PACKAGE_URL https://repo.mysql.com/yum/mysql-5.7-community/docker/x86_64/mysql-community-server-minimal-5.7.18-1.el7.x86_64.rpm

# Install server
RUN rpmkeys --import https://repo.mysql.com/RPM-GPG-KEY-mysql \
  && yum install -y $PACKAGE_URL \
  && yum install -y libpwquality \
  && yum install -y iproute \
  && rm -rf /var/cache/yum/*

COPY my.cnf /etc/my.cnf

VOLUME /var/lib/mysql

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

#EXPOSE 33061 
CMD ["mysqld"]
