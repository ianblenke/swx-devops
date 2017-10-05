# .bash_profile
# Prepare our devops environment with variables, useful functions, and aliases.

devops=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

export AWS_CONFIG_FILE=${AWS_CONFIG_FILE:-~/.aws/config}
export AWS_PROFILE=${AWS_PROFILE:-sofwerx}
export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id --profile $AWS_PROFILE)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key --profile $AWS_PROFILE)
export AWS_REGION=${AWS_REGION:-$(aws configure get region --profile $AWS_PROFILE)}
export AWS_DEFAULT_REGION=${AWS_REGION}
export AWS_DEFAULT_OUTPUT=$(aws configure get output --profile $AWS_PROFILE)

# Set the bash prompt to show our $AWS_PROFILE
export PS1='[$AWS_PROFILE] \h:\W \u\$ '

# These variables become available for terraform to use
export TF_VAR_aws_region=${AWS_REGION}
export TF_VAR_aws_access_key_id=${AWS_ACCESS_KEY_ID}
export TF_VAR_aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}

if [ -d ${devops}/secrets/gnupg ] ; then
  export GNUPGHOME=${devops}/secrets/gnupg
else
  if [ -d "$HOME/.gnupg" ]; then
    export GNUPGHOME="$HOME/.gnupg"
  fi
fi

if [ -f "$HOME/.gpg-agent-info" ]; then
  . "$HOME/.gpg-agent-info"
  export GPG_AGENT_INFO
  export SSH_AUTH_SOCK
  export SSH_AGENT_PID
fi

if [ -d /usr/local/opt/gpg-agent ]; then
  export PATH="/usr/local/opt/gpg-agent/bin:$PATH"
  export PATH="/usr/local/opt/gpg-agent/libexec:$PATH"
fi

if [ -d $GNUPGHOME ] ; then
  KEYGRIP=$(gpg --fingerprint --fingerprint | grep fingerprint | tail -1 | cut -d= -f2 | sed -e 's/ //g')
  alias gpg_remember="echo -n 'Please enter your gpg key passphrase: '; gpg-preset-passphrase --preset $KEYGRIP"
  alias gpg_forget="gpg-preset-passphrase --forget $KEYGRIP"
  if [ -z "$GPG_AGENT_INFO" ]; then
    if which gpg-agent > /dev/null ; then
      GPG_TTY=$(tty)
      export GPG_TTY

      gpg-agent --daemon --enable-ssh-support --write-env-file $HOME/.gpg-agent-info --allow-preset-passphrase
    fi
  fi
  export TROUSSEAU_MASTER_GPG_ID=$(gpg --list-secret-keys | grep uid  | cut -d'<' -f2- | cut -d'>' -f1)
fi

# The trousseau and terraform commands need buckets
export TROUSSEAU_STORE="${TROUSSEAU_STORE:-${devops}/.trousseau}"

# TROUSSEAU_KEYRING_SERVICE
# TROUSSEAU_MASTER_GPG_ID
# TROUSSEAU_PRIVATE_KEY
if [ -z "${TROUSSEAU_PASSPHRASE}" ] &&
   [ -z "${TROUSSEAU_KEYRING_SERVICE}" ] &&
   [ -z "${GPG_AGENT_INFO}" ] ; then
  if [ -d $GNUPGHOME ]; then
    echo 'To save yourself some passphrase prompting pain, you may want to:'
    echo '    export TROUSSEAU_PASSPHRASE={your pgp passphrase}'
    echo 'Alternatively, you may want to add a password to your keyring service for trousseau to use:'
    echo '    export TROUSSEAU_KEYRING_SERVICE=trouseau'
  else
    echo 'You may need to first generate a gpg key:'
    echo '    gpg --gen-key'
  fi
fi

if [ -n "${GPG_AGENT_INFO}" -a -z "$TROUSSEAU_KEYRING_SERVICE" ]; then
  export TROUSSEAU_KEYRING_SERVICE=trouseau
fi

alias trousseau="$(which trousseau) --gnupg-home $GNUPGHOME --store $TROUSSEAU_STORE"

# Docker variables
export MACHINE_STORAGE_PATH=${devops}/secrets/docker