# Case study: UniFi Wi-Fi optimization for a dense office

> Environment anonymized.

## Context

- Corporate office, **6 UniFi access points**, high client density (laptops + phones + IoT such as meeting-room tablets).
- Goal: stable coverage and roaming across the office for all users.

## Approach

1. **Baseline** — reviewed client counts per AP, channel utilization, retries and RSSI in the UniFi controller.
2. **Channel planning**
   - 2.4 GHz: only non-overlapping channels **1 / 6 / 11**, 20 MHz width.
   - 5 GHz: non-overlapping channels per AP, **40 MHz** (80 MHz only where density is low), avoiding DFS where radar events caused channel changes.
3. **TX power**
   - Lowered TX power (especially 2.4 GHz) so cells don't overlap too much. Too much power = sticky clients and co-channel interference.
4. **Minimum RSSI**
   - Enabled minimum RSSI so weak clients are pushed to a closer AP instead of hanging on a distant one.
5. **Band steering**
   - Prefer 5 GHz for capable clients; 2.4 GHz kept for legacy/IoT.
6. **Roaming**
   - Enabled fast roaming (802.11r) after checking client compatibility; tuned so voice/video calls survive moving between rooms.
7. **Vendor proposal review**
   - Critically assessed a third-party infrastructure proposal against the measured needs instead of buying more hardware by default.

## Checklist I reuse

- [ ] Map AP locations vs. where users actually sit and meet
- [ ] 2.4 GHz: 1/6/11, 20 MHz, low power
- [ ] 5 GHz: no overlapping channels between neighbors, 40 MHz
- [ ] Minimum RSSI on, tested with real devices
- [ ] Band steering on
- [ ] Fast roaming tested with a Teams call walking the office
- [ ] Re-check retries/utilization one week later
