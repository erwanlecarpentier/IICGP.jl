# IICGP

[![Build Status](https://travis-ci.com/erwanlecarpentier/IICGP.jl.svg?branch=master)](https://travis-ci.com/erwanlecarpentier/IICGP.jl)
[![Coverage](https://codecov.io/gh/erwanlecarpentier/IICGP.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/erwanlecarpentier/IICGP.jl)
[![Coverage](https://coveralls.io/repos/github/erwanlecarpentier/IICGP.jl/badge.svg?branch=master)](https://coveralls.io/github/erwanlecarpentier/IICGP.jl?branch=master)

(Interactive) Interpretable Cartesian Genetic Programming

To build and install a Julia binding for [OpenCV](https://github.com/opencv/opencv), we recommend [the following tutorial](https://docs.opencv.org/master/d8/da4/tutorial_julia.html).

## Functions

Scalar functions:

| Function | `@btime` | MTCGP |
|---|---|---|
| f_add | 111.783 ns (5 allocations: 160  bytes) | ✔ |
| f_subtract | 117.740 ns (5 allocations: 160  bytes) | ✔ |
| f_mult | 117.701 ns (5 allocations: 160  bytes) | ✔ |
| f_div | 111.949 ns (5 allocations: 160  bytes) | ✗ |
| f_abs | 112.747 ns (5 allocations: 160  bytes) | ✔ |
| f_sqrt | 112.968 ns (5 allocations: 160  bytes) | ✔ |
| f_pow | 180.738 ns (5 allocations: 160  bytes) | ✔ |
| f_exp | 140.404 ns (5 allocations: 160  bytes) | ✔ |
| f_sin | 116.558 ns (5 allocations: 160  bytes) | ✔ |
| f_cos | 118.014 ns (5 allocations: 160  bytes) | ✗ |
| f_tanh | 152.643 ns (5 allocations: 160  bytes) | ✗ |
| f_sqrt_xy | 116.383 ns (5 allocations: 160  bytes) | ✔ |
| f_lt | 112.345 ns (5 allocations: 160  bytes) | ✔ |
| f_gt | 116.601 ns (5 allocations: 160  bytes) | ✔ |
| f_and | 116.466 ns (5 allocations: 160  bytes) | ? |
| f_or | 120.068 ns (5 allocations: 160  bytes) | ? |
| f_xor | 116.824 ns (5 allocations: 160  bytes) | ? |
| f_not | 112.535 ns (5 allocations: 160  bytes) | ? |

Image functions:

| Function | `@btime` | MTCGP |
|---|---|---|
| f_dilate | 157.016 μs (10 allocations: 65.97 KiB) | ✗ |
| f_erode | 156.048 μs (10 allocations: 65.97 KiB) | ✗ |
| f_subtract | 18.538 μs (4 allocations: 65.88 KiB) | ✗ |
| f_remove_details | 626.301 μs (34 allocations: 263.55 KiB) | ✗ |
| f_make_boxes |  | ✗ |
| f_felzenszwalb_segmentation |  | ✗ |
| f_components_segmentation |  | ✗ |
| f_box_segmentation |  | ✗ |
| f_threshold |  | ✗ |
| f_binary |  | ✗ |
| f_corners |  | ✗ |
| f_gaussian |  | ✗ |
| f_laplacian |  | ✗ |
| f_sobel_x |  | ✗ |
| f_sobel_y |  | ✗ |
| f_canny |  | ✗ |
| f_edges |  | ✗ |
| f_opening |  | ✗ |
| f_closing |  | ✗ |
| f_tophat |  | ✗ |
| f_bothat |  | ✗ |
| f_morphogradient |  | ✗ |
| f_morpholaplace |  | ✗ |
| f_bitwise_not |  | ✗ |
| f_bitwise_and |  | ✗ |
| f_bitwise_or |  | ✗ |
| f_bitwise_xor |  | ✗ |
| f_motion_capture |  | ✗ |
| f_motion_distances |  | ✗ |
