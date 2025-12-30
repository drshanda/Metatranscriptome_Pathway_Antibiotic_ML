# Pathway-Level Modeling of Antibiotic-Induced Functional Perturbation in the Gut Metatranscriptome

AI/ML • Bioinformatics • Metatranscriptomics • Interpretable ML • Microbial Functional Ecology

> **Project status:** *Ongoing / In active development*

---

## 1. Overview

This project presents an end-to-end, interpretability-first machine learning pipeline for modeling **acute antibiotic-induced functional perturbations** in the gut microbiome using **metatranscriptomic data**.

Rather than operating on taxonomic abundance or gene-level features, this analysis represents microbial state using **pathway-level functional activity** derived from expressed transcripts and curated biological knowledge (KEGG). The primary objective is not to maximize predictive accuracy, but to **identify which microbial functional programs are disrupted, suppressed, or induced** by distinct antibiotic classes.

The pipeline integrates:

* Metatranscriptomic sequencing (RNA; expressed activity)
* Pathway-level functional abstraction (KEGG)
* Supervised machine learning (classification and exploratory regression)
* Explainable AI (SHAP) at the pathway level
* Careful leakage control and small-n evaluation
* Cloud-native ingestion and reproducible analysis infrastructure
* MLOps tooling (MLflow, DVC, Docker, AWS S3)

This project reframes antibiotic perturbation as a **functional execution problem**, emphasizing mechanistic interpretability and biological coherence over leaderboard performance.

---

## 2. Project Objectives

This project aims to:

* Model **acute functional responses** of the gut microbiome to antibiotic exposure.
* Represent microbial state using **pathway-level features**, not taxa or genes.
* Treat antibiotic exposure as a **categorical perturbation**, not a dose–response continuum.
* Compare linear, tree-based, and shallow neural models under constrained sample size.
* Use **SHAP-based interpretability** to attribute predictions to disrupted biological pathways.
* Demonstrate principled ML design aligned with experimental constraints.
* Provide a reproducible, cloud-scalable analysis framework.

---

## 3. Repository Structure

```
01_data/
└── processed/                

02_src/
├── bash/
└── python/

03_results/
├── figures/                  
└── tables/                   

docker/
mlruns/
README.md
```

---

## 4. Methods

### 4.1 Data Source and Study Design

Metatranscriptomic data were obtained from a controlled murine antibiotic perturbation experiment (BioProject **PRJNA504846**) in which six-week-old female C57BL/6J mice were exposed to amoxicillin, ciprofloxacin, or doxycycline for short durations (12–24 h), alongside untreated controls. Each condition included four biological replicates distributed across at least two cages.

---

### 4.2 Functional Feature Engineering

* **Omic layer:** Metatranscriptomics (RNA) only
* **Primary representation:** KEGG pathways

Processing flow:

Reads → genes / KOs → KEGG pathway aggregation → pathway activity matrix

This abstraction emphasizes coordinated functional programs rather than individual genes or taxa.

---

### 4.3 Normalization and Preprocessing

Primary normalization is performed using log-transformed TPM values:

```
[
z_{ij} = \log(\mathrm{TPM}_{ij} + 1)
]
```

The processing order is fixed as:

Quantification → normalization → pathway aggregation → downstream transformation

Centered log-ratio (CLR) normalization is evaluated only as a robustness check due to instability in small-sample settings.

All preprocessing steps are fit **within training folds only** to prevent leakage.

---

### 4.4 Primary Analysis: Multiclass Classification

**Task:**
Multiclass classification of antibiotic exposure
(control vs amoxicillin vs ciprofloxacin vs doxycycline)

**Models evaluated:**

* Regularized logistic regression (baseline anchor)
* XGBoost (interaction discovery)
* Shallow neural networks (primary nonlinear model)

Shallow neural networks are deliberately constrained (1–2 hidden layers, weight decay, early stopping) to capture pathway–pathway interactions without overfitting.

**Evaluation:**

* Repeated stratified *k*-fold cross-validation (50 repeats)
* Macro-F1, balanced accuracy, ROC-AUC
* Confusion matrices and calibration diagnostics

**Interpretability:**

* Pathway-level SHAP values
* Emphasis on biological coherence and stability over maximal metrics

---

### 4.5 Secondary Analysis: Regression on Functional Disruption

As an exploratory complement to classification, functional disruption is modeled as a continuous quantity defined as the Euclidean distance between each sample’s pathway profile and the control centroid in standardized pathway space.

Regression models (regularized linear models and shallow neural networks) are evaluated using rank-based metrics and residual diagnostics. This analysis is retained only if it adds interpretive clarity and is explicitly framed as descriptive rather than causal.

---

## 5. MLOps and Reproducibility

### 5.1 Data Version Control (DVC)

DVC is used to version:

* Pathway activity matrices
* Feature tables
* Train/test splits

Remote storage is backed by Amazon S3.

---

### 5.2 Cloud Storage (AWS S3)

Amazon S3 serves as the system of record for:

* Raw FASTQs
* Processed intermediates
* Final feature matrices

---

### 5.3 Docker Containerization

A Docker image standardizes the bioinformatics and ML environment, ensuring reproducibility across machines and enabling future deployment on managed cloud platforms.

---

### 5.4 MLflow Tracking

MLflow is used to log:

* Model parameters
* Cross-validation metrics
* Final performance summaries
* SHAP artifacts

The MLflow UI enables experiment comparison and model lineage tracking.

---

## 6. Results Summary *(In Progress)*

**Machine Learning Results**
*Placeholder – results to be added once analysis is finalized.*

**Interpretability Results**
*Placeholder – SHAP summaries and pathway-level insights forthcoming.*

**Functional Biology Insights**
*Placeholder – convergence with known antibiotic mechanisms will be assessed.*

---

## 7. Discussion *(Planned)*

This section will synthesize ML results, pathway-level interpretations, and known antibiotic mechanisms to frame antibiotic perturbation as a functional execution problem rather than a taxonomic shift.

---

## 8. Conclusion *(Planned)*

The final project will present a reproducible, interpretable framework for modeling acute functional perturbations in the gut microbiome, emphasizing principled ML design under biological and experimental constraints.

---

## 9. Running the Project *(In Progress)*

Detailed instructions for:

* Launching the analysis EC2 instance
* Pulling data from S3
* Running the bash pipeline
* Executing ML analyses
* Reproducing results via Docker

will be added as the analysis phase is completed.
