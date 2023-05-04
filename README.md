# diskcapture
A single, interactive shell script that gets added to every time I find a new method of capturing disk and partition images using Linux CLI. Borne out of the frustration of not knowing which method to choose, how to calculate block size, sector count, gauge progress, minimise errors and maximise compression. 

Currently uses combinations of:
- dd
- pv
- gzip
- zstd

### Usage
```
./diskcapture.sh <diskname> <outputfilename>

## eg.
./diskcapture.sh sda image

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

### Work In Progress
I have a list of about twenty different methods that need adding when I've got time.
