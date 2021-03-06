# PtyLab.jl


| **Documentation**                       | **Build Status**                          | **Code Coverage**               |
|:---------------------------------------:|:-----------------------------------------:|:-------------------------------:|
| [![][docs-stable-img]][docs-stable-url] [![][docs-dev-img]][docs-dev-url] | [![][CI-img]][CI-url] | [![][codecov-img]][codecov-url] |


Julia Implementation of PtyLab. PtyLab is a software for Ptychography reconstruction.

The following features are implemented:
* simple Ptychography reconstruction (loading from a .hdf5 file)
* ePIE
* CUDA support
* probe center of mass restriction
* regular randomized grid generation

The structure should be flexible to add more solvers, etc.

[docs-dev-img]: https://img.shields.io/badge/docs-dev-pink.svg
[docs-dev-url]: https://roflmaostc.github.io/PtyLab.jl/dev/

[docs-stable-img]: https://img.shields.io/badge/docs-stable-darkgreen.svg
[docs-stable-url]:  https://roflmaostc.github.io/PtyLab.jl/stable/

[CI-img]: https://github.com/roflmaostc/PtyLab.jl/actions/workflows/ci.yml/badge.svg
[CI-url]: https://github.com/roflmaostc/PtyLab.jl/actions/workflows/ci.yml

[codecov-img]: https://codecov.io/gh/roflmaostc/PtyLab.jl/branch/main/graph/badge.svg?token=OQ6BQCUFQB
[codecov-url]: https://codecov.io/gh/roflmaostc/PtyLab.jl
