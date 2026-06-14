---
slug: wiring
id: om4yddzp39c2
type: challenge
title: 'Exercise 1: Wiring Activities and Signals'
teaser: Move service calls into proper activities with distinct retry policies, then
  add a signal-based approval gate.
notes:
- type: text
  contents: |-
    # The workflow is doing too much

    The starting code calls FraudService, PaymentService, and TitleService
    directly inside the workflow. That is the same mistake as the original
    pipeline from Day 1 -- just wearing different clothes.

    Direct calls inside a workflow break durability: Temporal cannot retry
    them, they leave no trace in event history, and a crash mid-run loses
    everything after the last completed step.

    Activities are the fix. They are the boundary between your orchestration
    logic and the outside world.
- type: text
  contents: |-
    # Stage A: activities and retry policies

    Your first task is to move the three service calls into
    VehicleTransactionActivities.cs and replace them with
    Workflow.ExecuteActivityAsync calls.

    You will also define two ActivityOptions with different retry policies --
    one for the fraud check (fast, aggressive retry) and one for payment
    and title transfer (slower, conservative retry with a maximum attempt cap).

    Before you write a single line, think: why should these two have
    different policies?
- type: text
  contents: |-
    # Stage B: signals and the approval gate

    High-value vehicle sales require a manager to approve before payment
    proceeds. The workflow needs to pause -- durably, with no polling and
    no timeout -- until a signal arrives.

    A WorkflowSignal method lets external systems push an event into a
    running workflow. WaitConditionAsync blocks the workflow until a
    predicate becomes true. Together they replace polling loops entirely.

    A WorkflowQuery method lets you read the current state of a paused
    workflow from the outside -- from a CLI, a dashboard, or another service.
tabs:
- id: 28uutmab6of1
  title: Terminal 1 - Worker
  type: terminal
  hostname: workshop
  workdir: /root/workshop/exercise
- id: rb37hkuny8ap
  title: Terminal 2 - Starter
  type: terminal
  hostname: workshop
  workdir: /root/workshop/exercise
- id: fziqfiulxafr
  title: VS Code
  type: service
  hostname: workshop
  port: 8080
- id: xazvhlccrhqk
  title: Temporal UI
  type: service
  hostname: workshop
  port: 8233
difficulty: basic
timelimit: 3000
enhanced_loading: null
---

# Exercise 1: Wiring Activities and Signals

> [!NOTE]
> **Tabs:** [button label="Terminal 1 - Worker" background="#444CE7"](tab-0) · [button label="Terminal 2 - Starter" background="#444CE7"](tab-1) · [button label="VS Code" background="#444CE7"](tab-2) · [button label="Temporal UI" background="#444CE7"](tab-3)

## Stage A -- Wire activities and retry policies (20 min)

Open [button label="VS Code" background="#444CE7"](tab-2) and look at `VehicleTransactionWorkflow.cs`.
The workflow calls `FraudService`, `PaymentService`, and `TitleService` directly.

**Step 1: Move the service calls into `VehicleTransactionActivities.cs`.**

Add an `[Activity]`-annotated method for each call. For the fraud check, throw
`ApplicationFailureException` with `nonRetryable: true` if the service returns `false`
-- that is a business rule failure, not a transient error.

**Step 2: Define `FraudOptions` and `PaymentOptions` in the workflow.**

- `FraudOptions` -- fraud checks are fast: `StartToCloseTimeout` 10s, retry 1s
  initial, 10s max, coefficient 2.0.
- `PaymentOptions` -- payment and title calls are slower and more sensitive:
  `StartToCloseTimeout` 60s, retry 2s initial, 60s max, coefficient 2.0,
  `MaximumAttempts` 5.

**Step 3: Replace each direct service call** with `Workflow.ExecuteActivityAsync`,
passing the right options.

**Step 4: Register the activities** with the worker in `Program.cs`. Find the
TODO comment and add `.AddAllActivities(new VehicleTransactionActivities())`.

### Run Stage A

Start the worker in [button label="Terminal 1 - Worker" background="#444CE7"](tab-0):

```bash,run
dotnet run -- worker
```

Run a standard order in [button label="Terminal 2 - Starter" background="#444CE7"](tab-1):

```bash,run
dotnet run -- starter
```

Open [button label="Temporal UI" background="#444CE7"](tab-3) and find the workflow. Each activity
should appear as a separate entry in the event history. Try killing the worker
mid-run with Ctrl+C and restarting -- does the workflow pick up where it left off?

---

## Stage B -- Signal handler and approval gate (20 min)

High-value orders (over $50,000) require manager approval before payment.

**Step 1: Add `ApproveTransactionAsync`** decorated with `[WorkflowSignal]`.
Set `_managerApproved = true` when it fires.

**Step 2: Add `GetStatus`** decorated with `[WorkflowQuery]`.
Return a `WorkflowStatus` with the three state fields. No `await`, no mutation.

**Step 3: Add the approval gate** in `RunAsync`. After the fraud check, if
`order.PurchasePrice > 50_000m`:
- Set `_managerApprovalRequired = true`
- Set `_stage = "awaiting-approval"`
- `await Workflow.WaitConditionAsync(() => _managerApproved)`

### Run Stage B

Restart the worker in [button label="Terminal 1 - Worker" background="#444CE7"](tab-0).

Submit a high-value order in [button label="Terminal 2 - Starter" background="#444CE7"](tab-1):

```bash,run
dotnet run -- starter high
```

The terminal will pause -- the workflow is waiting for approval. Note the workflow ID printed.

Query the paused workflow:

```bash,run
dotnet run -- query vehicle-tx-VIN-2026-COXAUTO-006
```

Send the approval signal:

```bash,run
dotnet run -- approve vehicle-tx-VIN-2026-COXAUTO-006
```

Watch [button label="Terminal 2 - Starter" background="#444CE7"](tab-1) -- the workflow resumes and completes.
In [button label="Temporal UI" background="#444CE7"](tab-3), find the `WorkflowSignalReceived` event in the
history. Notice the gap between that event and the `ActivityTaskScheduled` for payment.

Click **Check** when at least one high-value workflow completes after receiving the approval signal.
