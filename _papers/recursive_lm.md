---
title: "Recursive Language Models"
authors: "Zhang et al"
year: 2019
venue: "arXiv"
link: "https://arxiv.org/abs/2512.24601"
tags: [LLMs, Inference-Time Scaling, Large contexts]
status: completed
---

<section class="page-content">
<div class="container" markdown="1">

## How Do We Handle VERY Large Contexts?

### Read The Paper

Want to read the paper? You can find it [here](https://arxiv.org/abs/2512.24601).

### TL;DR

LLMs struggle with very long contexts, we get context rot (where performance degrades steeply as the context grows larger and larger). The authors propose instead of using current methodologies like compaction (where we summarise the long context) we place the model inside of a sandbox environment where the large context is a variable that the model can write code to access, filter and process calling sub-agents on those subparts. This frees up the models context and essentially allows for an infinite context length. They show that using their framework, frontier models like GPT-5 can drastically improve their performance on large-context benchmarks like OOLONG and OOLONG-Pairs.

### Motivation: Why This Paper Matters

Context windows are fundamentally broken for complex tasks, and simply making them bigger does not fix the underlying problem. Even frontier models like GPT-5 exhibit context rot, where performance degrades steeply as prompts grow longer. Yet the problem is not just about length, it's about the interaction between length and task complexity. A needle-in-a-haystack task remains easy at 1M tokens because the model is only searching for one thing. But tasks like OOLONG, where the model needs to semantically process nearly every line, break down at far shorter lengths. OOLONG-Pairs, which requires reasoning over pairs of entries, is essentially unsolvable even at 32K tokens where frontier models score very close to 0. Transformers process everything in a single forward pass through attention, and that mechanism cannot scale to tasks requiring dense, structured processing of the input. As LLMs are increasingly adopted for long-horizon tasks involving tens or hundreds of millions of tokens the authors draw seek to solve this issue through Recursive-Language-Models (RLMs).

### How It Works

It's rather simple really! We have a language model *M*, initialise a REPL environment around *M* that treats the prompt the user has given as an environment variable. Give the root model meta-data about the prompt such as the length. Allow the root model to write code to process the prompt and invoke calls to sub-agents with sub-parts of that prompt. Keep this process going until the root model decides it has enough to answer the users query by changing the state to *Final*. Then return *Final*. The root model is the conductor with the sub-agents being the orchestra! It's also worth mentioning that this setup scales more effectively than other systems like THREAD or Claude Code sub-agents because the model uses symbolic recursion rather than autoregressively verbalising each delegation one by one, the root model writes a short piece of code like a for-loop that the REPL then executes, programmatically spawning hundreds of sub-agent calls from just a few lines of code. This means the number of sub-calls is limited only by the data, not by how many tokens the model can output.

![How REPL Works.](/assets/images/recursive-llm/repl_image.png)

When a sub-agent returns an answer to a call, the state of REPL is updated with the answer, but only meta-data about the answer such as a short prefix and the length of the answer are actually added to the root-models context. Essentially anything that can bloat the models context are now environment variables within the sandbox that the model can access when it wants by writing code, only adding a summary of what it is working with to the context itself so that the model stays up to date with the problem its dealing with! 

This methodology is different to current sandbox environments that typically keep the prompt in the models context: 

![Comparison of REPL vs Other Sandbox Environments.](/assets/images/recursive-llm/repl_algo.png)

The authors also show that we can train models to perform this task of delegation. The authors essentially state that the whole orchestration process is one of the more difficult parts. So training a model to specifically orchestrate would improve results. They gathered all of the trajectories where the root model looks at the current state, generates some code, that code runs in the REPL, and the results come back. A full trajectory might have 5-7 of these turns before reaching a final answer. After some filtering, they take the trajectories and generate their SFT data. Where each SFT example is the input of that step (so if we are working with step 3, the input is the the code written, the REPL outputs, the metadata from steps 1 and 2) and the output is then supervised. Essentially they are training the root model to learn how to pre-process the prompt and call sub-agents effectively to get what they want.

### Results That Stood Out

RLMs allow models to scale effectively to the 10M+ token regime, and remarkably, they do not cost more than simply calling a single LLM directly or using other agentic scaffold frameworks. In many cases, the median RLM run is actually cheaper than the base model call because it selectively views context rather than ingesting everything at once.

![RLMs allow for higher performance on very very large context lengths.](/assets/images/recursive-llm/results.png)

The REPL environment is crucial for handling information-dense inputs, especially when they are long. The paper demonstrates that the ability to invoke sub-agents is necessary to accurately answer questions in these settings. For example, the authors found that RLMs will proactively probe and filter the user prompt using regex to search for certain patterns and keywords, narrowing the search space before dispatching targeted sub-calls for semantic analysis.

While RLMs do enable substantially higher performance over larger context lengths compared to base models, performance does still degrade as context length increases. Interestingly, the authors also found that RLM performance is actually worse than the base model on smaller input lengths. Evidence from a friend of mine (Aryo) shows in his [paper](https://arxiv.org/pdf/2507.14417) that scaling reasoning traces at test time can essentially cause overthinking and in-turn performance degradation. Perhaps a similar issue is occurring here? If we scale agents across smaller inputs, does the root model over-complicate things when realistically it could just one-shot the original query itself?

Different models exhibit notably different behaviours when managing context and making sub-calling decisions. While the authors do not tune the system prompt for each model or benchmark specifically, their results make clear that you cannot simply place any model into the REPL environment and expect things to go well. The model's underlying tendencies significantly shape the quality of the resulting trajectories.

### Limitations & Open Questions

The system prompts used in the RLM framework are not model agnostic. The authors had to modify the prompt between GPT-5 and Qwen3-Coder, and again for the fine-tuned Qwen3-8B, to account for differences in how each model behaves as an RLM. This raises the question of why this is the case, and whether there are distinct differences or meaningful similarities across the system prompts that could inform a more universal prompt design.

The RLM framework requires the orchestrating model to have strong coding abilities in order to effectively interact with the REPL environment. This raises an interesting architectural question: what would happen if the orchestration role were split between two models, one acting as a thinker and coordinator that plans the decomposition strategy, and another acting as a worker at the root level that translates those plans into executable code? This might allow for better reasoning and coordination as the "thinker" no longer needs to worry about coding and vice-versa with the coding model, it can just focus on coding. 

The models used within the RLM framework still need sufficient context to be effective, despite the REPL's ability to limit how much context is loaded at any given time. On the sub-call side in particular, models with limited output budgets often run out of tokens because chain-of-thought reasoning consumes the majority of the available output length. This suggests a further extension: what if the coordinator could dynamically choose which model to call and dispatch those calls asynchronously? For quick, straightforward answers it could invoke a smaller model, while for difficult questions requiring deep reasoning it could route to a large-context thinking model, optimising both cost and quality across the trajectory.

### My Take

The paper gives us a very interesting insight into how we can utilise agentic sandboxes to enable models to work through large contexts (the paper hints at possibly infinite contexts) by careful setup on the environment. This enables the root model to write code to search, process and filter the user input and recursively call itself on sub-tasks. 

That said, the performance degradation on smaller inputs is something I find particularly interesting and underexplored. I suspect the root model over-complicates tasks that it could easily one-shot, similar to the overthinking problem Aryo identifies in his paper on scaling reasoning traces. If that's the case, a meaningful next step would be building a routing mechanism that decides whether to use the RLM framework at all based on input complexity, rather than always defaulting to the full orchestration pipeline. 

I also think the paper underexplores the engineering side of the framework. The sub-calls are currently synchronous and use a single model, but there's no reason the coordinator couldn't dynamically route tasks to different models based on difficulty (small models for quick classifications, large thinking models for complex reasoning). Combining this with asynchronous dispatch could dramatically reduce both cost and latency. The fact that the authors got strong results with such a naive implementation suggests there is a lot of headroom here.

Finally, the requirement for strong coding ability in the root model feels like an unnecessary bottleneck for an orchestrator, for example a PM and an SWE have distinct and complementary skills, so why not try and replicate that? Splitting the orchestration into a planning model and a code-generation model could open the framework up to a much wider range of base models and potentially improve the quality of both the decomposition strategy and the code itself!

</div>
</section>
