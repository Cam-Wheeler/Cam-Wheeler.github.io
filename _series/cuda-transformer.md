---
title: "CUDA Transformer"
description: "Building and training a Qwen-style transformer, then rewriting its hot paths in raw CUDA and optimising the GEMMs step by step."
github: "https://github.com/Cam-Wheeler/"
tags: [CUDA, PyTorch, GEMM, Performance]
---

This series documents the whole project from the first PyTorch model to hand-tuned kernels. Each part stands alone, but they build on each other, so the introduction is the best place to start.
