[![Stories in Ready](https://badge.waffle.io/project-douglas/epm.png?label=ready&title=Ready)](https://waffle.io/project-douglas/epm)

# Introduction

EPM is a package manager for sets of Ethereum smart contracts. It is meant to simplify the management of git hosted repositories which contain Ethereum contracts. This package manager should work in a way which is roughly analogous to how most package managers operate -- with the addition that it will be able to interact with the Ethereum BlockChain. The Gem will primarily act as a hub for Ethereum contract developers by assisting them in the building, testing, simulating, and deploying of their Ethereum smart contracts.

Ethereum Package Manager allows Ethereum contract developers to push contracts straight to their ethereum clients via rpc. EPM also supports various other necessities when developing ethereum contract networks. In addition to deploying contracts to ethereum clients (Ethereal, Ethereum-go, and Eth-cpp currently support RPC; *note*, AlethZero does not), the package has other features as well. The package:

* keeps a log of the contracts which have been deployed so that you can then easily see those contracts;
* allows users to transact with contracts;
* allows users to query contract storage;
* allows users to deploy a sequence of contracts; and
* allows users to start, stop, and restart ethereum servers with predefined options.

The package manager will (soon-ish) add in a standard tipping functionality which is -- by convention but not requirement -- built to allow tipping of the stack which the developer has used to build, test, and deploy their contracts onto the Ethereum BlockChain. The tipping system will be on by default as a mechanism to assist in further development of Ethereum contract deployment products. It can, of course, be turned off (this is, after all, open source software).

# Installing

This is a Ruby gem and will require that you have Ruby on your system (unless and until someone ports this to Python or Node).

* On debian variants of Linux, use `sudo apt-get install ruby2.0 ruby 1.9-dev` (2.0 is not a strict dependency, the ruby is fairly standard so there should be no problem running on 1.9 but I'm not sure if it will work with 1.8 the 1.9-dev package adds compilation features which are needed for some of the dependencies).
* On OSX ruby is installed by default.
* Windows users can use the rubyinstaller from [here](http://rubyinstaller.org/).

Once you have ensured that you have Ruby on your system, `gem install epm`.

## Important - Configure your Client

**The first thing to do** when you have installed the EPM package is to configure the server. The epm config file is placed by default in `~/.epm/epm-rpc.json`. To install the default settings run:

```bash
$ rake setup
```

After running the rake command (rake is ruby's make), then you can edit the config file in whatever editor you use. Set your preferred settings to however you like them. After that you can use the Create and Transact commands freely.

## Install Compilers

Note, the EPM example config file has paths to all of the compilers. EPM, however is agnostic to which compiler you use. Whichever one (or ones) you want to use, install those. The rest forget about.

The compilers you use should be manually installed.

* Mutan is installed with `go get -u github.com/obscuren/mutan`.
* LLLC is installed with the cpp-ethereum client (see build instructions [here](https://github.com/ethereum/cpp-ethereum/wiki)).
* Serpent is installed with the following commands:

```bash
git clone https://github.com/ethereum/serpent.git
cd serpent
sudo python setup.py install
```

When you send a create or deploy command, EPM will look at the file extension of the contract. When it is `lll` then EPM will call the LLL compiler (from the supplied LLLC path); when it is `mu` or `mut` then EPM will call the Mutan compiler; when it is `se` or `ser` then EPM will call the Serpent compiler.

# Using the CLI Interface

All of the commands are built to run primarily from the command line. Of course the gem will integrate as a Ruby gem into your Ruby application, but primarily it is meant to work from the command line.

EPM offers the following commands:

* `epm start` -- starts the default ethereum server with the configuration options supplied in the config file.
* `epm stop` -- stops the default ethereum server.
* `epm restart` -- restarts the default ethereum server.
* `epm rpc` -- sends any of the rpc commands to the ethereum server. This is useful when developers need access to the rpc commands which are not wrapped and summarized below, or when developers need to use one of the commands below (primarily create and transact) but without the opinionated epm defaults (e.g., endowment of 0, and transact with 0).
* `epm query` -- queries a storage location on the ethereum blockchain. Accepts two arguments, the first argument is the contract to be queried, and the second argument is the storage location to be queried.
* `epm transact` -- sends a transaction to an ethereum contract. By definition this will be a 0 value call. The account sending the transaction will need ether, but only to provide the gas for the individual call. The first argument sent to the command line will be the recipient and the remaining arguments sent to the command line will be the data with each of the data slots separated by a space on the command line (or a new element in the array if calling programmatically). Arguments which are prefixed by `0x` will be treated as hex values and arguments which are not will be treated as strings. EPM will compile all of the arguments into a single RPC call which is correctly formated for all of the clients.
* `epm compile` -- compiles a contract and returns the byte code array for that contract to the command line (or if called programmatically to the calling program).
* `epm create` -- compiles a contract and sends to the ethereum blockchain. Create is used only for single contracts rather than packages of contracts. Use epm deploy to send packages of contracts to the blockchain.
* `epm deploy` -- deploy is the most sophisticated command. It is a wrapper for the remainder of the EPM functionality which works in an automated way to deploy as many contracts and send as many transactions as the developer needs to set up a system of contracts. Deploy will work either with local package-definition files or with package-definition files located on any remote git server which the user has access to. See the package definition section below for the domain specific langauge which EPM deploy uses.

# Package Deployment

Rarely will contract devs only want to deploy one contract. Usually they will want to deploy a series of contracts. EPM assists in this with the package deployment feature. To deploy packages, there are three commands that can be used: `create`, `modify-deploy`, `transact`, `query`, `log`, and `set`.

These commands **must** be formulated as such:

```
# Package Email: dennis@projectdouglas.org
# Package Repository: https://github.com/project-douglas/c3D-contracts

deploy:
  General/DOUG-v6.lll => {{DOUG}}
modify-deploy:
  General/repDB.lll => {{rep}}
  (def 'DOUG 0x9c0182658c9d57928b06d3ee20bb2b619a9cbf7b) => (def 'DOUG {{DOUG}})
transact:
  {{DOUG}} => "register" "rep" {{rep}} "" "" "" "" ""
query:
  {{DOUG}} => 0x18 => {{DOUG_LIKES_YOU}}
```

Each line which does not begin with whitespace is read as a command sequence. The remainder of the lines relevant to that command must begin with whitespace (tabs or spaces do not matter). Lines which are blank or begin with a `#` will not be parsed.

The first portion of the command is the command, the remainder are the params for the command. Each param is separated by ` => `.

## Deploy Command

The command is straight-forward. Deploy a contract params:

1. File of the contract to be compiled and deployed (relative path from the definition file, or absolute path).
2. The variable name of the contract (usually to be used later).

## Modify-Deploy Command

This command first modifies a section of a contract (usually substituting in a variable) and then deploys. Modify-deploy a contract params:

1. File of the contract to be compiled and deployed (relative path from the definition file, or absolute path).
2. The variable name of the contract (usually to be used later).
3. The portion of the contract which will be substituted.
4. What is to replace it (which can use variable names established by contracts deployed prior to this modification).

Modify-deploy commands may have multiple substitutions. Just add additional substitutions on new indented lines separated by `=>`

## Transact Command

The transact command is also straight forward. Transact params:

1. The recipient of the transaction.
2. The data for the transaction.

As with all EPM transactions, this is not meant to support value, it is meant to provide data. Each 32 byte transaction slot is separated by a space. Strings can be sent in quotes or not in quotes, hex address can be sent using 0x or without, empty slots are denoted by "".

## Query Command

The query command is used to query storage spaces. Query params:

1. The address of the contract to query.
2. The storage location of the contract to query.
3. The variable name to store the result as.

## Log Command

The log command will dump into your deploy log. Log params:

1. key
2. val

## Set Command

The set command is used to set key:val pairs for substitution later. Key params:

1. key
2. val

# Tips && Usage

If you want to use AlethZero, that is fine but you will also have to use `eth` headless because AlethZero does not currently have RPC capabilities. I run eth in a second directory listening on a second port with a peer server of AlethZero and it works just fine. Such a set up allows devs to see what is happening in AlethZero (as long as both headless and Aleth connect to the same peer server) but gain the RPC capabilities the package needs.

Note, EPM is set up to interact with contracts, not to transmit value. You'll have to modify the codebase if you intend to use EPM to send ether to contracts. Better yet, use the actual clients for that...!

# Contributing

1. Fork the repository.
2. Create your feature branch (`git checkout -b my-new-feature`).
3. Add Tests (and feel free to help here since I don't (yet) really know how to do that.).
4. Commit your changes (`git commit -am 'Add some feature'`).
5. Push to the branch (`git push origin my-new-feature`).
6. Create new Pull Request.

# License

Modified MIT License - (c) 2014 - Project Douglas Limited. All copyrights are owned by [Project Douglas Limited](http://projectdouglas.org).

See License file.

In other words, don't be a jerk.