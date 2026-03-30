---
title: "Making You LLM Go Brrrrr"
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

This blog is going to be a slightly longer one. I am going to walk you through the many different techniques that we can use as engineers to make our models as fast as possible, I am going to try and make it as comprehensive as possible. To maintain some scope, I am going to focus primarily on infernece, but I will also link to some techniques that can be useful during training as well when possible! 

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

## Theory and Terminology

Okay, lets get started. The context for this blog is, you have a nice newly trained LLM for you domain. You have spent significant effort and compute with the newest architecture (RoPE, SwiGLU for example) to squeeze as much performance out as possible. But now we want to serve our models to users. You have build an API that users can call, but some users are not too happy with the speed at which their requests get served. This is not ideal. So how could you go about making it faster? 

There are several ways we can measure the speed of our inference, the first is Time To First Token (TTFT) this is the time it takes for the user to start seeing the models output after hitting enter on the query. Tokens per second (TPS) how many tokens our decode stage is generating per second. Time Per Token Output (TPOT) the time it takes to generate an output token for each user that is querying our system. Latency, the overall time it takes to generate the models full reponse to a user. Throughput, the number of output tokens per second that our server can generate across all the users and requests. 

Another thing to be aware off is the idea that certain operations within our network are compute bound, and others are memory bound. To place things roughly into categories, the prefill stage of our infernece is compute bound and the decode stage is memory bound. What does this mean? Why does this happen?

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
