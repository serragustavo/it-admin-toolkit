# Case study: PIN-based secure printing with JumpCloud Cloud LDAP (no Active Directory)

> All names, IPs and IDs in this write-up are anonymized.

## Context

- ~125 users, **no on-prem Active Directory**: identity lives in **JumpCloud**.
- Print management server (NDD Print Host) running on a **Windows Server VM in a public cloud**, outside the office network.
- Office edge: enterprise firewall (Huawei USG series). Two multifunction printers (Epson WorkForce series).
- Goal: users must authenticate at the printer with a **PIN** before a job is released (cost control + confidentiality).

## Architecture

```
[User PC] --LPR (515)--> [Print server VM - cloud VPC] <--LDAPS (636)--> [JumpCloud Cloud LDAP]
                                   |
                         existing VPC route to office LAN
                                   |
                       [Edge firewall - NAT rules] ---> [MFPs on office LAN]
```

## What I did

1. **LDAP integration**
   - Enabled JumpCloud Cloud LDAP and bound the print server over **LDAPS (636), LDAP v3**.
   - Base DN: `ou=Users,o=<ORG_ID>,dc=jumpcloud,dc=com`.
   - Synced **125 users** into the print platform.
2. **Network path cloud ↔ office**
   - Mapped the existing VPC routing to the office LAN instead of building a new IPsec tunnel (avoided unnecessary complexity).
   - Added **NAT rules on the edge firewall** so the printers reached the print server with the IPs registered in the platform.
3. **User identification without AD accounts**
   - Rejected creating local accounts per user and installing extra agents on the server.
   - Chose **LPR (TCP 515)**, which delivers the job with the logged-on username, so the platform maps the job to the correct JumpCloud user.
4. **Authentication at the device:** PIN only (no badge readers).

## Troubleshooting highlights

| Symptom | Root cause | Fix |
|---|---|---|
| LDAP bind "invalid credentials" | Expired/changed password on bind account | Updated credentials; planned move to a dedicated **service account** |
| Printer panel: `500 Internal Server Error` | Printer reached the server from an unexpected source IP | NAT rule on the edge firewall |
| LPR queue mapping failed; spooler rejected its own IP | Long hostname truncated to a 15-char **NetBIOS name**; spooler only recognized the short name | Renamed the server with `Rename-Computer` to a ≤15-char name, rebooted, validated all services |
| Printer at a different IP than registered | Device on Wi-Fi with a manual IP in another subnet | Documented real addressing and aligned the platform/queues |

## Lessons learned

- Cloud IAM + LDAPS can replace on-prem AD for legacy apps that only speak LDAP.
- Check the **existing routing** before designing new tunnels.
- NetBIOS's 15-character limit still bites Windows services in 2026.
- Never leave a personal account as the LDAP bind: use a least-privilege service account.
