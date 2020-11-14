# Contributing

## Table of contents

- [Contributing](#contributing)
  - [Table of contents](#table-of-contents)
  - [Development Environment](#development-environment)
    - [Prerequisites](#prerequisites)
    - [Configuration](#configuration)
  - [Version Control](#version-control)
    - [Git configuration](#git-configuration)
    - [Signing your Git commits](#signing-your-git-commits)
    - [Git usage](#git-usage)
  - [Merge request](#merge-request)
    - [GitLab web interface](#gitlab-web-interface)
  - [Code review](#code-review)
  - [Unit tests](#unit-tests)

## Development Environment

### Prerequisites

The following software packages must be installed on your MacBook before proceeding

- [Xcode Command Line Tools](https://apps.apple.com/gb/app/xcode/id497799835?mt=12)
- [Brew](https://brew.sh/)
- [GNU make](https://formulae.brew.sh/formula/make)

Before proceeding, please make sure that your macOS operating system provisioned with the `curl -L bit.ly/make-devops-macos | bash` command.

### Configuration

From within the root directory of your project, please run the following command

    make macos-setup

The above make target ensures that your MacBook is configured correctly for development and the setup is consistent across the whole team. In a nutshell it will

- Update all the installed software packages
- Install any missing essential, additional and corporate software packages
- Configure shell (zsh), terminal (iTerm2) and IDE (Visual Studio Code) along with its extensions

This gives a head start and enables anyone complying with that configuration to focus on development straight away. After the command runs successfully, please restart your iTerm2 and Visual Studio Code sessions to fully apply the changes.

## Version Control

### Git configuration

Global Git configuration

    git config --global user.name "Your Name"
    git config --global user.email "your.name@nhs.net"
    git config --global branch.autosetupmerge false
    git config --global branch.autosetuprebase always
    git config --global commit.gpgsign true
    git config --global core.autocrlf input
    git config --global core.filemode true
    git config --global core.hidedotfiles false
    git config --global core.ignorecase false
    git config --global pull.rebase true
    git config --global push.default current
    git config --global push.followTags true
    git config --global rebase.autoStash true
    git config --global remote.origin.prune true

### Signing your Git commits

Signing Git commits is a good practice and ensures the correct web of trust has been established for the distributed version control management.

Generate a new pair of GPG keys. Please, change the passphrase and save it in your password manager.

    USER_NAME="Your Name"
    USER_EMAIL="your.name@nhs.net"
    file=$(echo $USER_EMAIL | sed "s/[^[:alpha:]]/-/g")

    cat > $file.gpg-key.script <<EOF
        %echo Generating a GPG key
        Key-Type: default
        Key-Length: 4096
        Subkey-Type: default
        Subkey-Length: 4096
        Name-Real: $USER_NAME
        Name-Email: $USER_EMAIL
        Expire-Date: 0
        Passphrase: [...]
        %commit
        %echo done
    EOF
    gpg --batch --generate-key $file.gpg-key.script && rm $file.gpg-key.script
    # or do it manually by running `gpg --full-gen-key`

Make note of the ID and save the keys.

    gpg --list-secret-keys --keyid-format LONG $USER_EMAIL
    ID=[...]
    gpg --armor --export $ID > $file.gpg-key.pub
    gpg --armor --export-secret-keys $ID > $file.gpg-key

Import already existing private key.

    gpg --import $file.gpg-key

Remove keys from the GPG agent if no longer needed.

    gpg --delete-secret-keys $ID
    gpg --delete-keys $ID

Configure Git to use the new key.

    git config --global user.signingkey $ID
    git config --global commit.gpgsign true

Upload the public key to your GitHub and GitLab accounts using the links below.

- [GitHub](https://github.com/settings/keys)
- [GitLab](https://gitlab.mgmt.texasplatform.uk/profile/gpg_keys)

### Git usage

Working on a new task

    git checkout -b task/JIRA-XXX_Descriptive_name
    # Make your changes here...
    git add .
    git commit -S -m "Description of the change"
    git push --set-upstream origin task/JIRA-XXX_Descriptive_name

Contributing to an already existing branch

    git checkout task/JIRA-XXX_Descriptive_name
    git pull
    # Make your changes here...
    git add .
    git commit -S -m "Description of the change"
    git push

Rebasing a branch onto master

    git checkout master
    git pull
    git checkout task/JIRA-XXX_Descriptive_name
    git rebase master
    # Resolve conflicts
    git add .
    git rebase --continue
    git push --force

Merging a branch to master - this should be done only in an exceptional circumstance as the proper process is to raise an MR

    git checkout master
    git pull --prune                                    # Make sure master is up-to-date
    git checkout task/JIRA-XXX_Descriptive_name
    git pull                                            # Make sure the task branch is up-to-date

    git rebase -i HEAD~3                                # Squash 3 commits
    # When prompted change commit type to `squash` for all the commits except the top one
    # On the following screen replace pre-inserted comments by a single summary

    git rebase master                                   # Rebase the task branch on top of master
    git checkout master                                 # Switch to master branch
    git merge -ff task/JIRA-XXX_Descriptive_name        # Fast-forward merge
    git push                                            # Push master to remote

    git push -d origin task/JIRA-XXX_Descriptive_name   # Remove remote branch
    git branch -d task/JIRA-XXX_Descriptive_name        # Remove local branch

If JIRA is currently not in use to track project changes, please drop any reference to it and omit `JIRA-XXX` in your commands.

## Merge request

### GitLab web interface

- Set the title to `JIRA-XXX Descriptive name of the task`, where `JIRA-XXX` is the ticket reference number
- Check `Remove source branch when merge request is accepted`
- Check `Squash commits when merge request is accepted`
- Merge only if
  - Peer review has been done
  - At least one thumbs up have been given
  - All discussions are resolved

## Code review

Please, refer to the [Clean Code](https://learning.oreilly.com/library/view/clean-code/9780136083238/), especially chapter 17 and [Clean Architecture](https://learning.oreilly.com/library/view/clean-architecture-a/9780134494272/) books by Robert C. Martin while performing peer code reviews.

## Unit tests

When writing or updating unit tests (whether you use Python, Java, Go or shell), please always structure them using the 3 A's approach of 'Arrange', 'Act', and 'Assert'. For example:

    @Test
    public void listServicesNullReturn() {

      // Arrange
      List<String> criteria = new ArrayList<>();
      criteria.add("Null");
      when(repository.findBy(criteria)).thenReturn(null);

      // Act
      List<Service> list = service.list(criteria);

      // Assert
      assertEquals(0, list.size());
    }
