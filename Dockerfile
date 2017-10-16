FROM manageiq/ruby:latest

# gcc-c++ for unf_ext gem
# git for git based gems
# postgresql-devel for pg gem (required by manageiq-gems-pending)
RUN yum -y install --setopt=tsflags=nodocs gcc-c++ git postgresql-devel && \
    yum clean all

COPY docker-assets/* /opt/manageiq/amazon-smartstate
WORKDIR /opt/manageiq/amazon-smartstate

RUN gem install bundler && \
    bundle update

CMD bundle exec amazon_ssa_agent
