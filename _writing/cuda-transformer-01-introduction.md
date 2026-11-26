---
title: "Introduction"
description: "What the project is, why I built it, and the route from a PyTorch Qwen to hand-written CUDA GEMMs."
series: cuda-transformer
part: 1
type: blog
date: 2026-11-26
tags: [CUDA, PyTorch, LLM]
---

<section class="page-content">
<div class="container" markdown="1">

## Introduction

Hello!

Welcome to the series on my CUDA Transformer project. My motivation behind doing this was to get my hands dirty with all the technologies I have been reading about recently, while also doing some LLM work in PyTorch. My PhD topic is in computer vision, which is DOMINATED by U-Net (especially within medical imaging) so I was starting to feel a bit left out from all the cool stuff that's happening in NLP. I audited my uni's ML Systems course, and the topics being discussed and taught there really piqued my interest. So this project is really just applying what I picked up from there and through some extra reading!

## The Aims

The aims here are really simple:

1. Take a modern open-weight LLM, implement it and train it on a small dataset.
2. Take the main operations in that LLM and write the CUDA kernels to replace Torch.
3. Optimise those kernels to beat my naive baseline and get as close as I can to Torch (which is backed by cuBLAS)!

A quick spoiler on where things ended up: the main MatMul went from 2.9 TFLOPS in my naive kernel to 9.4 TFLOPS (3.2x faster), which leaves it 1.6x slower than Torch. The batched MatMul used in attention got 4.9x faster and finished within 1.1x of Torch. So I did not beat cuBLAS (shocking, I know), but I got a lot closer than I expected to!

Within this series, I am going to assume a basic bit of knowledge about LLMs and PyTorch. You do not need to know any CUDA, we will cover the basics from scratch before writing any kernels. I will reference the main papers and blogs I have used for the project so if you would like to hit the original work, follow those links!

## The Series

The series will follow this ordering:

1. **The Model: Qwen3** - Here we will discuss the implementation of Qwen3, the clever techniques the team use within it and why. We will also chat about some things that went well as well as places I got stuck and how I fixed them.
2. **Training** - This will discuss how I went from a single GPU smoke test to utilising DDP in Torch across 4 A100s to crank through some proper training (around 300M tokens of TinyStories).
3. **CUDA Basics** - This will be a brief intro into CUDA, we will talk about the basics, things like threads, blocks, grids, warps etc.
4. **Naive CUDA** - I will walk you through my first attempts at the CUDA kernels, no fancy stuff. Just getting them working. This is the baseline for the optimisations.
5. **Profiling** - This part will chat about how I am actually profiling my CUDA code, what it measures, and more importantly, what it does not measure.
6. **MatMul Optimisation Ladder** - We will walk through end to end each optimisation I applied to the main operation in the project: the matrix multiplication. This is where things will hopefully get nitty-gritty.
7. **Other Optimisations** - We will then take a look at the other kernels I optimised: the softmax and the elementwise add and multiply. Here I used what I learned by optimising the MatMul and some new techniques I got to play around with, like warp shuffle reductions. We will also see why some kernels refuse to get any faster no matter what you do to them.
8. **Summary** - A final summary of everything, the final results 🔥.

I hope you enjoy the read :)

</div>
</section>
