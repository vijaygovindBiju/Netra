use netra_common::models::traffic::ProcessTrafficEntry;
use netra_common::Result;
use std::collections::HashMap;
use std::fs;
use std::time::Instant;

pub struct SocketScanner {
    // Maps PID to (prev_rx, prev_tx, last_updated)
    history: HashMap<u32, (u64, u64, Instant)>,
}

impl SocketScanner {
    pub fn new() -> Self {
        Self {
            history: HashMap::new(),
        }
    }

    /// Scans /proc to build a map of Socket Inode -> PID
    pub fn get_socket_inode_to_pid_map() -> HashMap<u64, u32> {
        let mut inode_map = HashMap::new();

        if let Ok(proc_entries) = fs::read_dir("/proc") {
            for entry in proc_entries.flatten() {
                if let Ok(file_name) = entry.file_name().into_string() {
                    if let Ok(pid) = file_name.parse::<u32>() {
                        let fd_dir = entry.path().join("fd");
                        if let Ok(fd_entries) = fs::read_dir(fd_dir) {
                            for fd_entry in fd_entries.flatten() {
                                if let Ok(target) = fs::read_link(fd_entry.path()) {
                                    if let Some(target_str) = target.to_str() {
                                        if target_str.starts_with("socket:[") && target_str.ends_with(']') {
                                            let inode_str = &target_str[8..target_str.len() - 1];
                                            if let Ok(inode) = inode_str.parse::<u64>() {
                                                inode_map.insert(inode, pid);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        inode_map
    }

    /// Reads /proc/[pid]/comm to get friendly process name
    pub fn get_process_name(pid: u32) -> String {
        fs::read_to_string(format!("/proc/{}/comm", pid))
            .map(|s| s.trim().to_string())
            .unwrap_or_else(|_| format!("PID-{}", pid))
    }

    /// Reads /proc/[pid]/cmdline to get executable command line
    pub fn get_process_cmdline(pid: u32) -> String {
        fs::read_to_string(format!("/proc/{}/cmdline", pid))
            .map(|s| s.replace('\0', " ").trim().to_string())
            .unwrap_or_default()
    }

    /// Scans active processes with network sockets and calculates real-time bandwidth
    pub fn scan_process_traffic(&mut self) -> Result<Vec<ProcessTrafficEntry>> {
        let inode_to_pid = Self::get_socket_inode_to_pid_map();
        let now = Instant::now();

        // Count open sockets and aggregate per PID
        let mut pid_sockets: HashMap<u32, usize> = HashMap::new();
        for &pid in inode_to_pid.values() {
            *pid_sockets.entry(pid).or_insert(0) += 1;
        }

        let mut entries = Vec::new();

        for (pid, socket_count) in pid_sockets {
            let name = Self::get_process_name(pid);
            let cmdline = Self::get_process_cmdline(pid);

            // Read /proc/[pid]/io if accessible to get process I/O bytes
            let (rx_bytes, tx_bytes) = Self::read_process_io_bytes(pid).unwrap_or((0, 0));

            let (rx_rate, tx_rate) = if let Some((prev_rx, prev_tx, prev_time)) = self.history.get(&pid) {
                let duration = (now - *prev_time).as_secs_f64();
                if duration > 0.05 {
                    let rx_delta = rx_bytes.saturating_sub(*prev_rx);
                    let tx_delta = tx_bytes.saturating_sub(*prev_tx);
                    (
                        (rx_delta as f64 / duration) as u64,
                        (tx_delta as f64 / duration) as u64,
                    )
                } else {
                    (0, 0)
                }
            } else {
                (0, 0)
            };

            self.history.insert(pid, (rx_bytes, tx_bytes, now));

            entries.push(ProcessTrafficEntry {
                pid,
                name,
                cmdline,
                rx_rate_bps: rx_rate,
                tx_rate_bps: tx_rate,
                total_rx_bytes: rx_bytes,
                total_tx_bytes: tx_bytes,
                open_socket_count: socket_count,
            });
        }

        // Sort by open sockets and rate descending
        entries.sort_by(|a, b| b.open_socket_count.cmp(&a.open_socket_count));

        Ok(entries)
    }

    fn read_process_io_bytes(pid: u32) -> Option<(u64, u64)> {
        let content = fs::read_to_string(format!("/proc/{}/io", pid)).ok()?;
        let mut rchar = 0u64;
        let mut wchar = 0u64;

        for line in content.lines() {
            if line.starts_with("rchar:") {
                rchar = line[6..].trim().parse().unwrap_or(0);
            } else if line.starts_with("wchar:") {
                wchar = line[6..].trim().parse().unwrap_or(0);
            }
        }

        Some((rchar, wchar))
    }
}
