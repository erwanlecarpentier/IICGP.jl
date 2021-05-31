# IICGP

[![Build Status](https://travis-ci.com/erwanlecarpentier/IICGP.jl.svg?branch=master)](https://travis-ci.com/erwanlecarpentier/IICGP.jl)
[![Coverage](https://codecov.io/gh/erwanlecarpentier/IICGP.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/erwanlecarpentier/IICGP.jl)
[![Coverage](https://coveralls.io/repos/github/erwanlecarpentier/IICGP.jl/badge.svg?branch=master)](https://coveralls.io/github/erwanlecarpentier/IICGP.jl?branch=master)

(Interactive) Interpretable Cartesian Genetic Programming

To build and install a Julia binding for [OpenCV](https://github.com/opencv/opencv), we recommend [the following tutorial](https://docs.opencv.org/master/d8/da4/tutorial_julia.html).

## Functions

Scalar functions:

| Function | Time (μs) | Allocations | MTCGP |
|---|---|---|---|
| f_add | 0.111 | 5 allocations: 160  bytes | ✔ |
| f_subtract | 0.117 | 5 allocations: 160  bytes | ✔ |
| f_mult | 0.117 | 5 allocations: 160  bytes | ✔ |
| f_div | 0.111 | 5 allocations: 160  bytes | ✗ |
| f_abs | 0.112 | 5 allocations: 160  bytes | ✔ |
| f_sqrt | 0.112 | 5 allocations: 160  bytes | ✔ |
| f_pow | 0.180 | 5 allocations: 160  bytes | ✔ |
| f_exp | 0.140 | 5 allocations: 160  bytes | ✔ |
| f_sin | 0.116 | 5 allocations: 160  bytes | ✔ |
| f_cos | 0.118 | 5 allocations: 160  bytes | ✗ |
| f_tanh | 0.152 | 5 allocations: 160  bytes | ✗ |
| f_sqrt_xy | 0.116 | 5 allocations: 160  bytes | ✔ |
| f_lt | 0.112 | 5 allocations: 160  bytes | ✔ |
| f_gt | 0.116 | 5 allocations: 160  bytes | ✔ |
| f_and | 0.116 | 5 allocations: 160  bytes | ? |
| f_or | 0.120 | 5 allocations: 160  bytes | ? |
| f_xor | 0.116 | 5 allocations: 160  bytes | ? |
| f_not | 0.112 | 5 allocations: 160  bytes | ? |

Image functions:

| Function | Time (μs) | Allocations | MTCGP |
|---|---|---|---|
| f_dilate | 157.016 | 10 allocations: 65.97 KiB | ✗ |
| f_erode | 156.048 | 10 allocations: 65.97 KiB | ✗ |
| f_subtract | 18.538 | 4 allocations: 65.88 KiB | ✗ |
| f_remove_details | 626.301 | 34 allocations: 263.55 KiB | ✗ |
| f_make_boxes | 2872 | 6964 allocations: 2.90 MiB | ✗ |
| f_felzenszwalb_segmentation | 24947 | 137476 allocations: 15.52 MiB | ✗ |
| f_components_segmentation | 1267 | 80 allocations: 1.75 MiB | ✗ |
| f_box_segmentation | 2760 | 920 allocations: 3.24 MiB | ✗ |
| f_threshold | 128.159 | 11 allocations: 546.45 KiB | ✗ |
| f_binary | 180.350 | 18 allocations: 616.47 KiB | ✗ |
| f_corners | 2125 | 15 allocations: 1.17 MiB | ✗ |
| f_gaussian | 1387 | 130 allocations: 1.68 MiB | ✗ |
| f_laplacian | 669.387 | 38 allocations: 1.35 MiB | ✗ |
| f_sobel_x | 741.476 | 120 allocations: 1.65 MiB | ✗ |
| f_sobel_y | 741.825 | 120 allocations: 1.65 MiB | ✗ |
| f_canny | 8932 | 555 allocations: 8.00 MiB | ✗ |
| f_edges | 1792 | 182 allocations: 3.75 MiB | ✗ |
| f_opening | 307.502 | 16 allocations: 66.06 KiB | ✗ |
| f_closing | 307.436 | 16 allocations: 66.06 KiB | ✗ |
| f_tophat | 329.343 | 18 allocations: 131.83 KiB | ✗ |
| f_bothat | 329.280 | 18 allocations: 131.83 KiB | ✗ |
| f_morphogradient | 334.750 | 20 allocations: 197.59 KiB | ✗ |
| f_morpholaplace | 753.983 | 30 allocations: 2.31 MiB | ✗ |
| f_bitwise_not | 20.906 | 4 allocations: 65.88 KiB | ✗ |
| f_bitwise_and | 20.463 | 4 allocations: 65.88 KiB | ✗ |
| f_bitwise_or | 20.672 | 4 allocations: 65.88 KiB | ✗ |
| f_bitwise_xor | 22.856 | 4 allocations: 65.88 KiB | ✗ |
| f_motion_capture | 251.473 | 9 allocations: 197.41 KiB | ✗ |
| f_motion_distances | 3910 | 66781 allocations: 3.48 MiB | ✗ |
