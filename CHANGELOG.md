# Changelog

## [0.1.2](https://github.com/st0o0/dotfiles/compare/v0.1.1...v0.1.2) (2026-07-27)


### Bug Fixes

* always use main branch for chezmoi init ([0cfde11](https://github.com/st0o0/dotfiles/commit/0cfde1161fcd4d14c114c87b339f095cbd8bc607))
* use literal TOML strings for starship claude_cost format ([048c6fa](https://github.com/st0o0/dotfiles/commit/048c6fa72a6e5e784800ff5dc3b28f9e66d8fb51))

## [0.1.1](https://github.com/st0o0/dotfiles/compare/v0.1.0...v0.1.1) (2026-07-27)


### Bug Fixes

* avoid sudo in install.sh when already root ([f16c707](https://github.com/st0o0/dotfiles/commit/f16c70737dc81f5efd5b2ec450e9774bb28ce003))

## 0.1.0 (2026-07-27)


### Features

* add --version and --status flags to install.sh ([a5433e7](https://github.com/st0o0/dotfiles/commit/a5433e7a9a1206c51bd191a73161424a46886f54))
* add OS-based filtering to .chezmoiignore ([5671878](https://github.com/st0o0/dotfiles/commit/567187892eda4b318d7c1398bace9b58fb8c82fa))
* add PowerShell profile with Starship, zoxide, fzf, psmux ([247ab67](https://github.com/st0o0/dotfiles/commit/247ab67daaba2fbab63c0534c300134abf9ea3a5))
* add psmux config with Catppuccin Mocha status bar ([7b30f90](https://github.com/st0o0/dotfiles/commit/7b30f907e4c3e5720562e45651ec29784ebb74cd))
* rewrite install.ps1 for PowerShell-native setup with versioning ([620b339](https://github.com/st0o0/dotfiles/commit/620b3396f7856455f186d28e2e582abad8c1cd47))


### Bug Fixes

* add exit-code checks and PS7 requirement to install.ps1 ([e6b831a](https://github.com/st0o0/dotfiles/commit/e6b831ad27fb28c89ae1b266f2dee7157313bf28))
* correct Nerd Font family name to JetBrainsMono NF ([6d4a885](https://github.com/st0o0/dotfiles/commit/6d4a885be2420e17be3c51dc41af4045be002c02))
* enable focus-events in tmux and psmux for Claude Code compatibility ([2523908](https://github.com/st0o0/dotfiles/commit/25239082fca40209c60f3fc86bbd60f1cb1e9458))
* enable RGB true color for tmux-256color terminal override ([147b676](https://github.com/st0o0/dotfiles/commit/147b67648011229dfd6084634e480e657c7e8b5b))
* gate oh-my-zsh externals to non-Windows ([ebfcabf](https://github.com/st0o0/dotfiles/commit/ebfcabf5e0a0e971130e689ffd3273fb38784be6))
* merge date into time module, remove slow custom commands on Windows ([cb64064](https://github.com/st0o0/dotfiles/commit/cb640648a2e6716cf2cf230bedda66ed3b776557))
* OS-compatible starship custom modules and zoxide init ([a882c82](https://github.com/st0o0/dotfiles/commit/a882c82ae272680a8c21bfabccb3de3e262e9cfa))
* prevent install.sh crash when no GitHub release exists ([5a1f7bc](https://github.com/st0o0/dotfiles/commit/5a1f7bc0299960de2c596f6a5892c0719d762569))
* refresh PATH in dotfiles-shell.ps1 for winget-installed tools ([142d8d1](https://github.com/st0o0/dotfiles/commit/142d8d1029ac666780827390c19c39e8dbc35e32))
* remove globe icon from hostname module in starship ([62830d8](https://github.com/st0o0/dotfiles/commit/62830d8370fb22f9e6a6b85c3c259cc3fe7fe4c9))
* restore plink SSH command for YubiKey on Windows ([31de7bc](https://github.com/st0o0/dotfiles/commit/31de7bc1c1d16e0ad58f5919110abdc8dfab0173))
* start psmux directly in WT profile, source dotfiles-shell.ps1 via default-shell ([5632cd8](https://github.com/st0o0/dotfiles/commit/5632cd89ac23d45d21cb6ec17445247ac1c07c05))
* use Documents/ instead of dot_Documents/ for PowerShell profile path ([036ae6c](https://github.com/st0o0/dotfiles/commit/036ae6c9b392123a641ca78a6d017691f0968a55))
* use dot-sourcing and correct Nerd Font name in WT profile ([e6fcd24](https://github.com/st0o0/dotfiles/commit/e6fcd24db308d8d6d791b2beaf3002fb96ba2ba9))
* use env-gated profile hook instead of psmux default-shell wrapper ([aa1a261](https://github.com/st0o0/dotfiles/commit/aa1a261bc1e9aacdfb96a8b2e843a6d65dc33194))
* use Tc flag and terminal-features for broader true color support ([559fc9a](https://github.com/st0o0/dotfiles/commit/559fc9a225d645e54b1529279fb3185650e8ecc3))
* use wildcard Tc override for true color in all terminals ([4f74c12](https://github.com/st0o0/dotfiles/commit/4f74c1288865b4e655553e8d2a70c409366b90eb))
* use wrapper .cmd for psmux default-shell ([a106757](https://github.com/st0o0/dotfiles/commit/a1067576bfe6798ab9de223e538a864fba40bc89))
