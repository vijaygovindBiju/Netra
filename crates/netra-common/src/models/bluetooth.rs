use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum DeviceCategory {
    AudioHeadset,
    AudioSpeaker,
    Phone,
    InputKeyboard,
    InputMouse,
    Unknown,
}

impl DeviceCategory {
    pub fn from_icon_or_class(icon: &str, class: u32) -> Self {
        if icon.contains("headset") || icon.contains("headphones") {
            DeviceCategory::AudioHeadset
        } else if icon.contains("speaker") || icon.contains("audio") {
            DeviceCategory::AudioSpeaker
        } else if icon.contains("phone") {
            DeviceCategory::Phone
        } else if icon.contains("keyboard") {
            DeviceCategory::InputKeyboard
        } else if icon.contains("mouse") {
            DeviceCategory::InputMouse
        } else if (class & 0x000400) != 0 {
            DeviceCategory::AudioHeadset
        } else if (class & 0x000200) != 0 {
            DeviceCategory::Phone
        } else {
            DeviceCategory::Unknown
        }
    }

    pub fn as_str(&self) -> &'static str {
        match self {
            DeviceCategory::AudioHeadset => "AudioHeadset",
            DeviceCategory::AudioSpeaker => "AudioSpeaker",
            DeviceCategory::Phone => "Phone",
            DeviceCategory::InputKeyboard => "InputKeyboard",
            DeviceCategory::InputMouse => "InputMouse",
            DeviceCategory::Unknown => "Unknown",
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct BluetoothDevice {
    pub address: String,
    pub name: String,
    pub alias: String,
    pub category: DeviceCategory,
    pub is_paired: bool,
    pub is_connected: bool,
    pub is_trusted: bool,
    pub battery_percentage: Option<u8>,
    pub rssi: Option<i16>,
    pub uuids: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BluetoothAdapterInfo {
    pub address: String,
    pub name: String,
    pub is_powered: bool,
    pub is_discovering: bool,
    pub is_pairable: bool,
    pub manufacturer: String,
    pub chipset_name: String,
    pub bluetooth_version: String,
    pub hci_version: u8,
    pub max_active_connections: u8,
    pub max_recommended_audio_streams: u8,
    pub supports_le_audio: bool,
    pub supports_2m_phy: bool,
}
