---
title: "CUDA Transformer"
description: "A Qwen-3 style transformer trained with PyTorch DDP, with its hot paths rewritten as custom CUDA kernels and the GEMMs optimised step by step."
tags: [CUDA, C++, PyTorch, GEMM, DDP, Performance]
github: "https://github.com/Cam-Wheeler/cuda_transformer"
live: ""
series: cuda-transformer
---

<section class="page-content">
<div class="container" markdown="1">

## CUDA Transformer

A Qwen-3 style transformer built from scratch, trained with PyTorch Distributed Data Parallel, then progressively moved onto custom CUDA kernels. The GEMM work goes from a naive kernel through coalesced loads, shared-memory tiling and register tiling, measuring each step against the last.

The full write-up lives in the [CUDA Transformer series](/series/cuda-transformer/).

</div>
</section>
