---
title: "Comparison of multi-organ CT image segmentation tools for whole-body [18F]FDG-PET/CT clinical imaging"
description: "Evaluating MOOSE and TotalSegmentator on lung cancer PET/CT data, comparing technical and clinical segmentation metrics."
type: paper
date: 2025-11-27
venue: "EJNMMI"
link: "https://link.springer.com/article/10.1007/s00259-025-07666-5"
tags: [PhD, Machine Learning, Computer Vision, Segmentation, PET/CT]
status: accepted
---

<section class="page-content">
<div class="container" markdown="1">

## Comparison of multi-organ CT image segmentation tools for whole-body [18F]FDG-PET/CT clinical imaging

This is my first paper 🫠. Our hypothesis was that automated multi-organ segmentation tools must perform well under pathological conditions if they are to be used reliably in clinical and research settings.

The two current state-of-the-art methods in this space are MOOSE and TotalSegmentator. Both were trained on datasets with a high proportion of healthy patients, though MOOSE does include Auto-PET, which contains a substantial number of patients with three types of cancer. We wanted to see how these models would perform on our own (rather small) dataset of patients with lung cancer. More importantly, we wanted to evaluate them based on their clinical output, rather than relying solely on typical segmentation metrics.

We found that while both methods are comparable when assessed using technical metrics, they differ significantly when evaluated with clinical metrics such as VOI volume and VOI PET SUV min/max. This highlights two key points: first, clinical evaluation should be standard practice when developing new segmentation methods, not just technical benchmarking; and second, these models could lead to different clinical conclusions when deployed in practice.

[Check it out here](https://link.springer.com/article/10.1007/s00259-025-07666-5){:target="_blank"}

</div>
</section>
