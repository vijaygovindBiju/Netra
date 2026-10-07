pub mod bandwidth;
pub mod clients;
pub mod nm_dbus;
pub mod oui;

pub use bandwidth::BandwidthMonitor;
pub use clients::ClientTracker;
pub use nm_dbus::NetworkManagerClient;
pub use oui::lookup_vendor;

use netra_common::models::hotspot::{ConnectedClient, HotspotConfig, HotspotStatus, QoSPriority};
use netra_common::models::network::{AccessPointInfo, InterfaceMetrics, InterfaceState};
use netra_common::{NetraError, Result};
use tracing::{error, info};
use zbus::zvariant::OwnedObjectPath;

pub struct NetworkEngine {
    nm_client: NetworkManagerClient,
    bandwidth_monitor: BandwidthMonitor,
    client_tracker: ClientTracker,
    primary_wifi: Option<(String, OwnedObjectPath)>,
    hotspot_status: HotspotStatus,
    active_hotspot_config: Option<HotspotConfig>,
}

impl NetworkEngine {
    pub async fn new() -> Result<Self> {
        let nm_client = NetworkManagerClient::new().await?;
        let primary_wifi = nm_client.get_primary_wireless_device().await.ok();
        
        info!(
            "NetworkEngine initialized. Primary Wi-Fi interface: {:?}",
            primary_wifi.as_ref().map(|(name, _)| name)
        );

        Ok(Self {
            nm_client,
            bandwidth_monitor: BandwidthMonitor::new(),
            client_tracker: ClientTracker::new(),
            primary_wifi,
            hotspot_status: HotspotStatus::Inactive,
            active_hotspot_config: None,
        })
    }

    pub fn get_primary_interface_name(&self) -> Option<String> {
        self.primary_wifi.as_ref().map(|(name, _)| name.clone())
    }

    pub async fn scan_wifi(&self) -> Result<()> {
        let (_, dev_path) = self.primary_wifi.as_ref().ok_or_else(|| {
            NetraError::InterfaceNotFound("No wireless interface available".into())
        })?;

        self.nm_client.request_wifi_scan(&dev_path.as_ref()).await
    }

    pub async fn get_access_points(&self) -> Result<Vec<AccessPointInfo>> {
        let (_, dev_path) = self.primary_wifi.as_ref().ok_or_else(|| {
            NetraError::InterfaceNotFound("No wireless interface available".into())
        })?;

        self.nm_client.get_access_points(&dev_path.as_ref()).await
    }

    pub async fn connect_wifi(&self, ssid: &str, passphrase: &str) -> Result<()> {
        let (_, dev_path) = self.primary_wifi.as_ref().ok_or_else(|| {
            NetraError::InterfaceNotFound("No wireless interface available".into())
        })?;

        self.nm_client.connect_wifi(&dev_path.as_ref(), ssid, passphrase).await
    }

    pub async fn disconnect_wifi(&self) -> Result<()> {
        let (_, dev_path) = self.primary_wifi.as_ref().ok_or_else(|| {
            NetraError::InterfaceNotFound("No wireless interface available".into())
        })?;

        self.nm_client.disconnect_wifi(&dev_path.as_ref()).await
    }

    pub async fn start_hotspot(&mut self, config: HotspotConfig) -> Result<()> {
        let (_, dev_path) = self.primary_wifi.as_ref().ok_or_else(|| {
            NetraError::InterfaceNotFound("No wireless interface available".into())
        })?;

        self.hotspot_status = HotspotStatus::Starting;
        match self.nm_client.start_hotspot(&dev_path.as_ref(), &config).await {
            Ok(()) => {
                self.hotspot_status = HotspotStatus::Active;
                self.active_hotspot_config = Some(config);
                info!("Hotspot successfully started");
                Ok(())
            }
            Err(e) => {
                self.hotspot_status = HotspotStatus::Failed(e.to_string());
                error!("Hotspot activation failed: {e}");
                Err(e)
            }
        }
    }

    pub async fn stop_hotspot(&mut self) -> Result<()> {
        self.hotspot_status = HotspotStatus::Stopping;
        match self.nm_client.stop_hotspot().await {
            Ok(()) => {
                self.hotspot_status = HotspotStatus::Inactive;
                self.active_hotspot_config = None;
                info!("Hotspot successfully stopped");
                Ok(())
            }
            Err(e) => {
                self.hotspot_status = HotspotStatus::Failed(e.to_string());
                Err(e)
            }
        }
    }

    pub fn get_hotspot_status(&self) -> HotspotStatus {
        self.hotspot_status.clone()
    }

    pub fn get_connected_clients(&mut self) -> Result<Vec<ConnectedClient>> {
        let iface = self.get_primary_interface_name().unwrap_or_default();
        self.client_tracker.discover_clients(&iface)
    }

    pub fn set_client_priority(&mut self, mac: &str, priority: QoSPriority) {
        self.client_tracker.set_priority(mac, priority);
    }

    pub fn get_interface_metrics(&mut self) -> Result<Vec<InterfaceMetrics>> {
        let rates = self.bandwidth_monitor.update()?;
        let primary_iface = self.get_primary_interface_name().unwrap_or_default();

        let mut metrics_list = Vec::new();

        for (iface, rate) in rates {
            let is_wireless = iface == primary_iface;
            let state = if is_wireless {
                if self.hotspot_status == HotspotStatus::Active {
                    InterfaceState::Connected
                } else {
                    InterfaceState::Connected
                }
            } else {
                InterfaceState::Connected
            };

            metrics_list.push(InterfaceMetrics {
                iface_name: iface,
                state,
                is_wireless,
                rx_bytes: rate.rx_bytes,
                tx_bytes: rate.tx_bytes,
                rx_rate_bps: rate.rx_rate_bps,
                tx_rate_bps: rate.tx_rate_bps,
                ip_address: None,
                gateway: None,
                dns_servers: Vec::new(),
                connected_ssid: if is_wireless {
                    self.active_hotspot_config.as_ref().map(|c| c.ssid.clone())
                } else {
                    None
                },
            });
        }

        Ok(metrics_list)
    }
}
