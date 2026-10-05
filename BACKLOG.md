# Product Backlog

### PBI-001. Establish the product vision

Produce `README.md` as the accepted product vision, using the Product Owner’s stated intent. It must clearly state the intended user value, problem, outcome, and important constraints.

Test: Review confirms that the product vision is understandable, internally consistent, and accepted by the Product Owner.

### PBI-002. Derive the initial project plan from the vision

Create the project-specific roadmap and propose the next sprint from the accepted vision. The resulting work must be prioritized, outcome-oriented, and open to iterative refinement.

Test: Review confirms that the roadmap and proposed next sprint are traceable to the accepted vision and ready for Product Owner acceptance.

### PBI-003. Define system view and stakeholders

Define the Meeting Summarizer system boundary, context, and stakeholders that shape the accepted vision.

Test: Review confirms that the system view and stakeholders are understandable and traceable to the accepted vision.

### PBI-004. Define actors, use cases, and success criteria

Identify the actors and define representative end-to-end use cases and success criteria for the accepted vision.

Test: Review confirms that each use case has a clear actor, outcome, and success criterion.

### PBI-005. Materialize the Software Requirements Specification

Create `docs/srs.md` as the Software Requirements Specification for the agreed system boundary, stakeholders, use cases, success criteria, functional and non-functional requirements, release scope, constraints, assumptions, and risks.

Test: Review confirms that the SRS is understandable, testable, and traceable to use cases and the accepted vision.

### PBI-006. Establish and prioritize the Product Backlog

Establish and prioritize Product Owner-level product increments from the agreed requirements.

Test: Review confirms that the backlog is outcome-oriented, ordered, and traceable to requirements.

### PBI-007. Define the initial release scope

Select the smallest useful macOS-first initial release from the prioritized backlog, with acceptance criteria and explicit exclusions that preserve iOS portability and fully local operation.

Test: Review confirms that the initial release scope has measurable acceptance criteria and explicit exclusions.

### PBI-008. Identify constraints, assumptions, and major risks

Identify the constraints, assumptions, and major risks affecting the selected initial release, including fully local operation, OS permissions, model feasibility, device resources, privacy, recording formats, and macOS-to-iOS portability.

Test: Review confirms that significant risks have a mitigation or validation approach and assumptions are explicit.

### PBI-009. Materialize the candidate architecture

Create `docs/architecture.md` as a technology-neutral candidate architecture for the selected initial release, covering shared core capabilities, UI/CLI cooperation, local event coordination, local AI responsibilities, capture, and durable local data. Identify the architectural guidance needed to refine the later prototype work without inventing that work prematurely. Complete the project test profile with the selected toolchain's exact build and test commands before Sprint 2 starts.

Test: Review confirms that the candidate architecture addresses the selected initial release and its significant risks, and that `docs/test-profile.md` contains the exact commands required for Sprint 2.

### PBI-010. Review the Inception baseline for consistency and viability

Review the vision and intended outcomes, `docs/srs.md`, `docs/architecture.md`, Product Backlog, and test profile as one coherent Inception baseline. Record the checkpoint requiring Sprint 2 to refine PBI-011 into independently reviewable prototype work items from the accepted architecture.

Test: Review confirms that the baseline is internally consistent, viable, ready for architecture-risk validation, and has the required prototype-refinement checkpoint.

### PBI-011. Build an executable architectural prototype

Build a focused executable prototype that exercises the selected MVP's architecturally significant paths without claiming to be production implementation.

Test: Review confirms that the prototype can be executed and covers the intended architectural paths.

### PBI-018. Benchmark technical decisions

Compare architecturally significant technology options on common test data and explicit quality and resource measures. Preserve reproducible measurements and their limits so the next iteration can analyze them and make architecture decisions.

Test: Review confirms that compared options used the same evaluation basis and that results and limits are reproducible.

### PBI-012. Validate critical technical assumptions and use cases

Analyze the prototype and benchmark evidence against the highest-risk local capture, transcription, attribution, summarization/action, and UI/CLI-coordination assumptions and use cases. Perform targeted follow-up validation where the evidence is incomplete.

Test: Review confirms that each significant assumption and use case has an evidence-based conclusion or explicitly defined remaining work.

### PBI-013. Refine use cases and supplementary requirements

Refine the use cases and supplementary requirements when prototype evidence exposes gaps, constraints, or changed assumptions.

Test: Review confirms that refinements are traceable to prototype evidence and remain consistent with the accepted vision.

### PBI-014. Stabilize the architecture baseline

Formulate and stabilize the architecture baseline from prototype evidence.

Test: Review confirms that the baseline addresses the selected MVP and its significant risks.

### PBI-015. Assess the Lifecycle Architecture milestone

Decide whether the stabilized architecture is ready to support Construction. If it is not, identify the remaining Elaboration objective rather than asserting the milestone prematurely.

Test: Review confirms that the milestone decision has explicit supporting evidence and remaining objectives where needed.

### PBI-016. Create the Construction plan

Create the Construction plan from the validation evidence, including the updated backlog, delivery order, resource assumptions, and remaining risks.

Test: Review confirms that the Construction plan follows accepted decisions, unresolved risks, resource assumptions, and the milestone assessment.

### PBI-017. Chair-assisted participant identification

Status: Proposed

Allow the local operator, acting as meeting chair, to explicitly provide a
participant list and review suggestions derived only from information they
intentionally supply. This improves speaker attribution without introducing
accounts, mailbox access, external lookup, or any departure from the local-only
privacy boundary.

Test: Review confirms that participant identification uses only explicitly supplied local information and requires no accounts, mailbox access, or network service.

### PBI-019. Operator-controlled transcript segment splitting

Status: Proposed

Allow the operator to split a transcript segment at a selected point through both the CLI and Meeting Review. This lets the operator correct boundaries where one segment combines separate utterances or topics. Preserve source audio references, text corrections, speaker information, and a history of the boundary change.

Test: Verify that splitting through either interface produces the same saved boundaries visible in both interfaces while preserving source text, corrections, speaker information, and audio references.

### PBI-020. Operator-controlled transcript segment merging

Status: Proposed

Allow the operator to merge selected consecutive transcript segments through both the CLI and Meeting Review. This lets the operator correct unnecessary boundaries within a continuous utterance. Preserve source audio references, text corrections, speaker information, and a history of the boundary change.

Test: Verify that merging through either interface produces the same saved segment visible in both interfaces while preserving source text, corrections, speaker information, and audio references.
