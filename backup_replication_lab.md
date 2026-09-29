# PostgreSQL Backup, Point-in-Time Recovery, and Streaming Replication Lab

## 1. Logical Backup and Restore

### Create Logical Backup

The `bootcamp` database was backed up using PostgreSQL custom-format `pg_dump`:

```bash
sudo -u postgres pg_dump -Fc -f /tmp/bootcamp.dump bootcamp
```

The backup was copied to a backup directory:

```bash
mkdir -p ~/backups
cp /tmp/bootcamp.dump ~/backups/bootcamp.dump
```

The backup contents were verified:

```bash
pg_restore --list ~/backups/bootcamp.dump
```

The backup was restored into a separate verification database:

```bash
sudo -u postgres createdb bootcamp_check
sudo -u postgres pg_restore -d bootcamp_check ~/backups/bootcamp.dump
```

The restored database was verified with:

```bash
sudo -u postgres psql -d bootcamp_check -c "SELECT COUNT(*) FROM students;"
```

The logical backup and restore completed successfully.

## 2. WAL Archiving

WAL archiving was enabled on the PostgreSQL 18 primary.

Relevant configuration:

```conf
wal_level = replica
archive_mode = on
archive_command = 'cp %p /var/lib/postgresql/18/wal_archive/%f'
```

The WAL archive directory was:

```text
/var/lib/postgresql/18/wal_archive/
```

WAL segment files were successfully created in the archive directory.

## 3. Physical Base Backup

A physical base backup was created with:

```bash
sudo -u postgres pg_basebackup -D /var/lib/postgresql/18/base_backup -Ft -z -Xs -P
```

The backup completed successfully.

The base backup contained:

```text
PG_VERSION
backup_label
backup_manifest
```

## 4. Point-in-Time Recovery

Before the simulated disaster, the `students` table contained 5 rows.

The recovery target was:

```text
2026-09-28 10:44:29.101878+03
```

The recovery configuration used:

```conf
restore_command = 'cp /var/lib/postgresql/18/wal_archive/%f %p'
recovery_target_time = '2026-09-28 10:44:29.101878+03'
recovery_target_action = 'pause'
```

During recovery, PostgreSQL reported `pg_is_in_recovery() = t` and the recovered `students` table contained 5 rows.

The replay LSN was verified with:

```sql
SELECT pg_last_wal_replay_lsn();
```

The database was then promoted with:

```sql
SELECT pg_promote();
```

Final PITR verification returned:

```text
pg_is_in_recovery | count
------------------+------
f                 | 5
```

This confirmed that the deleted student rows were recovered and the database was successfully promoted after PITR.

## 5. Streaming Replication Configuration

A dedicated replication role was configured:

```sql
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD '<LAB_PASSWORD>';
```

The primary `pg_hba.conf` included:

```conf
host replication replicator 127.0.0.1/32 scram-sha-256
```

The password is intentionally represented as `<LAB_PASSWORD>` and is not committed to the repository.

## 6. Provisioning the Standby

The standby was provisioned from the primary using:

```bash
sudo -u postgres pg_basebackup -h 127.0.0.1 -p 5432 -U replicator -D /var/lib/postgresql/18/standby -R -P
```

The standby configuration included:

```conf
data_directory = '/var/lib/postgresql/18/standby'
port = 5433
listen_addresses = '127.0.0.1'
include = '/var/lib/postgresql/18/standby/postgresql.auto.conf'
```

## 7. Standby Verification

The standby was verified with:

```bash
sudo -u postgres psql -p 5433 -d postgres -c "SELECT pg_is_in_recovery() AS standby, inet_server_port() AS port;"
```

The result confirmed:

```text
standby = t
```

## 8. Live Replication Test

A test row was inserted on the primary:

```sql
INSERT INTO students (name, course)
VALUES ('Final Replication Test', 'Streaming Replication');
```

The row appeared on the standby:

```text
id |          name          |        course
---+------------------------+-----------------------
39 | Final Replication Test | Streaming Replication
```

This confirmed that streaming replication was functioning.

## 9. Replication Status and Lag

Replication status was checked on the primary with:

```sql
SELECT application_name,
       client_addr,
       state,
       sync_state,
       pg_size_pretty(
         pg_wal_lsn_diff(sent_lsn, replay_lsn)
       ) AS lag
FROM pg_stat_replication;
```

Observed result:

```text
application_name | client_addr |   state   | sync_state |   lag
-----------------+-------------+-----------+------------+---------
walreceiver      | 127.0.0.1   | streaming | async      | 0 bytes
```

The standby WAL receive and replay positions were also checked:

```sql
SELECT pg_is_in_recovery() AS standby,
       pg_last_wal_receive_lsn() AS received_lsn,
       pg_last_wal_replay_lsn() AS replayed_lsn;
```

Observed result:

```text
standby | received_lsn | replayed_lsn
--------+--------------+-------------
t       | 0/11000680   | 0/11000680
```

The standby was in recovery, both WAL positions matched, and replication lag was 0 bytes at the time of verification.

## 10. Final Verification

- Logical backup using `pg_dump`
- Logical restore using `pg_restore`
- WAL archiving
- Physical backup using `pg_basebackup`
- Point-in-time recovery using `recovery_target_time`
- PITR validation using `pg_is_in_recovery()`
- Recovery of the deleted `students` rows
- Promotion after recovery
- Replication authentication through `pg_hba.conf`
- Provisioning of a streaming standby
- Live replication from primary to standby
- Replication monitoring through `pg_stat_replication`
- Verification of WAL receive and replay positions
- Verification of 0-byte replication lag
