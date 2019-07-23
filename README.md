# Demo app for Deep Security

This repository contains a script to help deploy a tomcat application to introduce folks to the capabilities of Deep Security.

## Table of Contents

* [Usage](#usage)
* [Support](#support)
* [Contribute](#contribute)

## Usage

This project contains a tomcat war app and a bash script that installs and configures tomcat.

The demo app can be configured by running the below command.
NOTE: This has only been tested on Ubuntu18.04 platform on AWS.

```
wget https://github.com/deep-security/demo-app/blob/master/demo-app.sh | sudo bash
```

Since tomcat serves requests on port 8080 by default, the security group assigned to the newly created instances needs to allow incoming requests on port 8080.

## Support

For bug reports or feature requests, please [open an issue](../issues). You are welcome to [contribute](#contribute).

Project contributors may be able to help, depending on their time and availability. Please be specific about what you're trying to do, your system, and steps to reproduce the problem.

Official support from Trend Micro is not available. Individual contributors may be Trend Micro employees, but are not official support.

## Contribute

We accept contributions from the community. To submit changes:

1. Fork this repository.
2. Create a new feature branch.
3. Make your changes.
4. Submit a pull request with an explanation of your changes or additions.

We will review and work with you to release the code.