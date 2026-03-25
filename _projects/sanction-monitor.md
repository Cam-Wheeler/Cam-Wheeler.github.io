---
title: "Sanction Monitor"
description: "A scalable event-driven pipeline for real-time sanctions screening of banking transactions, using Kafka, Flink, and LLM-powered analysis."
tags: [Java, Rust, Kafka, Flink, PostgreSQL, Docker, Kubernetes, Terraform, AWS]
github: "https://github.com/Cam-Wheeler/Sanction_Monitor"
live: ""
---

<section class="page-content">
<div class="container" markdown="1">

## Sanction Monitor

Banks operating in the UK are required by regulators to screen every transaction against sanctioned individuals. Failure to catch these transactions results in substantial fines. Starling Bank was fined nearly £29 million by the FCA, and Bank of Scotland was fined £160,000 for allowing a sanctioned individual to access their systems using a variant spelling of his name. With transaction volumes in the millions, manual review is impossible. Sanction Monitor is an event-driven pipeline that automates this screening in real time, flagging suspicious transactions for human review while letting legitimate ones flow through.

The core challenge: sanctioned individuals actively try to evade detection, the volume of transactions is enormous, and the cost of missing one is severe. The system needs to be fast, accurate, auditable, and resilient.

Want to check out the code: [press here](https://github.com/Cam-Wheeler/Sanction_Monitor)

## System Architecture

The pipeline is broken into discrete stages connected by Kafka topics, so each component can fail, scale, and evolve independently.

**Transaction Producer** generates transaction events and publishes them to a Kafka topic. In production this would be fed by the bank's core banking system.

**Transaction Filter** consumes raw transactions and performs a fuzzy search for each one against a sanctions database, where I have uploaded the current UK sanctions list, after some cleaning and processing (this could still do with some more work really). Transactions with no match are routed to an Approved Topic and passed straight through. Flagged transactions, where the sender or receiver fuzzy-matches a sanctioned individual, are forwarded to a Filtered Topic for deeper analysis.

**Flink Analyser** is the heart of the system. It consumes flagged transactions from the Filtered Topic, enriches them with recent transaction history using Flink's keyed state, and sends them asynchronously to the Anthropic API for LLM-powered reasoning about whether the match is genuinely suspicious. Results are written to an Enriched Topic.

**Storage Consumer** reads from the Enriched Topic and persists final decisions to a PostgreSQL database, which feeds a dashboard for compliance analysts.

![Our system.](/assets/images/sanction-monitor/system.png)

## Why Kafka?

Kafka gives the system several properties that matter for compliance work. Every transaction, flag, and screening decision becomes an immutable event that can be replayed and audited, this is critical when regulators come by during audit season. The topics act as durable buffers between pipeline stages, so if Flink goes down temporarily (for example), nothing is lost; messages sit in the topic until the consumer catches up. Consumer groups enable horizontal scaling for high throughput, and guaranteed ordering per partition means all transactions for a given account are processed in sequence.

## Why Flink?

Flink handles the stateful, time-sensitive logic that sits at the core of the screening process. When a flagged transaction arrives, Flink extracts the event time, routes it to the correct keyed context (by party UID), checks and updates state with the current transaction's history, registers a TTL timer for cleanup, sends the enriched payload to the Anthropic API asynchronously, and writes the result to the sink. The process looks like this:

![Flink in our system.](/assets/images/sanction-monitor/flink-in-our-system.png)

State management is the trickiest part. Flink maintains a rolling window of recent transactions per party so the LLM has temporal context to reason on, but that state can't live forever. Each entry gets a TTL (e.g., 30 minutes), and a cleanup timer fires once the watermark passes the expiry time.

The watermark buffer is critical here. Originally I was questioning why Flink uses it at all? The lightbulb moment was when I walked through this scenario.

**Scenario 1:** Flink uses the maximum observed event time as its clock.

**Scenario 2:** Flink uses the watermark as its clock.

Event order is not guaranteed in Flink, events all happen in a distinct order, but once they hit the network, we cannot assume that Flink sees them in the same order! Lets say an event rolls in at 14:00:00. We run our event through our Flink job and add that event to state.

![Scenario start.](/assets/images/sanction-monitor/start-of-scenario.png)

Several transactions later, the same individual has made another transaction at 14:30:45. 

![New event.](/assets/images/sanction-monitor/new-event-comes-in.png)

This is past the 30 min TTL of that users event in state. So without the watermark, Flink clears state for that individual.

![Clearning state.](/assets/images/sanction-monitor/clearning-state.png)

But as I said just before, event order is NOT guaranteed so a new event rolls in with the event time 14:29:50. This is within the 30 min TTL of our first event, so we would like to enrich this transaction with the previous one at 14:00:00. But in scenario 1, we cannot... Flink has already cleared state! This is why we need to use watermarks. With watermarks, Flink understands that events prior to 14:30:45 could still arrive, so holds off clearing state until we are certain! 

![Good vs Bad.](/assets/images/sanction-monitor/good-vs-bad.png)


**To summarise:** If a late event arrives, in scenario 1, the state will already have be cleared. So the enrichment lookup has no state to check, and a sanctioned party's transaction gets processed without full history. With a 1-minute watermark buffer, the clock that dictates when Flink takes action lags behind, giving late-arriving events a window to land before state is cleaned. The watermark is our contract with Flink to say "You have seen event with time X, Y, Z. But hold off before taking any action, as some events prior to this one may arrive". In our system the watermark is the difference between a complete analysis of transactions made by a sanctioned individual and a gap in coverage.

## Shifting Left

Systems that follow an Extract-Load-Transform (ELT) pattern will often end up dumping into a warehouse, then batch-processed after the fact. This means intelligence is always a step behind reality. In our system, if we did this, the time suspicious patterns are identified, the money may already have moved for example a sanctioned individual could move money at 9am and we wouldn't flag it until the overnight job runs at 2am. The streaming approach allows for us to shift processing left (closer to the source). Instead of analysing yesterday's data in a batch job, the system reasons about transactions as they happen. Context is fresh, latency is low, and the LLM gets a real-time view of a party's recent activity rather than a stale snapshot. On-top of this, in a more production like system, we can govern our data much more strictly! Each shift left reduces the gap between something happening and the system knowing what to do about it and event streaming is how we get it done!

## Local Development with Docker Compose

For development, the entire system runs locally via Docker Compose, just run `'docker compose up'` and everything should work. Why not just use this in production? Well, if a service crashes, it stays dead until someone notices. There's no automatic scaling, no rolling updates, and no self-healing.

## Moving to Kubernetes

Kubernetes solves the operational problems that Docker alone can't. The desired state is declared in our YAML manifests, and K8s continuously reconciles reality to match. If a pod crashes, K8s replaces it automatically. If throughput spikes, horizontal pod autoscaling adds capacity. Rolling updates deploy new versions with zero downtime, and automatic rollback kicks in if health checks fail. A full breakdown of how K8s works in our system is on the way...

## Cloud Deployment on AWS

The production architecture runs inside a VPC with public and private subnets. An Application Load Balancer and NAT Gateway sit in the public subnet, while MSK (3 brokers running KRaft), the EKS cluster (containing all application pods), and RDS instances live in the private subnet. ECR sits outside the VPC for container image storage. 

All AWS infrastructure is provisioned through Terraform rather than manual console configuration (cause that would take years). Like K8s, Terraform is declarative we describe the desired end state, and it figures out how to get there. A complete breakdown of our terraform and AWS setup is also coming soon!

The workflow follows `'init'` → `'plan'` → `'apply'` → `'destroy'`, this will spin everything up, but DO NOT FORGET TO PULL EVERYTHING DOWN. If you have AWS setup, first move is to setup the bucket that terraform uses to store its current state in AWS. To do this, go into `'backend'` and run `'terraform init'` then `'terraform apply'` (also do `'plan'` if you need to). Then to provision the infrastructure, go to `01-infra` and run the same pipeline. Next move the `scripts` and build and push the images to AWS. Finally, within `02-app` and again, run the pipeline of commands to setup everything, the system in now running in AWS. 

## Summary

The goal of this project was to build a system where the time between a sanctioned individual making a transaction and a compliance officer knowing about it is as small as possible with as much information as they need to make accurate decisions. Event streaming with Kafka and stateful processing with Flink let us move that intelligence inline into the system, reasoning about transactions as they happen rather than in a batch job hours later. On top of that, integrating an LLM into the pipeline gives us nuanced triage that goes beyond simple name matching. We could further extend this with MCPs to enable Claude to reason more effectively on more data!

Beyond the core pipeline, this project was a chance to work through the full journey from local development to production infrastructure. Docker Compose for fast iteration, Kubernetes for resilience and scaling, and Terraform to provision everything on AWS without clicking through consoles. Each step introduced real problems to solve, and I learned a lot working through them. There's still more to do! I'll be writing up the K8s and Terraform layers in more detail soon.

Thanks for reading 📚

</div>
</section>
