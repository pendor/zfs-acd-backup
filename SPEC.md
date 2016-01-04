Snapshot Mirror specs
=====================

Snapshots 
---------

ZFS metadata:
-------------
* Name of last incremental successfully sent.
* Name of full that's the basis for all incrementals
* Encryption info - algo, CRC of key?
* Symmetric key (optional)
* Public key

Modes of Operation:
-------------------
* Just send a snapshot.  Don't update metadata or worry about incrementals.  Just send the whole thing.
* Backup:
  * First time or bad/missing initial snap:  Do the backup, then store snap name (and piece information / hashes?) in zfs meta.
  * Incremental: We have an initial snap in meta.  Do what we can to verify it.  Write a new incremental based on that snap & verify that.  Store new name (and piece information / hashes?) in zfs meta.  Delete old incremental from ACD (optional?).
* Verify: Probably called by the other modes.  Check out the snaps on ACD and make sure they match what's in meta.
  
  
General notes:
--------------
* Files are stored in ACD as their hash (SHA1?).  Use that and store hashes of pieces we upload to determine if we s`till have an intact snapshot.  Is storing all that in zfs meta too much?

* Snapshots can be done recursively.  Store the meta in the top level & do nothing in the lower levels.  It's valid for snap processes to be overlapping -- do a recursive from root, do something different at a lower level in addition to it.  Only warn if would clobber at a given starting level with different recursive settings as that would orphan the snaps for the rest of the tree.




Backup:
=======

* **START**: *Check meta at the target level:*
  * **No meta**?    => Full backup
  * **Meta**?       => Verify ACD status
  * Has Full & OK?
    * **Yes**       => Incremental Backup
    * **No**        => Warn if general backup, error if asked for incremental only.
* **VERIFY ACD STATUS**
  * Get list of snap names, pieces, and hashes from zfs meta.
  * ACD sync & check that ACD listing still contains each piece.  Verify size?
* **Incremental Backup**
  * Verify full backup ACD status.
  * Proceed identical to full backup except using `zfs send -I`
* **FULL BACKUP**
  * Check space on ACD? (Is that a thing?)
  * Calculate size of backup data (recursive size of ZFS)
  * Estimate backup size (size * compression ratio)
  * *Store upload speed as setting or do speed test?*
  * Estimate time to complete backup.
  * *User specified snap name?*
    * **Yes**       => Check that it exists || error
    * **No**        => Create it.
  * *Key material in meta or command line?*
    * **No**        => Prompt for it
  * Start streaming.
  * *Wait for it....*
  * Verify ACD Status.  **OK?**
    * **Yes**       => Update meta
    * **No**        => Error
