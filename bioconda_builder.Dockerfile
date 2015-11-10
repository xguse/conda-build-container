FROM centos:centos5

MAINTAINER Gus Dunn "gus.dunn@yale.edu"

# Setup home
ENV home=/home/builder
RUN yum install -y zsh tmux
RUN useradd builder -p '' -s /bin/zsh

# add tools useful for compilation
RUN rpm -Uvh http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
RUN yum install -y wget bzip2 bzip2-devel git gcc gcc-c++ patch zlib-devel make gcc44 gcc44-c++ cmake ncurses-devel unzip
RUN wget http://people.centos.org/tru/devtools-2/devtools-2.repo -O /etc/yum.repos.d/devtools-2.repo
RUN wget --no-check-certificate https://copr.fedoraproject.org/coprs/praiskup/autotools/repo/epel-5/praiskup-autotools-epel-5.repo -O /etc/yum.repos.d/autotools.repo
RUN yum install -y devtoolset-2-gcc devtoolset-2-binutils devtoolset-2-gcc-c++ devtoolset-2-gcc-gfortran autotools-latest pkgconfig which

# install rust compiler and cargo in the nightly version
RUN yum install -y file gpg
RUN curl -sSf http://static.rust-lang.org/rustup.sh | sh -s -- --channel=nightly -y --disable-sudo

# install conda
RUN mkdir -p /tmp/conda-build
RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh && bash Miniconda3-latest-Linux-x86_64.sh -b -p $home/anaconda
ENV PATH=/opt/rh/devtoolset-2/root/usr/bin:/opt/rh/autotools-latest/root/usr/bin:$home/anaconda/bin:$PATH
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
RUN mkdir -p $home/anaconda/conda-bld/linux-64  # workaround for bug in current conda (conda issue #466)
RUN mkdir -p $home/anaconda/conda-bld/osx-64    # workaround for bug in current conda (conda issue #466)

# setup conda
RUN conda install -y conda conda-build anaconda-client pyyaml toolz jinja2 nose

RUN conda index $home/anaconda/conda-bld/linux-64 $home/anaconda/conda-bld/osx-64
RUN conda config --add channels bioconda
RUN conda config --add channels r
RUN conda config --add channels file://$home/anaconda/conda-bld
RUN conda config --add channels http://xguse.github.io/conda-package-repo/pkgs/channel/

RUN conda install -y toposort ipython gnureadline


# setup personal recipe directories
ENV PERSONAL_REPOS=$home/repos
RUN mkdir -p $PERSONAL_REPOS

## recipe repos
RUN git clone https://github.com/xguse/conda-package-repo.git $PERSONAL_REPOS/conda-package-repo
RUN git clone https://github.com/xguse/recipes.git $PERSONAL_REPOS/bioconda-recipes
RUN git clone https://github.com/xguse/conda-recipes.git $PERSONAL_REPOS/conda-recipes

# RUN git --git-dir=$PERSONAL_REPOS/conda-package-repo checkout -t origin/gh-pages
# RUN git --git-dir=$PERSONAL_REPOS/bioconda-recipes checkout -t origin/develop
# RUN git --git-dir=$PERSONAL_REPOS/conda-recipes checkout -t origin/f/personal_repo

## zsh setup
RUN git clone https://github.com/tarjoilija/zgen.git $PERSONAL_REPOS/zgen
RUN git clone https://github.com/xguse/zshrc.git $PERSONAL_REPOS/zshrc
RUN ln -sf $PERSONAL_REPOS/zshrc/zshrc_conda_build_docker_image.sh $home/.zshrc



# # setup entrypoint (assuming that repo is mounted under /bioconda-recipes)
# ENTRYPOINT ["/bioconda-recipes/scripts/build-packages.py"]
# CMD []
