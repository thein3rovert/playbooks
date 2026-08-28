---
id: PLB-002
title: Repair and secure the Nix installation role
status: To Do
assignee: []
created_date: '2026-08-28 22:03'
labels:
  - ansible
  - nix
  - reliability
  - security
dependencies: []
documentation:
  - >-
    backlog/docs/reviews/ansible-standards-review/doc-001 -
    Ansible-Standards-Review-and-Improvement-Plan.md
modified_files:
  - roles/nix/tasks/main.yml
  - roles/nix/defaults/main.yml
priority: high
type: bug
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Make the Nix role reliable for both first-time installation and repeated Ansible runs. The current role contains execution-breaking variable and condition errors and relies on an unverified installer source.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A first-time Nix installation completes without undefined-variable or malformed-condition errors
- [ ] #2 A repeated run against an already configured host completes without unnecessary installation changes
- [ ] #3 The installer source is pinned and its integrity is verified before execution
- [ ] #4 Task conditions execute at the correct Ansible task level
- [ ] #5 The role passes syntax validation and its first-run and repeat-run behavior are verified safely
<!-- AC:END -->
