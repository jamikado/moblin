#  IRL protocol specification

## Goals
- Bonding.
- Prioritize audio over video.
- Adaptive bitrate friendly.
- Efficient. Low CPU usage.
- Simple.
- Fixed latency for video and audio?
- Dynamic latency for data? Deliver data when available (in order).

## Protocol

### Segment types

```
Name          Value  Direction         Has SN
------------------------------------------------
video         0      client to server  yes
audio         1      client to server  yes
video empty   2      client to server  yes (same as original video (0))
audio empty   3      client to server  yes (same as original audio (1))
video format  4      client to server  yes
audio format  5      client to server  yes
mux           6      client to server  no  (contained segments have)
ack           7      both ways         no
data          8      both ways         yes
create group  9      both ways         no  (client initiated)
add to group  10     both ways         no  (client initiated)
```

### Comments
- Use transport layer packet length as segment length. Typically up to 1400 bytes (roughly MTU).
- `data` will need congestion control somehow. Probably as simple as a maximum number of outstanding
  packets.

### Segments

All segments starts with a 5 bits type.

First `video`, `audio`, `video format` or `audio format` segment, first=1, including total length

```
+---------+-------------+--------------+--------+------------------+-------------------------+
| 5b type | 2b reserved | 1b first (1) | 24b SN | 24b total length | payload (PTS, DTS, ...) |
+---------+-------------+--------------+--------+------------------+-------------------------+
```

Consecutive `video`, `audio`, `video format` or `audio format` segment, first=0

```
+---------+-------------+--------------+--------+---------+
| 5b type | 2b reserved | 1b first (0) | 24b SN | payload |
+---------+-------------+--------------+--------+---------+
```

`video empty` or `audio empty` segment, sent to drop given segment in receiver

```
+---------+-------------+--------+--------+
| 5b type | 3b reserved | 24b SN | 4b PTS |
+---------+-------------+--------+--------+
```

`mux` segment, containing at least two other segments

```
+---------+-------------+------------+------------+------------+------------+
| 5b type | 3b reserved | 16b length | segment #1 | 16b length | segment #2 |
+---------+-------------+------------+------------+------------+------------+
```

`ack` segment, sent every 50 ms on all connections

```
+---------+-------------+----------------+--------+--------+--------+--------+--------+
| 5b type | 3b reserved | 8b singles (3) | 24b SN | 24b SN | 24b SN | 24b SN | 24b SN |
+---------+-------------+----------------+--------+--------+--------+--------+--------+
                                           single   single   single        range
```

First `data` segment, first=1, including total length

```
+---------+-------------+--------------+--------+------------------+---------+
| 5b type | 2b reserved | 1b first (1) | 24b SN | 24b total length | payload |
+---------+-------------+--------------+--------+------------------+---------+
```

Consecutive `data` segment, first=0

```
+---------+-------------+--------------+--------+---------+
| 5b type | 2b reserved | 1b first (0) | 24b SN | payload |
+---------+-------------+--------------+--------+---------+
```

`create group`, sent on first connection, response on same connection

```
+---------+-------------+--------------+--------------+
| 5b type | 3b reserved | 288b UUID #1 | 288b UUID #2 |
+---------+-------------+--------------+--------------+
```

`add to group`, sent on additional connections, response on same connection

```
+---------+-------------+--------------+--------------+
| 5b type | 3b reserved | 288b UUID #1 | 288b UUID #2 |
+---------+-------------+--------------+--------------+
```