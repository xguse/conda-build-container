FROM debian:7.4

MAINTAINER Gus Dunn "gus.dunn@yale.edu"



RUN apt-get update --fix-missing && apt-get install -y wget bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1 zsh tmux git vim stow

# Setup home
RUN useradd conda -p '' -s /bin/zsh
ENV home=/home/conda
RUN mkdir $home
RUN chown -R conda $home


RUN apt-get install -y curl grep sed dpkg && \
    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb && \
    apt-get clean



###### Switch to user execution ######
USER conda
WORKDIR $home

# setup personal recipe directories
ENV PERSONAL_REPOS=$home/repos
RUN mkdir -p $PERSONAL_REPOS

## zsh setup
RUN git clone https://github.com/tarjoilija/zgen.git $PERSONAL_REPOS/zgen
RUN git clone https://github.com/xguse/zshrc.git $PERSONAL_REPOS/zshrc
RUN ln -sf $PERSONAL_REPOS/zshrc/zshrc_conda_build_docker_image.sh $home/.zshrc && source $home/.zshrc

## recipe repos
RUN git clone https://github.com/xguse/conda-package-repo.git $PERSONAL_REPOS/conda-package-repo
RUN git clone https://github.com/xguse/recipes.git $PERSONAL_REPOS/bioconda-recipes
RUN git clone https://github.com/xguse/conda-recipes.git $PERSONAL_REPOS/conda-recipes

# RUN (cd $PERSONAL_REPOS/conda-package-repo && git checkout -t origin/gh-pages)
RUN (cd $PERSONAL_REPOS/bioconda-recipes && git checkout -t origin/develop)
RUN (cd $PERSONAL_REPOS/conda-recipes && git checkout -t origin/f/personal_repo)




# #### install conda ####
# RUN wget --quiet https://repo.continuum.io/archive/Anaconda2-2.4.0-Linux-x86_64.sh && \
#     /bin/bash /Anaconda2-2.4.0-Linux-x86_64.sh -b -p $home/anaconda && \
#     rm /Anaconda2-2.4.0-Linux-x86_64.sh && \
#     /opt/conda/bin/conda install --yes conda==3.18.3
#
# # setup conda
# RUN conda install -y conda conda-build anaconda-client pyyaml toolz jinja2 nose pytest
#
#
# RUN mkdir -p anaconda/conda-bld/linux-64 anaconda/conda-bld/osx-64 && touch .condarc
# RUN conda index $home/anaconda/conda-bld/linux-64 $home/anaconda/conda-bld/osx-64
# RUN conda config --add channels bioconda && \
#     conda config --add channels r && \
#     conda config --add channels file://$home/anaconda/conda-bld && \
#     conda config --add channels http://xguse.github.io/conda-package-repo/pkgs/channel/
#
# RUN conda install -y toposort ipython gnureadline








###### Switch BACK to root execution ######

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
USER root
ENV LANG C.UTF-8

ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD [ "/bin/zsh" ]
