

- Explain how to mount directly the raw image (or boot or ext4) with offsets.
- Explain how to mount with losetup.
- Explain that sfdisk -l and blkid can be used. (althoug blkid doesn't show the
  ext4 partition when applied to raw).
- Since it uses a FAT16 boot partition, it doesn't work on Digital Ocean (where
  only EXT3 or EXT4 are supported).
  Workaround is to build the image manually with the make-qcow2.sh script
  (which use losetup and mount).
