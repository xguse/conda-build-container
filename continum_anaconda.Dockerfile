FROM debian:7.4

MAINTAINER Gus Dunn "gus.dunn@yale.edu"



RUN apt-get update --fix-missing && apt-get install -y wget bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1 zsh tmux git vim stow curl grep sed dpkg

RUN curl -o /usr/local/bin/gosu -SL 'https://github.com/tianon/gosu/releases/download/1.0/gosu' \
    && chmod +x /usr/local/bin/gosu

# Setup home
RUN useradd player1 -p '' -s /bin/zsh
ENV HOME=/home/player1 PERSONAL_REPOS=$HOME/repos
RUN mkdir $HOME
RUN chown -R player1: $HOME


RUN TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb && \
    apt-get clean


ADD ssh $HOME/.ssh
RUN chown -R player1: $HOME/.ssh

###### Switch to user execution ######
USER player1
WORKDIR $HOME

# setup personal recipe directories
RUN mkdir -p $PERSONAL_REPOS

## zsh setup
RUN git clone https://github.com/tarjoilija/zgen.git $PERSONAL_REPOS/zgen
RUN git clone git@github.com:xguse/zshrc.git $PERSONAL_REPOS/zshrc
RUN ln -sf $PERSONAL_REPOS/zshrc/zshrc_conda_build_docker_image.sh $HOME/.zshrc
# RUN /bin/zsh -c "source /home/conda/repos/zshrc/zshrc_conda_build_docker_image.sh"

## recipe repos
RUN git clone git@github.com:xguse/conda-package-repo.git $PERSONAL_REPOS/conda-package-repo
RUN git clone git@github.com:xguse/recipes.git $PERSONAL_REPOS/bioconda-recipes
RUN git clone git@github.com:xguse/conda-recipes.git $PERSONAL_REPOS/conda-recipes

# RUN (cd $PERSONAL_REPOS/conda-package-repo && git checkout -t origin/gh-pages)
RUN (cd $PERSONAL_REPOS/bioconda-recipes && git checkout -t origin/develop)
RUN (cd $PERSONAL_REPOS/conda-recipes && git checkout -t origin/f/personal_repo)

#### install conda ####
RUN wget --quiet https://repo.continuum.io/archive/Anaconda2-2.4.0-Linux-x86_64.sh && \
    /bin/bash $HOME/Anaconda2-2.4.0-Linux-x86_64.sh -b -p $HOME/anaconda && \
    rm $HOME/Anaconda2-2.4.0-Linux-x86_64.sh && \
    gosu player1 $HOME/anaconda/bin/conda install --yes conda==3.18.3

# setup conda
RUN gosu player1 $HOME/anaconda/bin/conda install -y conda conda-build anaconda-client pyyaml toolz jinja2 nose pytest


RUN mkdir -p anaconda/conda-bld/linux-64 anaconda/conda-bld/osx-64 && touch .condarc
RUN gosu player1 anaconda/bin/conda index anaconda/conda-bld/linux-64 anaconda/conda-bld/osx-64 && \
echo "channels: \n\
    - bioconda\n\
    - r\n\
    - file://$HOME/anaconda/conda-bld\n\
    - http://xguse.github.io/conda-package-repo/pkgs/channel/\n\
    - defaults\n" > .condarc

# RUN /bin/zsh -c "source anaconda/bin/activate root" && conda config --add channels bioconda && \
#     conda config --add channels r && \
#     conda config --add channels file://$HOME/anaconda/conda-bld && \
#     conda config --add channels http://xguse.github.io/conda-package-repo/pkgs/channel/

RUN gosu player1 anaconda/bin/conda install -y toposort ipython gnureadline

RUN /bin/zsh -c "source /home/player1/.zshrc"

###### Switch BACK to root execution ######

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
USER root
ENV LANG C.UTF-8


ENTRYPOINT [ "/usr/bin/tini", "--" ]
USER player1
CMD [ "/bin/zsh"]
