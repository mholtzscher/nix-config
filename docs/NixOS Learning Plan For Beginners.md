

# **The NixOS Onboarding Itinerary: A 5-Day Plan for Mastering Declarative System Management**

Welcome to NixOS. Embarking on this journey is not merely about learning a new Linux distribution; it is about adopting a fundamentally different and more powerful paradigm for system management. Traditional operating systems evolve through a series of commands and manual edits, often leading to a state of "configuration drift" where the system's true configuration is unknown and difficult to replicate. NixOS addresses this by treating the entire operating system as a single, computable value derived from a set of declarative configuration files. This approach guarantees reproducibility, enhances reliability, and transforms system administration into a discipline with the rigor of software engineering.1  
This five-day plan is designed to guide a new user from the foundational principles of the Nix paradigm to the implementation of modern best practices. Day 1 focuses on building the essential mental model. Day 2 provides hands-on experience with basic system management. Day 3 introduces Flakes, the key to true reproducibility. Day 4 separates user and system concerns with Home Manager. Finally, Day 5 equips the user with patterns for scaling their configuration and resources for continued learning. By the end of this itinerary, a user will have built a robust, version-controlled, and declaratively managed NixOS system from the ground up.

## **Day 1: The Nix Paradigm Shift \- Foundational Concepts**

**Objective:** To build the essential mental model for NixOS by focusing on the "why" behind its unique architecture. This day is dedicated to understanding the core principles before engaging in significant configuration.

### **1.1 Understanding Declarative Configuration: The "What," Not the "How"**

The most significant departure of NixOS from other operating systems is its embrace of a declarative configuration model.2 In a traditional, imperative system (such as Debian or Fedora), an administrator issues a sequence of commands to reach a desired state: install a package, then edit a configuration file, then enable a service. Each command modifies the global state of the system, and the history of these modifications is often lost, making it difficult to reproduce the exact same setup on another machine or recover from a mistake.3  
NixOS inverts this model. Instead of specifying *how* to build the system, the administrator specifies *what* the final system should look like in a set of configuration files, primarily /etc/nixos/configuration.nix.4 This configuration declares everything: the set of installed packages, the content of configuration files, the services that should be running, the users that should exist, and more. The Nix toolchain then takes this description and builds the entire system to match it.  
This approach offers several profound advantages:

* **Reproducibility:** Since the entire system is derived from a single set of files, that set of files can be used to create an identical system on any other machine.3 This eliminates the "it works on my machine" problem for system configurations.  
* **Transparency:** The configuration files serve as a single source of truth. To understand what software is installed or how a service is configured, one only needs to read the configuration, not inspect the live state of the system or parse shell history.3  
* **Version Control:** The system configuration can be stored in a Git repository. This provides a complete, auditable history of every change made to the system. Mistakes can be easily identified and reverted by simply reverting a commit.3

This paradigm shift effectively transforms system administration into a practice that mirrors software development. The configuration is the source code, nixos-rebuild is the compiler, and the running system is the binary. This brings a level of determinism and reliability to system management that is difficult to achieve with imperative models.  
**Table 1: Imperative vs. Declarative System Management**

| Task | Imperative Approach (e.g., Ubuntu) | Declarative Approach (NixOS) |
| :---- | :---- | :---- |
| **Installing a Package** | sudo apt-get install htop | Add htop to the environment.systemPackages list in configuration.nix. |
| **Configuring a Service** | sudo apt-get install ssh, then manually edit /etc/ssh/sshd\_config. | Define services.openssh.enable \= true; and set options like services.openssh.settings.PasswordAuthentication \= false; in configuration.nix. |
| **Upgrading the System** | sudo apt-get update && sudo apt-get upgrade | Update the package source (channel or flake input) and run nixos-rebuild switch \--upgrade. |
| **Reverting a Change** | Manually undo the change (e.g., apt-get remove, revert config file edit). This is error-prone and may not fully restore the previous state. | Run nixos-rebuild switch \--rollback to atomically revert to the previous system generation. |
| **Replicating the System** | Requires a complex sequence of shell scripts, manual steps, or disk imaging. Prone to failure due to environmental differences. | Copy the NixOS configuration files to a new machine and run nixos-rebuild switch. The result is a byte-for-byte identical system configuration. |

### **1.2 Core Principles of the Nix Package Manager**

The declarative power of NixOS is built upon the unique foundation of the Nix package manager. Nix is described as a "purely functional" package manager, meaning it treats packages like immutable values in a functional programming language.6 This principle has several key consequences that enable the features of NixOS.

* **The Nix Store:** All packages, configuration files, and system components are stored in the Nix store, located at /nix/store. Each item in the store resides in its own unique subdirectory with a name prefixed by a cryptographic hash, such as /nix/store/sglc...-git-2.38.1/.4 This hash is derived from *all* inputs used to build the package—its source code, its dependencies, its compiler flags, and its build script. If any input changes, even by a single byte, the hash changes, and the new package is stored in a new, different directory.6 This immutability is the cornerstone of Nix's reliability.  
* **Complete Dependencies:** During a package build, Nix creates a sandboxed environment where the build script can only see the dependencies that were explicitly declared. It cannot access programs or libraries from the host system.6 This strictness guarantees that if a package builds successfully, its dependency specification is complete. This solves a common source of failure in traditional packaging where a build succeeds on a developer's machine due to an undeclared dependency being present, only to fail on a user's machine where it is absent.  
* **Multiple Versions:** Because every package version with even slightly different dependencies lives in a unique path in the Nix store, multiple versions of the same software can coexist on the system without any conflict. An application that needs an older version of a library can link to it directly in the store, while another application uses a newer version from a different path. This effectively eliminates the "DLL hell" problem that plagues many operating systems.6  
* **Multi-User Support:** Nix allows non-privileged users to install their own software into their own "profile" without needing root access. A profile is essentially a collection of symbolic links pointing to packages in the Nix store. If a user installs a package that already exists in the store (perhaps installed by another user or the system), Nix simply creates the necessary links instead of downloading or building it again. This is done securely, preventing one user from modifying a package used by another.4  
* **Garbage Collection:** When a package is "uninstalled," it is not immediately deleted from the /nix/store. Instead, the symbolic links pointing to it from a user profile or system generation are removed. The package itself remains until the garbage collector is run with nix-collect-garbage. This command safely deletes any package in the store that is no longer referenced by any system generation, user profile, or running process, freeing up disk space.6

### **1.3 System Generations and the Power of Atomic Rollbacks**

The principles of the Nix store enable one of NixOS's most celebrated features: atomic upgrades and rollbacks. Every time an administrator successfully applies a new configuration with nixos-rebuild switch, NixOS creates a new "generation".4  
A generation is a complete, self-contained snapshot of the entire system state. It is represented by a numbered directory in /nix/var/nix/profiles/ which contains a tree of symbolic links pointing to all the specific package versions and configuration files in the /nix/store that make up that particular version of the system. The currently active system is determined by a single symbolic link, /run/current-system, which points to one of these generation directories.8  
The process of a system upgrade is atomic because it happens in two distinct phases:

1. **Build:** Nix builds the entire new system configuration in the background. All new packages are downloaded or built and placed in the /nix/store. A new generation directory is created, populated with links to the new system's components.  
2. **Switch:** Once the build is complete and successful, the "switch" is a single, instantaneous, atomic operation: changing the /run/current-system symlink to point from the old generation to the new one.4

This process ensures there is no window of time during an upgrade where the system is in an inconsistent state.6 Furthermore, because old packages are not overwritten, all previous generations remain available. If a new configuration proves to be broken, rolling back is as simple as telling NixOS to switch the symlink back to a previous, known-good generation. This operation is not only atomic but also typically instantaneous, as no files need to be re-downloaded or re-installed.4 This provides a risk-free way to experiment with system changes.3

### **1.4 Practical Exercise 1: Exploring System History and Performing a Rollback**

This exercise demonstrates the concept of generations in a safe, practical way.

1. **List Current Generations:** Open a terminal and list the existing system generations. Since this is a fresh installation, there will likely be only one or two.  
   Bash  
   nixos-rebuild \--list-generations

2. **Create a New Generation:** Perform a "no-op" rebuild. This command will evaluate the current configuration and, finding no changes, will still create a new generation that is identical to the current one.  
   Bash  
   sudo nixos-rebuild switch

3. **Observe the New Generation:** List the generations again. A new generation will now appear at the top of the list, marked as "(current)".  
   Bash  
   nixos-rebuild \--list-generations

4. **Perform a Rollback:** Now, execute the rollback command. This will switch the system back to the previous generation.  
   Bash  
   sudo nixos-rebuild switch \--rollback

   The output will confirm that the system has been switched to the prior generation. Listing the generations again will show that the older generation is now marked as "(current)".9 This exercise confirms how simple and immediate it is to move between system states.

## **Day 2: Your First Declarative Steps \- Mastering configuration.nix**

**Objective:** To gain practical, hands-on experience managing a NixOS system using the foundational configuration.nix file and the nixos-rebuild command.

### **2.1 Anatomy of configuration.nix: A Guided Tour**

The central hub of a classic NixOS system is the file /etc/nixos/configuration.nix. This file is the top-level module that defines the entire system configuration.5 Understanding its structure is the first step toward mastering NixOS.  
At its core, configuration.nix is a Nix expression that defines a function. This function takes an attribute set as its input and returns an attribute set as its output, which represents the desired system configuration. The function signature typically looks like this:

Nix

{ config, pkgs,... }:

* pkgs: This argument provides access to the entire Nix Packages collection (Nixpkgs), the vast repository of software available to NixOS. It is used to specify which packages to install (e.g., pkgs.firefox).4  
* config: This argument represents the final, evaluated configuration of the entire system. It can be used to reference the values of other options within the configuration (e.g., to configure a service based on the system's hostname).  
* ...: This ellipsis indicates that the function can accept other arguments, which are passed in by the NixOS module system, such as lib for helper functions.

The default file generated during installation contains several key sections:

* imports \= \[./hardware-configuration.nix \];: This line imports other NixOS modules. By default, it includes the hardware-specific configuration that was detected during installation. This file contains settings for filesystems, kernel modules, and other hardware-dependent options, and it is kept separate so that the main configuration.nix can be more portable between machines.5  
* boot.loader.\*: Configures the system's bootloader (e.g., GRUB or systemd-boot).  
* networking.hostName \= "nixos";: Sets the system's hostname.  
* users.users.\<username\> \= {... };: Defines user accounts and their properties, such as whether they are a normal user and their group memberships.5  
* environment.systemPackages \= with pkgs; \[... \];: This list defines the packages that should be installed system-wide, making them available in the PATH for all users.4

### **2.2 The Rebuild-Switch-Test Cycle with nixos-rebuild**

The primary tool for applying changes made to configuration.nix is nixos-rebuild. The typical workflow is to edit the configuration file and then run this command to build and activate the new system generation.10 Understanding its subcommands is essential for efficient system management.  
The nixos-rebuild command takes a subcommand that specifies the desired action. The most common ones are:

* switch: This is the most frequently used command. It builds the new configuration, activates it immediately, and makes it the default entry in the bootloader.10  
* boot: This command builds the new configuration and makes it the default for the next boot, but it does not activate it for the current running session. This is useful for changes that require a reboot, such as a kernel update.9  
* test: This command builds and activates the new configuration but does not add an entry to the bootloader. This is ideal for temporarily testing a change without making it permanent. If the system becomes unusable, a simple reboot will revert to the last known-good configuration.9

In addition to these subcommands, several flags modify their behavior:

* \--upgrade: Before building, this flag updates the Nix channel for the root user, ensuring the system is built against the latest available packages.10  
* \--rollback: This flag ignores the current configuration file and instead switches to the immediately preceding generation. It is the primary tool for recovering from a bad configuration.10

**Table 2: Common nixos-rebuild Subcommands and Flags**

| Command / Flag | Function | Use Case |
| :---- | :---- | :---- |
| switch | Builds, activates, and sets as boot default. | The standard command for applying and activating configuration changes. |
| boot | Builds and sets as boot default, but does not activate. | Applying changes that require a reboot to take effect (e.g., kernel updates). |
| test | Builds and activates, but does not create a boot entry. | Safely testing a potentially risky change that can be reverted by rebooting. |
| build | Builds the configuration but does not activate or install it. Creates a result symlink. | Verifying that a configuration builds successfully without affecting the running system. |
| dry-activate | Builds the configuration and shows what would change upon activation, but does not perform the activation. | Previewing the changes (e.g., new services to be started) before committing to them. |
| \--upgrade | Updates the Nix channel before building. | Ensuring the system is rebuilt with the latest security patches and software versions from the channel. |
| \--rollback | Ignores the configuration file and switches to the previous generation. | Immediately recovering from a configuration change that caused system instability. |

### **2.3 Managing System-Wide Packages and Services**

With an understanding of the configuration file and the rebuild command, managing the system becomes a straightforward process.  
To install a package globally, making it available to all users, one simply adds it to the environment.systemPackages list. The with pkgs; syntax brings all the package names from the pkgs attribute set into the local scope, allowing one to write htop instead of pkgs.htop.4

Nix

environment.systemPackages \= with pkgs; \[  
  vim  
  git  
  curl  
  htop  
\];

Enabling and configuring a system service follows a similar declarative pattern. Most services are managed under the services.\* attribute set. To enable a service, the enable option is set to true. Further options are then set in the same block to configure the service's behavior.11 For example, to enable the OpenSSH server:

Nix

services.openssh \= {  
  enable \= true;  
  settings \= {  
    \# Forbid logging in as root  
    PermitRootLogin \= "no";  
    \# Disable password-based authentication in favor of keys  
    PasswordAuthentication \= false;  
  };  
  \# Automatically open the default SSH port in the firewall  
  openFirewall \= true;  
};

This single declaration enables the sshd service, generates its configuration file based on the specified settings, and adjusts the system's firewall rules accordingly.5  
A crucial skill for any NixOS user is discovering the available options and packages. The NixOS ecosystem is vast, and memorizing all options is impossible. The primary tools for discovery are:

* **NixOS Options Search:** A searchable web interface for all available system configuration options: [search.nixos.org/options](https://search.nixos.org/options)  
* Nix Packages Search: A similar interface for finding available packages: search.nixos.org/packages  
  These tools are indispensable for finding the correct attribute path and available settings for any desired system modification.5

### **2.4 Practical Exercise 2: Installing System Tools and Enabling the SSH Daemon**

This exercise applies the concepts of package and service management.

1. **Edit the Configuration:** Open /etc/nixos/configuration.nix with a text editor (e.g., sudo nano /etc/nixos/configuration.nix).  
2. **Install System Tools:** Locate the environment.systemPackages list and add git, curl, and htop.  
   Nix  
   environment.systemPackages \= with pkgs; \[  
     \# Keep any existing packages like vim  
     git  
     curl  
     htop  
   \];

3. **Enable and Configure SSH:** Add the following block to the configuration to enable and secure the SSH daemon. If the services.openssh block already exists from a previous step, modify it.  
   Nix  
   services.openssh \= {  
     enable \= true;  
     settings.PasswordAuthentication \= false;  
   };

4. **Open the Firewall:** While openFirewall \= true is a convenient option for SSH, it's good practice to know how to manage the firewall directly. Add the following to ensure port 22 is open.  
   Nix  
   networking.firewall.allowedTCPPorts \= \[ 22 \];

5. **Apply the Configuration:** Save the file and run the rebuild command.  
   Bash  
   sudo nixos-rebuild switch

6. **Verify the Changes:** After the rebuild completes, open a new terminal.  
   * Run htop to confirm it was installed.  
   * Run git \--version to confirm Git is available.  
   * Check the status of the SSH service: systemctl status sshd.  
   * Attempt to connect to the machine via SSH from another terminal: ssh \<username\>@localhost. If key-based authentication is set up, it should connect.

## **Day 3: Embracing True Reproducibility \- Migrating to Flakes**

**Objective:** To transition from the classic, channel-based workflow to the modern, fully reproducible Flake-based system. This is the most critical step in adopting best practices.

### **3.1 Introduction to Flakes: Solving the Reproducibility Puzzle**

While the declarative configuration.nix ensures the system's logic is reproducible, the classic NixOS setup has a subtle source of impurity: channels. A Nix channel is essentially a pointer to a specific state of the Nixpkgs repository, and it is updated imperatively with nix-channel \--update.12 This means that the same configuration.nix file can produce two different systems if it is built at different times against different versions of the channel. This "channel drift" undermines true, bit-for-bit reproducibility.5  
Nix Flakes are the solution to this problem. A Flake is a self-contained directory (or Git repository) that bundles the Nix code with explicit, version-pinned declarations of all its dependencies.14 This is achieved through two key files:

* flake.nix: Defines the inputs (dependencies) and outputs (packages, systems, etc.) of the project.  
* flake.lock: An automatically generated lockfile that pins each input to a specific commit hash.15

By using Flakes, the entire dependency tree of the system configuration is frozen. Anyone who checks out the same Git commit of a Flake-based configuration will build the *exact* same system, regardless of when they build it or what state their local channels are in.3  
Although Flakes are still officially labeled as an "experimental feature," they have been stable for years and are the widely adopted community standard for any serious NixOS configuration.16 Adopting them is essential for implementing modern best practices.

### **3.2 Anatomy of a flake.nix File**

The flake.nix file is the entry point for a Flake-based project. It has a standardized structure that allows Nix to understand its dependencies and what it provides.14  
A basic flake.nix for a NixOS system consists of three top-level attributes:

Nix

{  
  description \= "A NixOS system configuration flake";

  inputs \= {  
    \# Define the inputs (dependencies) for this flake.  
    nixpkgs.url \= "github:NixOS/nixpkgs/nixos-unstable";  
  };

  outputs \= { self, nixpkgs,... }: {  
    \# Define the outputs produced by this flake.  
    nixosConfigurations.my-machine \= nixpkgs.lib.nixosSystem {  
      system \= "x86\_64-linux";  
      modules \= \[  
       ./configuration.nix  
      \];  
    };  
  };  
}

* description: A simple, human-readable string describing the Flake's purpose.  
* inputs: This attribute set declares all external dependencies. Each input is given a name (e.g., nixpkgs) and a URL-like "flake reference" that tells Nix where to fetch it from. This syntax supports various sources, including GitHub, generic Git repositories, and local paths.14  
* outputs: This is a function that receives the resolved inputs as arguments (e.g., nixpkgs now refers to a local path containing a checkout of the Nixpkgs repository). It returns an attribute set containing the Flake's outputs. For a NixOS configuration, the primary output is nixosConfigurations. This is an attribute set where each key is a hostname, and the value is a complete NixOS system definition, typically created with the nixpkgs.lib.nixosSystem helper function.19

### **3.3 The Role of flake.lock: Pinning Your System's Universe**

The flake.lock file is the cornerstone of a Flake's reproducibility. When a Nix command that uses Flakes (like nixos-rebuild switch \--flake.) is run for the first time, Nix resolves all the inputs from flake.nix, fetches them, and records their exact versions (e.g., the full Git commit hash) in a JSON file named flake.lock.15  
On all subsequent runs, Nix will use the versions specified in flake.lock rather than fetching the latest versions from the input URLs. This ensures that the build is deterministic. The only way to update the dependencies is to explicitly run nix flake update. This command will fetch the latest versions for all inputs, update the flake.lock file with the new commit hashes, and should be committed to Git along with any other configuration changes.19  
The presence of flake.lock in the version control repository guarantees that every developer and every machine using that repository will build from the exact same dependency tree, achieving true, verifiable reproducibility.3

### **3.4 Practical Exercise 3: Converting Your System to a Flake-Based Configuration**

This exercise guides the user through the one-time process of migrating the system from a channel-based to a Flake-based configuration. This process fundamentally shifts the configuration from being a set of files tied to a specific machine's /etc/nixos directory to being a portable, self-contained project in a Git repository.

1. **Enable Flakes:** First, Flakes must be enabled on the current system. Add the following lines to /etc/nixos/configuration.nix and perform one final channel-based rebuild.  
   Nix  
   \# In /etc/nixos/configuration.nix  
   nix.settings.experimental-features \= \[ "nix-command" "flakes" \];

   Bash  
   sudo nixos-rebuild switch

   17  
2. **Create a Git Repository for Your Configuration:** Flakes require the configuration to be tracked by Git. It is best practice to move the configuration out of the system-owned /etc/nixos directory into a user-owned directory.  
   Bash  
   \# Move the configuration to your home directory  
   sudo mv /etc/nixos \~/nixos-config  
   \# Take ownership of the files  
   sudo chown \-R $(whoami) \~/nixos-config  
   \# Navigate into the new directory and initialize a Git repository  
   cd \~/nixos-config  
   git init

   19  
3. **Create the flake.nix File:** In the \~/nixos-config directory, create a new file named flake.nix. This file will be the new entry point for the system build.  
   Nix  
   \# \~/nixos-config/flake.nix  
   {  
     description \= "My NixOS Flake Configuration";

     inputs \= {  
       \# The primary source for packages and NixOS modules.  
       \# It's recommended to pin to a specific release branch for stability.  
       \# Replace "nixos-23.11" with your system's stateVersion from configuration.nix.  
       nixpkgs.url \= "github:NixOS/nixpkgs/nixos-23.11";  
     };

     outputs \= { self, nixpkgs,... }: {  
       \# Define the system configuration.  
       \# Replace "nixos" with your actual hostname.  
       nixosConfigurations.nixos \= nixpkgs.lib.nixosSystem {  
         system \= "x86\_64-linux"; \# Or "aarch64-linux" for ARM

         \# The 'modules' list now includes the original configuration.nix.  
         \# The hardware-configuration.nix is imported from within configuration.nix as before.  
         modules \= \[  
          ./configuration.nix  
         \];  
       };  
     };  
   }

   **Important:** Replace "nixos" with the actual hostname of the machine, and "nixos-23.11" with the value of system.stateVersion from configuration.nix.21  
4. **Track Files and Rebuild with Flakes:** Before rebuilding, all necessary files must be added to the Git staging area, as Nix will ignore untracked files.  
   Bash  
   \# Add all configuration files to be tracked by Git  
   git add.

   Now, run the nixos-rebuild command using the \--flake flag. The . specifies the current directory as the location of the Flake, and the \#\<hostname\> part selects the correct output from nixosConfigurations.  
   Bash  
   \# Replace 'nixos' with your hostname if it's different  
   sudo nixos-rebuild switch \--flake.\#nixos

   10

After this command succeeds, the system is now fully managed by the Flake in \~/nixos-config. The flake.lock file will have been created, and it should be committed to the Git repository. The old system path /etc/nixos is no longer used.

## **Day 4: Taming the Home Environment \- Introduction to Home Manager**

**Objective:** To introduce the separation of system and user concerns and manage the user's environment declaratively using Home Manager.

### **4.1 The Rationale for Home Manager: System vs. User Configuration**

While configuration.nix is powerful for managing the entire system, it is not ideal for managing user-specific configurations, often called "dotfiles" (e.g., .bashrc, .gitconfig). Placing user-level preferences in the system-wide configuration can lead to clutter and makes those configurations difficult to reuse on other machines, especially non-NixOS systems.22  
Home Manager is a specialized NixOS module and standalone tool that solves this problem by providing a dedicated, declarative framework for managing a user's home directory.23 It allows users to define their personal packages, dotfiles, services, and environment variables in a separate set of Nix files.  
The key benefits of using Home Manager are:

* **Separation of Concerns:** It creates a clean boundary between system-level configuration (managed by NixOS) and user-level configuration (managed by Home Manager). This improves organization and clarity.23  
* **Portability:** A Home Manager configuration can be used on any machine where Nix is installed, including other Linux distributions and macOS. This allows a user to replicate their personal environment consistently across all their machines.23  
* **Declarative Dotfiles:** It brings the power of declarative management to dotfiles, which are traditionally managed with imperative symlink farms or scripts.25

### **4.2 Integrating Home Manager into Your NixOS Flake**

The recommended way to use Home Manager on NixOS is to integrate it as a NixOS module within the system's Flake. This ensures that both system and home configurations are built and deployed together in a single, atomic transaction.

1. **Add Home Manager as an Input:** First, add Home Manager to the inputs section of the flake.nix. It is crucial to add inputs.nixpkgs.follows \= "nixpkgs";. This line tells Home Manager to use the exact same version of Nixpkgs that the main system is using, which prevents a wide range of potential version-skew issues.22  
   Nix  
   \# \~/nixos-config/flake.nix  
   {  
     inputs \= {  
       nixpkgs.url \= "github:NixOS/nixpkgs/nixos-23.11";

       home-manager \= {  
         url \= "github:nix-community/home-manager";  
         inputs.nixpkgs.follows \= "nixpkgs";  
       };  
     };  
     \#...  
   }

2. **Include the Home Manager Module:** Next, add the Home Manager NixOS module to the modules list in the nixosConfigurations block. This makes all of Home Manager's configuration options available to the system.  
   Nix  
   \# \~/nixos-config/flake.nix  
   {  
     \#...  
     outputs \= { self, nixpkgs, home-manager,... }: {  
       nixosConfigurations.nixos \= nixpkgs.lib.nixosSystem {  
         \#...  
         modules \=;  
       };  
     };  
   }

3. **Link the User's Configuration:** Finally, within configuration.nix, specify which user's configuration Home Manager should manage and where to find it. A new file, home.nix, will be created to hold this user-specific configuration.  
   Nix  
   \# \~/nixos-config/configuration.nix  
   { config, pkgs,... }: {  
     \#... existing system configuration  
     home-manager.users.your-username \= import./home.nix;  
   }

   Replace your-username with the actual username. This line tells the Home Manager module to build the configuration defined in home.nix for the specified user.23

### **4.3 Declarative Dotfile Management and User Packages**

The home.nix file is the heart of a Home Manager configuration. It has a structure similar to configuration.nix but contains options specific to the user environment.26  
**User Packages:** To install packages that are only available to a specific user, add them to the home.packages list. These packages will be installed into the user's profile, not the system-wide environment.

Nix

\# \~/nixos-config/home.nix  
{ config, pkgs,... }: {  
  home.packages \= with pkgs; \[  
    neofetch  
    ripgrep  \# A fast search tool  
    fd       \# A simple and fast alternative to \`find\`  
  \];  
}

23  
**Dotfile Management:** Home Manager offers two primary methods for managing dotfiles, each with its own trade-offs.25

1. **Linking Existing Files (home.file):** This method, sometimes called the "impure" approach, is often the most practical for complex configurations. It involves keeping the dotfiles as plain text files within the Git repository and telling Home Manager to create symbolic links to them in the correct locations in the home directory.  
   Nix  
   \# \~/nixos-config/home.nix  
   {  
     \# Assuming a file named 'my-vimrc' exists in the same directory  
     home.file.".vimrc".source \=./my-vimrc;  
   }

   This approach is familiar, allows for easy editing of the config files with standard tools, and benefits from features like syntax highlighting in editors.24  
2. **Using the Nix DSL (programs.\*):** This is the "pure" Nix way. For many popular applications, Home Manager provides a dedicated Domain-Specific Language (DSL) to generate the configuration file directly from Nix expressions. This keeps the entire configuration within .nix files.  
   Nix  
   \# \~/nixos-config/home.nix  
   {  
     programs.git \= {  
       enable \= true;  
       userName  \= "John Doe";  
       userEmail \= "john.doe@example.com";  
     };

     programs.bash \= {  
       enable \= true;  
       shellAliases \= {  
         ll \= "ls \-l";  
         update \= "sudo nixos-rebuild switch \--flake.\#nixos";  
       };  
     };  
   }

   This method is powerful because it allows for programmatic configuration (e.g., sharing variables between different program configurations), but it requires a rebuild for every change to take effect and can be more verbose than editing a plain text file.24

### **4.4 Practical Exercise 4: Configuring Your Shell, Git, and Editor with Home Manager**

This exercise puts Home Manager into practice by declaratively configuring a user's core development tools.

1. **Create home.nix:** In the \~/nixos-config directory, create a new file named home.nix.  
2. **Populate home.nix:** Add the following content, replacing the placeholder values with personal information.  
   Nix  
   \# \~/nixos-config/home.nix  
   { config, pkgs,... }: {  
     \# This must match your username and home directory path.  
     home.username \= "your-username";  
     home.homeDirectory \= "/home/your-username";

     \# This is required for Home Manager to work. It should match the  
     \# system.stateVersion from your configuration.nix.  
     home.stateVersion \= "23.11";

     \# Let Home Manager manage itself.  
     programs.home-manager.enable \= true;

     \# Install some user-specific packages.  
     home.packages \= with pkgs; \[  
       neofetch  
       ripgrep  
     \];

     \# Configure Git using the Nix DSL.  
     programs.git \= {  
       enable \= true;  
       userName  \= "Your Name";  
       userEmail \= "your.email@example.com";  
     };

     \# Configure Bash with some useful aliases.  
     programs.bash \= {  
       enable \= true;  
       shellAliases \= {  
         ls \= "ls \--color=auto";  
         grep \= "grep \--color=auto";  
         ".." \= "cd..";  
       };  
     };  
   }

3. **Update flake.nix and configuration.nix:** Ensure that the changes from section 4.2 (adding Home Manager as an input and module) are present in the flake.nix and that the home-manager.users line is in configuration.nix.  
4. **Rebuild and Verify:** Add the new home.nix file to Git (git add home.nix) and apply the configuration.  
   Bash  
   sudo nixos-rebuild switch \--flake.\#nixos

   After the build completes, open a new terminal session.  
   * Run neofetch to confirm the user package was installed.  
   * Check the global Git config: git config \--global user.name. It should show the name configured in home.nix.  
   * Test the new shell aliases, for example, by typing .. to go up one directory.

## **Day 5: Advanced Techniques and The Path Forward**

**Objective:** To provide patterns for scaling a NixOS configuration and to introduce advanced topics and community resources for continued learning.

### **5.1 Structuring for Scale: Modularizing Your Configuration**

As a NixOS configuration grows, placing everything in a single configuration.nix and home.nix becomes unmanageable. The solution is to modularize the configuration by splitting it into smaller, logically grouped files.28 NixOS is designed for this; configuration.nix is itself just the top-level module in a system composed of hundreds of modules.29  
The imports keyword is the mechanism for combining modules. It takes a list of paths to other .nix files, and Nix recursively merges their configurations. For example, a user could create separate files for different aspects of the system:

* ./modules/base.nix: Common packages and settings for all systems.  
* ./modules/ssh.nix: All SSH server and client configuration.  
* ./modules/desktop.nix: GUI applications, window manager, and display server settings.

The main configuration.nix would then become a simple entry point that imports these components:

Nix

\# \~/nixos-config/configuration.nix  
{ config, pkgs,... }: {  
  imports \= \[  
   ./modules/base.nix  
   ./modules/ssh.nix  
   ./modules/desktop.nix  
   ./hardware-configuration.nix  
  \];

  \# Only machine-specific overrides would remain here.  
  networking.hostName \= "nixos-desktop";  
}

This modular structure is the key to managing multiple machines from a single repository. The flake.nix can define multiple outputs in nixosConfigurations, one for each machine. Each machine's configuration can then import a set of shared modules (like base.nix and ssh.nix) along with its own machine-specific module.30

Nix

\# \~/nixos-config/flake.nix  
{  
  \#... inputs  
  outputs \= { self, nixpkgs,... }: {  
    nixosConfigurations \= {  
      \# Configuration for a desktop machine  
      desktop \= nixpkgs.lib.nixosSystem {  
        system \= "x86\_64-linux";  
        modules \=;  
      };

      \# Configuration for a headless server  
      server \= nixpkgs.lib.nixosSystem {  
        system \= "x86\_64-linux";  
        modules \=;  
      };  
    };  
  };  
}

With this structure, a change to common.nix will be applied to both machines on their next rebuild, while a change to gui.nix will only affect the desktop.30

### **5.2 A Primer on Package Customization with Overlays**

Occasionally, a package in Nixpkgs may not be configured exactly as needed. While one can use package.overrideAttrs for a one-off modification, this does not affect other packages that depend on the original. The standard mechanism for applying global modifications to the package set is through "overlays".32  
An overlay is a function that takes the original package set (super or prev) and returns a modified version (self or final). This allows for changing default build flags, applying patches, or replacing a package version across the entire system. Overlays are added to the nixpkgs.overlays list in the configuration.32  
For example, to apply a custom patch to a package:

Nix

\# In a configuration module  
{  
  nixpkgs.overlays \= \[  
    \# An overlay is a function that modifies the package set.  
    (final: prev: {  
      \# Override the 'htop' package.  
      htop \= prev.htop.overrideAttrs (oldAttrs: {  
        \# Add a patch to the build process.  
        patches \= (oldAttrs.patches or) \++ \[./my-htop-patch.patch \];  
      });  
    })  
  \];  
}

This is an advanced topic, but awareness of overlays is crucial for tackling more complex package customization tasks.

### **5.3 Securely Managing Secrets: An Introduction to sops-nix and agenix**

A major challenge with storing a system configuration in a public Git repository is the management of secrets like API keys, passwords, and private certificates. Committing these in plain text is a significant security risk.  
The NixOS community has developed robust solutions for this problem, with the two most prominent being sops-nix and agenix. Both tools operate on a similar principle: secrets are encrypted using public-key cryptography and the encrypted files (which are safe to commit) are stored in the Git repository.33  
The general workflow is as follows:

1. **Encryption:** Secrets are encrypted using the public keys of the machines that need to access them (e.g., the server's SSH host key) and the public keys of the administrators who need to edit them (e.g., a personal GPG or SSH key).35  
2. **Storage:** The resulting encrypted file is committed to the configuration repository.  
3. **Decryption:** When nixos-rebuild is run on a target machine, the sops-nix or agenix NixOS module uses the machine's private key (e.g., /etc/ssh/ssh\_host\_ed25519\_key) to decrypt the secret at build time.37  
4. **Access:** The decrypted secret is placed in a secure, temporary location (e.g., under /run/secrets/ or /run/agenix/) with strict permissions. Services can then be configured to read the secret from this path, ensuring the plaintext secret never touches the world-readable Nix store.34

This approach provides a secure, auditable, and declarative way to manage secrets as part of the overall system configuration.

### **5.4 Navigating the Ecosystem: Essential Community Resources**

The Nix and NixOS ecosystem is large, powerful, and has a steep learning curve. Knowing where to find help and documentation is critical for success. Here is a curated list of essential resources:

* **Official Manuals:** These are the definitive references for the core components.  
  * (https://nixos.org/manual/nixos/stable)  
  * [Nix Manual](https://nixos.org/manual/nix/stable)  
  * Nixpkgs Manual

    39  
* **Community Help Platforms:**  
  * ([https://discourse.nixos.org/](https://discourse.nixos.org/)): The official forum. This is the best place for well-formed questions, discussions, and announcements.40  
  * ([https://matrix.to/\#/\#nix:nixos.org](https://matrix.to/#/#nix:nixos.org)): For real-time chat, quick questions, and community interaction.40  
  * ([https://www.reddit.com/r/NixOS/](https://www.reddit.com/r/NixOS/)): An active, unofficial community for discussion and help.40  
* **Search and Discovery Tools:**  
  * ([https://search.nixos.org/options](https://search.nixos.org/options)): Search all available configuration options for NixOS and Home Manager.  
  * (https://search.nixos.org/packages): Search the entire Nixpkgs package collection.

    41  
* **Learning and Community-Curated Content:**  
  * (https://wiki.nixos.org/): A community-maintained collection of guides, tutorials, and configuration examples.41  
  * [Awesome Nix](https://github.com/nix-community/awesome-nix): A curated list of high-quality Nix resources, projects, and tutorials.41  
  * [Zero to Nix](https://zero-to-nix.com/): A modern, structured guide to learning Nix from the ground up.

### **5.5 Practical Exercise 5: Refactoring Your Configuration into Modules**

This final exercise solidifies the concept of modularity and prepares the configuration for future growth.

1. **Create a Directory Structure:** In the \~/nixos-config repository, create a modules directory for shared system modules and a hosts directory for machine-specific configurations.  
   Bash  
   mkdir \-p modules hosts/nixos

2. **Create a Base Module:** Create a file modules/base.nix and move common configuration into it, such as the list of system-wide packages.  
   Nix  
   \# \~/nixos-config/modules/base.nix  
   { config, pkgs,... }: {  
     environment.systemPackages \= with pkgs; \[  
       vim  
       git  
       curl  
       htop  
     \];  
     \# Add other common settings here, e.g., time zone  
     time.timeZone \= "Etc/UTC";  
   }

3. **Create an SSH Module:** Create modules/ssh.nix and move all SSH-related configuration there.  
   Nix  
   \# \~/nixos-config/modules/ssh.nix  
   { config, pkgs,... }: {  
     services.openssh \= {  
       enable \= true;  
       settings.PasswordAuthentication \= false;  
     };  
     networking.firewall.allowedTCPPorts \= \[ 22 \];  
   }

4. **Refactor the Main Configuration:** Move the original configuration.nix into the host-specific directory, hosts/nixos/, and simplify it to import the new modules.  
   Bash  
   mv configuration.nix hosts/nixos/

   Nix  
   \# \~/nixos-config/hosts/nixos/configuration.nix  
   { config, pkgs,... }: {  
     imports \= \[  
      ../../modules/base.nix  
      ../../modules/ssh.nix  
      ./hardware-configuration.nix  
     \];

     \# Machine-specific settings  
     networking.hostName \= "nixos";  
     \#... other host-specific options  
   }

5. **Update flake.nix:** Adjust the path in flake.nix to point to the new location of the main configuration file.  
   Nix  
   \#...  
   modules \= \[./hosts/nixos/configuration.nix \];  
   \#...

6. **Rebuild and Verify:** Add the new files to Git (git add.) and rebuild the system. It should build successfully and have the exact same configuration as before, but now with a clean, modular structure ready for expansion.

## **Conclusion**

This five-day journey provides a structured path through the foundational concepts and modern practices of the NixOS ecosystem. The itinerary begins with the paradigm shift to declarative configuration, establishing the core principles of immutability and reproducibility that underpin the entire system. It then progresses through hands-on management of a classic configuration, providing a necessary baseline before undertaking the crucial migration to Flakes—the modern standard for truly reproducible systems. The introduction of Home Manager reinforces the important separation of system and user concerns, enabling portable and cleanly organized user environments. Finally, the introduction of advanced topics like modularization, overlays, and secret management equips the user with the tools and patterns needed to scale their configuration to multiple machines and complex use cases.  
The initial investment in learning NixOS is significant, but the dividends are substantial. A system managed with these principles is transparent, reliable, and recoverable in ways that traditional systems are not. The configuration becomes a durable, version-controlled asset that can be deployed, adapted, and trusted over the long term. With the foundation built over these five days, a user is well-prepared to continue exploring the vast capabilities of NixOS, contribute to its vibrant community, and enjoy the confidence that comes from mastering a truly declarative system.

#### **Works cited**

1. Nix & NixOS | Declarative builds and deployments, accessed October 28, 2025, [https://nixos.org/](https://nixos.org/)  
2. Declarative programming \- Zero to Nix, accessed October 28, 2025, [https://zero-to-nix.com/concepts/declarative/](https://zero-to-nix.com/concepts/declarative/)  
3. What is the advantages of declarative package management : r/NixOS \- Reddit, accessed October 28, 2025, [https://www.reddit.com/r/NixOS/comments/10tjs8d/what\_is\_the\_advantages\_of\_declarative\_package/](https://www.reddit.com/r/NixOS/comments/10tjs8d/what_is_the_advantages_of_declarative_package/)  
4. NixOS \- Zero to Nix, accessed October 28, 2025, [https://zero-to-nix.com/concepts/nixos/](https://zero-to-nix.com/concepts/nixos/)  
5. Get Started with NixOS | NixOS & Flakes Book, accessed October 28, 2025, [https://nixos-and-flakes.thiscute.world/nixos-with-flakes/get-started-with-nixos](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/get-started-with-nixos)  
6. How Nix Works | Nix & NixOS, accessed October 28, 2025, [https://nixos.org/guides/how-nix-works/](https://nixos.org/guides/how-nix-works/)  
7. Introduction \- Nix Reference Manual, accessed October 28, 2025, [https://nix.dev/manual/nix/prev-stable/](https://nix.dev/manual/nix/prev-stable/)  
8. How does Nix's rollback capability work? | Ask Dexa, accessed October 28, 2025, [https://dexa.ai/s/jYfwNl55](https://dexa.ai/s/jYfwNl55)  
9. nixos-rebuild: reconfigure a NixOS machine | Man Page | System Administration \- ManKier, accessed October 28, 2025, [https://www.mankier.com/8/nixos-rebuild](https://www.mankier.com/8/nixos-rebuild)  
10. Nixos-rebuild \- NixOS Wiki, accessed October 28, 2025, [https://nixos.wiki/wiki/Nixos-rebuild](https://nixos.wiki/wiki/Nixos-rebuild)  
11. Anatomy of a NixOS Service Description \- Abilian Innovation Lab, accessed October 28, 2025, [https://lab.abilian.com/Tech/Linux/Packaging/Nix/Anatomy%20of%20a%20NixOS%20Service%20Description/](https://lab.abilian.com/Tech/Linux/Packaging/Nix/Anatomy%20of%20a%20NixOS%20Service%20Description/)  
12. Nix package manager \- NixOS Wiki, accessed October 28, 2025, [https://nixos.wiki/wiki/Nix\_package\_manager](https://nixos.wiki/wiki/Nix_package_manager)  
13. Why Home-manager and Flakes? \- Documentation \- NixOS Discourse, accessed October 28, 2025, [https://discourse.nixos.org/t/why-home-manager-and-flakes/41335](https://discourse.nixos.org/t/why-home-manager-and-flakes/41335)  
14. Flakes \- NixOS Wiki, accessed October 28, 2025, [https://wiki.nixos.org/wiki/Flakes](https://wiki.nixos.org/wiki/Flakes)  
15. Nix flakes \- Zero to Nix, accessed October 28, 2025, [https://zero-to-nix.com/concepts/flakes/](https://zero-to-nix.com/concepts/flakes/)  
16. How to start using Nix(OS) \- Help, accessed October 28, 2025, [https://discourse.nixos.org/t/how-to-start-using-nix-os/37804](https://discourse.nixos.org/t/how-to-start-using-nix-os/37804)  
17. Flakes \- NixOS Wiki, accessed October 28, 2025, [https://nixos.wiki/wiki/Flakes](https://nixos.wiki/wiki/Flakes)  
18. Experimental Features \- Nix Reference Manual, accessed October 28, 2025, [https://nix.dev/manual/nix/2.18/contributing/experimental-features](https://nix.dev/manual/nix/2.18/contributing/experimental-features)  
19. Migrating from NixOS channels to Flakes \- tty.is, accessed October 28, 2025, [https://tty.is/blog/migrating-to-flakes.html](https://tty.is/blog/migrating-to-flakes.html)  
20. Getting started with Nix and Nix Flakes \- DEV Community, accessed October 28, 2025, [https://dev.to/arnu515/getting-started-with-nix-and-nix-flakes-mml](https://dev.to/arnu515/getting-started-with-nix-and-nix-flakes-mml)  
21. Convert configuration.nix to be a flake – NixOS Asia, accessed October 28, 2025, [https://nixos.asia/en/configuration-as-flake](https://nixos.asia/en/configuration-as-flake)  
22. Next step in Nix: Embracing Flakes and Home Manager | Callista, accessed October 28, 2025, [https://callistaenterprise.se/blogg/teknik/2025/04/10/nix-flakes/](https://callistaenterprise.se/blogg/teknik/2025/04/10/nix-flakes/)  
23. Getting Started with Home Manager | NixOS & Flakes Book, accessed October 28, 2025, [https://nixos-and-flakes.thiscute.world/nixos-with-flakes/start-using-home-manager](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/start-using-home-manager)  
24. Managing dotfiles on macOS with Nix | Davis Haupt, accessed October 28, 2025, [https://davi.sh/blog/2024/02/nix-home-manager/](https://davi.sh/blog/2024/02/nix-home-manager/)  
25. Managing dotfiles with Nix \- seroperson's website, accessed October 28, 2025, [https://seroperson.me/2024/01/16/managing-dotfiles-with-nix/](https://seroperson.me/2024/01/16/managing-dotfiles-with-nix/)  
26. Home Manager Manual \- Nix community homepage, accessed October 28, 2025, [https://nix-community.github.io/home-manager/](https://nix-community.github.io/home-manager/)  
27. Setting up your dotfiles with home-manager as a flake · Chris Portela, accessed October 28, 2025, [https://www.chrisportela.com/posts/home-manager-flake/](https://www.chrisportela.com/posts/home-manager-flake/)  
28. Modularize Your NixOS Configuration | NixOS & Flakes Book, accessed October 28, 2025, [https://nixos-and-flakes.thiscute.world/nixos-with-flakes/modularize-the-configuration](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/modularize-the-configuration)  
29. NixOS modules \- NixOS Wiki, accessed October 28, 2025, [https://wiki.nixos.org/wiki/NixOS\_modules\#:\~:text=NixOS%20produces%20a%20full%20system,options%20declared%20in%20other%20modules.](https://wiki.nixos.org/wiki/NixOS_modules#:~:text=NixOS%20produces%20a%20full%20system,options%20declared%20in%20other%20modules.)  
30. Bootstrapping a multi-host NixOS configuration using flakes and ..., accessed October 28, 2025, [https://www.return12.net/posts/bootstrapping-nixos/](https://www.return12.net/posts/bootstrapping-nixos/)  
31. How to manage multiple different machines using nix? : r/NixOS, accessed October 28, 2025, [https://www.reddit.com/r/NixOS/comments/ppl19u/how\_to\_manage\_multiple\_different\_machines\_using/](https://www.reddit.com/r/NixOS/comments/ppl19u/how_to_manage_multiple_different_machines_using/)  
32. Overlays | NixOS & Flakes Book, accessed October 28, 2025, [https://nixos-and-flakes.thiscute.world/nixpkgs/overlays](https://nixos-and-flakes.thiscute.world/nixpkgs/overlays)  
33. NixOS Secrets Management \- Unmoved Centre, accessed October 28, 2025, [https://unmovedcentre.com/posts/secrets-management/](https://unmovedcentre.com/posts/secrets-management/)  
34. Agenix \- NixOS Wiki, accessed October 28, 2025, [https://nixos.wiki/wiki/Agenix](https://nixos.wiki/wiki/Agenix)  
35. Mic92/sops-nix: Atomic secret provisioning for NixOS based ... \- GitHub, accessed October 28, 2025, [https://github.com/Mic92/sops-nix](https://github.com/Mic92/sops-nix)  
36. Managing secrets with agenix \- Jonas Carpay, accessed October 28, 2025, [https://jonascarpay.com/posts/2021-07-27-agenix.html](https://jonascarpay.com/posts/2021-07-27-agenix.html)  
37. Getting Started with Agenix | Mitchell Hanberg, accessed October 28, 2025, [https://www.mitchellhanberg.com/getting-started-with-agenix/](https://www.mitchellhanberg.com/getting-started-with-agenix/)  
38. Nix secrets for dummies | Farid Zakaria's Blog, accessed October 28, 2025, [https://fzakaria.com/2024/07/12/nix-secrets-for-dummies](https://fzakaria.com/2024/07/12/nix-secrets-for-dummies)  
39. Learn Nix | Nix & NixOS | Nix & NixOS, accessed October 28, 2025, [https://nixos.org/learn/](https://nixos.org/learn/)  
40. Community | Nix & NixOS, accessed October 28, 2025, [https://nixos.org/community/](https://nixos.org/community/)  
41. Resources \- NixOS Wiki, accessed October 28, 2025, [https://nixos.wiki/wiki/Resources](https://nixos.wiki/wiki/Resources)