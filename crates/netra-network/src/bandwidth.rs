use netra_common::{NetraError, Result};
use std::collections::HashMap;
use std::fs;
use std::time::Instant;

#[derive(Debug, Clone)]
pub struct RawInterfaceCounters {
    pub rx_bytes: u64,
    pub tx_bytes: u64,
    pub timestamp: Instant,
}

#[derive(Debug, Clone, Default)]
pub struct BandwidthRate {
    pub rx_bytes: u64,
    pub tx_bytes: u64,
    pub rx_rate_bps: u64,
    pub tx_rate_bps: u64,
}

pub struct BandwidthMonitor {
    previous_counters: HashMap<String, RawInterfaceCounters>,
}

impl BandwidthMonitor {
    pub fn new() -> Self {
        Self {
            previous_counters: HashMap::new(),
        }
    }

    pub fn read_counters() -> Result<HashMap<String, (u64, u64)>> {
        let content = fs::read_to_string("/proc/net/dev")
            .map_err(|e| NetraError::Io(e))?;

        let mut counters = HashMap::new();

        for line in content.lines().skip(2) {
            let parts: Vec<&str> = line.split(':').collect();
            if parts.len() != 2 {
                continue;
            }

            let iface = parts[0].trim().to_string();
            let stats: Vec<&str> = parts[1].split_whitespace().collect();

            if stats.len() >= 9 {
                if let (Ok(rx), Ok(tx)) = (stats[0].parse::<u64>(), stats[8].parse::<u64>()) {
                    counters.insert(iface, (rx, tx));
                }
            }
        }

        Ok(counters)
    }

    pub fn update(&mut self) -> Result<HashMap<String, BandwidthRate>> {
        let current_raw = Self::read_counters()?;
        let now = Instant::now();
        let mut rates = HashMap::new();

        for (iface, (rx_bytes, tx_bytes)) in current_raw {
            if let Some(prev) = self.previous_counters.get(&iface) {
                let duration_secs = (now - prev.timestamp).as_secs_f64();
                if duration_secs > 0.001 {
                    let rx_delta = rx_bytes.saturating_sub(prev.rx_bytes);
                    let tx_delta = tx_bytes.saturating_sub(prev.tx_bytes);

                    let rx_rate = (rx_delta as f64 / duration_secs) as u64;
                    let tx_rate = (tx_delta as f64 / duration_secs) as u64;

                    rates.insert(
                        iface.clone(),
                        BandwidthRate {
                            rx_bytes,
                            tx_bytes,
                            rx_rate_bps: rx_rate,
                            tx_rate_bps: tx_rate,
                        },
                    );
                }
            } else {
                rates.insert(
                    iface.clone(),
                    BandwidthRate {
                        rx_bytes,
                        tx_bytes,
                        rx_rate_bps: 0,
                        tx_rate_bps: 0,
                    },
                );
            }

            self.previous_counters.insert(
                iface,
                RawInterfaceCounters {
                    rx_bytes,
                    tx_bytes,
                    timestamp: now,
                },
            );
        }

        Ok(rates)
    }
}
