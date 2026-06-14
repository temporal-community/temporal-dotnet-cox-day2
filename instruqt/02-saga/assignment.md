---
slug: saga
type: challenge
title: 'Exercise 2: Saga / Compensation'
teaser: Undo completed steps in reverse when a later step fails permanently.
notes:
- type: text
  contents: |-
    # The problem Temporal can't solve for you

    Temporal retries transient failures automatically. But it cannot undo
    side effects that already happened in external systems.

    If payment succeeds and title transfer then fails permanently, the
    buyer has been charged with no title. Temporal kept your workflow
    alive -- but your data is now inconsistent.

    That's your responsibility to fix. The Saga pattern gives you the
    structure to do it.
- type: text
  contents: |-
    # The compensation stack

    After each step with an irreversible side effect, push a compensation
    action onto a stack. If a later step fails permanently, unwind the
    stack -- running compensations in reverse order.

    Payment succeeded? Push RefundPaymentAsync.
    Title transfer succeeded? Push RevertTitleTransferAsync.

    If title transfer then fails after all retries: the stack unwinds,
    the refund runs, and the workflow fails cleanly with no money charged
    and no orphaned records.
tabs:
- title: Terminal 1 - Worker
  type: terminal
  hostname: workshop
  workdir: /root/workshop/exercise
- title: Terminal 2 - Starter
  type: terminal
  hostname: workshop
  workdir: /root/workshop/exercise
- title: VS Code
  type: service
  hostname: workshop
  port: 8080
- title: Temporal UI
  type: service
  hostname: workshop
  port: 8233
difficulty: intermediate
timelimit: 2700
---

# Exercise 2: Saga / Compensation

> [!NOTE]
> **Tabs:** [button label="Terminal 1 - Worker" background="#444CE7"](tab-0) · [button label="Terminal 2 - Starter" background="#444CE7"](tab-1) · [button label="VS Code" background="#444CE7"](tab-2) · [button label="Temporal UI" background="#444CE7"](tab-3)

## Your task

Open [button label="VS Code" background="#444CE7"](tab-2) and open `VehicleTransactionWorkflow.cs`.
The entire body of `RunAsync` is a single TODO.

Implement the Saga using a `Stack<Func<Task>>`:

1. Create an empty `compensations` stack. Wrap all forward steps in a `try` block.
2. Run `CheckFraudAsync` -- read-only, no compensation needed.
3. Run `ProcessPaymentAsync`, capture the confirmation string. Push
   `RefundPaymentAsync` as a compensation immediately after.
4. Run `TransferTitleAsync`. Push `RevertTitleTransferAsync` as a compensation.
5. In the `catch` block, `await` each item in the stack in turn, then re-throw.
6. After the `try/catch`, return a `TransactionResult` with `Status = "Completed"`.

Use `DefaultOptions` for forward activities and `CompensationOptions` for
compensations -- both are defined in the class. Read the README for the full pattern.

## Run it

Start the worker in [button label="Terminal 1 - Worker" background="#444CE7"](tab-0):

```bash,run
dotnet run -- worker
```

Run a few workflows in [button label="Terminal 2 - Starter" background="#444CE7"](tab-1) -- title
transfer fails ~60% of the time, so compensations should trigger quickly:

```bash,run
dotnet run -- starter
```

Watch the worker terminal. When title transfer fails after a successful payment,
you should see:

```
[Compensation] Refunded payment PAY-XXXXXXXXXXXX for buyer buyer-riley-w
```

Open [button label="Temporal UI" background="#444CE7"](tab-3) and find a failed workflow. In its
event history, look for `RefundPaymentAsync` scheduled after the title transfer
failure -- proof the compensation ran as part of the same durable execution.

Click **Check** when compensations have run at least once.
