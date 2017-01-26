# Vagrant Local Environment

## Prerequisites

* [Vagrant]([https://www.vagrantup.com/) [ Version: 1.8.x ]
* [VirtualBox](https://www.virtualbox.org/) [ Version: 5.0.x ]

Once Vagrant and VirtualBox are installed we also need to install a Vagrant Plugin. Run

  ```
  vagrant plugin install vagrant-vbguest
  ```

## Introduction

We use [Ansible](https://www.ansible.com/) to provision a *CentOS 6* box ready to work
with all dependencies and software pre installed and configured for you.

## How to Use it

* Clone this repository and change directory

  ```
  git clone git@extdev.hesapps.com:h4h-api
  cd h4h-api
  ```

* Launch VagrantBox

  ```
  vagrant up
  ```

  The first take will take a while, since we need to download *CentOSs* base image and after
  that ansible will run and install all the required software to run this project.

  At this point the following packages are installed and configured:
  - RVM
  - Ruby [ 2.2.3 ]
  - Rails [ 3.2.2 ]
  - Memcached
  - Redis
  - MariaDB

  Ansible also take care of running *bundle install* in app root directory _/srv/h4h-api_,
  *npm install* in _/srv/h4h-api/realtime_ and rake tasks to leave instance ready to run
  this api.

* You are now ready to login to the vagrant box

  ```
  vagrant ssh
  ```

  Change directory to */srv/h4h-api/* and run the app.
  
## Vagrant Useful Commands

Always run the following commands in the root directory of the project [ where Vagrantfile is placed ]
in your local machine

* Start a vagrant box

  ```
  vagrant up
  ```

* Stop/Shutdown a vagrant box

  ```
  vagrant halt
  ```

* Destroy a vagrant box

  ```
  vagrant destroy -f
  ```

* Check vagrant status

  ```
  vagrant global-status
  ```

## Windows installation notes

#### Required software
* https://www.cygwin.com/ (ssh, and rsync packages).
_Note: do not use folder names with spaces for cygwin software folder_

#### Possible errors
##### VERR_VMX_MSR_ALL_VMX_DISABLED - When you try to run the machine from VirtualBox GUI

**Solution 1**: In VirtualBox "Settings" > System Settings > Processor > Enable the PAE/NX option. (could help).

**Solution 2**: Turn ON VT-x in BIOS (will help for sure).

##### The executable 'cygpath' Vagrant is trying to run was not found *OR* An error occurred in the underlying SSH library that Vagrant uses.

**Solution**: Add installed cygwin software folder to your PATH variable.

##### SSH connection stucks with no errors _Make sure the machine is running properly, probably your problem outside of SSH. It's much easier to do with GUI on._

**Solution 1**: To enable GUI within vagrant add the following into vagrantfile:
```
config.vm.provider :virtualbox do |vb|
    vb.gui = true
end
```
**Solution 2**: Run machine manually from VirtualBox.

##### There was an error when attempting to rsync a synced folder. Please inspect the error message below for more info.

**Solution**: In file ```<vagrant folder>\embedded\gems\gems\vagrant-1.8.1\plugins\synced_folders\rsync\helper.rb``` remove lines 77-79, they look like this:
```
"-o ControlMaster=auto " +
"-o ControlPath=#{controlpath} " +
"-o ControlPersist=10m " +
```

_Solution link: https://github.com/mitchellh/vagrant/issues/6702#issuecomment-166503021_

##### ```vagrant up``` command breaks with following error

```
The following SSH command responded with a non-zero exit status.
Vagrant assumes that this means the command failed!
chown `id -u vagrant`:`id -g vagrant` /srv/h4h-api
```

**Debugging**:
1. establish SSH connection with machine (```vagrant ssh```)
2. navigate to "srv/h4h-api" (probably you'll need to use ``` cd .. ``` a few times to move a few catalogs higher)
3. try to run ``` ls -a ``` inside this folder, if you get "operation not permitted" error, then use the following solution

**Solution**:
Change ```windows_unc_path()``` in ```<vagrant folder>\embedded\gems\gems\vagrant-1.8.1\lib\vagrant\util\platform.rb``` to:

    def windows_unc_path(path)
      path = path.gsub("/", "\\")

      # If the path is just a drive letter, then return that as-is
      return path if path =~ /^[a-zA-Z]:\\?$/

      # Convert to UNC path
      path
    end

_Solution link: https://github.com/mitchellh/vagrant/issues/5933#issuecomment-167978276_