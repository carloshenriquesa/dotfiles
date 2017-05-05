source $HOME/.bash_profile.d/completion/bash.sh
source $HOME/.bash_profile.d/completion/git.sh
source $HOME/.bash_profile.d/completion/gem.sh
source $HOME/.bash_profile.d/completion/ssh.sh
source $HOME/.bash_profile.d/completion/brew.sh
source $HOME/.bash_profile.d/completion/hub.sh
source $HOME/.bash_profile.d/completion/docker.sh
source $HOME/.bash_profile.d/completion/docker-machine.sh
source $HOME/.bash_profile.d/completion/docker-compose.sh
source $HOME/.bash_profile.d/completion/aws.sh
source $HOME/.bash_profile.d/prompt.sh
source $HOME/.bash_profile.d/aliases.sh
source $HOME/.bash_profile.d/exports.sh
source $HOME/.bash_profile.d/functions.sh
source $HOME/.bash_profile.d/settings.sh
source $HOME/.bash_profile.d/ruby.sh
source $HOME/.bash_profile.d/javascript.sh

# Stuff I don't want public avaiable
[ -r $HOME/.bash_profile_extras ] && source $HOME/.bash_profile_extras

export PATH="$HOME/bin:$PATH"

# habilita direnv (https://github.com/zimbatm/direnv)
# tem que ser a última coisa
which direnv > /dev/null && eval "$(direnv hook bash)"
