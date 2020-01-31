# Setting up your macOS using [Make DevOps](https://github.com/nhsd-ddce/make-devops)

## Next steps

* Restart your macOS
* Fully enable the `Avast Security` antivirus software
* Open the `Docker Desktop` application and make sure it always starts when you log in and has sufficient resources allocated. e.g. at least 4GB memory and 4 CPUs
* Use the `Spectacle` and `KeepingYouAwake` applications to improve the ergonomics
* Go to System Preferences > Security & Privacy > Privacy > Full Disk Access > [ Add iTerm to the list ]
* If you can no longer open Java-based applications (e.g. DBeaver) due to the JDK execution error, follow the steps below
    1. Run from the command-line `sudo spctl --master-disable` to disable the Gatekeeper
    2. Open the application again (e.g. DBeaver), which now should open normally
    3. Run from the command-line `sudo spctl --master-enable` to enable the Gatekeeper again
* Always check if your macOS is up-to-date
* Clone git projects to the `~/projects` directory
* Your AWS profiles are stored in `~/.aws/config`, check it
* Your AWS credentials are stored in `~/.aws/credentials`, check it
* Edit `~/.dotfiles/oh-my-zsh/plugins/make-devops/aws-platform.zsh` to include correct AWS platform variables
* Place the Kubernetes configuration as `~/.kube/configs/*-nonprod-kubeconfig` file and the `KUBECONFIG` environment variable will be set automatically when your shell session reloads
* From now on use `iTerm` as your terminal and `Visual Studio Code` as your text editor

## Useful commands

* `tx-mfa` - Prompt for new AWS MFA session
* `tx-mfa-clear` - Clear the current AWS MFA session
* `tns` - Toggle natural scrolling
* `nvm` (Node.js), `pyenv` (Python), `jenv` (Java), `gvm` (Go) to set up and switch virtual environments

## Starting from scratch

* Turn off and then on your MacBook and immediately press and hold Command-R to enter the macOS recovery mode
* Erase the disk and set it to APFS (Case-sensitive, Encrypted), disk name "System"
* Reinstall the operating system
* Create the administrator account
* Create a developer account with the administrative privileges
* Log in as the developer and register your Apple ID
* Perform all system updates
* Go to System Preferences > Software Update > [ Tick all the checkboxes ]
* Go to System Preferences > Sharing > Computer Name > [ Set name to macos-xxxxxx ]
* Run Make DevOps script by executing `curl -L bit.ly/make-devops | bash` in the Terminal

---
>_A copy of this page has been saved to your desktop._
