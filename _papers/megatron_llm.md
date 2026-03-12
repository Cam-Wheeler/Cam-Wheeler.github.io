---
title: "Megatron-LM: Training Multi-Billion Parameter Language Models Using Model Parallelism"
authors: "Shoeybi et al."
year: 2019
venue: "arXiv"
link: "https://arxiv.org/abs/1909.08053"
tags: [LLMs, NVIDIA, ML Systems]
status: completed
---

<section class="page-content">
<div class="container" markdown="1">

## How Do We Train Huge Models?

### Read The Paper

Want to read the paper? You can find it [here](https://arxiv.org/abs/1909.08053).

### TL;DR
As models become larger, they cannot fit into single GPU devices! Model parallelism is the process of distributing the model across several GPUs, however the current methodologies are complex, requiring reworking of the model and custom compilers! The authors propose Megatron-LM, a framework that uses model and tensor parallelism making only minor changes to PyTorch. They show that scaling the model allows for higher performance of GPT-2 and BERT achieving SOTA results on WikiText103, LAMBADA and RACE datasets!


### Motivation: Why This Paper Matters
We need to scale compute and data in order to achieve better results! The main reason the LLMs we use today (Claude, GPT and Gemini for example) are so good, is down to the ability for the machine learning engineers at the frontier labs to access huge models and vast quantities of data! But how do we train such models? Sure, we can train smaller models on a single device, for example I recently trained a segmentation model for tissue slide segmentation with around 124 million parameters. But what happens when the model has multiple billion parameters and in turn billions of optimiser states to go along with it? We can't fit that into a single GPU! We already know of a similar issue when it comes to designing systems. We have too many users accessing our system and we cannot handle the scale. To solve this problem can vertically scale (we can buy bigger, faster machines) but this is exponentially harder to do as the engineering required to get more onto a single GPU becomes harder and harder the larger we need, so its very expensive. Or we can scale horizontally by just throwing more GPUs at the problem, this much easier to do (as long as GPU providers have enough) and it is cheaper than vertically scaling! But then we get stuck on an issue, our code, our model and our data now no longer just lives on a single device. It is not longer just sticking our code onto the device and letting rip, we need clever ways to actually split our model up and allow communication between GPUs.

At the time the Megatron paper was written, the current frameworks for implementing model parallelism were GPipe and Mesh-Tensorflow, however these methods require that the model be redesigned to fit within the framework or utilise custom compilers. The authors decided that there must be a simpler way to parallelise the the models to allow for larger scaling, without these complexities. So they propose Megatron!

### Core Ideas

Transformers are inherently parallel models. Multi-head self-attention allows us to compute attention across multiple heads all in a single pass, which makes them a natural fit for distributed computation.

There are two main paradigms for scaling deep neural networks. The first is **data parallelism**, where we split a batch of inputs into micro-batches and send those micro-batches to different GPUs that each host the same model weights. After the backward pass, we collect and synchronise the gradients across all GPUs before updating the weights. The second is **model parallelism**, where we split the model itself across multiple GPUs, feeding the output of one as input to the next. When each GPU is responsible for its own set of layers, this is called **layer parallelism** (or pipeline parallelism). We can take this a step further and divide the weights *within* a single layer across multiple GPUs as well, which is called **tensor parallelism**.

### How It Works

The main focus of this paper is on tensor parallelism. The authors cleverly split weight matrices vertically so that each GPU hosts a specific "slice" of the model. Using reduce functions, they can then consolidate the outputs of each GPU to build the complete output for that layer.

In the MLP block of the transformer, they split the weight matrix across columns. This allows the non-linear GeLU activation to be applied on each device independently, since each GPU has a full row of the output and can apply the activation without needing values from other GPUs.

For attention, they distribute the heads across devices so that each GPU is responsible for a subset of the heads. This keeps the heads isolated and does not require any consolidation of values across devices during the attention computation itself.

Both of these approaches are illustrated in the figure below:

![Tensor parallelism in the MLP and attention blocks of a transformer.](/assets/images/megatron-llm/megatron_llm_parallelism.png)

One thing that took me a moment to wrap my head around was the reduce functions. There are two key operators, *f* and *g*, that swap roles depending on whether we are in the forward or backward pass. In the forward pass, *f* is an identity operation that simply copies the input to all GPUs, so every GPU receives the same activation as input to the layer. Meanwhile, *g* is an all-reduce that sums the partial outputs from all GPUs so that every GPU ends up with the same complete result. In the backward pass, the roles flip: *f* becomes an all-reduce because gradients flowing back need to be summed across GPUs, and *g* becomes an identity that just passes gradients through.

LLMs also have very large vocabulary embedding matrices. The authors split this matrix across GPUs so that each device hosts its own portion of the vocabulary. On input, each GPU sees the token and looks up the embedding. If the token falls within that GPU's range, it returns the embedding; otherwise, it returns a zero vector.

To make this concrete, consider a vocabulary of size 50,000 distributed across 2 GPUs. GPU 1 holds rows 1 through 25,000 and GPU 2 holds rows 25,001 through 50,000. When token ID 7,342 comes in, GPU 1 owns that range and returns the full H-dimensional embedding vector, while GPU 2 outputs a zero vector. An all-reduce operation then sums across GPUs, and since only one GPU contributed something non-zero, every GPU now has the correct embedding.

The output layer shares weights with the input embedding. At the output, we need to compute logits over the entire vocabulary by multiplying the hidden state by the embedding matrix to get a score for every token. Since the matrix is already split column-wise, each GPU naturally computes logits for only its portion of the vocabulary: GPU 1 gets logits for tokens 1 through 25,000, and GPU 2 gets logits for tokens 25,001 through 50,000.

Naively, we would need to gather all those logits together to compute softmax and cross-entropy loss, which would mean communicating a tensor of size batch x sequence_length x vocabulary, this is a huge amount of data. Instead, Megatron fuses the cross-entropy computation with the parallel output so that each GPU computes a partial loss over its vocabulary slice. Each GPU then only needs to communicate scalar loss values (batch x sequence_length numbers), which is a dramatically smaller communication cost.

On top of tensor parallelism, the authors also make use of data parallelism. Each batch is split into micro-batches and distributed across model-parallel groups. The figure below illustrates how both forms of parallelism are combined.

![Combined model and data parallelism across GPU groups.](/assets/images/megatron-llm/model_and_data_parallelism.png)

### Results That Stood Out

Scale is critical to achieving state-of-the-art results. As the authors increase the model size, perplexity drops consistently, confirming that larger models trained with Megatron's parallelism approach genuinely improve language modelling performance.

![Perplexity decreases as model size increases.](/assets/images/megatron-llm/llm_perplexity.png)

Architectural tweaks can also improve training stability in parallel scenarios. The authors found that when training a larger BERT model, stability dropped significantly. They altered the architecture slightly by moving the residual connection to before the layer norm, which not only allowed them to train stably but also increased performance.

![The effect of architectural tweaks on training loss stability.](/assets/images/megatron-llm/model_tweaks_and_loss.png)

### Limitations & Open Questions

Although this paper discusses layer parallelism, the implementation focuses on tensor parallelism. It would be very interesting to see both layer and tensor parallelism combined in the same system. For example, tensor parallelism only works if each slice of the model can fit in GPU memory, but what happens when even the slices are too large?

The authors restrict tensor parallelism to within a single DGX node (8 GPUs connected via NVLink), relying on data parallelism to scale across nodes. How could tensor parallelism be extended across node boundaries, and how would the slower inter-node interconnects (compared to NVLink) affect training throughput?

Are there ways to optimise the parameter and optimiser states themselves? Can we reduce the memory footprint through techniques like mixed precision, gradient checkpointing, or state sharding?

Finally, this paper focuses entirely on training. What about inference? How would the parallelism setup differ when serving these models at scale, and what trade-offs arise between latency and throughput?

### My Take

This paper was awesome. The authors demonstrate that scaling compute can push past the state of the art, and they show that weak scaling can be used to train larger LLMs on larger datasets to achieve top results. They improve on existing parallel training pipelines by making only minor tweaks to PyTorch, keeping the approach practical and accessible. I really look forward to reading more recent improvements on Megatron-LM to see if they answer any of my open questions!

</div>
</section>
