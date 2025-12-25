# AI Evaluations

This directory contains artifacts, datasets, and reports related to the evaluation of AI models and applications within the Foundry environment.

## Structure

*   **`safety/`**: Artifacts for testing content safety, jailbreaks, and policy violations.
    *   *Examples:* Adversarial datasets, Prompt Shield test cases, RAI policy evaluation results.
*   **`performance/`**: Benchmarks for latency, throughput, and quality.
    *   *Examples:* Load test scripts (Locust/k6), quality metrics (Grounding, Relevance), cost-per-token analysis.
*   **`red-team/`**: Reports and artifacts from manual or automated red-teaming exercises.
    *   *Examples:* Attack vectors, vulnerability reports, mitigation strategies.

## Usage

Teams should store evaluation configurations (e.g., Prompt Flow evaluation flows) and summarized reports here. Large datasets should be stored in Azure Blob Storage and referenced here.

## Implementation Approach

Evaluations in this environment follow a standardized workflow using **Azure AI Foundry** and **Prompt Flow**.

### 1. Tooling
*   **Azure AI Evaluation SDK**: Used for programmatic assessment of quality (Grounding, Relevance, Coherence) and safety (Hate, Violence, Self-Harm).
*   **Prompt Flow**: Used to construct evaluation flows that run against test datasets.
*   **Azure AI Content Safety**: The underlying engine for safety checks.

### 2. Workflow
1.  **Dataset Creation**: Teams curate "Golden Datasets" (Input/Expected Output) and store them in the Project's Storage Account.
2.  **Flow Definition**: Evaluation logic is defined as a Prompt Flow (stored in `evaluations/{type}/flow`).
3.  **Execution**:
    *   **Local**: Developers run evaluations locally using the SDK during development.
    *   **CI/CD**: The pipeline triggers an evaluation run on Pull Requests.
4.  **Reporting**: Results are logged to the Foundry Project and summarized in this folder.

### 3. Metrics Standard
*   **RAG Quality**: Groundedness (1-5), Relevance (1-5), Retrieval Score.
*   **Safety**: Defect Rate (percentage of unsafe responses).
*   **Performance**: P95 Latency, Tokens/Sec.

