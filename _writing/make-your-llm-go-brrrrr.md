---
title: "Making Your LLM Go Brrrrrtt"
description: "Inference engineering methodologies to make your LLM speeeeeeeedy."
type: blog
date: 2026-03-30
venue: ""
link: ""
tags: [Blog, Machine Learning, LLM, Inference Engineering]
status: "under-construction"
---

<section class="page-content">
<div class="container" markdown="1">

## Introduction

This blog is going to be a slightly longer one. I am going to walk you through the many different techniques that we can use as engineers to make our models as fast as possible, I am going to try and make it as comprehensive as possible. To maintain some scope, I am going to focus primarily on inference, but I will also link to some techniques that can be useful during training as well when possible! 

The blog has the following structure:

    1. Theory and Terminology
    2. Batching
    3. Parallelism
    4. Kernel Fusion
    5. Quantisation
    6. Speculation
    7. Caching
    8. Disaggregation
    9. Summary

If you are unsure why I named it "Making Your LLM Go Brrrrrtt" it comes from the A10 Warthog, specifically its main gun. Google it, trust me, its very cool. 

![A10 Gif](/assets/images/make-your-llm-go-brrrrrtt/brrrrrtt.gif)

## Theory and Terminology

Okay, lets get started. The context for this blog is, you have a nice newly trained LLM for you domain. You have spent significant effort and compute with the newest architecture (RoPE, SwiGLU for example) to squeeze as much performance out as possible. But now we want to serve our models to users. You have build an API that users can call, but some users are not too happy with the speed at which their requests get served. This is not ideal. So how could you go about making it faster? 

There are several ways we can measure the speed of our inference, the first is Time To First Token (TTFT) this is the time it takes for the user to start seeing the models output after hitting enter on the query. Tokens per second (TPS) how many tokens our decode stage is generating per second. Time Per Token Output (TPOT) the time it takes to generate an output token for each user that is querying our system. Latency, the overall time it takes to generate the models full reponse to a user. Throughput, the number of output tokens per second that our server can generate across all the users and requests. 

Another thing to be aware of is that certain operations within the network are compute-bound, and others are memory-bound. To place things roughly into categories, the prefill stage is compute-bound and the decode stage is memory-bound.

To make this more concrete, we can look at the roofline chart. This plots arithmetic intensity (FLOPs per byte loaded) on the x-axis against achieved throughput (FLOPs per second) on the y-axis. There are two key regions. 

![Roofline Chart](/assets/images/make-your-llm-go-brrrrrtt/roofline.png)

On the left, the sloped region, our operations are memory-bound. This is characteristic of the decode stage, where each forward pass loads the full set of model weights from HBM to the compute units, but only performs a small matrix-vector multiplication against them. The bottleneck isn't the computation — it's the time required to move all those weights across the memory bus.

On the right, the flat region, our operations are compute-bound. This is characteristic of the prefill stage. We're loading the same weights, but because we're processing the entire input sequence in parallel, those weights get multiplied against a much larger matrix. The arithmetic intensity is far higher, and the bottleneck shifts to how quickly the hardware can execute the matmul itself.

So consider an example where we are working with an A100. It has roughly 312 TFLOPS @ FP16 and 2TB/s bandwidth. Lets take a single linear weight layer of (4096x4096). During decode (batch size 1), you're doing a matrix-vector multiply. That's 4096 × 4096 × 2 = ~33.5M FLOPs. You load 4096 × 4096 × 2 bytes = ~33.5 MB. So the arithmetic intensity is 33.5M / 33.5M = roughly 1 FLOP/byte. Very far left on the chart. During prefill with a sequence of 1024 tokens, we are doing a matrix-matrix multiply. FLOPs go up to 4096 × 4096 × 1024 × 2 = ~34.4B FLOPs. We load roughly the same ~33.5 MB of weights. The arithmetic intensity jumps to roughly 1024 FLOPs/byte. Far right on the chart.

If we want to see how well we are doing we can simply plot our point. For our decode stage, we have worked our the arithmetic intensity for that operation is 1FLOP/byte. So we measure the time it takes to perform that operation, and its 0.02ms. So our throughput is 33.5M FLOPS / 0.00002s = 1.675 TFLOPS. So we plot our point at X=1, Y=1.675 and measure the difference between the roof and our point. Ideally, we want the gap between the roof and our point to be as small as possible!

Keep this in mind. We are going to be revisiting this a lot as we walk through the engineering techniques. I will try and make sure its really clear what the method is actually trying to improve, is it memory, or it is compute?

## Batching Requests



## Running Things in Parallel

...

## Write Better Kernels

...

## Quantisation 

...

## Speculative Decoding

...

## Caching

...

## Splitting Prefill and Decoding

...


## Summary

To summarise, we have discussed many different ways we can improve our inference speed of our model. 





</div>
</section>
