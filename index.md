---
layout: default
title: Home
---

{% include header.html %}

<section id="about" class="section">
  <div class="container">
    <h2>About Me</h2>
    <p>I'm a PhD researcher at The University of Edinburgh building explainable multi-organ segmentation pipelines for PET/CT oncology imaging 🩻. My supervisors are Prof. Adriana Tavares and Dr. Eleonora D'Arnese. My work focuses on closing the gap between benchmark performance and real clinical utility in medical image analysis. We aim to build the next generation of multi-organ segmentation systems.</p>
    <p style="margin-top: 2rem;">Alongside my research, I'm a Teaching Assistant for three courses:</p>
    <ul style="color: var(--text-secondary); margin-bottom: 1rem;">
      <li>☁️ <strong>Applied Cloud Programming</strong> — Where I teach how we can build cloud-native systems using tools like Kafka and Flink!</li>
      <li>👀 <strong>Computer Vision</strong> — Where I am often developing baseline code for student coursework.</li>
      <li>💻 <strong>Informatics Large Practical</strong> — Where we cover topics like REST APIs, Docker, and standard development practice like testing!</li>
    </ul>
    <p style="margin-top: 2rem;">When I'm not researching, you'll still find me coding — check out my <a href="#projects">projects</a> to see what I've been up to 🏗️.</p>
  </div>
</section>

<section id="skills" class="section">
  <div class="container">
    <h2>Skills</h2>
    <div class="skills-grid">
      <div class="skill-group">
        <h3>Languages I Use</h3>
        <ul>
          <li>Python</li>
          <li>Java</li>
          <li>C++</li>
          <li>CUDA</li>
          <li>Rust</li>
          <li>SQL</li>
        </ul>
      </div>
      <div class="skill-group">
        <h3>Libraries I Use</h3>
        <ul>
          <li>PyTorch</li>
          <li>MONAI</li>
          <li>Spring</li>
          <li>Flask</li>
          <li>OpenCV</li>
          <li>Hugging Face</li>
          <li>Pandas / NumPy</li>
          <li>Scikit-Learn</li>
          <li>HydraConf</li>
        </ul>
      </div>
      <div class="skill-group">
        <h3>Tools I Use</h3>
        <ul>
          <li>Docker</li>
          <li>Kubernetes</li>
          <li>Slurm</li>
          <li>Kafka / Flink</li>
          <li>Terraform</li>
          <li>GCP / AWS</li>
          <li>GitHub Actions</li>
          <li>Weights &amp; Biases</li>
        </ul>
      </div>
    </div>
  </div>
</section>

<section id="projects" class="section">
  <div class="container">
    <h2>Projects</h2>
    <div class="projects-grid">
      <div class="project-card">
        <h3>Under Construction</h3>
        <p>This section is currently being built. Check back soon!</p>
      </div>
    </div>
  </div>
</section>

<section id="writing" class="section">
  <div class="container">
    <h2>Things I've Written</h2>
    <div class="projects-grid">
      {% for piece in site.writing %}
        {% include writing-card.html piece=piece %}
      {% endfor %}
    </div>
  </div>
</section>

<section id="reading" class="section">
  <div class="container">
    <h2>Reading</h2>
    <div class="projects-grid">
      {% for paper in site.papers %}
        {% include paper-card.html paper=paper %}
      {% endfor %}
    </div>
  </div>
</section>

<section id="contact" class="section">
  <div class="container">
    <h2>Get In Touch</h2>
    <p>Interested in working together? Feel free to reach out.</p>
    <a href="mailto:Cam.Wheeler@ed.ac.uk" class="btn">Email Me</a>
  </div>
</section>
