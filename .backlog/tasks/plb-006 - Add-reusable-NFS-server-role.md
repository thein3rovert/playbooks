---
id: PLB-006
title: Add reusable NFS server role
status: Done
assignee:
  - AI
created_date: '2026-09-04 19:04'
updated_date: '2026-09-04 19:07'
labels:
  - ansible
  - nfs
  - storage
dependencies: []
priority: medium
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Provide a reusable Ansible role that prepares a dedicated data disk and configures an Ubuntu host as an NFS server, initially targeting the Nightblood storage VM.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Role safely formats only an unformatted configured data device
- [x] #2 Data filesystem mounts persistently at the configured export path
- [x] #3 NFS exports are configurable and the server is enabled
- [x] #4 Nightblood inventory opts into the role
- [x] #5 Ansible syntax check passes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a reusable storage/nfs-server role with configurable device, filesystem, mount path, and exports.
2. Add Nightblood to production inventory with host-specific NFS settings.
3. Wire the role into site.yml and validate syntax.
4. Run the role on Nightblood only after validation.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented reusable nfs-server role and added Nightblood inventory settings for /dev/sdb mounted at /srv/nfs and exported to 192.168.0.0/24.

Role execution initially found /etc/exports.d absent; added an idempotent directory task and reran successfully. Nightblood now mounts /dev/sdb at /srv/nfs, exports it to 192.168.0.0/24, and nfs-server is active.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added a reusable nfs-server Ansible role with safe format-once behavior, persistent filesystem mounting, configurable exports, and service management. Added Nightblood to production inventory and verified the role successfully configured /dev/sdb as a 100 GB /srv/nfs export.
<!-- SECTION:FINAL_SUMMARY:END -->
