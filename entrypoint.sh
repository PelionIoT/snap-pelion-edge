#!/bin/bash

# Add local user that matches the $PWD owner and run command as that user
USER_ID=$(stat -c "%u" ${PWD})
echo "${PWD} is owned by UID ${USER_ID}.  Starting as that UID"
useradd --shell /bin/bash -u ${USER_ID} -o -c "" -m user

# Give the user sudo privileges so that snapcraft can install required packages
usermod -aG sudo user
echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy ssh keys, netrc, and other necessary config files so that snapcraft
# can clone private repos
cp -rf ${HOME}/.ssh /home/user/
cp -f ${HOME}/.netrc /home/user/
cp -f ${HOME}/.gitconfig /home/user/
chown -R user:user /home/user/

# Run the command as user
export HOME=/home/user
exec gosu user "$@"
