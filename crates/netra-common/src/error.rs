use thiserror::Error;

#[derive(Error, Debug)]
pub enum NetraError {
    #[error("NetworkManager error: {0}")]
    NetworkManager(String),

    #[error("Interface not found: {0}")]
    InterfaceNotFound(String),

    #[error("Wi-Fi scanning failed: {0}")]
    ScanFailed(String),

    #[error("Connection failed: {0}")]
    ConnectionFailed(String),

    #[error("Hotspot operation failed: {0}")]
    HotspotError(String),

    #[error("Polkit authorization denied: {0}")]
    AuthorizationDenied(String),

    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),

    #[error("D-Bus error: {0}")]
    DBus(String),

    #[error("Netlink error: {0}")]
    Netlink(String),

    #[error("Invalid parameter: {0}")]
    InvalidParameter(String),
}

pub type Result<T> = std::result::Result<T, NetraError>;
