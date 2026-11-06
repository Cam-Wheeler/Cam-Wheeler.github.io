---
title: "Sanction Monitor"
description: "A scalable event-driven pipeline for real-time sanctions screening of banking transactions, using Kafka, Flink, and LLM-powered analysis."
tags: [Java, Rust, Kafka, Flink, PostgreSQL, Docker, Kubernetes, Terraform, AWS]
github: "https://github.com/Cam-Wheeler/Sanction_Monitor"
live: ""
series: sanction-monitor
---

<section class="page-content">
<div class="container" markdown="1">

## Sanction Monitor

A real-time sanctions screening pipeline for banking transactions. Kafka carries every transaction as an immutable event, Flink enriches flagged ones with recent history, and Claude reasons about whether a match is genuinely suspicious. The whole thing runs locally on Docker Compose and in production on Kubernetes and AWS, provisioned with Terraform.

The full write-up lives in the [Sanction Monitor series](/series/sanction-monitor/), starting with the [system overview](/writing/sanction-monitor-01-system-overview/).

</div>
</section>
