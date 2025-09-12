# Packer Image Builder Script

This repository contains an interactive script for building packer images using
Jenkins Job Builder (JJB) validated combinations, excluding End-of-Life platforms.

## Prerequisites

### 1. Environment Setup

Before running any packer builds, you must configure your environment:
Ensure the latest version of the ci-management repository is cloned on
a host with the cloud tenant access. If you are running this locally
ensure you have a loopback ssh tunnel to the bastion host (IP address of
the Jenkins sandbox) on a separate terminal.

```bash
# Set Python version using pyenv
pyenv global 3.10.13

# Activate ansible virtual environment
source ~/virtualenv/ansible/bin/activate

# Verify setup
python --version  # Should show Python 3.10.13
which python      # Should show pyenv path
```

### 2. Required Files

Ensure these files exist in the parent directory:

- `cloud-env.json` - OpenStack cloud configuration
- `OS_CLOUD` environment variable set to `odlci`
- `.config/openstack/clouds.yaml` - OpenStack credentials

### 3. Directory Structure

The script expects this structure:

```
ci-management/                         # Repository root
├── jjb/
│   └── releng-packer-jobs.yaml  # JJB configuration (validates combinations)
├── packer/
│   ├── common-packer/           # This directory
│   │   ├── build-packer-images.sh  # Interactive JJB script
│   │   ├── vars/                # Variable files
│   │   │   ├── ubuntu-22.04.pkrvars.hcl
│   │   │   ├── ubuntu-24.04.pkrvars.hcl
│   │   │   └── ...
│   │   └── templates/           # Common templates
│   │       ├── builder.pkr.hcl
│   │       ├── docker.pkr.hcl
│   │       └── ...
│   └── templates/               # Additional templates
│       ├── devstack.pkr.hcl
│       ├── robot.pkr.hcl
│       └── ...
└── cloud-env.json               # OpenStack cloud configuration
```

## Usage

### Interactive JJB Script (Recommended)

1. **Navigate to the repository root:**

   ```bash
   cd builder
   ```

2. **Run the JJB-based interactive script:**

   ```bash
   ./packer/common-packer/build-packer-images.sh
   ```

3. **Follow the prompts:**
   - **Option 1**: Build all JJB combinations (21 validated builds, ubuntu-18.04 EOL excluded)
   - **Option 2**: Select specific combinations by number
   - **Option 3**: Exit

4. **Choose execution mode:**
   - **Mode 1**: Execute builds immediately (sequential) with live output + log files
   - **Mode 2**: Generate build commands only (dry-run)
   - **Mode 3**: Execute builds in background (parallel) with individual log files

### JJB Validated Combinations (21 total)

The script only builds combinations validated in `jjb/releng-packer-jobs.yaml`:

**Builder images (6 platforms):**

- centos-7, centos-cs-8, centos-cs-9, ubuntu-20.04, ubuntu-22.04, ubuntu-24.04

**Docker images (3 platforms, ubuntu-18.04 EOL excluded):**

- centos-7, ubuntu-20.04, ubuntu-22.04

**DevStack variants (centos-7 only):**

- devstack, devstack-pre-pip-queens, devstack-pre-pip-rocky, devstack-pre-pip-stein

**Specialized images:**

- helm (centos-7)
- mininet-ovs-217 (ubuntu-22.04, ubuntu-24.04)
- robot (centos-7, centos-cs-8, centos-cs-9, ubuntu-22.04, ubuntu-24.04)

### Direct Command Line

For individual builds, use this format:

```bash
# Set environment first
pyenv global 3.10.13
source ~/virtualenv/ansible-new/bin/activate

# Run packer build
OS_CLOUD=odlci packer.io build \
  -only=openstack.<template-name> \
  -var-file=cloud-env.json \
  -var-file=common-packer/vars/<var-file>.pkrvars.hcl \
  templates/<template-file>.pkr.hcl
```

#### Build Target Examples:

- Builder: `-only=openstack.builder`
- Docker: `-only=openstack.docker`
- Devstack: `-only=openstack.devstack`
- Robot: `-only=openstack.robot`
- Helm: `-only=openstack.helm`

## Available Configurations

### Variable Files (OS/Architecture)

- `centos-7.pkrvars.hcl`, `centos-7-arm64.pkrvars.hcl`
- `centos-8.pkrvars.hcl`
- `centos-cs-8.pkrvars.hcl`, `centos-cs-9.pkrvars.hcl`
- `ubuntu-16.04.pkrvars.hcl`, `ubuntu-16.04-arm64.pkrvars.hcl`
- `ubuntu-18.04.pkrvars.hcl`, `ubuntu-18.04-arm64.pkrvars.hcl`
- `ubuntu-20.04.pkrvars.hcl`, `ubuntu-20.04-arm64.pkrvars.hcl`
- `ubuntu-22.04.pkrvars.hcl`
- `ubuntu-24.04.pkrvars.hcl`, `ubuntu-24.04-arm64.pkrvars.hcl`
- `windows-server-2016.pkrvars.hcl`

### Template Files (Image Types)

- `builder.pkr.hcl` - Basic builder image
- `docker.pkr.hcl` - Docker-enabled image
- `devstack.pkr.hcl` - OpenStack DevStack image
- `helm.pkr.hcl` - Kubernetes Helm image
- `robot.pkr.hcl` - Robot Framework testing image
- `mininet-ovs-217.pkr.hcl` - Mininet networking image
- Various devstack pre-pip templates

## Example Usage Scenarios

### Scenario 1: Test Single Configuration

```bash
cd /home/abelur/git/builder
./packer/common-packer/build-packer-images.sh
# Choose: 2 (select specific combinations)
# Enter: 15 (ubuntu-22.04 + builder)
# Choose: 2 (dry-run mode)
```

### Scenario 2: Build All Ubuntu Builder Images

```bash
cd /home/abelur/git/builder
./packer/common-packer/build-packer-images.sh
# Choose: 2 (select specific combinations)
# Enter: 13 15 7 (ubuntu-20.04, ubuntu-22.04, ubuntu-24.04 + builder)
# Choose: 3 (execute in background)
```

### Scenario 3: Build All JJB Combinations

```bash
cd /home/abelur/git/builder
./packer/common-packer/build-packer-images.sh
# Choose: 1 (build all 21 JJB combinations)
# Choose: 3 (execute in background)
```

## Build Process

Each packer build follows this process:

1. **Environment Setup**: Creates OpenStack instance with specified OS
2. **Python Installation**: Installs Python and configures package mirrors
3. **Ansible Setup**: Creates virtual environment and installs Ansible roles
4. **Provisioning**: Runs Ansible playbooks to configure the image
5. **Image Creation**: Snapshots the configured instance as a reusable image

## Troubleshooting

### Common Issues

1. **Python 3.10 not found**

   ```bash
   # Solution: Set pyenv before running builds
   pyenv global 3.10.13
   ```

2. **Ansible virtual environment missing**

   ```bash
   # Solution: Activate ansible venv
   source ~/virtualenv/ansible-new/bin/activate
   ```

3. **netselect download failures**
   - The script automatically handles version compatibility
   - Ubuntu ≤ 20.04 uses older netselect version
   - Ubuntu > 20.04 uses newer version

4. **Wrong build target**
   - The script automatically determines correct targets
   - Manual commands: use `-only=openstack.<template-basename>`

5. **Cloud configuration issues**
   ```bash
   # Verify cloud-env.json exists and OS_CLOUD is set
   ls -la ../cloud-env.json
   echo $OS_CLOUD  # Should show: odlci
   ```

### Network Issues

If ansible-galaxy role downloads fail:

- Check network connectivity
- Retry the build - temporary network issues often resolve
- Use `--ignore-errors` flag in ansible-galaxy calls if needed

## Performance Tips

- **Parallel builds**: Use background execution mode for multiple builds
- **Selective building**: Use dry-run mode first to verify commands
- **Resource limits**: Monitor OpenStack quota when running many parallel builds
- **Build time**: Each build takes 15-45 minutes depending on complexity

## Build Output and Logging

### Log Files

All builds are automatically logged to `/tmp/` with detailed filenames:

- **Format**: `/tmp/packer-build-{platform}-{template}-{timestamp}.log`
- **Examples**:
  - `/tmp/packer-build-ubuntu-22.04-builder-20250912-143022.log`
  - `/tmp/packer-build-centos-7-docker-20250912-143055.log`
- **Contents**: Complete packer output, Ansible logs, error details

### Build Monitoring

- **Sequential mode (1)**: Live output + log files using `tee`
- **Background mode (3)**: Monitor with `tail -f /tmp/packer-build-*.log`
- **Status check**: Use `jobs` and `wait` commands

Successful builds create:

- **OpenStack Images**: Registered in the OpenStack image service
- **Build Logs**: Complete execution logs in `/tmp/`
- **Ansible Details**: Provisioning steps and configuration changes

Failed builds:

- **Error Logs**: Detailed failure information in log files
- **Cleanup**: Automatically clean up temporary resources
- **Retry**: Can be safely retried after fixing issues

## Script Features

- **Auto-discovery**: Finds all variable and template files automatically
- **Smart filtering**: Excludes configuration files (cloud-env.\*)
- **Interactive selection**: User-friendly numbered menus
- **Flexible execution**: Immediate, dry-run, or background modes
- **Path handling**: Works with any repository name/structure
- **Error handling**: Validates inputs and file existence
- **Progress tracking**: Clear indication of build progress

## Support

For issues:

1. Check the troubleshooting section above
2. Verify all prerequisites are met
3. Use dry-run mode to validate commands
4. Review packer and ansible logs for specific errors
