# Data type registry adoption plan

**Status:** data type registry implemented in JCore; consumer adoption is
planned and not part of this change.

This document records how future JCore consumers can adopt the current data
type catalog. It does not provide a migration utility or legacy-ID
compatibility layer.

## Completed in JCore

- Define the registry IDs and parameter formulas in
  [`../architecture/README.md`](../architecture/README.md).
- Expose catalog lookup, encoding, decoding, validation, SMALLINT bounds, and
  PostgreSQL type declarations through the existing Dart package.
- Keep the existing Group 3 API separate; no conversion between catalog IDs
  is performed.

## Deferred schema adoption work

Each consumer's schema adoption must be handled in a separate task after its
schemas, persisted data, dependencies, and rollout constraints have been
inspected:

1. Select the current catalog APIs and IDs for newly authored schemas.
2. Inventory persisted and exchanged schema IDs that the consumer currently
   reads or writes.
3. Decide whether that consumer needs a one-time data migration. Specify
   backups, validation, deployment order, and rollback before implementing it.
4. Update only that consumer's schema handling and tests as part of its own
   adoption work.

The Git dependency paths in AIX and MJUX now select `dart`. Their
schema migration remains separate. This plan does not infer an ID crosswalk or
promise that stored legacy IDs will be accepted by future consumer versions.

## Repository boundaries

The Dart `jcore` package root is `dart`. JUX, JSYNC, other language
ports, and splitting the repository or package are future architecture
decisions. No placeholder package or public surface is created for those
planned layers here.
