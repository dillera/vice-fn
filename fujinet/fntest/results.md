# fntest results

C64 test programs from fujinet-lib's `tests-latest` release, run in VICE
against fujinet-pc over NetIEC. `run-fntests.sh` adds one row per test per
run. Each program stops at its first failure, so Passed and Failed count only
the checks that ran. STATUS.md explains the failures.

| When | Test | Result | Passed | Skipped | Failed | First failure | Firmware | Tests | Run |
|---|---|---|---|---|---|---|---|---|---|
| 2026-10-23 15:00 | appkey | PASS | 18 | 0 | 0 |  | vice-fn b80e8728+ (before the toUTF8 fix) | 31cea90 | runs/2026-10-23_150023 |
| 2026-10-23 15:00 | clipbord | FAIL | 1 | 0 | 1 | /// reads it back (line 84) | vice-fn b80e8728+ (before the toUTF8 fix) | 31cea90 | runs/2026-10-23_150023 |
| 2026-10-23 15:00 | devlist | FAIL | 3 | 0 | 1 | Network 1 online (line 93) | vice-fn b80e8728+ (before the toUTF8 fix) | 31cea90 | runs/2026-10-23_150023 |
| 2026-10-23 15:00 | disk | FAIL | 1 | 0 | 1 | SD host slot found (line 74) | vice-fn b80e8728+ (before the toUTF8 fix) | 31cea90 | runs/2026-10-23_150023 |
| 2026-10-23 15:00 | fujidev | FAIL | 14 | 0 | 1 | fuji_put_device_slots round-trip succeeds (line 125) | vice-fn b80e8728+ (before the toUTF8 fix) | 31cea90 | runs/2026-10-23_150023 |
| 2026-10-23 15:00 | html | FAIL | 2 | 0 | 1 | network no error (line 42) | vice-fn b80e8728+ (before the toUTF8 fix) | 31cea90 | runs/2026-10-23_150023 |
| 2026-10-23 15:00 | net5plus | FAIL | 2 | 0 | 1 | listener reports connection (line 395) | vice-fn b80e8728+ (before the toUTF8 fix) | 31cea90 | runs/2026-10-23_150023 |
| 2026-10-23 15:00 | netfile | FAIL | 2 | 0 | 1 | working directory matches (line 269) | vice-fn b80e8728+ (before the toUTF8 fix) | 31cea90 | runs/2026-10-23_150023 |
| 2026-10-23 15:00 | netproto | FAIL | 1 | 0 | 1 | read returns exactly 64 bytes (line 223) | vice-fn b80e8728+ (before the toUTF8 fix) | 31cea90 | runs/2026-10-23_150023 |
| 2026-10-23 15:00 | network | FAIL | 3 | 0 | 1 | network_read echoed data (line 68) | vice-fn b80e8728+ (before the toUTF8 fix) | 31cea90 | runs/2026-10-23_150023 |
| 2026-10-23 15:00 | parserr | FAIL | 0 | 0 | 1 | bare NET_PARSE with no channel reports an error (line 94) | vice-fn b80e8728+ (before the toUTF8 fix) | 31cea90 | runs/2026-10-23_150023 |
| 2026-10-23 15:00 | qrcode | PASS | 22 | 0 | 0 |  | vice-fn b80e8728+ (before the toUTF8 fix) | 31cea90 | runs/2026-10-23_150023 |
| 2026-10-23 15:00 | wifi | PASS | 18 | 0 | 0 |  | vice-fn b80e8728+ (before the toUTF8 fix) | 31cea90 | runs/2026-10-23_150023 |
| 2026-10-23 15:07 | appkey | PASS | 18 | 0 | 0 |  | vice-fn b80e8728+55d0f7 | 31cea90 | runs/2026-10-23_150757 |
| 2026-10-23 15:07 | clipbord | FAIL | 12 | 0 | 1 | write open on an older snippet fails (line 119) | vice-fn b80e8728+55d0f7 | 31cea90 | runs/2026-10-23_150757 |
| 2026-10-23 15:07 | clock | FAIL | 4 | 0 | 1 | TZ read-back matches set value (line 40) | vice-fn b80e8728+55d0f7 | 31cea90 | runs/2026-10-23_150757 |
| 2026-10-23 15:07 | devlist | FAIL | 3 | 0 | 1 | Network 1 online (line 93) | vice-fn b80e8728+55d0f7 | 31cea90 | runs/2026-10-23_150757 |
| 2026-10-23 15:07 | disk | FAIL | 1 | 0 | 1 | SD host slot found (line 74) | vice-fn b80e8728+55d0f7 | 31cea90 | runs/2026-10-23_150757 |
| 2026-10-23 15:07 | fujidev | FAIL | 14 | 0 | 1 | fuji_put_device_slots round-trip succeeds (line 125) | vice-fn b80e8728+55d0f7 | 31cea90 | runs/2026-10-23_150757 |
| 2026-10-23 15:07 | html | FAIL | 7 | 0 | 1 | decoded body equals ABC (line 91) | vice-fn b80e8728+55d0f7 | 31cea90 | runs/2026-10-23_150757 |
| 2026-10-23 15:07 | net5plus | FAIL | 2 | 0 | 1 | listener reports connection (line 395) | vice-fn b80e8728+55d0f7 | 31cea90 | runs/2026-10-23_150757 |
| 2026-10-23 15:07 | netfile | FAIL | 2 | 0 | 1 | working directory matches (line 269) | vice-fn b80e8728+55d0f7 | 31cea90 | runs/2026-10-23_150757 |
| 2026-10-23 15:07 | netproto | FAIL | 2 | 0 | 1 | 64 bytes match pattern (line 226) | vice-fn b80e8728+55d0f7 | 31cea90 | runs/2026-10-23_150757 |
| 2026-10-23 15:07 | network | FAIL | 21 | 1 | 1 | N1 DOES NOT have bytes waiting (line 270) | vice-fn b80e8728+55d0f7 | 31cea90 | runs/2026-10-23_150757 |
| 2026-10-23 15:07 | parserr | FAIL | 0 | 0 | 1 | bare NET_PARSE with no channel reports an error (line 94) | vice-fn b80e8728+55d0f7 | 31cea90 | runs/2026-10-23_150757 |
| 2026-10-23 15:07 | qrcode | PASS | 22 | 0 | 0 |  | vice-fn b80e8728+55d0f7 | 31cea90 | runs/2026-10-23_150757 |
| 2026-10-23 15:07 | wifi | PASS | 18 | 0 | 0 |  | vice-fn b80e8728+55d0f7 | 31cea90 | runs/2026-10-23_150757 |
| 2026-10-23 15:18 | appkey | PASS | 18 | 0 | 0 |  | vice-fn b80e8728+55d0f7 | 31cea90 | runs/2026-10-23_151804 |
| 2026-10-23 15:18 | clock | FAIL | 4 | 0 | 1 | TZ read-back matches set value (line 40) | vice-fn b80e8728+55d0f7 | 31cea90 | runs/2026-10-23_151804 |
| 2026-10-23 15:31 | clock | FAIL | 32 | 0 | 1 | APPLE3_SOS reserved byte[8] is 0 (line 184) | vice-fn b80e8728+5ab5ef | 31cea90 | runs/2026-10-23_153106 |
| 2026-10-23 15:35 | clock | PASS | 48 | 0 | 0 |  | vice-fn b80e8728+04586d | 31cea90 | runs/2026-10-23_153547 |
| 2026-10-23 15:36 | appkey | PASS | 18 | 0 | 0 |  | vice-fn b80e8728+04586d | 31cea90 | runs/2026-10-23_153624 |
| 2026-10-23 15:36 | clipbord | FAIL | 12 | 0 | 1 | write open on an older snippet fails (line 119) | vice-fn b80e8728+04586d | 31cea90 | runs/2026-10-23_153624 |
| 2026-10-23 15:36 | clock | PASS | 48 | 0 | 0 |  | vice-fn b80e8728+04586d | 31cea90 | runs/2026-10-23_153624 |
| 2026-10-23 15:36 | devlist | FAIL | 3 | 0 | 1 | Network 1 online (line 93) | vice-fn b80e8728+04586d | 31cea90 | runs/2026-10-23_153624 |
| 2026-10-23 15:36 | disk | FAIL | 1 | 0 | 1 | SD host slot found (line 74) | vice-fn b80e8728+04586d | 31cea90 | runs/2026-10-23_153624 |
| 2026-10-23 15:36 | fujidev | FAIL | 14 | 0 | 1 | fuji_put_device_slots round-trip succeeds (line 125) | vice-fn b80e8728+04586d | 31cea90 | runs/2026-10-23_153624 |
| 2026-10-23 15:36 | html | FAIL | 7 | 0 | 1 | decoded body equals ABC (line 91) | vice-fn b80e8728+04586d | 31cea90 | runs/2026-10-23_153624 |
| 2026-10-23 15:36 | net5plus | FAIL | 2 | 0 | 1 | listener reports connection (line 395) | vice-fn b80e8728+04586d | 31cea90 | runs/2026-10-23_153624 |
| 2026-10-23 15:36 | netfile | FAIL | 2 | 0 | 1 | working directory matches (line 269) | vice-fn b80e8728+04586d | 31cea90 | runs/2026-10-23_153624 |
| 2026-10-23 15:36 | netproto | FAIL | 2 | 0 | 1 | 64 bytes match pattern (line 226) | vice-fn b80e8728+04586d | 31cea90 | runs/2026-10-23_153624 |
| 2026-10-23 15:36 | network | FAIL | 21 | 1 | 1 | N1 DOES NOT have bytes waiting (line 270) | vice-fn b80e8728+04586d | 31cea90 | runs/2026-10-23_153624 |
| 2026-10-23 15:36 | parserr | FAIL | 0 | 0 | 1 | bare NET_PARSE with no channel reports an error (line 94) | vice-fn b80e8728+04586d | 31cea90 | runs/2026-10-23_153624 |
| 2026-10-23 15:36 | qrcode | PASS | 22 | 0 | 0 |  | vice-fn b80e8728+04586d | 31cea90 | runs/2026-10-23_153624 |
| 2026-10-23 15:36 | wifi | PASS | 18 | 0 | 0 |  | vice-fn b80e8728+04586d | 31cea90 | runs/2026-10-23_153624 |
| 2026-10-23 15:50 | netfile | FAIL | 2 | 0 | 1 | working directory matches (line 269) | vice-fn b80e8728+a8c5a9 | 31cea90 | runs/2026-10-23_155001 |
| 2026-10-23 15:50 | devlist | FAIL | 3 | 0 | 1 | Network 1 online (line 93) | vice-fn b80e8728+a8c5a9 | 31cea90 | runs/2026-10-23_155001 |
| 2026-10-23 15:52 | netfile | FAIL | 10 | 0 | 1 | directory that was never created does not open (line 218) | vice-fn b80e8728+fbbf34 | 31cea90 | runs/2026-10-23_155259 |
| 2026-10-23 15:54 | devlist | FAIL | 3 | 0 | 1 | Network 1 online (line 93) | vice-fn b80e8728+fbbf34 | 31cea90 | runs/2026-10-23_155428 |
| 2026-10-23 15:55 | appkey | PASS | 18 | 0 | 0 |  | vice-fn b80e8728+867ddd | 31cea90 | runs/2026-10-23_155549 |
| 2026-10-23 15:55 | clipbord | FAIL | 12 | 0 | 1 | write open on an older snippet fails (line 119) | vice-fn b80e8728+867ddd | 31cea90 | runs/2026-10-23_155549 |
| 2026-10-23 15:55 | clock | PASS | 48 | 0 | 0 |  | vice-fn b80e8728+867ddd | 31cea90 | runs/2026-10-23_155549 |
| 2026-10-23 15:55 | devlist | FAIL | 3 | 0 | 1 | Network 1 online (line 93) | vice-fn b80e8728+867ddd | 31cea90 | runs/2026-10-23_155549 |
| 2026-10-23 15:55 | disk | FAIL | 1 | 0 | 1 | SD host slot found (line 74) | vice-fn b80e8728+867ddd | 31cea90 | runs/2026-10-23_155549 |
| 2026-10-23 15:55 | fujidev | FAIL | 14 | 0 | 1 | fuji_put_device_slots round-trip succeeds (line 125) | vice-fn b80e8728+867ddd | 31cea90 | runs/2026-10-23_155549 |
| 2026-10-23 15:55 | html | FAIL | 7 | 0 | 1 | decoded body equals ABC (line 91) | vice-fn b80e8728+867ddd | 31cea90 | runs/2026-10-23_155549 |
| 2026-10-23 15:55 | net5plus | FAIL | 2 | 0 | 1 | listener reports connection (line 395) | vice-fn b80e8728+867ddd | 31cea90 | runs/2026-10-23_155549 |
| 2026-10-23 15:55 | netfile | FAIL | 2 | 0 | 1 | working directory matches (line 269) | vice-fn b80e8728+867ddd | 31cea90 | runs/2026-10-23_155549 |
| 2026-10-23 15:55 | netproto | FAIL | 2 | 0 | 1 | 64 bytes match pattern (line 226) | vice-fn b80e8728+867ddd | 31cea90 | runs/2026-10-23_155549 |
| 2026-10-23 15:55 | network | FAIL | 21 | 1 | 1 | N1 DOES NOT have bytes waiting (line 270) | vice-fn b80e8728+867ddd | 31cea90 | runs/2026-10-23_155549 |
| 2026-10-23 15:55 | parserr | FAIL | 0 | 0 | 1 | bare NET_PARSE with no channel reports an error (line 94) | vice-fn b80e8728+867ddd | 31cea90 | runs/2026-10-23_155549 |
| 2026-10-23 15:55 | qrcode | PASS | 22 | 0 | 0 |  | vice-fn b80e8728+867ddd | 31cea90 | runs/2026-10-23_155549 |
| 2026-10-23 15:55 | wifi | PASS | 18 | 0 | 0 |  | vice-fn b80e8728+867ddd | 31cea90 | runs/2026-10-23_155549 |
| 2026-10-23 15:59 | netfile | FAIL | 10 | 0 | 1 | directory that was never created does not open (line 218) | vice-fn b80e8728+867ddd | 31cea90 | runs/2026-10-23_155917 |
| 2026-10-23 16:07 | disk | FAIL | 1 | 0 | 1 | SD host slot found (line 74) | vice-fn b80e8728+867ddd | 31cea90 | runs/2026-10-23_160733 |
| 2026-10-23 16:07 | html | FAIL | 7 | 0 | 1 | decoded body equals ABC (line 91) | vice-fn b80e8728+867ddd | 31cea90 | runs/2026-10-23_160733 |
| 2026-10-23 16:07 | netproto | FAIL | 2 | 0 | 1 | 64 bytes match pattern (line 226) | vice-fn b80e8728+867ddd | 31cea90 | runs/2026-10-23_160733 |
| 2026-10-23 16:15 | disk | FAIL | 5 | 0 | 1 | lobby.dsk found on the TNFS source (line 158) | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_161524 |
| 2026-10-23 16:15 | html | PASS | 98 | 1 | 0 |  | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_161524 |
| 2026-10-23 16:15 | netproto | PASS | 107 | 0 | 0 |  | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_161524 |
| 2026-10-23 16:22 | disk | FAIL | 15 | 0 | 1 | fuji_create_new succeeds (line 317) | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_162247 |
| 2026-10-23 16:25 | appkey | PASS | 18 | 0 | 0 |  | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_162517 |
| 2026-10-23 16:25 | clipbord | FAIL | 12 | 0 | 1 | write open on an older snippet fails (line 119) | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_162517 |
| 2026-10-23 16:25 | clock | PASS | 48 | 0 | 0 |  | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_162517 |
| 2026-10-23 16:25 | devlist | FAIL | 3 | 0 | 1 | Network 1 online (line 93) | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_162517 |
| 2026-10-23 16:25 | disk | FAIL | 14 | 0 | 1 | fuji_create_new succeeds (line 317) | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_162517 |
| 2026-10-23 16:25 | fujidev | FAIL | 14 | 0 | 1 | fuji_put_device_slots round-trip succeeds (line 125) | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_162517 |
| 2026-10-23 16:25 | html | PASS | 98 | 1 | 0 |  | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_162517 |
| 2026-10-23 16:25 | net5plus | FAIL | 2 | 0 | 1 | listener reports connection (line 395) | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_162517 |
| 2026-10-23 16:25 | netfile | FAIL | 10 | 0 | 1 | directory that was never created does not open (line 218) | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_162517 |
| 2026-10-23 16:25 | netproto | PASS | 107 | 0 | 0 |  | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_162517 |
| 2026-10-23 16:25 | network | FAIL | 21 | 1 | 1 | N1 DOES NOT have bytes waiting (line 270) | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_162517 |
| 2026-10-23 16:25 | parserr | FAIL | 0 | 0 | 1 | bare NET_PARSE with no channel reports an error (line 94) | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_162517 |
| 2026-10-23 16:25 | qrcode | PASS | 22 | 0 | 0 |  | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_162517 |
| 2026-10-23 16:25 | wifi | PASS | 18 | 0 | 0 |  | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_162517 |
| 2026-10-23 16:49 | fujidev | FAIL | 17 | 0 | 1 | fuji_mount_host_slot with invalid host fails (line 138) | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_164902 |
| 2026-10-23 16:49 | disk | FAIL | 15 | 0 | 1 | the new image is on the SD host (line 320) | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_164902 |
| 2026-10-23 16:52 | appkey | PASS | 18 | 0 | 0 |  | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_165222 |
| 2026-10-23 16:52 | clipbord | FAIL | 12 | 0 | 1 | write open on an older snippet fails (line 119) | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_165222 |
| 2026-10-23 16:52 | clock | PASS | 48 | 0 | 0 |  | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_165222 |
| 2026-10-23 16:52 | devlist | FAIL | 3 | 0 | 1 | Network 1 online (line 93) | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_165222 |
| 2026-10-23 16:52 | disk | FAIL | 15 | 0 | 1 | the new image is on the SD host (line 320) | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_165222 |
| 2026-10-23 16:52 | fujidev | FAIL | 17 | 0 | 1 | fuji_mount_host_slot with invalid host fails (line 138) | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_165222 |
| 2026-10-23 16:52 | html | PASS | 98 | 1 | 0 |  | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_165222 |
| 2026-10-23 16:52 | net5plus | FAIL | 2 | 0 | 1 | listener reports connection (line 395) | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_165222 |
| 2026-10-23 16:52 | netfile | FAIL | 10 | 0 | 1 | directory that was never created does not open (line 218) | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_165222 |
| 2026-10-23 16:52 | netproto | PASS | 107 | 0 | 0 |  | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_165222 |
| 2026-10-23 16:52 | network | FAIL | 21 | 1 | 1 | N1 DOES NOT have bytes waiting (line 270) | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_165222 |
| 2026-10-23 16:52 | parserr | FAIL | 0 | 0 | 1 | bare NET_PARSE with no channel reports an error (line 94) | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_165222 |
| 2026-10-23 16:52 | qrcode | PASS | 22 | 0 | 0 |  | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_165222 |
| 2026-10-23 16:52 | wifi | PASS | 18 | 0 | 0 |  | vice-fn b80e8728+867ddd | 31cea90* | runs/2026-10-23_165222 |
| 2026-10-23 17:17 | disk | FAIL | 18 | 0 | 1 | the new image is the size asked for (line 323) | vice-fn b80e8728+c97e94 | 31cea90* | runs/2026-10-23_171753 |
| 2026-10-23 17:27 | disk | FAIL | 18 | 0 | 1 | the new image is the size asked for (line 323) | vice-fn b80e8728+76f914 | 31cea90* | runs/2026-10-23_172757 |
| 2026-10-23 17:28 | appkey | PASS | 18 | 0 | 0 |  | vice-fn b80e8728+76f914 | 31cea90* | runs/2026-10-23_172832 |
| 2026-10-23 17:28 | clipbord | FAIL | 12 | 0 | 1 | write open on an older snippet fails (line 119) | vice-fn b80e8728+76f914 | 31cea90* | runs/2026-10-23_172832 |
| 2026-10-23 17:28 | clock | PASS | 48 | 0 | 0 |  | vice-fn b80e8728+76f914 | 31cea90* | runs/2026-10-23_172832 |
| 2026-10-23 17:28 | devlist | FAIL | 3 | 0 | 1 | Network 1 online (line 93) | vice-fn b80e8728+76f914 | 31cea90* | runs/2026-10-23_172832 |
| 2026-10-23 17:28 | disk | FAIL | 18 | 0 | 1 | the new image is the size asked for (line 323) | vice-fn b80e8728+76f914 | 31cea90* | runs/2026-10-23_172832 |
| 2026-10-23 17:28 | fujidev | FAIL | 17 | 0 | 1 | fuji_mount_host_slot with invalid host fails (line 138) | vice-fn b80e8728+76f914 | 31cea90* | runs/2026-10-23_172832 |
| 2026-10-23 17:28 | html | PASS | 98 | 1 | 0 |  | vice-fn b80e8728+76f914 | 31cea90* | runs/2026-10-23_172832 |
| 2026-10-23 17:28 | net5plus | FAIL | 2 | 0 | 1 | listener reports connection (line 395) | vice-fn b80e8728+76f914 | 31cea90* | runs/2026-10-23_172832 |
| 2026-10-23 17:28 | netfile | FAIL | 10 | 0 | 1 | directory that was never created does not open (line 218) | vice-fn b80e8728+76f914 | 31cea90* | runs/2026-10-23_172832 |
| 2026-10-23 17:28 | netproto | PASS | 107 | 0 | 0 |  | vice-fn b80e8728+76f914 | 31cea90* | runs/2026-10-23_172832 |
| 2026-10-23 17:28 | network | FAIL | 21 | 1 | 1 | N1 DOES NOT have bytes waiting (line 270) | vice-fn b80e8728+76f914 | 31cea90* | runs/2026-10-23_172832 |
| 2026-10-23 17:28 | parserr | FAIL | 0 | 0 | 1 | bare NET_PARSE with no channel reports an error (line 94) | vice-fn b80e8728+76f914 | 31cea90* | runs/2026-10-23_172832 |
| 2026-10-23 17:28 | qrcode | PASS | 22 | 0 | 0 |  | vice-fn b80e8728+76f914 | 31cea90* | runs/2026-10-23_172832 |
| 2026-10-23 17:28 | wifi | PASS | 18 | 0 | 0 |  | vice-fn b80e8728+76f914 | 31cea90* | runs/2026-10-23_172832 |
| 2026-10-23 22:02 | appkey | PASS | 18 | 0 | 0 |  | vice-fujinet_1.0_ubuntu24.04_amd64 | 31cea90* | runs/2026-10-23_220209 |
| 2026-10-23 22:02 | clipbord | FAIL | 12 | 0 | 1 | write open on an older snippet fails (line 119) | vice-fujinet_1.0_ubuntu24.04_amd64 | 31cea90* | runs/2026-10-23_220220 |
| 2026-10-23 22:02 | clock | PASS | 48 | 0 | 0 |  | vice-fujinet_1.0_ubuntu24.04_amd64 | 31cea90* | runs/2026-10-23_220232 |
| 2026-10-23 22:02 | devlist | FAIL | 3 | 0 | 1 | Network 1 online (line 93) | vice-fujinet_1.0_ubuntu24.04_amd64 | 31cea90* | runs/2026-10-23_220249 |
| 2026-10-23 22:03 | disk | FAIL | 17 | 0 | 1 | the new image is the size asked for (line 323) | vice-fujinet_1.0_ubuntu24.04_amd64 | 31cea90* | runs/2026-10-23_220301 |
| 2026-10-23 22:03 | fujidev | FAIL | 17 | 0 | 1 | fuji_mount_host_slot with invalid host fails (line 138) | vice-fujinet_1.0_ubuntu24.04_amd64 | 31cea90* | runs/2026-10-23_220318 |
| 2026-10-23 22:03 | html | PASS | 98 | 1 | 0 |  | vice-fujinet_1.0_ubuntu24.04_amd64 | 31cea90* | runs/2026-10-23_220330 |
| 2026-10-23 22:03 | net5plus | FAIL | 2 | 0 | 1 | listener reports connection (line 395) | vice-fujinet_1.0_ubuntu24.04_amd64 | 31cea90* | runs/2026-10-23_220357 |
| 2026-10-23 22:04 | netfile | FAIL | 10 | 0 | 1 | directory that was never created does not open (line 218) | vice-fujinet_1.0_ubuntu24.04_amd64 | 31cea90* | runs/2026-10-23_220409 |
| 2026-10-23 22:04 | netproto | PASS | 107 | 0 | 0 |  | vice-fujinet_1.0_ubuntu24.04_amd64 | 31cea90* | runs/2026-10-23_220420 |
| 2026-10-23 22:04 | network | FAIL | 21 | 1 | 1 | N1 DOES NOT have bytes waiting (line 270) | vice-fujinet_1.0_ubuntu24.04_amd64 | 31cea90* | runs/2026-10-23_220453 |
| 2026-10-23 22:05 | parserr | FAIL | 0 | 0 | 1 | bare NET_PARSE with no channel reports an error (line 94) | vice-fujinet_1.0_ubuntu24.04_amd64 | 31cea90* | runs/2026-10-23_220504 |
| 2026-10-23 22:05 | qrcode | PASS | 22 | 0 | 0 |  | vice-fujinet_1.0_ubuntu24.04_amd64 | 31cea90* | runs/2026-10-23_220516 |
| 2026-10-23 22:05 | wifi | PASS | 18 | 0 | 0 |  | vice-fujinet_1.0_ubuntu24.04_amd64 | 31cea90* | runs/2026-10-23_220528 |
| 2026-10-25 12:30 | network | FAIL | 27 | 1 | 1 | N1 DOES NOT have bytes waiting (line 270) | VICE-FN v1.1 (c8b401984) | 31cea90* | runs/2026-10-25_123025 |
| 2026-10-25 12:31 | network | FAIL | 23 | 1 | 1 | TELNET read gets the line before the close (line 368) | VICE-FN v1.0 (b80e8728*) | 31cea90* | runs/2026-10-25_123101 |
| 2026-10-25 13:25 | network | FAIL | 27 | 1 | 1 | N1 DOES NOT have bytes waiting (line 270) | VICE-FN v1.1 (c8b401984) | 31cea90* | runs/2026-10-25_132506 |
| 2026-10-25 13:25 | network | FAIL | 23 | 1 | 1 | TELNET read gets the line before the close (line 368) | VICE-FN v1.0 (b80e8728*) | 31cea90* | runs/2026-10-25_132529 |
| 2026-10-25 13:26 | network | FAIL | 27 | 1 | 1 | N1 DOES NOT have bytes waiting (line 270) | VICE-FN v1.1 (c8b401984) | 09d77c1 | runs/2026-10-25_132619 |
| 2026-10-25 13:26 | network | FAIL | 23 | 1 | 1 | TELNET read gets the line before the close (line 368) | VICE-FN v1.0 (b80e8728*) | 09d77c1 | runs/2026-10-25_132636 |
| 2026-11-01 11:43 | appkey | PASS | 18 | 0 | 0 |  | vice-fn c8b40198 | 106a725 (v5.1.1-dev) | runs/2026-11-01_114334 |
| 2026-11-01 11:43 | clipbord | FAIL | 12 | 0 | 1 | write open on an older snippet fails (line 119) | vice-fn c8b40198 | 106a725 (v5.1.1-dev) | runs/2026-11-01_114334 |
| 2026-11-01 11:43 | clock | FAIL | 55 | 0 | 1 | long wait within tolerance (line 350) | vice-fn c8b40198 | 106a725 (v5.1.1-dev) | runs/2026-11-01_114334 |
| 2026-11-01 11:43 | devlist | FAIL | 3 | 0 | 1 | Network 1 online (line 96) | vice-fn c8b40198 | 106a725 (v5.1.1-dev) | runs/2026-11-01_114334 |
| 2026-11-01 11:43 | disk | FAIL | 18 | 0 | 1 | the new image is the size asked for (line 323) | vice-fn c8b40198 | 106a725 (v5.1.1-dev) | runs/2026-11-01_114334 |
| 2026-11-01 11:43 | fujidev | FAIL | 18 | 0 | 1 | fuji_mount_host_slot with invalid host fails (line 153) | vice-fn c8b40198 | 106a725 (v5.1.1-dev) | runs/2026-11-01_114334 |
| 2026-11-01 11:43 | html | PASS | 95 | 1 | 0 |  | vice-fn c8b40198 | 106a725 (v5.1.1-dev) | runs/2026-11-01_114334 |
| 2026-11-01 11:43 | net5plus | FAIL | 2 | 0 | 1 | listener reports connection (line 390) | vice-fn c8b40198 | 106a725 (v5.1.1-dev) | runs/2026-11-01_114334 |
| 2026-11-01 11:43 | netfile | FAIL | 10 | 0 | 1 | directory that was never created does not open (line 218) | vice-fn c8b40198 | 106a725 (v5.1.1-dev) | runs/2026-11-01_114334 |
| 2026-11-01 11:43 | netproto | PASS | 107 | 0 | 0 |  | vice-fn c8b40198 | 106a725 (v5.1.1-dev) | runs/2026-11-01_114334 |
| 2026-11-01 11:43 | network | FAIL | 33 | 1 | 1 | N1 DOES NOT have bytes waiting (line 322) | vice-fn c8b40198 | 106a725 (v5.1.1-dev) | runs/2026-11-01_114334 |
| 2026-11-01 11:43 | parserr | FAIL | 0 | 0 | 1 | bare NET_PARSE with no channel reports an error (line 94) | vice-fn c8b40198 | 106a725 (v5.1.1-dev) | runs/2026-11-01_114334 |
| 2026-11-01 11:43 | qrcode | PASS | 22 | 0 | 0 |  | vice-fn c8b40198 | 106a725 (v5.1.1-dev) | runs/2026-11-01_114334 |
| 2026-11-01 11:43 | wifi | PASS | 19 | 0 | 0 |  | vice-fn c8b40198 | 106a725 (v5.1.1-dev) | runs/2026-11-01_114334 |
| 2026-11-01 11:47 | clock | PASS | 57 | 0 | 0 |  | vice-fn c8b40198 | 310fe77* (v5.1.1-dev) | runs/2026-11-01_114734 |
| 2026-11-01 11:48 | clock | PASS | 57 | 0 | 0 |  | vice-fn c8b40198 | 310fe77* (v5.1.1-dev) | runs/2026-11-01_114800 |
| 2026-11-01 11:48 | clock | PASS | 57 | 0 | 0 |  | vice-fn c8b40198 | 310fe77* (v5.1.1-dev) | runs/2026-11-01_114827 |
| 2026-11-01 11:49 | html | FAIL | 7 | 0 | 1 | decoded body equals ABC (line 91) | vice-fn c8b40198 | 310fe77* (v5.1.1-dev) | runs/2026-11-01_114939 |
| 2026-11-01 11:49 | netproto | FAIL | 2 | 0 | 1 | 64 bytes match pattern (line 226) | vice-fn c8b40198 | 310fe77* (v5.1.1-dev) | runs/2026-11-01_114939 |
| 2026-11-01 11:49 | disk | FAIL | 1 | 0 | 1 | SD host slot found (line 74) | vice-fn c8b40198 | 310fe77* (v5.1.1-dev) | runs/2026-11-01_114939 |
