# Create Arch Linux Ansible Role to Replace Debian

## Overview
Create a comprehensive Arch Linux-based Ansible role that mirrors the functionality of the existing Debian role. This includes package management (using pacman instead of apt), Docker setup, JetBrains toolbox installation, media applications, and development tools. The role will enable Arch Linux system provisioning with the same capabilities currently available for Debian/Ubuntu systems.

## Requirements
- Support all package installations from the Debian role using Arch equivalents (pacman, AUR helpers)
- Configure Docker with proper Arch Linux installation and repository setup
- Install JetBrains Toolbox on Arch Linux systems
- Set up media applications including Firefox and Syncthing
- Support development tools and runtime environment setup
- Include conditional GUI installation tasks when `enable_arch_gui` is enabled
- Maintain consistent variable structure with existing roles for easy integration
- Support aarch64 architecture alongside x86_64

## Non-Goals
- Migrating existing Debian systems to Arch (out of scope)
- Supporting other Linux distributions besides Arch
- Creating a unified role that works across all distributions (each role handles distribution-specific logic)
- GUI desktop environment installation (only applications)
- System-wide configuration management beyond package installation

## Acceptance Criteria
- [ ] Arch role directory structure created with all necessary task files
- [ ] `programs.yml` installs core development packages using pacman and AUR
- [ ] `docker.yml` configures Docker with Arch Linux repository and latest packages
- [ ] `jetbrains.yml` downloads and installs JetBrains Toolbox on Arch systems
- [ ] `media.yml` installs Firefox and Syncthing container management
- [ ] `mise.yml` task file exists and is callable from main.yml
- [ ] All tasks properly conditioned on `ansible_distribution == 'Arch'`
- [ ] Task conditionals include `enable_arch_gui` for GUI-specific installations
- [ ] Variables defined in `vars/arch.yml` with pacman package equivalents
- [ ] Role integrated into setup_arch.yml playbook
- [ ] All task names and structure mirror Debian role for consistency

## Implementation Complexity
**Factors:**
- Arch Linux uses different package manager (pacman) requiring syntax changes from apt
- Some Debian packages have different names in Arch (e.g., libfuse2 vs fuse2)
- AUR (Arch User Repository) may be needed for some packages not in official repos
- Docker installation on Arch differs from Debian (no deb822_repository module)
- Package availability varies between Debian and Arch ecosystems
- Need to understand Arch package naming conventions and dependencies

## Implementation

### Approach
Create a new `roles/arch/` directory mirroring the structure of `roles/debian/` with task files adapted for Arch Linux package management. Use pacman as the primary package manager, leveraging Arch's official repositories. For packages unavailable in official repos, document AUR alternatives. Maintain task organization and naming conventions for consistency with the Debian role.

### Files to Create/Modify

1. **Create role directory structure:**
   - `roles/arch/tasks/main.yml`
   - `roles/arch/tasks/programs.yml`
   - `roles/arch/tasks/docker.yml`
   - `roles/arch/tasks/jetbrains.yml`
   - `roles/arch/tasks/media.yml`
   - `roles/arch/tasks/mise.yml`

2. **Update variables:**
   - Update `vars/arch.yml` with pacman package names

3. **Create main playbook file:**
   - Update or create `setup_arch.yml` to include the arch role

### Implementation Steps

1. **Create Arch role main.yml** - `roles/arch/tasks/main.yml`
   - Include conditional task imports for all subtasks
   - Mirror Debian role's structure with Arch-specific conditions

2. **Create programs.yml** - `roles/arch/tasks/programs.yml`
   - Replace apt package manager calls with pacman equivalents
   - Handle packages only in AUR (snap replacements)
   - Update package names for Arch equivalents

3. **Create docker.yml** - `roles/arch/tasks/docker.yml`
   - Use pacman to install docker packages
   - Configure Docker daemon for Arch
   - Add user to docker group

4. **Create jetbrains.yml** - `roles/arch/tasks/jetbrains.yml`
   - Replace libfuse2 with fuse2 (Arch package name)
   - Keep download and installation logic from Debian role
   - Support aarch64 architecture

5. **Create media.yml** - `roles/arch/tasks/media.yml`
   - Install Firefox using pacman
   - Keep Syncthing Docker container management
   - Maintain Docker community module usage

6. **Create mise.yml** - `roles/arch/tasks/mise.yml`
   - Create empty placeholder file (matches Debian structure)

7. **Update vars/arch.yml** - Update variable definitions
   - Map Arch package names for all items in `apt_programs`
   - Remove snap packages (not applicable to Arch)
   - Add AUR helper configuration if needed

## Risks
- **Risk:** Package name differences between Arch and Debian
  - Mitigation: Research Arch package names using `pacman -Ss` and ArchWiki before implementation
  
- **Risk:** Some packages may not exist in official Arch repos
  - Mitigation: Document AUR alternatives and provide instructions for AUR helper setup
  
- **Risk:** Docker installation differs significantly from Debian
  - Mitigation: Follow official Arch Linux Docker installation documentation
  
- **Risk:** Architecture-specific downloads (aarch64 vs x86_64)
  - Mitigation: Implement architecture checks similar to Debian role

## Dependencies
- Ansible 2.10+ (same as existing roles)
- Arch Linux distribution
- pacman package manager (native to Arch)
- Docker (for containerized applications)
- JetBrains Toolbox download availability
- internet connectivity for package downloads and installations

## References
- Existing Debian role: `roles/debian/tasks/`
- Existing Arch vars: `vars/arch.yml`
- Arch Linux pacman documentation
- Docker on Arch Linux: https://wiki.archlinux.org/title/Docker
- JetBrains Toolbox: https://www.jetbrains.com/toolbox-app/
