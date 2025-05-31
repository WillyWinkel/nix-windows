# nix-windows

A reproducible Nix + Home Manager setup for WSL.

## Quickstart

On a fresh WSL installation, run the following command to bootstrap everything:

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/WillyWinkel/nix-windows/main/bootstrap.sh)
```

Or, for extra safety, download and inspect the script before running:

```sh
curl -fsSL https://raw.githubusercontent.com/WillyWinkel/nix-windows/main/bootstrap.sh -o /tmp/bootstrap.sh
less /tmp/bootstrap.sh   # (optional: inspect the script)
bash /tmp/bootstrap.sh
```

This will:
- Clone this repository to `~/nix-windows`
- Install required dependencies
- Set up passwordless sudo for your user
- Install Nix and Home Manager
- Apply the Home Manager configuration from `~/nix-windows/home.nix`
- Make a `hm` command available in `~/bin` (after the first switch) so you can run Home Manager from anywhere

## Usage

After installation, you can update/apply your Home Manager config at any time by running:

```sh
hm
```

## Development

This repository provides a [devenv](https://devenv.sh/) environment for development and pre-commit checks.

### Usage

1. Install [Nix](https://nixos.org/download.html) if you haven't already.
2. Enter the development shell:

   ```sh
   nix develop
   ```

   This will provide all necessary tools (including `pre-commit`) and automatically install the git hooks.

Now, every commit will check Nix files for syntax errors.

## Manual steps (if needed)

1. Clone this repository:
   ```sh
   git clone https://github.com/WillyWinkel/nix-windows.git ~/nix-windows
   cd ~/nix-windows
   ```
2. Run the bootstrap script:
   ```sh
   ./bootstrap.sh
   ```

## Pre-commit Hooks

This repository uses [pre-commit](https://pre-commit.com/) to run Nix syntax checks before each commit.

> **Note:** If you use the `nix develop` shell, pre-commit and the hooks are set up automatically.  
> If you want to set up pre-commit manually, follow these steps:

### Manual Setup

1. Install pre-commit (if not already installed):

   ```sh
   pip install pre-commit
   ```

2. Install the git hooks:

   ```sh
   pre-commit install
   ```

Now, every commit will check Nix files for syntax errors.

## Notes

- The setup is user-agnostic and contains no sensitive data.
- After installation, you can customize your Home Manager config in `~/nix-windows/home.nix`.
- **Security tip:** Always review scripts before running them from the internet.

## License

This project is licensed under the [MIT License](./LICENSE).
