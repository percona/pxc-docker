#!/bin/bash



# Not using mktemp -d here since fig doesn't work with capital letter basenames.
branch="$1"

if [[ -z $branch ]];then 
    echo "Please provide branch as first argument"
    echo "Using  5.6 as default"
    branch="5.6"
    echo 
    echo
fi



numcp=$(grep -c processor /proc/cpuinfo)
numcp=$(( numcp-1 ))





echo "
FROM centos:centos7
MAINTAINER Raghavendra Prabhu raghavendra.prabhu@percona.com
RUN curl -s http://jenkins.percona.com/yum-repo/percona-dev.repo > /etc/yum.repos.d/percona-dev.repo
RUN yum install -y http://epel.check-update.co.uk/7/x86_64/e/epel-release-7-9.noarch.rpm
RUN yum install -y http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm
RUN yum install -y which lsof libaio compat-readline5 socat percona-xtrabackup perl-DBD-MySQL perl-DBI rsync openssl098e eatmydata pv qpress gzip openssl
RUN yum install -y bzr automake gcc  make  libtool autoconf pkgconfig gettext git scons    boost_req boost-devel libaio openssl-devel  check-devel gdb perf
RUN yum install -y gcc-c++ gperf ncurses-devel perl readline-devel time zlib-devel libaio-devel bison cmake 
RUN yum install -y coreutils grep procps 
RUN git clone --depth=1 -b $branch http://github.com/percona/percona-xtradb-cluster
WORKDIR /percona-xtradb-cluster
RUN cmake -DBUILD_CONFIG=mysql_release -DDEBUG_EXTNAME=OFF -DWITH_ZLIB=system  -DWITH_SSL=system -DCMAKE_INSTALL_PREFIX="/usr"   .
RUN make -j$numcp
RUN make install
WORKDIR /
RUN git clone --depth=1 https://github.com/percona/galera
WORKDIR /galera
RUN scons -j$numcp --config=force  libgalera_smm.so
RUN install libgalera_smm.so /usr/lib64/
WORKDIR /
ADD node.cnf /etc/my.cnf
RUN groupadd -r mysql
RUN useradd -M -r -d /var/lib/mysql -s /bin/bash -c \"MySQL server\" -g mysql mysql
EXPOSE 3306 4567 4568
RUN /usr/scripts/mysql_install_db --basedir=/usr --user=mysql
CMD  /usr/bin/mysqld --basedir=/usr --wsrep-new-cluster --user=mysql --core-file --skip-grant-tables --wsrep-sst-method=rsync

" > Dockerfile 

echo "Use:> docker-compose scale bootstrap=1 members=2 for a 3 node cluster!"


