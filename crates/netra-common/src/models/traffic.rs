use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum SocketProtocol {
    Tcp,
    Udp,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct SocketConnection {
    pub local_address: String,
    pub local_port: u16,
    pub remote_address: String,
    pub remote_port: u16,
    pub protocol: SocketProtocol,
    pub state: String,
    pub inode: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ProcessTrafficEntry {
    pub pid: u32,
    pub name: String,
    pub cmdline: String,
    pub rx_rate_bps: u64,
    pub tx_rate_bps: u64,
    pub total_rx_bytes: u64,
    pub total_tx_bytes: u64,
    pub open_socket_count: usize,
}
