#! /bin/bash

# Setup arguments
psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

# Validate arguments
if [ "$#" -ne 5 ]; then
      echo "Illegal number of parameters"
      exit 1
fi

# Collect machine statistics
vmstat_mb=$(vmstat --unit M)
hostname=$(hostname -f)

# Parse resource usage statistics
memory_free=$(echo "$vmstat_mb" | awk '{print $4}' | tail -n1 | xargs)
cpu_idle=$(echo "$vmstat_mb" | awk '{print $15}' | tail -n1 | xargs)
cpu_kernel=$(echo "$vmstat_mb" | awk '{print $14}' | tail -n1 | xargs)
disk_io=$(vmstat -d | awk '{print $10}' | tail -n1 | xargs)
disk_available=$(df -BM / | tail -n1 | awk '{print $4}' | tr -d 'M')

# Collect current UTC timestamp
timestamp=$(date -u '+%Y-%m-%d %H:%M:%S')

# Find matching host ID
host_id="(SELECT id FROM host_info WHERE hostname='$hostname')"

# Construct SQL statement
insert_stmt="INSERT INTO host_usage (timestamp, host_id, memory_free, cpu_idle, cpu_kernel, disk_io, disk_available)
VALUES ('$timestamp', $host_id, $memory_free, $cpu_idle, $cpu_kernel, $disk_io, $disk_available);"

# Execute SQL statement
export PGPASSWORD=$psql_password
psql -h "$psql_host" -p "$psql_port" -d "$db_name" -U "$psql_user" -c "$insert_stmt"
exit $?
