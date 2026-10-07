use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct AudioSink {
    pub id: u32,
    pub name: String,
    pub description: String,
    pub volume_percent: u8, // 0 - 100% (or up to 150%)
    pub is_muted: bool,
    pub is_default: bool,
    pub is_bluetooth: bool,
    pub is_virtual: bool,
    pub latency_offset_ms: i32, // -100ms to +150ms for sync
    pub active_port: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct AudioStream {
    pub id: u32,
    pub name: String,
    pub app_name: String,
    pub binary_name: String,
    pub current_sink_id: u32,
    pub volume_percent: u8,
    pub is_muted: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct VirtualMultiSinkGroup {
    pub group_id: String,
    pub group_name: String,
    pub member_sink_ids: Vec<u32>,
    pub master_sink_id: Option<u32>,
    pub is_active: bool,
}
