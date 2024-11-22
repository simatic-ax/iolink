# @simatic-ax/iolink

## Description

This library is used to control IO-Link devices that are connected to a SIMATIC S7-1500 PLC. It also backs up and restores the configuration of devices and the Siemens IO-Link master. Additionally, it reads diagnostic data from devices.

It is based on the IO-Link library for the S7-1500 PLC in the TIA Portal context. You can find the original library here:

[https://support.industry.siemens.com/cs/document/82981502/](https://support.industry.siemens.com/cs/document/82981502/library-for-io-link-(liolink)?dti=0&lc=en-WW)

## Getting started

Install with Apax:

> If not yet done login to the GitHub registry first.
> More information you'll find [here](https://github.com/simatic-ax/.github/blob/main/docs/personalaccesstoken.md)

```cli
apax add @simatic-ax/iolink
```

Add the namespace in your ST code:

```iec-st
Using Simatic.Ax.iolink;
```

| Classes | Description         |
|---------|---------------------|
| IOLinkBase | Basic class containing common functionality for all other classes. Only for internal use |
| Device | Read or write data to a IO-Link device |
| Master | Backup or restore a complete configuration of a IO-Link Master |
| Diagnose | Retrieve diagnostic data for a IO-Link Master |

You can find a detailed documentation of the blocks and types [here](docs/main.md)
<!-- 
| Functions   | Description             |
|-------------|-------------------------|
| *xyz*       | *description for*xyz**  |

| Function Blocks | Description           |
|-----------------|-----------------------|
| *xyz*           | *description for xyz* | 
-->

## Contribution

Thanks for your interest in contributing. Anybody is free to report bugs, unclear documentation, and other problems regarding this repository in the Issues section or, even better, is free to propose any changes to this repository using Merge Requests.

## Markdownlint-cli

This workspace will be checked by the [markdownlint-cli](https://github.com/igorshubovych/markdownlint-cli) (there is also documented ho to install the tool) tool in the CI workflow automatically.
To avoid, that the CI workflow fails because of the markdown linter, you can check all markdown files locally by running the markdownlint with:

```sh
markdownlint **/*.md --fix
```

## License and Legal information

Please read the [Legal information](LICENSE.md)
