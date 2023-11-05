# diskcapture
A single, interactive shell script that gets added to every time I find a new method of capturing disk and partition images using Linux CLI. Borne out of the frustration of having to do a lot of custom imaging but hearing conflicting information about which method is the quickest and most reliable. Having to manually calculate block size and count sectors is also tedious and prone to error. This script takes care of that.

It's an ongoing project currently supporting combinations of:
- dd
- pv
- gzip
- zstd

### Usage
```
./diskcapture.sh <diskname> <outputfilename>
```
## eg.
```
./diskcapture.sh sda image
```
## Returns:
```
/dev/sda
240055295488 bytes
58607249 sectors

Contains partitions:
sda1 sda2 sda3 sda4

Partition Details:
sda1: 1048576 bytes       256 sectors       Block size: 4096
sda2: 536870912 bytes     131072 sectors    Block size: 4096
sda3: 222337506816 bytes  54281617 sectors  Block size: 4096
sda4: 17179869184 bytes   4194304 sectors   Block size: 4096

Here's your options for capturing the disk:

1) dd | pv | gzip
2) dd --progress
3) dd --progress | gzip
4) dd --progress bs=1M | gzip
5) dd --progress bs=1M | zst

Please enter the number of the method you'd like to choose.
```
### Methods
```
dd if=${disk} bs=${block_size} count=${total_sectors} | pv -s ${total_bytes} | gzip -${compressionlevel} > ${filename}
dd if=${disk} bs=${block_size} count=${total_sectors} of=${filename} status=progress
dd if=${disk} bs=${block_size} count=${total_sectors} | gzip -c > ${filename}
dd bs=1M iflag=fullblock if=${disk} status=progress | gzip >${filename}
dd bs=1M iflag=fullblock if=${disk} status=progress | zstd -16v >${filename}
```
